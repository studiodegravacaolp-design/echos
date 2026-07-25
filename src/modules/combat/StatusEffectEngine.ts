// src/modules/combat/StatusEffectEngine.ts

import { ICombatantState, IStatusEffect } from '../../types/aetheris.types';

export class StatusEffectEngine {
    private activeEffects: Map<string, IStatusEffect[]> = new Map(); // Chave: combatantId

    /**
     * Aplica um efeito de status temporário a um combatente.
     */
    public applyEffect(combatantId: string, effect: IStatusEffect): void {
        if (!this.activeEffects.has(combatantId)) {
            this.activeEffects.set(combatantId, []);
        }

        const effects = this.activeEffects.get(combatantId)!;
        const existingIndex = effects.findIndex(e => e.id === effect.id);

        if (existingIndex !== -1) {
            // Se o efeito já existe, renova a duração e mantém o mais forte
            effects[existingIndex].duration = Math.max(effects[existingIndex].duration, effect.duration);
        } else {
            effects.push({ ...effect });
        }
    }

    /**
     * Executa as ações de início de turno (ex: ticks de dano de Vapor)
     */
    public processTurnStartTicks(combatant: ICombatantState): string[] {
        const combatantId = combatant.id;
        const effects = this.activeEffects.get(combatantId) || [];
        const logs: string[] = [];

        effects.forEach(effect => {
            if (!effect.applyTick) {
                return;
            }
            const tickResult = effect.applyTick(combatant);
            if (tickResult.hpDelta !== 0) {
                combatant.stats.currentHp = Math.max(1, combatant.stats.currentHp + tickResult.hpDelta); // Impede morte direta por tick ambiental
            }
            if (tickResult.message) {
                logs.push(tickResult.message);
            }
        });

        return logs;
    }

    /**
     * Decrementa a duração dos efeitos e remove os expirados ao fim do turno.
     */
    public processTurnEndDecrement(combatantId: string): string[] {
        const effects = this.activeEffects.get(combatantId) || [];
        const logs: string[] = [];

        const updatedEffects = effects.map(effect => {
            effect.duration -= 1;
            return effect;
        }).filter(effect => {
            if (effect.duration <= 0) {
                logs.push(`✨ O efeito '${effect.name}' expirou em ${combatantId}.`);
                return false;
            }
            return true;
        });

        this.activeEffects.set(combatantId, updatedEffects);
        return logs;
    }

    /**
     * Retorna o multiplicador de ataque acumulado de todos os efeitos ativos.
     */
    public getAttackModifier(combatantId: string, baseAttack: number): number {
        const effects = this.activeEffects.get(combatantId) || [];
        let finalAttack = baseAttack;

        effects.forEach(effect => {
            if (effect.modifyAttack) {
                finalAttack = effect.modifyAttack(finalAttack);
            }
        });

        return finalAttack;
    }

    /**
     * Retorna o multiplicador de defesa acumulado de todos os efeitos ativos.
     */
    public getDefenseModifier(combatantId: string, baseDefense: number): number {
        const effects = this.activeEffects.get(combatantId) || [];
        let finalDefense = baseDefense;

        effects.forEach(effect => {
            if (effect.modifyDefense) {
                finalDefense = effect.modifyDefense(finalDefense);
            }
        });

        return finalDefense;
    }

    public getActiveEffectsFor(combatantId: string): IStatusEffect[] {
        return this.activeEffects.get(combatantId) || [];
    }

    public clear(): void {
        this.activeEffects.clear();
    }
}