/**
 * ====================================================================
 * CombatLoopEngine.ts
 * --------------------------------------------------------------------
 * Loop de combate por turnos do Aetheris.
 *
 * Consome um encontro gerado pelo BestiaryEngine (IEnemyInstance[]) e
 * resolve o combate turno a turno entre a party e os inimigos,
 * reutilizando:
 *   - CombatEngine.calculateMitigatedDamage (mitigação hiperbólica)
 *   - StatusEngine (DoT e modificadores de atributo por condição)
 *   - CombatAIEngine (escolha de alvo dos inimigos por arquétipo)
 *   - CharacterState.getEffective* (atributos com Estafa/status/oxidação)
 *
 * Headless e determinístico (sem readline/aleatoriedade): heróis focam
 * o inimigo com menor HP; inimigos usam sua IA. Adequado a simulação,
 * auto-resolução no CLI e testes.
 *
 * ARQUITETURA: reside em core e NÃO depende do CLI. Constrói os
 * combatentes inimigos (CharacterState) e suas IAs a partir das
 * instâncias do bestiário.
 * ====================================================================
 */

import { CharacterState } from './CharacterState';
import { CombatEngine } from './CombatEngine';
import { CombatAIEngine } from './CombatAIEngine';
import { StatusEngine } from './StatusEngine';
import { IEnemyInstance, ENEMY_TO_COMBAT_ARCHETYPE } from './BestiaryEngine';
import { PenetrationType } from '../types/aetheris.types';

// ==================================================================
// TIPAGENS
// ==================================================================

export type CombatOutcome = 'VICTORY' | 'DEFEAT' | 'DRAW';

export interface ICombatResult {
    outcome: CombatOutcome;
    /** Número de rodadas executadas. */
    rounds: number;
    /** Log narrado do combate. */
    log: string[];
    /** IDs dos membros da party sobreviventes (HP > 0). */
    survivingParty: string[];
    /** IDs dos inimigos derrotados. */
    defeatedEnemies: string[];
}

export interface ICombatOptions {
    /** Estafa do grupo (influencia a IA inimiga). */
    estafaBalance?: number;
    /** Teto de rodadas para evitar combates infinitos (padrão 50). */
    maxRounds?: number;
}

/** Combatente interno (party ou inimigo). */
interface ICombatant {
    state: CharacterState;
    side: 'PARTY' | 'ENEMY';
    name: string;
    ai?: CombatAIEngine;
}

const DEFAULT_MAX_ROUNDS = 50;

// ==================================================================
// CLASSE — CombatLoopEngine
// ==================================================================

export class CombatLoopEngine {
    private readonly engine = new CombatEngine();

    /**
     * runCombat(party, enemyInstances, options?)
     * ------------------------------------------------------------------
     * Executa o combate completo e retorna o desfecho + log.
     *
     * @param party          - Membros da party (CharacterState[])
     * @param enemyInstances - Inimigos do encontro (BestiaryEngine)
     * @param options        - { estafaBalance, maxRounds }
     */
    public runCombat(
        party: CharacterState[],
        enemyInstances: IEnemyInstance[],
        options: ICombatOptions = {},
    ): ICombatResult {
        const estafa = options.estafaBalance ?? 0;
        const maxRounds = options.maxRounds ?? DEFAULT_MAX_ROUNDS;
        const log: string[] = [];

        // Constrói os combatentes.
        const combatants: ICombatant[] = [
            ...party.map((state) => ({ state, side: 'PARTY' as const, name: state.id })),
            ...enemyInstances.map((inst) => this.buildEnemyCombatant(inst)),
        ];

        const alive = (c: ICombatant) => c.state.hp > 0;
        const partyAlive = () => combatants.filter((c) => c.side === 'PARTY' && alive(c));
        const enemiesAlive = () => combatants.filter((c) => c.side === 'ENEMY' && alive(c));

        log.push(`⚔️ Combate iniciado: ${party.length} herói(s) vs ${enemyInstances.length} inimigo(s).`);

        let round = 0;
        while (round < maxRounds && partyAlive().length > 0 && enemiesAlive().length > 0) {
            round++;
            log.push(`\n── Rodada ${round} ──`);

            // Ordem de turno por velocidade efetiva (RUST_LOCK desacelera);
            // empate → party age antes dos inimigos.
            const turnOrder = combatants
                .filter(alive)
                .sort((a, b) => {
                    const diff = b.state.getEffectiveMovementSpeed() - a.state.getEffectiveMovementSpeed();
                    if (diff !== 0) return diff;
                    return a.side === b.side ? 0 : a.side === 'PARTY' ? -1 : 1;
                });

            for (const actor of turnOrder) {
                if (!alive(actor)) continue; // pode ter morrido nesta rodada

                // Início de turno: DoT + decremento de durações.
                const tick = StatusEngine.processTurnStart(actor.state);
                if (tick.totalDamage > 0) {
                    log.push(`   ☠️ ${actor.name} sofre ${tick.totalDamage} de dano contínuo.`);
                }
                if (!alive(actor)) {
                    log.push(`   💀 ${actor.name} sucumbe às condições.`);
                    continue;
                }

                // Se um lado foi eliminado no meio da rodada, encerra.
                if (partyAlive().length === 0 || enemiesAlive().length === 0) break;

                // Escolha de alvo + ataque.
                const target = this.selectTarget(actor, partyAlive(), enemiesAlive(), estafa);
                if (!target) continue;

                const dealt = this.resolveAttack(actor.state, target.state);
                log.push(`   ${actor.side === 'PARTY' ? '🛠️' : '👾'} ${actor.name} ataca ${target.name} causando ${dealt} de dano (HP ${Math.max(0, target.state.hp)}/${target.state.maxHp}).`);
                if (!alive(target)) {
                    log.push(`   💥 ${target.name} foi derrotado!`);
                }
            }
        }

        // Desfecho.
        let outcome: CombatOutcome;
        if (enemiesAlive().length === 0 && partyAlive().length > 0) outcome = 'VICTORY';
        else if (partyAlive().length === 0) outcome = 'DEFEAT';
        else outcome = 'DRAW';

        log.push(`\n🏁 Resultado: ${outcome} em ${round} rodada(s).`);

        return {
            outcome,
            rounds: round,
            log,
            survivingParty: partyAlive().map((c) => c.state.id),
            defeatedEnemies: combatants.filter((c) => c.side === 'ENEMY' && !alive(c)).map((c) => c.state.id),
        };
    }

