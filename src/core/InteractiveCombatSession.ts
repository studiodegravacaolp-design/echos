/**
 * ====================================================================
 * InteractiveCombatSession.ts
 * --------------------------------------------------------------------
 * Combate por turnos INTERATIVO — o jogador escolhe a ação de cada
 * herói, e cada comando passa pela Balança de Estafa (Insubordinação
 * Tática) antes de ser executado.
 *
 * Máquina de estados dirigível passo a passo (sem readline): o driver
 * (CLI ou teste) consulta getCurrentTurn(), lista as ações disponíveis
 * (com bloqueios por Estafa) e chama submitPlayerAction(); os turnos de
 * inimigos e o dano contínuo (DoT) são resolvidos automaticamente entre
 * as decisões do jogador.
 *
 * Reutiliza: CombatEngine (mitigação), StatusEngine (DoT/atributos),
 * CombatAIEngine (alvo dos inimigos + resolvePlayerCommand da
 * Insubordinação) e EstafaCalculator (bloqueio de ações na UI).
 * ====================================================================
 */

import { CharacterState } from './CharacterState';
import { CombatEngine } from './CombatEngine';
import { CombatAIEngine } from './CombatAIEngine';
import { StatusEngine } from './StatusEngine';
import { EstafaCalculator, EstafaActionType } from '../mechanics/EstafaCalculator';
import { IEnemyInstance, ENEMY_TO_COMBAT_ARCHETYPE } from './BestiaryEngine';
import { PenetrationType } from '../types/aetheris.types';
import { CombatOutcome } from './CombatLoopEngine';

// ==================================================================
// TIPAGENS
// ==================================================================

/** Ação de combate escolhível pelo jogador. */
export type CombatActionType = 'ATTACK' | 'EXECUTE' | 'MERCY_HEAL';

/** Opção de ação renderizável (com estado de bloqueio pela Estafa). */
export interface ICombatActionOption {
    action: CombatActionType;
    label: string;
    /** true se a psique atual do herói bloqueia esta ação. */
    locked: boolean;
    lockReason?: string;
}

/** Instantâneo de um combatente para a UI. */
export interface ICombatantView {
    id: string;
    name: string;
    hp: number;
    maxHp: number;
}

/** Contexto do turno atual (decisão de um herói). */
export interface ITurnContext {
    round: number;
    actorId: string;
    actorName: string;
    actorEstafa: number;
    actions: ICombatActionOption[];
    enemies: ICombatantView[];
    allies: ICombatantView[];
}

/** Resultado da resolução de uma ação do jogador. */
export interface IActionResolution {
    requestedAction: CombatActionType;
    /** Ação efetivamente executada (difere da pedida em caso de insubordinação). */
    executedAction: CombatActionType;
    insubordination: boolean;
    lockReason?: string;
    autonomousAlternative?: string;
    /** Deslocamento de Estafa aplicado por esta ação (0 se bloqueada/neutra). */
    estafaShift: number;
    /** Log desta ação + turnos inimigos até a próxima decisão. */
    log: string[];
    over: boolean;
    outcome?: CombatOutcome;
}

/** Combatente interno. */
interface ICombatant {
    state: CharacterState;
    side: 'PARTY' | 'ENEMY';
    name: string;
    ai?: CombatAIEngine;
}

export interface ICombatSessionOptions {
    estafaBalance?: number;
    maxRounds?: number;
}

// ==================================================================
// CONSTANTES
// ==================================================================

const DEFAULT_MAX_ROUNDS = 50;
/** Multiplicador de dano da Execução Fria. */
const EXECUTE_DAMAGE_MULTIPLIER = 1.6;
/** Fator de cura da Cura Compassiva (sobre o dano efetivo do curador). */
const MERCY_HEAL_FACTOR = 1.5;

/**
 * Deslocamento de Estafa por ação executada (feedback loop):
 *   - Execução Fria endurece o líder rumo ao Paterno (+).
 *   - Cura Compassiva o abranda rumo ao Materno (−).
 *   - Ataque padrão é neutro.
 */
const ESTAFA_SHIFT_BY_ACTION: Record<CombatActionType, number> = {
    ATTACK: 0,
    EXECUTE: 10,
    MERCY_HEAL: -10,
};

/** Mapa de ação de combate → tipo de ação da Balança de Estafa. */
const COMBAT_TO_ESTAFA: Record<CombatActionType, EstafaActionType> = {
    ATTACK: 'STANDARD',
    EXECUTE: 'COLD_EXECUTION',
    MERCY_HEAL: 'COMPASSIONATE_HEAL',
};

