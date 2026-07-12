/**
 * ====================================================================
 * SkillEngine.ts
 * --------------------------------------------------------------------
 * Motor de execução de habilidades/feitiços (ISkillOrSpell) do
 * Projeto Aetheris.
 *
 * Responsabilidades:
 *   - executeSkill — Aplica o custo de estafa (estafaCost) da skill
 *     no caster, resolve a Regra do Retrocesso (Backlash) quando a
 *     estafa potencial ultrapassa o piso -100, e executa o efeito
 *     da skill sobre o target.
 *
 * Fonte: src/types/aetheris.types.ts (ISkillOrSpell)
 *        src/core/CharacterState.ts (shortTermEstafa, applyDirectDamage)
 * ====================================================================
 */

import { CharacterState } from '../../core/CharacterState';
import {
  ISkillOrSpell,
  ISkillDamageResult,
  Race,
  ElementType,
} from '../../types/aetheris.types';
import {
  EngineeringManager,
  IEngineeringKit,
} from '../engineering/EngineeringManager';

// Re-exportado por conveniência — quem consome SkillEngine.executeSkill
// também costuma precisar tipar o kit de Engenharia Elemental.
export type { IEngineeringKit };

// Re-exportado por compatibilidade — a definição canônica de
// ElementType agora vive em src/types/aetheris.types.ts.
export type { ElementType };

/**
 * Contexto de execução de uma skill: quem conjura, quem é o alvo, e o
 * elemento associado ao efeito.
 */
export interface ISkillExecutionContext {
  caster: CharacterState;
  target: CharacterState;
  element: ElementType;
}

/** Multiplicador aplicado quando o alvo do dano é vulnerável ao elemento */
const ELEMENTAL_WEAKNESS_MULTIPLIER = 1.5;

/**
 * Prefixo de convenção para o ID de status effect que marca
 * vulnerabilidade elemental ativa (ex: "WEAKNESS_FIRE").
 *
 * NOTA: CharacterState ainda não expõe um sistema real de afinidade/
 * vulnerabilidade elemental (sem campo ou método dedicado). Esta é
 * uma verificação simulada que reaproveita o sistema de status
 * effects já existente (`hasStatusEffect`) como indicador, até que
 * uma Matriz de Fraqueza Elemental formal seja modelada em
 * CharacterState.
 */
const WEAKNESS_EFFECT_PREFIX = 'WEAKNESS_';

/**
 * Fraquezas elementais nativas permanentes por raça.
 * Fonte: Débito técnico — Matriz de Fraqueza Elemental (raças)
 */
const RACIAL_ELEMENTAL_WEAKNESS: Partial<Record<Race, ElementType>> = {
  [Race.ELF]: 'FIRE',
  [Race.DWARF]: 'ICE',
  [Race.HUMAN]: 'LIGHTNING',
  [Race.FAERIE]: 'ICE',
  [Race.DRACONIAN]: 'LIGHTNING',
  [Race.LURID]: 'FIRE',
};

/**
 * Classe SkillEngine
 * --------------------------------------------------------------------
 * Motor estático de resolução de skills. Não mantém estado próprio —
 * opera diretamente sobre as instâncias de CharacterState fornecidas.
 */
export class SkillEngine {
  private constructor() {
    // Classe estática — não deve ser instanciada.
  }

  // ==================================================================
  // MÉTODO AUXILIAR: hasElementalWeakness
  // ==================================================================

