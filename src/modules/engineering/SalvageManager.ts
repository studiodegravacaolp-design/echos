/**
 * ====================================================================
 * SalvageManager.ts
 * --------------------------------------------------------------------
 * Economia de sucata (scrap) da Engenharia Elemental. Converte sucata
 * coletada em campo em cargas físicas utilizáveis por
 * EngineeringManager/SkillEngine.
 *
 * Responsabilidades:
 *   - craftCharge — Deduz sucata de um ISalvageInventory e, se
 *     suficiente, fabrica 1 carga de um elemento via
 *     EngineeringManager.reloadKit.
 *
 * Fonte: src/modules/engineering/EngineeringManager.ts
 *        src/types/aetheris.types.ts (ElementType)
 * ====================================================================
 */

import { EngineeringManager, IEngineeringKit } from './EngineeringManager';
import { ElementType } from '../../types/aetheris.types';

/** Custo padrão em sucata para fabricar 1 carga (usado se scrapCost for omitido) */
const DEFAULT_SCRAP_COST = 20;

/**
 * Interface ISalvageInventory
 * --------------------------------------------------------------------
 * Rastreia a quantidade de sucata coletada disponível para fabricação
 * de cargas de Engenharia Elemental.
 */
export interface ISalvageInventory {
  scrapCount: number;
}

/**
 * Classe SalvageManager
 * --------------------------------------------------------------------
 * Motor estático da economia de sucata. Não mantém estado próprio —
 * opera diretamente sobre o ISalvageInventory e o IEngineeringKit
 * fornecidos pelo chamador.
 */
export class SalvageManager {
  private constructor() {
    // Classe estática — não deve ser instanciada.
  }

  // ==================================================================
  // MÉTODO: craftCharge
  // ==================================================================

  /**
   * craftCharge(inventory, kit, element, scrapCost)
   * ------------------------------------------------------------------
   * Fabrica 1 carga física de `element` a partir de sucata coletada.
   *
   *   1. Se `inventory.scrapCount` for insuficiente para `scrapCost`,
   *      retorna false sem mutar inventário ou kit.
   *   2. Caso contrário, deduz `scrapCost` de `inventory.scrapCount`,
   *      chama EngineeringManager.reloadKit(kit, element, 1) e
   *      retorna true.
   *
   * @param inventory  - Inventário de sucata do personagem
   * @param kit        - Kit de Engenharia Elemental a ser recarregado
   * @param element    - Elemento da carga a fabricar
   * @param scrapCost  - Custo em sucata por carga (padrão: 20)
   * @returns true se a carga foi fabricada, false se sucata insuficiente
   *          (ou scrapCost inválido)
   */
  public static craftCharge(
    inventory: ISalvageInventory,
    kit: IEngineeringKit,
    element: ElementType,
    scrapCost: number = DEFAULT_SCRAP_COST,
  ): boolean {
    if (!Number.isFinite(scrapCost) || scrapCost <= 0) {
      return false; // Custo inválido — proteção defensiva
    }

    if (inventory.scrapCount < scrapCost) {
      return false; // Sucata insuficiente
    }

    inventory.scrapCount -= scrapCost;
    EngineeringManager.reloadKit(kit, element, 1);

    return true;
  }
}
