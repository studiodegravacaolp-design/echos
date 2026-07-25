/**
 * ====================================================================
 * CombatRewardEngine.ts
 * --------------------------------------------------------------------
 * Recompensas de vitória: sucata (loot) e progressão de nível pós-combate.
 *
 * Ao vencer um encontro, distribui sucata proporcional ao nível/categoria
 * dos inimigos derrotados (via LootEngine) ao grupo, e concede XP a cada
 * sobrevivente (via ProgressionManager), aplicando eventuais subidas de
 * nível e overflow de Marcas de Aço no teto.
 *
 * ARQUITETURA: reside em core; reutiliza LootEngine (sucata) e
 * ProgressionManager (XP/nível). Recebe IEnemyInstance[] do bestiário.
 * ====================================================================
 */

import { CampaignManager, IInventoryItem } from './CampaignManager';
import { CharacterState } from './CharacterState';
import { ProgressionManager } from './ProgressionManager';
import { LootEngine } from '../modules/combat/LootEngine';
import { IEnemyInstance } from './BestiaryEngine';

// ==================================================================
// TIPAGENS
// ==================================================================

/** Subida de nível de um personagem no pós-combate. */
export interface ICharacterLevelUp {
    characterId: string;
    levelsGained: number;
    newLevel: number;
}

/** Recompensa consolidada de uma vitória. */
export interface IVictoryReward {
    /** Sucata total concedida ao grupo. */
    scrapAwarded: number;
    /** XP concedido a cada sobrevivente. */
    xpAwarded: number;
    /** Subidas de nível ocorridas. */
    levelUps: ICharacterLevelUp[];
    /** Marcas de Aço geradas por overflow no nível máximo. */
    overflowMarks: number;
    /** Itens largados pelos inimigos e adicionados ao inventário. */
    itemsDropped: IInventoryItem[];
}

/** Opções de recompensa. */
export interface IRewardOptions {
    /** RNG injetável (padrão Math.random) para as rolagens de drop. */
    rng?: () => number;
}

// ==================================================================
// CONSTANTES
// ==================================================================

/** XP concedido por nível de inimigo derrotado. */
const BASE_XP_PER_ENEMY_LEVEL = 30;

// ==================================================================
// CLASSE — CombatRewardEngine
// ==================================================================

export class CombatRewardEngine {
    public static readonly BASE_XP_PER_ENEMY_LEVEL = BASE_XP_PER_ENEMY_LEVEL;

    /**
     * grantVictoryRewards(campaign, defeatedEnemies, survivors, progression)
     * ------------------------------------------------------------------
     * Concede sucata (distribuída no grupo) e XP (a cada sobrevivente),
     * aplicando subidas de nível. Autômatos rendem mais sucata (loot
     * mecânico). Retorna o resumo das recompensas.
     *
     * @param campaign        - Estado da campanha (recebe a sucata).
     * @param defeatedEnemies - Inimigos derrotados no encontro.
     * @param survivors       - Membros vivos que recebem XP.
     * @param progression     - Gerenciador de progressão (estado de XP).
     */
    public grantVictoryRewards(
        campaign: CampaignManager,
        defeatedEnemies: IEnemyInstance[],
        survivors: CharacterState[],
        progression: ProgressionManager,
        options: IRewardOptions = {},
    ): IVictoryReward {
        const rng = options.rng ?? Math.random;

        // --- Sucata: soma por inimigo (autômato = loot mecânico) ---
        let scrapAwarded = 0;
        for (const enemy of defeatedEnemies) {
            const isMechanical = enemy.category === 'AUTOMATON';
            scrapAwarded += LootEngine.calculateBattleLoot(enemy.level, isMechanical);
        }

        // --- Drops: rola a tabela de cada inimigo derrotado ---
        const itemsDropped: IInventoryItem[] = [];
        for (const enemy of defeatedEnemies) {
            for (const drop of enemy.dropTable) {
                if (rng() < drop.chance) {
                    itemsDropped.push({
                        id: drop.itemId,
                        name: drop.name,
                        type: drop.type,
                        quantity: drop.quantity,
                    });
                }
            }
        }

        // Consolida sucata + itens no grupo/inventário em uma única operação.
        if (scrapAwarded > 0 || itemsDropped.length > 0) {
            campaign.consolidateLoot(scrapAwarded, itemsDropped);
        }

        // --- XP: proporcional ao nível dos inimigos, por sobrevivente ---
        const xpAwarded = defeatedEnemies.reduce(
            (sum, e) => sum + Math.max(1, e.level) * BASE_XP_PER_ENEMY_LEVEL,
            0,
        );

        const levelUps: ICharacterLevelUp[] = [];
        let overflowMarks = 0;

        for (const survivor of survivors) {
            const result = progression.addExperience(survivor, xpAwarded);
            overflowMarks += result.overflowMarks;
            if (result.levelsGained > 0) {
                levelUps.push({
                    characterId: survivor.id,
                    levelsGained: result.levelsGained,
                    newLevel: survivor.currentLevel,
                });
            }
        }

        return { scrapAwarded, xpAwarded, levelUps, overflowMarks, itemsDropped };
    }
}
