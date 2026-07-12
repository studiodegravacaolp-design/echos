/**
 * ====================================================================
 * LootEngine.ts
 * --------------------------------------------------------------------
 * Motor de recompensas pós-batalha — calcula e concede sucata
 * (scrap) ao inventário do grupo ao final de um combate bem-sucedido.
 *
 * Responsabilidades:
 *   - calculateBattleLoot — Calcula a quantidade de sucata proporcional
 *     ao nível e ao tipo (mecânico ou não) do inimigo derrotado.
 *   - awardSalvage — Concede sucata a um ISalvageInventory com segurança.
 *
 * Fonte: src/modules/engineering/SalvageManager.ts (ISalvageInventory)
 * ====================================================================
 */

import { ISalvageInventory } from '../engineering/SalvageManager';

/** Sucata base concedida por nível de inimigo */
const BASE_SCRAP_PER_LEVEL = 5;

/** Multiplicador de sucata para inimigos do tipo mecânico */
const MECHANICAL_LOOT_MULTIPLIER = 2.0;

/**
 * Classe LootEngine
 * --------------------------------------------------------------------
 * Motor estático de recompensas pós-batalha. Não mantém estado
 * próprio — opera diretamente sobre o ISalvageInventory fornecido
 * pelo chamador.
 */
export class LootEngine {
  private constructor() {
    // Classe estática — não deve ser instanciada.
  }

  // ==================================================================
  // MÉTODO: calculateBattleLoot
  // ==================================================================

  /**
   * calculateBattleLoot(enemyLevel, isMechanical)
   * ------------------------------------------------------------------
   * Calcula a quantidade de sucata concedida pela derrota de um
   * inimigo, proporcional ao seu nível:
   *
   *   scrapYield = enemyLevel * BASE_SCRAP_PER_LEVEL * multiplicador
   *
   * Inimigos mecânicos concedem o dobro de sucata (MECHANICAL_LOOT_MULTIPLIER),
   * refletindo que seus componentes físicos são diretamente reaproveitáveis
   * pela Engenharia Elemental.
   *
   * @param enemyLevel   - Nível do inimigo derrotado
   * @param isMechanical - Se o inimigo é do tipo mecânico
   * @returns A quantidade de sucata (sempre >= 0, inteiro)
   */
  public static calculateBattleLoot(enemyLevel: number, isMechanical: boolean): number {
    const safeLevel = Number.isFinite(enemyLevel) && enemyLevel > 0 ? enemyLevel : 0;
    const multiplier = isMechanical ? MECHANICAL_LOOT_MULTIPLIER : 1.0;

    return Math.round(safeLevel * BASE_SCRAP_PER_LEVEL * multiplier);
  }

  // ==================================================================
  // MÉTODO: awardSalvage
  // ==================================================================

  /**
   * awardSalvage(inventory, scrapAmount)
   * ------------------------------------------------------------------
   * Concede sucata a um inventário do grupo, com segurança contra
   * valores inválidos (NaN, Infinity, <= 0 são ignorados — no-op).
   *
   * @param inventory   - Inventário de sucata do grupo a premiar
   * @param scrapAmount - Quantidade de sucata a conceder
   */
  public static awardSalvage(inventory: ISalvageInventory, scrapAmount: number): void {
    if (!Number.isFinite(scrapAmount) || scrapAmount <= 0) {
      return;
    }

    inventory.scrapCount += scrapAmount;
  }
}
