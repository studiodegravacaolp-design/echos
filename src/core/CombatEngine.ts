  /**
 * ====================================================================
 * CombatEngine.ts
 * --------------------------------------------------------------------
 * Motor de Combate do Projeto Aetheris — Sprint 2.
 * Gerencia o ciclo dinâmico das batalhas e processa as equações
 * físicas baseadas em ENG-MOTOR-COMBATE.md e ENG-MATEMATICA-COMBATE.md.
 *
 * Rotinas implementadas:
 *   - processAbilityDelta  — Aplica deslocamento de estafa (deltaM)
 *   - calculateMitigatedDamage — Mitigação hiperbólica de dano (K=150.0)
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import {
  IAbility,
  IProcessResult,
  IEquipment,
  AxisTag,
  PenetrationType,
  ErrorCodes,
} from '../types/aetheris.types';
import { CharacterState } from './CharacterState';
import { StatusEngine } from '../modules/combat/StatusEngine';

/**
 * Constantes calibradas do motor de dano.
 * Fonte: ENG-MATEMATICA-COMBATE Seção 3
 */
const ARMOR_MITIGATION_CONSTANT_K = 150.0;
const MIN_DAMAGE_FRACTION = 0.05;
const FRATURA_FRENESI_MULTIPLIER = 1.30;
const FRICTION_ARMOR_IGNORE_FRAC = 0.40;

/** Fator de redução de velocidade sob ESTAGNACAO_TATICA */
const ESTAGNACAO_SPEED_MULTIPLIER = 0.50;

/** Fração mínima da velocidade base garantida (clamp de jogabilidade) */
const MIN_SPEED_FRACTION = 0.10;

/** Penalidade de iniciativa para personagens sob FRATURA_FRENESI */
const FRATURA_FRENESI_INITIATIVE_PENALTY = 50;

/** Valor de estafa que indica ESTAGNACAO_TATICA (barra em -100) */
const ESTAGNACAO_THRESHOLD = -100;

/**
 * Classe CombatEngine
 * --------------------------------------------------------------------
 * Motor principal de resolução de combate. Encapsula as operações
 * de aplicação de habilidades no medidor de estafa (processAbilityDelta)
 * e cálculo de dano mitigado por armadura (calculateMitigatedDamage).
 *
 * Todas as operações respeitam os clamps de segurança, contratos de
 * dados e regras de encapsulamento definidos em ENG-ESTRUTURA-DADOS.md,
 * ENG-MOTOR-COMBATE.md e ENG-MATEMATICA-COMBATE.md.
 */
export class CombatEngine {
  // ==================================================================
  // MÉTODO: processAbilityDelta
  // ==================================================================