const ACTION_LABELS: Record<CombatActionType, string> = {
    ATTACK: '⚔️ Atacar',
    EXECUTE: '🔪 Execução Fria',
    MERCY_HEAL: '💧 Cura Compassiva',
};

// ==================================================================
// CLASSE — InteractiveCombatSession
// ==================================================================

export class InteractiveCombatSession {
    private readonly engine = new CombatEngine();
    private readonly combatants: ICombatant[] = [];
    private readonly estafa: number;
    private readonly maxRounds: number;

    private round = 0;
    private turnQueue: ICombatant[] = [];
    private turnIndex = 0;
    private pendingActor: ICombatant | null = null;
    private over = false;
    private outcome: CombatOutcome | null = null;
    private readonly fullLog: string[] = [];
    /** Soma dos deslocamentos de Estafa das ações do jogador no combate. */
    private netEstafaShift = 0;

    constructor(
        party: CharacterState[],
        enemyInstances: IEnemyInstance[],
        options: ICombatSessionOptions = {},
    ) {
        this.estafa = options.estafaBalance ?? 0;
        this.maxRounds = options.maxRounds ?? DEFAULT_MAX_ROUNDS;

        // A Estafa do grupo modela a psique dos heróis neste combate
        // (medidor de curto prazo — não persiste fora do combate).
        const seededEstafa = EstafaCalculator.clamp(this.estafa);

        for (const state of party) {
            state.shortTermEstafa = seededEstafa;
            this.combatants.push({ state, side: 'PARTY', name: state.id });
        }
        for (const inst of enemyInstances) {
            this.combatants.push(this.buildEnemyCombatant(inst));
        }
    }

    // --------------------------------------------------------------
    // API PÚBLICA
    // --------------------------------------------------------------

    /** Inicia o combate e avança até a primeira decisão de herói. */
    public start(): void {
        this.fullLog.push(`⚔️ Combate iniciado.`);
        this.startRound();
        this.advanceToNextDecision();
    }

    /** Contexto do turno atual, ou null se o combate acabou. */
    public getCurrentTurn(): ITurnContext | null {
        if (this.over || !this.pendingActor) return null;
        const actor = this.pendingActor;
        return {
            round: this.round,
            actorId: actor.state.id,
            actorName: actor.name,
            actorEstafa: actor.state.shortTermEstafa,
            actions: this.availableActions(actor),
            enemies: this.viewOf('ENEMY'),
            allies: this.viewOf('PARTY'),
        };
    }

    public isOver(): boolean {
        return this.over;
    }

    public getOutcome(): CombatOutcome | null {
        return this.outcome;
    }

    public getFullLog(): string[] {
        return [...this.fullLog];
    }

    /**
     * submitPlayerAction(action, targetId?)
     * ------------------------------------------------------------------
     * Resolve a ação do herói corrente através da Insubordinação Tática
     * e avança até a próxima decisão (resolvendo turnos inimigos e DoT).
     */
    public submitPlayerAction(action: CombatActionType, targetId?: string): IActionResolution {
        if (this.over || !this.pendingActor) {
            return {
                requestedAction: action,
                executedAction: action,
                insubordination: false,
                estafaShift: 0,
                log: ['(combate encerrado — ação ignorada)'],
                over: this.over,
                outcome: this.outcome ?? undefined,
            };
        }

        const actor = this.pendingActor;
        const localLog: string[] = [];

        // Validação da Insubordinação Tática (usa a Estafa do herói).
        const estafaType = COMBAT_TO_ESTAFA[action];
        const resolution = CombatAIEngine.resolvePlayerCommand(
            actor.state,
            estafaType,
            (code, message) => localLog.push(`   ⚠️ [${code}] ${message}`),
        );

        let executed: CombatActionType = action;
        let estafaShift = 0;

        if (resolution.insubordination) {
            // Comando bloqueado → executa a ação autônoma modificada.
            // Sem deslocamento de Estafa: a intenção foi recusada pela unidade.
            localLog.push(`   🧠 Insubordinação: ${resolution.reason}`);
            localLog.push(`   ➡️ ${resolution.autonomousAlternative}`);
            executed = 'ATTACK'; // a alternativa autônoma resolve como ataque padrão
            this.applyAttack(actor, targetId, localLog, { nonLethal: action === 'EXECUTE' });
        } else {
            // Comando permitido → executa a ação pedida.
            switch (action) {
                case 'ATTACK':
                    this.applyAttack(actor, targetId, localLog);
                    break;
                case 'EXECUTE':
                    this.applyAttack(actor, targetId, localLog, { multiplier: EXECUTE_DAMAGE_MULTIPLIER });
                    break;
                case 'MERCY_HEAL':
                    this.applyHeal(actor, localLog);
                    break;
            }

            // Feedback loop: a ação executada desloca a Estafa do herói e do grupo.
            estafaShift = ESTAFA_SHIFT_BY_ACTION[action];
            if (estafaShift !== 0) {
                actor.state.shortTermEstafa = actor.state.shortTermEstafa + estafaShift;
                this.netEstafaShift += estafaShift;
                localLog.push(
                    `   ⚖️ A escolha desloca a Estafa de ${actor.name} em ${estafaShift >= 0 ? '+' : ''}${estafaShift} ` +
                    `(agora ${actor.state.shortTermEstafa}).`,
                );
            }
        }

        this.pendingActor = null;

        // Verifica desfecho e avança para a próxima decisão.
        this.checkOutcome();
        if (!this.over) {
            this.advanceToNextDecision();
        }

        this.fullLog.push(...localLog);

        return {
            requestedAction: action,
            executedAction: executed,
            insubordination: resolution.insubordination,
            lockReason: resolution.reason,
            autonomousAlternative: resolution.autonomousAlternative,
            estafaShift,
            log: localLog,
            over: this.over,
            outcome: this.outcome ?? undefined,
        };
    }

