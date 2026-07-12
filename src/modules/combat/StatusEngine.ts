/**
 * ====================================================================
 * StatusEngine.ts
 * --------------------------------------------------------------------
 * Matriz de efeitos de status tecnológicos — condições aplicadas por
 * armamentos de Engenharia Elemental (THERMITE_GRENADE, CRYO_DISCHARGER,
 * TESLA_COIL). Reaproveita o sistema de status effects já existente em
 * CharacterState (addStatusEffect/removeStatusEffect/hasStatusEffect).
 *
 * Condições gerenciadas:
 *   - TECH_BURN       — dano por turno de fogo (DOT)
 *   - TECH_SLOW       — redução multiplicativa de velocidade de movimento
 *   - TECH_CONDUCTIVE — amplifica em 1.5x o PRÓXIMO dano de LIGHTNING
 *                       recebido pelo alvo (consumido no impacto)
 *
 * NOTA DE INTEGRAÇÃO: este módulo define e aplica as condições, e
 * expõe métodos de consulta/resolução (processBurnTick,
 * getSlowSpeedMultiplier, resolveIncomingDamage) para uso por quem
 * orquestra o loop de turnos e o pipeline de dano. Nenhum loop de
 * turnos automático existe ainda no motor (CombatEngine não possui
 * uma rotina "processTurn") — a invocação desses métodos a cada turno
 * é responsabilidade do chamador futuro.
 *
 * Fonte: src/core/CharacterState.ts (statusEffects, addStatusEffect,
 *        applyDirectDamage)
 *        src/types/aetheris.types.ts (IStatusEffect, ElementType)
 * ====================================================================
 */

import { CharacterState } from '../../core/CharacterState';
import { ElementType, IStatusEffect } from '../../types/aetheris.types';

/** IDs canônicos das condições tecnológicas geridas por este motor */
export const TECH_STATUS_IDS = {
  TECH_BURN: 'TECH_BURN',
  TECH_SLOW: 'TECH_SLOW',
  TECH_CONDUCTIVE: 'TECH_CONDUCTIVE',
} as const;

export type TechStatusId = (typeof TECH_STATUS_IDS)[keyof typeof TECH_STATUS_IDS];

// ======================================================================
// CONSTANTES DE MAGNITUDE — valores default de cada condição
// ======================================================================

const TECH_BURN_DAMAGE_PER_TURN = 15;
const TECH_BURN_DURATION_TURNS = 3;

const TECH_SLOW_SPEED_MULTIPLIER = 0.7; // -30% de velocidade
const TECH_SLOW_DURATION_TURNS = 2;

const TECH_CONDUCTIVE_LIGHTNING_MULTIPLIER = 1.5;
const TECH_CONDUCTIVE_DURATION_TURNS = 2;

// ======================================================================
// FÁBRICAS DE IStatusEffect
// ======================================================================

function createTechBurnEffect(): IStatusEffect {
  return {
    id: TECH_STATUS_IDS.TECH_BURN,
    duration: TECH_BURN_DURATION_TURNS,
    remainingDuration: TECH_BURN_DURATION_TURNS,
    modifiers: { damagePerTurn: TECH_BURN_DAMAGE_PER_TURN },
    flags: {
      blocksMovementInput: false,
      overridesMovementDirection: false,
      blocksAbilityAxis: null,
      freezesEstafaBar: false,
    },
  };
}

function createTechSlowEffect(): IStatusEffect {
  return {
    id: TECH_STATUS_IDS.TECH_SLOW,
    duration: TECH_SLOW_DURATION_TURNS,
    remainingDuration: TECH_SLOW_DURATION_TURNS,
    modifiers: { speedMultiplier: TECH_SLOW_SPEED_MULTIPLIER },
    flags: {
      blocksMovementInput: false,
      overridesMovementDirection: false,
      blocksAbilityAxis: null,
      freezesEstafaBar: false,
    },
  };
}

function createTechConductiveEffect(): IStatusEffect {
  return {
    id: TECH_STATUS_IDS.TECH_CONDUCTIVE,
    duration: TECH_CONDUCTIVE_DURATION_TURNS,
    remainingDuration: TECH_CONDUCTIVE_DURATION_TURNS,
    modifiers: { lightningDamageMultiplier: TECH_CONDUCTIVE_LIGHTNING_MULTIPLIER },
    flags: {
      blocksMovementInput: false,
      overridesMovementDirection: false,
      blocksAbilityAxis: null,
      freezesEstafaBar: false,
    },
  };
}