  /**
   * processAbilityDelta(attacker, ability)
   * ------------------------------------------------------------------
   * Aplica o deslocamento (deltaM) de uma habilidade no medidor
   * shortTermEstafa do atacante, respeitando o eixo da habilidade
   * e os bloqueios por estado de colapso.
   *
   * Validações:
   *   1. Se a habilidade é MATERNO enquanto o atacante está sob
   *      ESTAGNACAO_TATICA → bloqueia com MOTOR-ERR-002
   *   2. Aplica o deltaM diretamente no shortTermEstafa do atacante,
   *      que internamente executa clamp e dispara eventos de borda.
   *
   * Fonte: ENG-MOTOR-COMBATE Seção 3 (process_ability_delta)
   *        ENG-ESTRUTURA-DADOS Seção 2.2
   *
   * @param attacker  - Estado do personagem atacante (CharacterState)
   * @param ability   - Habilidade sendo executada (IAbility)
   * @returns IProcessResult — Resultado da operação
   */
  public processAbilityDelta(
    attacker: CharacterState,
    ability: IAbility,
  ): IProcessResult {
    // ================================================================
    // ETAPA 1: VALIDAÇÃO DE ENTRADA
    // ================================================================

    // 1.1 Verifica se a habilidade existe e não é nula
    if (!ability) {
      return {
        success: false,
        errorCode: ErrorCodes.MOTOR_ERR_001,
        finalEstafa: attacker.shortTermEstafa,
        triggerEvent: null,
      };
    }

    // 1.2 Verifica se o atacante está em ESTAGNACAO_TATICA
    //     e se a habilidade é do eixo MATERNO (bloqueada neste estado)
    // Fonte: ENG-MOTOR-COMBATE Seção 3.5 — Etapa 1.2
    if (
      attacker.hasStatusEffect('ESTAGNACAO_TATICA') &&
      ability.axis === AxisTag.MATERNO
    ) {
      return {
        success: false,
        errorCode: ErrorCodes.MOTOR_ERR_002,
        finalEstafa: attacker.shortTermEstafa,
        triggerEvent: null,
      };
    }

    // ================================================================
    // ETAPA 2: LEITURA DO EIXO E DELTA_M
    // ================================================================

    // 2.1 Lê o valor de deslocamento da habilidade
    const deltaM: number = ability.deltaM;

    // ================================================================
    // ETAPA 3: APLICAÇÃO DO DESLOCAMENTO
    // ================================================================

    // 3.1 Armazena o valor anterior para o resultado
    const previousEstafa: number = attacker.shortTermEstafa;

    // 3.2 Aplica o deslocamento no medidor de estafa
    //     O setter de shortTermEstafa aplica clamp e dispara eventos
    attacker.shortTermEstafa = attacker.shortTermEstafa + deltaM;

    // ================================================================
    // ETAPA 4: VERIFICA SE HOUVE CLAMP (EVENTO DE BORDA)
    // ================================================================

    // Verifica se o valor atingiu os limites (clamp foi acionado)
    const finalEstafa: number = attacker.shortTermEstafa;
    const wasClamped: boolean =
      finalEstafa === 100 || finalEstafa === -100;

    // Determina qual evento de borda foi disparado, se houve clamp
    let triggerEvent: string | null = null;
    if (wasClamped) {
      if (finalEstafa === 100) {
        triggerEvent = 'EVT_FRATURA_FRENESI';
      } else if (finalEstafa === -100) {
        triggerEvent = 'EVT_ESTAGNACAO_TATICA';
      }
    }

    // ================================================================
    // ETAPA 5: RETORNO
    // ================================================================

    return {
      success: true,
      errorCode: null,
      finalEstafa,
      deltaApplied: deltaM,
      previousEstafa,
      clamped: wasClamped,
      triggerEvent,
    };
  }

  // ==================================================================
  // MÉTODO: calculateMovementSpeed
  // ==================================================================