    /** Soma dos deslocamentos de Estafa das ações do jogador (para persistir no grupo). */
    public getNetEstafaShift(): number {
        return this.netEstafaShift;
    }

    // --------------------------------------------------------------
    // STEPPING INTERNO
    // --------------------------------------------------------------

    private startRound(): void {
        this.round++;
        this.turnQueue = this.combatants
            .filter((c) => this.alive(c))
            .sort((a, b) => {
                const diff = b.state.getEffectiveMovementSpeed() - a.state.getEffectiveMovementSpeed();
                if (diff !== 0) return diff;
                return a.side === b.side ? 0 : a.side === 'PARTY' ? -1 : 1;
            });
        this.turnIndex = 0;
        this.fullLog.push(`\n── Rodada ${this.round} ──`);
    }

    /**
     * Avança pelos turnos resolvendo DoT e ações inimigas automaticamente,
     * parando quando um herói vivo precisa decidir (pendingActor) ou o
     * combate termina.
     */
    private advanceToNextDecision(): void {
        while (!this.over) {
            if (this.turnIndex >= this.turnQueue.length) {
                if (this.round >= this.maxRounds) {
                    this.over = true;
                    this.outcome = 'DRAW';
                    this.fullLog.push(`\n🏁 Resultado: DRAW em ${this.round} rodada(s).`);
                    return;
                }
                this.startRound();
            }

            const actor = this.turnQueue[this.turnIndex];
            this.turnIndex++;
            if (!this.alive(actor)) continue;

            // Início de turno: DoT + decremento de durações.
            const tick = StatusEngine.processTurnStart(actor.state);
            if (tick.totalDamage > 0) {
                this.fullLog.push(`   ☠️ ${actor.name} sofre ${tick.totalDamage} de dano contínuo.`);
            }
            if (!this.alive(actor)) {
                this.fullLog.push(`   💀 ${actor.name} sucumbe às condições.`);
                this.checkOutcome();
                if (this.over) return;
                continue;
            }

            this.checkOutcome();
            if (this.over) return;

            if (actor.side === 'ENEMY') {
                this.resolveEnemyTurn(actor);
                this.checkOutcome();
                if (this.over) return;
                continue;
            }

            // Herói vivo → ponto de decisão.
            this.pendingActor = actor;
            return;
        }
    }

    private resolveEnemyTurn(actor: ICombatant): void {
        const partyAlive = this.living('PARTY');
        if (partyAlive.length === 0) return;

        let target: ICombatant | undefined;
        if (actor.ai) {
            const decision = actor.ai.evaluateAction(
                this.living('ENEMY').map((c) => c.state),
                partyAlive.map((c) => c.state),
                this.estafa,
            );
            target = partyAlive.find((c) => c.state.id === decision.targetId);
        }
        target = target ?? partyAlive[0];
        this.applyAttack(actor, target.state.id, this.fullLog, {}, this.combatants);
    }

    // --------------------------------------------------------------
    // EFEITOS
    // --------------------------------------------------------------

