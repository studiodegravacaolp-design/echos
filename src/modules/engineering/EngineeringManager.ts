/**
 * ====================================================================
 * EngineeringManager.ts
 * --------------------------------------------------------------------
 * Mecânica de Engenharia Elemental — exclusiva para as raças HUMAN e
 * DWARF. Permite substituir o custo de Estafa de uma skill por uma
 * carga física de kit de engenharia (FIRE/ICE/LIGHTNING), em vez do
 * fluxo místico padrão de SkillEngine.
 *
 * Responsabilidades:
 *   - processEngineeringUsage — Gate de pré-checagem: para HUMAN/DWARF,
 *     consome 1 carga do kit correspondente ao elemento da skill (sem
 *     tocar em shortTermEstafa); para as demais raças, autoriza o
 *     fluxo místico padrão sem mexer no kit.
 *   - reloadKit — Incrementa cargas físicas de um elemento (itens
 *     consumíveis de recarga), respeitando um teto opcional.
 *
 * Fonte: src/types/aetheris.types.ts (ISkillOrSpell, ElementType, Race)
 *        src/core/CharacterState.ts (race)
 * ====================================================================
 */

import { CharacterState } from '../../core/CharacterState';
import { ISkillOrSpell, ElementType, Race } from '../../types/aetheris.types';

/**
 * Interface IEngineeringKit
 * --------------------------------------------------------------------
 * Rastreia o número de cargas físicas disponíveis por elemento em um
 * kit de Engenharia Elemental.
 */
export interface IEngineeringKit {
  charges: Record<ElementType, number>;
  /**
   * Teto opcional de cargas por elemento (mesmo teto para os três).
   * Se omitido, reloadKit() não aplica nenhum limite superior.
   */
  maxCharges?: number;
}

/**
 * Classe EngineeringManager
 * --------------------------------------------------------------------
 * Motor estático da mecânica de Engenharia Elemental. Não mantém
 * estado próprio — opera diretamente sobre o IEngineeringKit fornecido
 * pelo chamador.
 */
export class EngineeringManager {
  private constructor() {
    // Classe estática — não deve ser instanciada.
  }

  // ==================================================================
  // MÉTODO: processEngineeringUsage
  // ==================================================================

  /**
   * processEngineeringUsage(character, skill, kit)
   * ------------------------------------------------------------------
   * Gate de pré-checagem da Engenharia Elemental, a ser consultado
   * ANTES de rodar SkillEngine.executeSkill:
   *
   *   - Se character.race for HUMAN ou DWARF:
   *       1. Lê o elemento nativo da skill (skill.element).
   *       2. Se o kit tiver >= 1 carga daquele elemento, decrementa a
   *          carga e retorna true — o custo de Estafa da skill deve
   *          ser desconsiderado (este método nunca toca em
   *          character.shortTermEstafa; a carga física substitui o
   *          custo místico por completo).
   *       3. Se não houver carga (ou a skill não tiver elemento
   *          definido), retorna false — falha por falta de suprimento;
   *          o fluxo místico padrão de estafa NÃO deve ser usado como
   *          fallback automático aqui.
   *   - Para qualquer outra raça (ex: ELF, FAERIE, DRACONIAN, LURID,
   *     ou character.race === null): retorna true imediatamente, sem
   *     tocar no kit — autoriza o fluxo místico padrão de estafa a
   *     operar normalmente em SkillEngine.
   *
   * @param character - Personagem conjurando a skill
   * @param skill     - Skill sendo executada
   * @param kit       - Kit de Engenharia Elemental do personagem
   * @returns true se a skill pode prosseguir (via carga física ou via
   *          fluxo místico padrão); false se HUMAN/DWARF sem carga
   *          suficiente para o elemento da skill
   */
  public static processEngineeringUsage(
    character: CharacterState,
    skill: ISkillOrSpell,
    kit: IEngineeringKit,
  ): boolean {
    const race = character.race;

    // ================================================================
    // Raças não-engenheiras: fluxo místico padrão de estafa
    // (SkillEngine.executeSkill aplica o custo normalmente) — o kit
    // não é consultado nem alterado.
    // ================================================================

    if (race !== Race.HUMAN && race !== Race.DWARF) {
      return true;
    }

    // ================================================================
    // HUMAN / DWARF: substituição do custo de Estafa por carga física
    // ================================================================

    const element = skill.element;

    if (!element) {
      return false; // Sem elemento definido — nenhuma carga física corresponde
    }

    if (kit.charges[element] >= 1) {
      kit.charges[element] -= 1;
      return true;
    }

    return false; // Falha por falta de suprimento
  }

  // ==================================================================
  // MÉTODO: reloadKit
  // ==================================================================

  /**
   * reloadKit(kit, element, amount)
   * ------------------------------------------------------------------
   * Incrementa com segurança o número de cargas físicas de um
   * elemento específico no kit — usado por itens consumíveis de
   * recarga (ex: caixa de munição elemental).
   *
   * Proteções:
   *   1. `amount` inválido (NaN, Infinity, <= 0) é ignorado — no-op
   *      seguro, nenhuma mutação ocorre.
   *   2. Se `kit.maxCharges` estiver definido, o resultado é travado
   *      nesse teto — a recarga nunca ultrapassa o limite físico do
   *      kit, mesmo que `amount` exceda o espaço restante.
   *   3. Sem `kit.maxCharges`, a carga apenas soma normalmente (sem
   *      teto superior).
   *
   * @param kit     - Kit de Engenharia Elemental a recarregar
   * @param element - Elemento cuja carga será incrementada
   * @param amount  - Quantidade de cargas a adicionar (deve ser > 0)
   */
  public static reloadKit(
    kit: IEngineeringKit,
    element: ElementType,
    amount: number,
  ): void {
    if (!Number.isFinite(amount) || amount <= 0) {
      return; // Proteção contra valores inválidos — no-op seguro
    }

    const rechargedAmount = kit.charges[element] + amount;

    kit.charges[element] =
      kit.maxCharges !== undefined
        ? Math.min(rechargedAmount, kit.maxCharges)
        : rechargedAmount;
  }
}