    // --------------------------------------------------------------
    // AUXILIARES
    // --------------------------------------------------------------

    /** Converte uma IEnemyInstance em combatente (CharacterState + IA). */
    private buildEnemyCombatant(inst: IEnemyInstance): ICombatant {
        const state = new CharacterState(
            { ...inst.stats },
            undefined,
            undefined,
            undefined,
            null,
            inst.instanceId,
        );
        state.currentLevel = inst.level;

        // Transfere as condições ambientais (ex.: RUST_LOCK) para o combatente.
        const statuses = state.activeStatuses;
        for (const s of inst.activeStatuses) {
            statuses.push({ ...s });
        }

        const ai = new CombatAIEngine(inst.instanceId, ENEMY_TO_COMBAT_ARCHETYPE[inst.archetypeAI]);
        return { state, side: 'ENEMY', name: inst.name, ai };
    }

    /**
     * Escolha de alvo:
     *   - PARTY: foca o inimigo vivo com menor HP (focus fire determinístico).
     *   - ENEMY: usa a IA (CombatAIEngine.evaluateAction) para mirar a party.
     */
    private selectTarget(
        actor: ICombatant,
        partyAlive: ICombatant[],
        enemiesAlive: ICombatant[],
        estafa: number,
    ): ICombatant | null {
        if (actor.side === 'PARTY') {
            if (enemiesAlive.length === 0) return null;
            return enemiesAlive.reduce((lowest, c) => (c.state.hp < lowest.state.hp ? c : lowest));
        }

        // Inimigo: delega à IA (enemies = time do ator; party = heróis).
        if (partyAlive.length === 0) return null;
        if (actor.ai) {
            const decision = actor.ai.evaluateAction(
                enemiesAlive.map((c) => c.state),
                partyAlive.map((c) => c.state),
                estafa,
            );
            const chosen = partyAlive.find((c) => c.state.id === decision.targetId);
            if (chosen) return chosen;
        }
        return partyAlive[0];
    }

    /**
     * Resolve um ataque físico: dano efetivo do atacante mitigado pela
     * defesa efetiva do alvo (fricção FÍSICA). Aplica o dano e retorna o
     * valor arredondado infligido.
     */
    private resolveAttack(attacker: CharacterState, target: CharacterState): number {
        const raw = attacker.getEffectiveDamage();
        const fractured = target.hasStatusEffect('FRATURA_FRENESI');
        const mitigated = this.engine.calculateMitigatedDamage(
            raw,
            target.getEffectivePhysicalDefense(),
            PenetrationType.FISICA,
            fractured,
        );
        const dealt = Math.round(mitigated);
        target.applyDirectDamage(dealt);
        return dealt;
    }
}