/**
 * Classe StatusEngine
 * --------------------------------------------------------------------
 * Motor estático da Matriz de Efeitos de Status Tecnológicos. Não
 * mantém estado próprio — opera diretamente sobre as instâncias de
 * CharacterState fornecidas.
 */
export class StatusEngine {
  private constructor() {
    // Classe estática — não deve ser instanciada.
  }

  // ==================================================================
  // MÉTODO: applyTechStatus
  // ==================================================================

  /**
   * applyTechStatus(target, statusId)
   * ------------------------------------------------------------------
   * Aplica uma condição tecnológica ao alvo, via
   * CharacterState.addStatusEffect. Segue as mesmas regras de
   * addStatusEffect: retorna false se o alvo já possuir a condição
   * ativa (sem duplicar nem renovar a duração).
   *
   * @param target   - Personagem que recebe a condição
   * @param statusId - Um dos TECH_STATUS_IDS
   * @returns true se a condição foi efetivamente aplicada
   */
  public static applyTechStatus(target: CharacterState, statusId: TechStatusId): boolean {
    switch (statusId) {
      case TECH_STATUS_IDS.TECH_BURN:
        return target.addStatusEffect(createTechBurnEffect());
      case TECH_STATUS_IDS.TECH_SLOW:
        return target.addStatusEffect(createTechSlowEffect());
      case TECH_STATUS_IDS.TECH_CONDUCTIVE:
        return target.addStatusEffect(createTechConductiveEffect());
      default:
        return false;
    }
  }

  // ==================================================================
  // MÉTODO: processBurnTick
  // ==================================================================

  /**
   * processBurnTick(character)
   * ------------------------------------------------------------------
   * Aplica o dano por turno de TECH_BURN, se ativo, via
   * CharacterState.applyDirectDamage.
   *
   * @param character - Personagem a processar
   * @returns O dano aplicado (0 se TECH_BURN não estiver ativo)
   */
  public static processBurnTick(character: CharacterState): number {
    const effect = character.statusEffects.find((e) => e.id === TECH_STATUS_IDS.TECH_BURN);

    if (!effect) {
      return 0;
    }

    const damage = effect.modifiers.damagePerTurn ?? 0;
    character.applyDirectDamage(damage);

    return damage;
  }

  // ==================================================================
  // MÉTODO: getSlowSpeedMultiplier
  // ==================================================================

  /**
   * getSlowSpeedMultiplier(character)
   * ------------------------------------------------------------------
   * Consulta o multiplicador de velocidade imposto por TECH_SLOW.
   *
   * @param character - Personagem a consultar
   * @returns O multiplicador (0.7 se TECH_SLOW ativo, 1.0 caso contrário)
   */
  public static getSlowSpeedMultiplier(character: CharacterState): number {
    const effect = character.statusEffects.find((e) => e.id === TECH_STATUS_IDS.TECH_SLOW);
    return effect?.modifiers.speedMultiplier ?? 1.0;
  }

  // ==================================================================
  // MÉTODO: resolveIncomingDamage
  // ==================================================================

  /**
   * resolveIncomingDamage(target, incomingDamage, incomingElement)
   * ------------------------------------------------------------------
   * Resolve o multiplicador de TECH_CONDUCTIVE contra um dano
   * recebido. Se o alvo estiver marcado por TECH_CONDUCTIVE e o dano
   * recebido for de elemento LIGHTNING, amplifica o dano em 1.5x e
   * CONSOME a condição (remove o status — vale apenas para o próximo
   * impacto de LIGHTNING).
   *
   * @param target          - Personagem que recebe o dano
   * @param incomingDamage  - Dano bruto antes da resolução de TECH_CONDUCTIVE
   * @param incomingElement - Elemento do dano recebido
   * @returns O dano final (amplificado se aplicável)
   */
  public static resolveIncomingDamage(
    target: CharacterState,
    incomingDamage: number,
    incomingElement?: ElementType,
  ): number {
    if (incomingElement !== 'LIGHTNING') {
      return incomingDamage;
    }

    const effect = target.statusEffects.find((e) => e.id === TECH_STATUS_IDS.TECH_CONDUCTIVE);

    if (!effect) {
      return incomingDamage;
    }

    // Consumido no impacto — vale apenas para este dano de LIGHTNING
    target.removeStatusEffect(TECH_STATUS_IDS.TECH_CONDUCTIVE);

    const multiplier = effect.modifiers.lightningDamageMultiplier ?? 1.0;
    return incomingDamage * multiplier;
  }
}