  /**
   * calculateMovementSpeed(baseSpeed, armorWeight, materialCoeff, hasEstagnacao, inventoryWeight)
   * ------------------------------------------------------------------
   * Calcula a velocidade final de movimento de um combatente, diminuída
   * pelo atrito físico do equipamento e pelo peso do inventário:
   *
   *   1. totalWeightPenalty = (armorWeight * materialCoeff) + inventoryWeight
   *      effectiveSpeed = baseSpeed - totalWeightPenalty
   *
   *   2. Se o personagem está sob ESTAGNACAO_TATICA (hasEstagnacao === true),
   *      aplica redutor multiplicativo adicional de 0.50x:
   *        effectiveSpeed *= 0.50
   *
   *   3. Clamp de velocidade mínima: garante 10% da baseSpeed para evitar
   *      paralisia permanente em tela (Garantia de jogabilidade mobile).
   *
   * Fonte: ENG-MATEMATICA-COMBATE Seção 7 (Friction Profile)
   *        ENG-MOTOR-COMBATE Seção 4.3.2 (ESTAGNACAO_TATICA)
   *        Sprint 4 — Tarefa 4.2 (Inventory Weight Integration)
   *
   * @param baseSpeed          - Velocidade de movimento base do personagem
   * @param armorWeight        - Peso total da armadura equipada
   * @param materialCoeff      - Coeficiente de atrito do material da armadura
   * @param hasEstagnacao      - Se o personagem está sob ESTAGNACAO_TATICA
   * @param inventoryWeight    - Peso cumulativo do inventário (padrão: 0)
   * @param techSlowMultiplier - Multiplicador de TECH_SLOW (Matriz de
   *                             Status Tecnológicos — StatusEngine
   *                             .getSlowSpeedMultiplier). Padrão: 1.0
   *                             (sem redução). Valor inválido (<= 0,
   *                             NaN, Infinity) é tratado como 1.0.
   * @returns number — Velocidade final após atrito e clamps
   */
  public calculateMovementSpeed(
    baseSpeed: number,
    armorWeight: number,
    materialCoeff: number,
    hasEstagnacao: boolean,
    inventoryWeight: number = 0,
    techSlowMultiplier: number = 1.0,
  ): number {
    // ================================================================
    // ETAPA 1: VALIDAÇÃO DE ENTRADA
    // ================================================================

    // 1.1 Proteção contra NaN, Infinity ou valores negativos na baseSpeed
    if (!Number.isFinite(baseSpeed) || baseSpeed < 0) {
      return 0.0;
    }

    // 1.2 Proteção contra NaN, Infinity ou valores negativos no armorWeight
    const safeArmorWeight: number =
      Number.isFinite(armorWeight) && armorWeight >= 0 ? armorWeight : 0;

    // 1.3 Proteção contra NaN, Infinity ou valores negativos no materialCoeff
    const safeMaterialCoeff: number =
      Number.isFinite(materialCoeff) && materialCoeff >= 0 ? materialCoeff : 0;

    // 1.4 Proteção contra NaN, Infinity ou valores negativos no inventoryWeight
    const safeInventoryWeight: number =
      Number.isFinite(inventoryWeight) && inventoryWeight >= 0 ? inventoryWeight : 0;

    // 1.5 Proteção contra NaN, Infinity ou valores <= 0 no techSlowMultiplier
    //     (um multiplicador inválido não deve travar nem acelerar o personagem)
    const safeTechSlowMultiplier: number =
      Number.isFinite(techSlowMultiplier) && techSlowMultiplier > 0 ? techSlowMultiplier : 1.0;

    // ================================================================
    // ETAPA 2: CÁLCULO DA VELOCIDADE EFETIVA
    // Fórmula: totalWeightPenalty = (armorWeight * materialCoeff) + inventoryWeight
    //          effectiveSpeed = baseSpeed - totalWeightPenalty
    // ================================================================

    const totalWeightPenalty: number =
      (safeArmorWeight * safeMaterialCoeff) + safeInventoryWeight;

    let effectiveSpeed: number = baseSpeed - totalWeightPenalty;

    // ================================================================
    // ETAPA 3: APLICAÇÃO DO REDUTOR DE ESTAGNAÇÃO TÁTICA
    // Se o personagem está sob ESTAGNACAO_TATICA, reduz a velocidade
    // em 50% multiplicativamente.
    // Fonte: ENG-MOTOR-COMBATE Seção 4.3.2
    // ================================================================

    if (hasEstagnacao) {
      effectiveSpeed *= ESTAGNACAO_SPEED_MULTIPLIER;
    }

    // ================================================================
    // ETAPA 3.5: APLICAÇÃO DO REDUTOR DE TECH_SLOW
    // Matriz de Status Tecnológicos (StatusEngine) — mesma natureza
    // multiplicativa do redutor de ESTAGNACAO_TATICA, mas independente
    // dele (os dois podem coexistir e se acumulam).
    // Fonte: Débito técnico — Matriz de Efeitos de Status Tecnológicos
    // ================================================================

    effectiveSpeed *= safeTechSlowMultiplier;

    // ================================================================
    // ETAPA 4: CLAMP DE VELOCIDADE MÍNIMA (Garantia de jogabilidade)
    // Garante que a velocidade nunca seja inferior a 10% da baseSpeed,
    // evitando que o personagem fique permanentemente paralisado.
    // Fonte: ENG-MATEMATICA-COMBATE Seção 7.3
    // ================================================================

    const minSpeed: number = baseSpeed * MIN_SPEED_FRACTION;

    if (effectiveSpeed < minSpeed) {
      effectiveSpeed = minSpeed;
    }

    // ================================================================
    // ETAPA 5: CLAMPS FINAIS DE SEGURANÇA
    // ================================================================

    // 5.1 Velocidade final NUNCA negativa
    if (effectiveSpeed < 0.0) {
      effectiveSpeed = 0.0;
    }

    // 5.2 Proteção contra NaN e Infinity
    if (!Number.isFinite(effectiveSpeed)) {
      effectiveSpeed = 0.0;
    }

    // ================================================================
    // ETAPA 6: RETORNO
    // ================================================================

    return effectiveSpeed;
  }

