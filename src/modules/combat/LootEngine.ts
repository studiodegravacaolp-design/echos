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
 * Expoente de escalabilidade de recompensa — determina o fator de
 * crescimento exponencial da sucata por nível do inimigo.
 *
 * Fórmula completa:
 *   scrapYield = Math.round(enemyLevel^SCALE_EXPONENT * BASE_SCRAP_PER_LEVEL * multiplicador)
 *
 * Com SCALE_EXPONENT = 1.15, inimigos de nível mais alto concedem
 * sucata progressivamente maior, incentivando o jogador a enfrentar
 * desafios maiores. (Sprint 10 — Fator de Escalabilidade)
 */
const SCALE_EXPONENT = 1.15;

/**
 * Expoente de escalabilidade de atributos de inimigo — aplicado
 * sobre o nível do inimigo para escalar seus stats base.
 *
 *   scaledStat = Math.round(baseStat * Math.pow(enemyLevel, ATTRIBUTE_SCALE_EXPONENT))
 *
 * ATTRIBUTE_SCALE_EXPONENT = 0.25 garante um crescimento sublinear
 * mas significativo (nível 50 => ~2.66x os atributos base).
 * (Sprint 10 — Fator de Escalabilidade de Inimigos)
 */
export const ATTRIBUTE_SCALE_EXPONENT = 0.25;

/** Atributos base de um inimigo NORMAL de nível 1 */
export const BASE_ENEMY_STATS = {
  maxHp: 100,
  damage: 15,
  defense: 10,
  resilience: 8,
  movementSpeed: 80,
};

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
  // MÉTODO: scaleEnemyStats
  // ==================================================================

  /**
   * scaleEnemyStats(enemyLevel)
   * ------------------------------------------------------------------
   * Escala os atributos base de um inimigo de acordo com seu nível,
   * usando o fator exponencial ATTRIBUTE_SCALE_EXPONENT.
   *
   * Fórmula:
   *   scaleFactor = Math.pow(enemyLevel, ATTRIBUTE_SCALE_EXPONENT)
   *   statEscalado = Math.round(statBase * scaleFactor)
   *
   * Com expoente 0.25, nível 50 produz fator ~2.66x.
   *
   * @param enemyLevel - Nível do inimigo (>= 1)
   * @returns Cópia dos atributos escalados
   */
  public static scaleEnemyStats(enemyLevel: number): { maxHp: number; damage: number; defense: number; resilience: number; movementSpeed: number } {
    const safeLevel = Number.isFinite(enemyLevel) && enemyLevel >= 1 ? Math.floor(enemyLevel) : 1;
    const factor = Math.pow(safeLevel, ATTRIBUTE_SCALE_EXPONENT);

    return {
      maxHp: Math.round(BASE_ENEMY_STATS.maxHp * factor),
      damage: Math.round(BASE_ENEMY_STATS.damage * factor),
      defense: Math.round(BASE_ENEMY_STATS.defense * factor),
      resilience: Math.round(BASE_ENEMY_STATS.resilience * factor),
      movementSpeed: Math.round(BASE_ENEMY_STATS.movementSpeed * factor),
    };
  }

  // ==================================================================
  // MÉTODO: calculateBattleLoot
  // ==================================================================

  /**
   * calculateBattleLoot(enemyLevel, isMechanical)
   * ------------------------------------------------------------------
   * Calcula a quantidade de sucata concedida pela derrota de um
   * inimigo, com crescimento exponencial conforme o nível:
   *
   *   scrapYield = Math.round(enemyLevel^SCALE_EXPONENT * BASE_SCRAP_PER_LEVEL * multiplicador)
   *
   * Inimigos mecânicos concedem o dobro de sucata (MECHANICAL_LOOT_MULTIPLIER),
   * refletindo que seus componentes físicos são diretamente reaproveitáveis
   * pela Engenharia Elemental.
   *
   * Fator exponencial SCALE_EXPONENT = 1.15 garante recompensa progressivamente
   * maior para inimigos de nível mais alto. (Sprint 10)
   *
   * @param enemyLevel   - Nível do inimigo derrotado
   * @param isMechanical - Se o inimigo é do tipo mecânico
   * @returns A quantidade de sucata (sempre >= 0, inteiro)
   */
  public static calculateBattleLoot(enemyLevel: number, isMechanical: boolean): number {
    const safeLevel = Number.isFinite(enemyLevel) && enemyLevel > 0 ? enemyLevel : 0;
    const multiplier = isMechanical ? MECHANICAL_LOOT_MULTIPLIER : 1.0;

    // Sprint 10: Escalabilidade exponencial com SCALE_EXPONENT
    const levelFactor = Math.pow(safeLevel, SCALE_EXPONENT);

    return Math.round(levelFactor * BASE_SCRAP_PER_LEVEL * multiplier);
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