    private applyAttack(
        attacker: ICombatant,
        targetId: string | undefined,
        log: string[],
        opts: { multiplier?: number; nonLethal?: boolean } = {},
        pool: ICombatant[] = this.combatants,
    ): void {
        const enemiesOfAttacker = pool.filter(
            (c) => c.side !== attacker.side && this.alive(c),
        );
        if (enemiesOfAttacker.length === 0) return;

        const target =
            enemiesOfAttacker.find((c) => c.state.id === targetId) ??
            enemiesOfAttacker.reduce((low, c) => (c.state.hp < low.state.hp ? c : low));

        const raw = attacker.state.getEffectiveDamage() * (opts.multiplier ?? 1);
        const fractured = target.state.hasStatusEffect('FRATURA_FRENESI');
        let dealt = Math.round(
            this.engine.calculateMitigatedDamage(
                raw,
                target.state.getEffectivePhysicalDefense(),
                PenetrationType.FISICA,
                fractured,
            ),
        );

        // Ação autônoma "não-letal": nunca reduz o alvo abaixo de 1 HP.
        if (opts.nonLethal && dealt >= target.state.hp) {
            dealt = Math.max(0, target.state.hp - 1);
        }

        target.state.applyDirectDamage(dealt);
        const icon = attacker.side === 'PARTY' ? '🛠️' : '👾';
        log.push(
            `   ${icon} ${attacker.name} ataca ${target.name} causando ${dealt} de dano ` +
            `(HP ${Math.max(0, target.state.hp)}/${target.state.maxHp}).`,
        );
        if (!this.alive(target)) {
            log.push(`   💥 ${target.name} foi derrotado!`);
        }
    }

    private applyHeal(healer: ICombatant, log: string[]): void {
        const allies = this.living('PARTY');
        if (allies.length === 0) return;
        // Alvo: aliado vivo mais ferido (menor razão de HP).
        const target = allies.reduce((worst, c) =>
            c.state.hp / c.state.maxHp < worst.state.hp / worst.state.maxHp ? c : worst,
        );
        const healAmount = Math.round(healer.state.getEffectiveDamage() * MERCY_HEAL_FACTOR);
        const before = target.state.hp;
        target.state.hp = target.state.hp + healAmount;
        const restored = target.state.hp - before;
        log.push(`   💧 ${healer.name} cura ${target.name} em ${restored} HP (HP ${target.state.hp}/${target.state.maxHp}).`);
    }

    // --------------------------------------------------------------
    // UTIL
    // --------------------------------------------------------------

    private buildEnemyCombatant(inst: IEnemyInstance): ICombatant {
        const state = new CharacterState({ ...inst.stats }, undefined, undefined, undefined, null, inst.instanceId);
        state.currentLevel = inst.level;
        const statuses = state.activeStatuses;
        for (const s of inst.activeStatuses) statuses.push({ ...s });
        const ai = new CombatAIEngine(inst.instanceId, ENEMY_TO_COMBAT_ARCHETYPE[inst.archetypeAI]);
        return { state, side: 'ENEMY', name: inst.name, ai };
    }

    private availableActions(actor: ICombatant): ICombatActionOption[] {
        return (Object.keys(COMBAT_TO_ESTAFA) as CombatActionType[]).map((action) => {
            const validation = EstafaCalculator.validateAction(actor.state.shortTermEstafa, COMBAT_TO_ESTAFA[action]);
            return {
                action,
                label: ACTION_LABELS[action],
                locked: !validation.allowed,
                lockReason: validation.reason,
            };
        });
    }

    private alive(c: ICombatant): boolean {
        return c.state.hp > 0;
    }

    private living(side: 'PARTY' | 'ENEMY'): ICombatant[] {
        return this.combatants.filter((c) => c.side === side && this.alive(c));
    }

    private viewOf(side: 'PARTY' | 'ENEMY'): ICombatantView[] {
        return this.combatants
            .filter((c) => c.side === side)
            .map((c) => ({ id: c.state.id, name: c.name, hp: Math.max(0, c.state.hp), maxHp: c.state.maxHp }));
    }

    private checkOutcome(): void {
        if (this.over) return;
        const partyAlive = this.living('PARTY').length;
        const enemiesAlive = this.living('ENEMY').length;
        if (enemiesAlive === 0 && partyAlive > 0) {
            this.over = true;
            this.outcome = 'VICTORY';
            this.fullLog.push(`\n🏁 Resultado: VICTORY em ${this.round} rodada(s).`);
        } else if (partyAlive === 0) {
            this.over = true;
            this.outcome = 'DEFEAT';
            this.fullLog.push(`\n🏁 Resultado: DEFEAT em ${this.round} rodada(s).`);
        }
    }
}
