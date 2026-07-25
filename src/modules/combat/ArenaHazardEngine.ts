// src/modules/combat/ArenaHazardEngine.ts

import { ICombatantState, IArenaHazard, IStatusEffect } from '../../types/aetheris.types';
import { StatusEffectEngine } from './StatusEffectEngine';

export class ArenaHazardEngine {
    private activeHazards: IArenaHazard[] = [];
    private statusEngine: StatusEffectEngine;

    constructor(statusEngine: StatusEffectEngine) {
        this.statusEngine = statusEngine;
    }

    /**
     * Registra os perigos ativos para o combate atual.
     */
    public registerHazard(hazard: IArenaHazard): void {
        this.activeHazards.push(hazard);
    }

    /**
     * Executado no início de cada rodada do combate (Round Start).
     * Roda a chance de ativação de 25% para cada perigo registrado.
     */
    public processRoundStartHazards(combatants: ICombatantState[]): string[] {
        const logs: string[] = [];

        this.activeHazards.forEach(hazard => {
            const roll = Math.random();
            if (roll <= hazard.triggerChance) {
                // Dispara o efeito lógico do perigo ambiental
                const result = hazard.onRoundStart(combatants, this.statusEngine);
                if (result.triggered) {
                    logs.push(`⚠️ [PERIGO AMBIENTAL: ${hazard.name}] ${result.description}`);
                }
            }
        });

        return logs;
    }

    public clear(): void {
        this.activeHazards = [];
    }
}

/**
 * [FÁBRICA DE ANOMALIAS CANÔNICAS]
 */
export const HAZARDS_LIBRARY = {
    // 1. Vazamento de Gás Combustível (Aplica Vapor Superaquecido)
    GAS_LEAK: (vaporEffect: IStatusEffect): IArenaHazard => ({
        hazardId: 'hazard_gas_leak',
        name: 'Vazamento de Gás Combustível',
        triggerChance: 0.25, // 25% de chance
        onRoundStart: (combatants, statusEngine) => {
            if (combatants.length === 0) return { triggered: false, description: '' };

            // Escolhe um alvo completamente aleatório (player ou inimigo)
            const randomTarget = combatants[Math.floor(Math.random() * combatants.length)];
            statusEngine.applyEffect(randomTarget.id, { ...vaporEffect });

            return {
                triggered: true,
                description: `Vapor corrosivo escapou dos dutos e envolveu ${randomTarget.id}, aplicando o debuff ${vaporEffect.name}!`
            };
        }
    }),

    // 2. Instabilidade do Chão de Fábrica (Reduz iniciativa de todos)
    GROUND_INSTABILITY: (): IArenaHazard => ({
        hazardId: 'hazard_ground_instability',
        name: 'Instabilidade do Chão de Fábrica',
        triggerChance: 0.25, // 25% de chance
        onRoundStart: (combatants) => {
            combatants.forEach(c => {
                // Reduz temporariamente a iniciativa (ou agilidade simulada) dos combatentes
                if (c.stats) {
                    // Para o teste, aplicamos uma redução fictícia de iniciativa de 5 pontos
                    (c as any).initiativeModifier = ((c as any).initiativeModifier || 0) - 5;
                }
            });

            return {
                triggered: true,
                description: `O chão tremeu devido a uma falha estrutural nos pistões! Todos os combatentes perderam 5 de iniciativa no próximo turno!`
            };
        }
    })
};