  // ==================================================================
  // MÉTODO: generateTurnQueue
  // ==================================================================

  /**
   * generateTurnQueue(characters)
   * ------------------------------------------------------------------
   * Gera a fila de turnos de combate ordenada por Iniciativa Dinâmica.
   *
   * Algorítmo:
   *   1. Para cada personagem, calcula a iniciativa baseada no
   *      modificador de velocidade atual (que já inclui penalidades
   *      de atrito por peso de equipamento).
   *
   *   2. Personagens sob FRATURA_FRENESI recebem uma penalidade
   *      temporária na ordem de ação devido ao colapso cinético.
   *
   *   3. Ordena a fila de forma decrescente (maior iniciativa age primeiro).
   *
   * Fonte: ENG-MOTOR-COMBATE Seção 6 (Turn Queue)
   *        ENG-MATEMATICA-COMBATE Seção 7.4 (Dynamic Initiative)
   *
   * @param characters - Array de estados de personagem (CharacterState[])
   * @returns CharacterState[] — Array ordenado por iniciativa (decrescente)
   */
  public generateTurnQueue(characters: CharacterState[]): CharacterState[] {
    // ================================================================
    // ETAPA 1: VALIDAÇÃO DE ENTRADA
    // ================================================================

    // 1.1 Proteção contra array nulo ou indefinido
    if (!Array.isArray(characters)) {
      return [];
    }

    // 1.2 Proteção contra array vazio
    if (characters.length === 0) {
      return [];
    }

    // ================================================================
    // ETAPA 2: CÁLCULO DE INICIATIVA POR PERSONAGEM
    // ================================================================

    // Mapa de iniciativa: associa cada personagem ao seu valor de iniciativa
    const initiativeMap: Map<CharacterState, number> = new Map();

    for (const character of characters) {
      // 2.1 Obtém o modificador de velocidade base do personagem
      const baseSpeed: number = character.stats.movementSpeed;

      // 2.2 Obtém o equipamento e calcula o atrito físico
      const equipment: IEquipment | null = character.equipment;
      const armorWeight: number = equipment ? equipment.weight : 0;
      const materialCoeff: number = equipment ? equipment.materialCoefficient : 0;

      // 2.3 Verifica se o personagem está sob ESTAGNACAO_TATICA
      const hasEstagnacao: boolean =
        character.shortTermEstafa <= ESTAGNACAO_THRESHOLD &&
        character.hasStatusEffect('ESTAGNACAO_TATICA');

      // 2.3.1 Consulta o redutor de TECH_SLOW (Matriz de Status Tecnológicos)
      const techSlowMultiplier: number = StatusEngine.getSlowSpeedMultiplier(character);

      // 2.4 Calcula a velocidade efetiva (com atrito, estagnação e TECH_SLOW)
      const effectiveSpeed: number = this.calculateMovementSpeed(
        baseSpeed,
        armorWeight,
        materialCoeff,
        hasEstagnacao,
        0,
        techSlowMultiplier,
      );

      // 2.5 Iniciativa base = velocidade efetiva
      let initiative: number = effectiveSpeed;

      // 2.6 Penalidade de FRATURA_FRENESI
      //     Personagens sob colapso cinético têm penalidade na ordem de ação
      if (character.hasStatusEffect('FRATURA_FRENESI')) {
        initiative -= FRATURA_FRENESI_INITIATIVE_PENALTY;
      }

      // 2.7 Clamp de segurança: iniciativa NUNCA negativa
      if (initiative < 0.0) {
        initiative = 0.0;
      }

      // Armazena no mapa
      initiativeMap.set(character, initiative);
    }

    // ================================================================
    // ETAPA 3: ORDENAÇÃO DA FILA
    // Ordem decrescente: maior iniciativa age primeiro
    // ================================================================

    const sortedCharacters: CharacterState[] = [...characters].sort((a, b) => {
      const initiativeA: number = initiativeMap.get(a) ?? 0;
      const initiativeB: number = initiativeMap.get(b) ?? 0;

      // Ordem decrescente (maior primeiro)
      return initiativeB - initiativeA;
    });

    // ================================================================
    // ETAPA 4: RETORNO
    // ================================================================

    return sortedCharacters;
  }