  /**
   * hasElementalWeakness(character, element)
   * ------------------------------------------------------------------
   * Resolve a vulnerabilidade elemental de um personagem, em duas
   * camadas:
   *   1. Fraqueza nativa permanente por raça (character.race), via
   *      RACIAL_ELEMENTAL_WEAKNESS — ex: ELF é permanentemente
   *      vulnerável a FIRE.
   *   2. Fraqueza temporária simulada (ver nota em
   *      WEAKNESS_EFFECT_PREFIX): status effect "WEAKNESS_<ELEMENTO>"
   *      ativo no personagem.
   *
   * @param character - Personagem a verificar
   * @param element   - Elemento a checar
   * @returns true se o personagem está vulnerável ao elemento
   */
  private static hasElementalWeakness(
    character: CharacterState,
    element: ElementType,
  ): boolean {
    // Camada 1: fraqueza nativa permanente por raça
    if (
      character.race !== null &&
      RACIAL_ELEMENTAL_WEAKNESS[character.race] === element
    ) {
      return true;
    }

    // Camada 2: fraqueza temporária simulada via status effect
    return character.hasStatusEffect(`${WEAKNESS_EFFECT_PREFIX}${element}`);
  }

  // ==================================================================
  // MÉTODO: executeSkill
  // ==================================================================