  // ==================================================================
  // MÉTODO: processTurnStartEffects
  // ==================================================================

  /**
   * processTurnStartEffects(character)
   * ------------------------------------------------------------------
   * Processa os efeitos de início de turno da Matriz de Status
   * Tecnológicos (StatusEngine) — hoje, exclusivamente o tick de dano
   * de TECH_BURN.
   *
   * ATENÇÃO — CONEXÃO PARCIAL: este motor ainda não possui um loop de
   * turnos automático (não existe nenhuma rotina "runTurn" ou
   * "simulateRound" em CombatEngine). Este método é o ponto de
   * conexão correto para o tick de TECH_BURN, mas depende de um
   * driver externo — ainda não implementado — que o chame uma vez por
   * turno para cada personagem ativo. Sem esse driver, TECH_BURN
   * continua aplicado ao personagem (via StatusEngine.applyTechStatus)
   * mas não causa dano automaticamente.
   *
   * Fonte: StatusEngine.processBurnTick
   *
   * @param character - Personagem cujo turno está começando
   * @returns O dano de TECH_BURN aplicado neste tick (0 se inativo)
   */
  public processTurnStartEffects(character: CharacterState): number {
    return StatusEngine.processBurnTick(character);
  }

  // ==================================================================
  // MÉTODO: calculateMitigatedDamage
  // ==================================================================