  /**
   * executeSkill(skill, caster, target, element, kit)
   * ------------------------------------------------------------------
   * Executa uma ISkillOrSpell, aplicando o custo de estafa no caster
   * e resolvendo o efeito da skill sobre o target.
   *
   * Gate de Engenharia Elemental (HUMAN/DWARF):
   *   - Se `kit` for informado e `caster.race` for HUMAN ou DWARF,
   *     consulta EngineeringManager.processEngineeringUsage ANTES de
   *     qualquer cálculo de estafa.
   *   - Se retornar false (sem carga física suficiente para
   *     `skill.element`), a execução é interrompida imediatamente:
   *     retorna `{ backlashDamage: 0, actualDamage: 0, success: false }`
   *     sem tocar em shortTermEstafa, HP ou no efeito da skill —
   *     falha por falta de suprimento.
   *   - Se retornar true, a carga física já foi consumida pelo
   *     EngineeringManager; a ETAPA 1 (custo místico de estafa e
   *     checagem de Backlash) é inteiramente pulada para este disparo
   *     — a carga substitui o custo por completo.
   *   - Para qualquer outra raça (ou quando `kit` é omitido), o gate
   *     não é consultado e o fluxo místico padrão abaixo se aplica
   *     normalmente.
   *
   * Regra do Retrocesso (Backlash) — pulada quando a Engenharia
   * Elemental é usada com sucesso:
   *   1. Calcula o custo potencial: caster.shortTermEstafa - skill.estafaCost
   *   2. Se o valor potencial ultrapassar o piso -100, o excedente
   *      (a distância entre -100 e o valor potencial) vira dano
   *      direto aplicado ao HP do caster — o corpo absorve o que a
   *      Balança de Estafa não comporta mais.
   *   3. A estafa do caster é travada em -100 através do próprio
   *      setter `shortTermEstafa`, que já executa o clamp ontológico
   *      (enforceEstafaOntologicalLock) — este é o "método adequado
   *      de ajuste"; nenhum clamp manual é feito aqui.
   *
   * Matriz de Fraqueza Elemental (sempre ativa, independente do gate
   * de Engenharia — afeta apenas o dano no target, não o custo do
   * caster):
   *   - Se `element` for informado e o `target` estiver vulnerável a
   *     ele (hasElementalWeakness), `actualDamage` é multiplicado
   *     por 1.5.
   *   - Se `element` for informado e o `caster` também estiver
   *     vulnerável a ele, o `backlashDamage` sofrido pelo caster é
   *     multiplicado por 1.5 ANTES de ser aplicado ao HP — dano
   *     cruzado: o próprio elemento que o personagem conjura o fere
   *     com mais força no retrocesso. (Não se aplica quando a
   *     Engenharia Elemental pulou a ETAPA 1.)
   *   - Se `element` for omitido, o motor usa `skill.element` como
   *     fallback automático (ver SkillRegistry.ts, onde cada skill já
   *     carrega seu próprio elemento). Se nenhum dos dois estiver
   *     definido, nenhum multiplicador é aplicado.
   *
   * @param skill   - A skill/feitiço sendo executado
   * @param caster  - Personagem que conjura a skill
   * @param target  - Personagem alvo do efeito
   * @param element - Elemento a usar na Matriz de Fraqueza Elemental
   *                  (opcional — se omitido, cai para `skill.element`)
   * @param kit     - Kit de Engenharia Elemental do caster (opcional
   *                  — só é consultado para HUMAN/DWARF)
   * @returns { backlashDamage, actualDamage, success }
   */
  public static executeSkill(
    skill: ISkillOrSpell,
    caster: CharacterState,
    target: CharacterState,
    element?: ElementType,
    kit?: IEngineeringKit,
  ): { backlashDamage: number; actualDamage: number; success: boolean } {
    // Fallback: se o chamador não informar `element`, usa o elemento
    // nativo da própria skill (ver ISkillOrSpell.element / SkillRegistry.ts)
    const resolvedElement = element ?? skill.element;

    // ================================================================
    // ETAPA 0: GATE DE ENGENHARIA ELEMENTAL (HUMAN/DWARF)
    // ================================================================

    let bypassMysticCost = false;

    if (kit && (caster.race === Race.HUMAN || caster.race === Race.DWARF)) {
      const engineeringSuccess = EngineeringManager.processEngineeringUsage(caster, skill, kit);

      if (!engineeringSuccess) {
        // Falha por falta de suprimento — interrompe a execução por
        // completo, sem tocar em estafa, HP ou efeito da skill.
        return { backlashDamage: 0, actualDamage: 0, success: false };
      }

      bypassMysticCost = true;
    }

    // ================================================================
    // ETAPA 1: REGRA DO RETROCESSO (BACKLASH)
    // Pulada inteiramente se a Engenharia Elemental já cobriu o custo.
    // ================================================================

    let backlashDamage = 0;

    if (!bypassMysticCost) {
      const potentialEstafa = caster.shortTermEstafa - skill.estafaCost;

      if (potentialEstafa < CharacterState.ESTAFA_MIN) {
        // Excedente que a Balança não comporta — vira dano direto no caster
        backlashDamage = CharacterState.ESTAFA_MIN - potentialEstafa;
      }

      // Aplica o deslocamento no medidor de estafa do caster.
      // O setter já trava o valor em -100 via enforceEstafaOntologicalLock.
      caster.shortTermEstafa = potentialEstafa;

      if (backlashDamage > 0) {
        // Dano cruzado: se o caster é vulnerável ao próprio elemento da
        // skill, o retrocesso o fere com 1.5x de intensidade.
        if (resolvedElement && SkillEngine.hasElementalWeakness(caster, resolvedElement)) {
          backlashDamage *= ELEMENTAL_WEAKNESS_MULTIPLIER;
        }

        caster.applyDirectDamage(backlashDamage);
      }
    }

    // ================================================================
    // ETAPA 2: EXECUÇÃO DO EFEITO DA SKILL SOBRE O TARGET
    // Aceita dois formatos de retorno de skill.execute():
    //   - number bruto (compatibilidade retroativa)
    //   - ISkillDamageResult { baseDamage } (formato padrão)
    // ================================================================

    const effectResult = skill.execute(caster, target);
    let actualDamage = 0;

    if (typeof effectResult === 'number' && Number.isFinite(effectResult)) {
      actualDamage = effectResult;
    } else if (
      effectResult &&
      typeof effectResult === 'object' &&
      typeof (effectResult as ISkillDamageResult).baseDamage === 'number' &&
      Number.isFinite((effectResult as ISkillDamageResult).baseDamage)
    ) {
      actualDamage = (effectResult as ISkillDamageResult).baseDamage;
    }

    // ================================================================
    // ETAPA 3: MATRIZ DE FRAQUEZA ELEMENTAL
    // Se o target é vulnerável ao elemento da skill, o dano efetivo
    // é amplificado.
    // ================================================================

    if (resolvedElement && SkillEngine.hasElementalWeakness(target, resolvedElement)) {
      actualDamage *= ELEMENTAL_WEAKNESS_MULTIPLIER;
    }

    return {
      backlashDamage,
      actualDamage,
      success: true,
    };
  }
}