  /**
   * calculateMitigatedDamage(rawDamage, targetDefense, penetrationType,
   *                          isTargetFractured)
   * ------------------------------------------------------------------
   * Calcula o dano final mitigado aplicado a um combatente, aplicando:
   *
   *   1. Redução hiperbólica por armadura:
   *        damageMultiplier = K / (K + effectiveDefense)
   *        onde K = 150.0
   *
   *   2. Penetração FÍSICA (Marreta de Fricção — EQP-ARM-022):
   *        Se penetrationType === FISICA, reduz a defesa efetiva
   *        do alvo em 40% ANTES do cálculo do multiplicador.
   *
   *   3. Multiplicador de vulnerabilidade FRATURA_FRENESI:
   *        Se isTargetFractured === true, aplica 1.30x ao dano
   *        pós-mitigação.
   *
   *   4. Floor de dano mínimo:
   *        Garante dano mínimo de 5% do rawDamage caso a defesa
   *        tenda a infinito, bloqueando vazamento numérico.
   *
   * Fonte: ENG-MATEMATICA-COMBATE Seção 4 (calculate_mitigated_damage)
   *        ENG-MOTOR-COMBATE Seção 4.3.1 (FRATURA_FRENESI)
   *
   * @param rawDamage        - Dano bruto (não mitigado)
   * @param targetDefense    - Defesa nativa do alvo
   * @param penetrationType  - Tipo de penetração da habilidade
   * @param isTargetFractured- Se o alvo está sob FRATURA_FRENESI
   * @returns number — Dano final mitigado (ponto flutuante)
   */
  public calculateMitigatedDamage(
    rawDamage: number,
    targetDefense: number,
    penetrationType: PenetrationType,
    isTargetFractured: boolean,
  ): number {
    // ================================================================
    // ETAPA 1: VALIDAÇÃO DE ENTRADA
    // ================================================================

    // 1.1 Proteção contra NaN, Infinity ou valores negativos no rawDamage
    if (
      !Number.isFinite(rawDamage) ||
      rawDamage < 0
    ) {
      return 0.0;
    }

    // 1.2 Proteção contra NaN, Infinity ou valores negativos na defesa
    if (
      !Number.isFinite(targetDefense) ||
      targetDefense < 0
    ) {
      // Fallback seguro: defesa inválida = sem mitigação (dano integral)
      return rawDamage;
    }

    // 1.3 Proteção contra overflow de rawDamage (> 1e12)
    const safeRawDamage: number = rawDamage > 1e12 ? 1e12 : rawDamage;

    // ================================================================
    // ETAPA 2: CÁLCULO DA DEFESA EFETIVA
    // ================================================================

    let effectiveDefense: number = targetDefense;

    // 2.1 Aplica penetração FÍSICA (Marreta de Fricção — EQP-ARM-022)
    //     Reduz a defesa nativa do alvo em 40%
    // Fonte: ENG-MATEMATICA-COMBATE Seção 5.1
    //        ENG-MATEMATICA-COMBATE Seção 3 (FRICTION_ARMOR_IGNORE_FRAC = 0.40)
    if (penetrationType === PenetrationType.FISICA) {
      const frictionReduction: number = targetDefense * FRICTION_ARMOR_IGNORE_FRAC;
      effectiveDefense -= frictionReduction;
    }

    // 2.2 Clamp de segurança: defesa efetiva NUNCA negativa
    if (effectiveDefense < 0.0) {
      effectiveDefense = 0.0;
    }

    // ================================================================
    // ETAPA 3: CÁLCULO DO MULTIPLICADOR BASE DE MITIGAÇÃO
    // Fórmula hiperbólica: damageMultiplier = K / (K + effectiveDefense)
    // ================================================================

    let damageMultiplier: number =
      ARMOR_MITIGATION_CONSTANT_K /
      (ARMOR_MITIGATION_CONSTANT_K + effectiveDefense);

    // 3.1 Clamp de segurança do multiplicador
    if (damageMultiplier < 0.0) {
      damageMultiplier = 0.0;
    }
    if (damageMultiplier > 1.0) {
      damageMultiplier = 1.0;
    }

    // 3.2 Aplica o floor de dano mínimo (5% do rawDamage)
    //     Garante que mesmo com defesa infinita, o dano mínimo
    //     nunca seja inferior a 5% do dano bruto original.
    // Fonte: ENG-MATEMATICA-COMBATE Seção 3 (MIN_DAMAGE_FRACTION = 0.05)
    const floorDamage: number = safeRawDamage * MIN_DAMAGE_FRACTION;
    const damageAfterMitigation: number = safeRawDamage * damageMultiplier;

    // Se o dano pós-mitigação for menor que o floor, usa o floor
    let finalDamage: number =
      damageAfterMitigation < floorDamage
        ? floorDamage
        : damageAfterMitigation;

    // ================================================================
    // ETAPA 4: APLICAÇÃO DO MULTIPLICADOR DE VULNERABILIDADE
    // FRATURA_FRENESI — amplifica o dano recebido em 30%
    // Fonte: ENG-MATEMATICA-COMBATE Seção 6
    //        ENG-MOTOR-COMBATE Seção 4.3.1
    // ================================================================

    if (isTargetFractured) {
      finalDamage = finalDamage * FRATURA_FRENESI_MULTIPLIER;
    }

    // ================================================================
    // ETAPA 5: CLAMPS FINAIS DE SEGURANÇA
    // ================================================================

    // 5.1 Dano final NUNCA negativo
    if (finalDamage < 0.0) {
      finalDamage = 0.0;
    }

    // 5.2 Proteção contra NaN e Infinity
    if (!Number.isFinite(finalDamage)) {
      finalDamage = 0.0;
    }

    // ================================================================
    // ETAPA 6: RETORNO
    // ================================================================

    return finalDamage;
  }
}