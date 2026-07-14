/**
 * ====================================================================
 * EnemyBehavior.ts
 * --------------------------------------------------------------------
 * Implementações de comportamentos de IA para inimigos no Projeto
 * Aetheris. Cada arquétipo (ASSASSINO, PROTETOR, DRENADOR_ESTAFA)
 * implementa a interface IEnemyBehavior com lógica de seleção de
 * alvo e habilidade baseada no estado atual do combate.
 *
 * Fonte: docs/04_arquitetura_software/ENG-MOTOR-COMBATE.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import {
  AIArchetype,
  IEnemyBehavior,
  ICombatantState,
  IAbility,
  AxisTag,
  PenetrationType,
} from '../../types/aetheris.types';

// ==================================================================
// CONSTANTES DE COMPORTAMENTO
// ==================================================================

/** Limiar de HP baixo para o ASSASSINO considerar um alvo como frágil */
const LOW_HP_THRESHOLD_RATIO = 0.35;

/** Valor de estafa considerado "alto" para DRENADOR_ESTAFA */
const HIGH_ESTAFA_THRESHOLD = 70;

/** Valor de estafa considerado "baixo" para DRENADOR_ESTAFA */
const LOW_ESTAFA_THRESHOLD = -70;

// ==================================================================
// HABILIDADES PADRÃO POR ARQUÉTIPO
// ==================================================================

/**
 * Habilidade base do ASSASSINO — dano perfurante com penetração
 * FÍSICA, deltaM positivo (desloca estafa para o lado PATERNO).
 */
const ASSASSINO_ABILITY: IAbility = {
  id: 'ENEMY_ABILITY_ASSASSINO',
  name: 'Golpe Sombrio',
  axis: AxisTag.PATERNO,
  deltaM: 25,
  baseDamage: 40,
  penetrationType: PenetrationType.FISICA,
  cooldown: 0,
  staminaCost: 0,
};

/**
 * Habilidade base do PROTETOR — dano moderado com penetração MAGICA,
 * deltaM negativo (desloca estafa para o lado MATERNO).
 */
const PROTETOR_ABILITY: IAbility = {
  id: 'ENEMY_ABILITY_PROTETOR',
  name: 'Escudo de Ferro',
  axis: AxisTag.MATERNO,
  deltaM: -20,
  baseDamage: 25,
  penetrationType: PenetrationType.MAGICA,
  cooldown: 0,
  staminaCost: 0,
};

/**
 * Habilidade base do DRENADOR_ESTAFA — dano baixo com penetração
 * VERDADEIRA, deltaM alto (grande deslocamento de estafa).
 */
const DRENADOR_ABILITY: IAbility = {
  id: 'ENEMY_ABILITY_DRENADOR',
  name: 'Dreno de Estafa',
  axis: AxisTag.NEUTRO,
  deltaM: 35,
  baseDamage: 15,
  penetrationType: PenetrationType.VERDADEIRA,
  cooldown: 0,
  staminaCost: 0,
};

// ==================================================================
// MAPA DE HABILIDADES POR ARQUÉTIPO
// ==================================================================

const ARCHETYPE_ABILITIES: Record<AIArchetype, IAbility> = {
  ASSASSINO: ASSASSINO_ABILITY,
  PROTETOR: PROTETOR_ABILITY,
  DRENADOR_ESTAFA: DRENADOR_ABILITY,
};

// ==================================================================
// CLASSE BASE: EnemyBehavior
// ==================================================================

/**
 * Classe abstrata base para comportamentos de inimigo.
 * Cada arquétipo concreto estende esta classe e implementa
 * o método evaluateAction.
 */
abstract class EnemyBehavior implements IEnemyBehavior {
  public readonly id: string;
  public readonly archetype: AIArchetype;
  public readonly ability: IAbility;

  constructor(id: string, archetype: AIArchetype) {
    this.id = id;
    this.archetype = archetype;
    this.ability = ARCHETYPE_ABILITIES[archetype];
  }

  /**
   * Avalia o estado atual do combate e decide qual ação tomar.
   *
   * @param enemies      - Lista de estados dos inimigos vivos
   * @param party        - Lista de estados dos personagens do grupo
   * @param estafaBalance - Saldo atual do medidor de estafa (curto prazo)
   * @returns Objeto com targetId, skillId e descrição da ação
   */
  public abstract evaluateAction(
    enemies: ICombatantState[],
    party: ICombatantState[],
    estafaBalance: number,
  ): { targetId: string; skillId: string; actionDescription: string };

  /**
   * Valida se os parâmetros de entrada são válidos.
   * Retorna true se ambos os arrays são arrays não vazios.
   */
  protected validateInputs(
    enemies: ICombatantState[],
    party: ICombatantState[],
  ): boolean {
    return (
      Array.isArray(enemies) &&
      enemies.length > 0 &&
      Array.isArray(party) &&
      party.length > 0
    );
  }

  /**
   * Encontra o party member com menor HP atual (razão currentHp / maxHp).
   * Usado pelo ASSASSINO para focar alvos frágeis.
   */
  protected findLowestHpTarget(party: ICombatantState[]): ICombatantState | null {
    if (party.length === 0) return null;

    let lowestHpTarget: ICombatantState = party[0];
    let lowestHpRatio = party[0].stats.currentHp / party[0].stats.maxHp;

    for (let i = 1; i < party.length; i++) {
      const member = party[i];
      const ratio = member.stats.currentHp / member.stats.maxHp;

      if (ratio < lowestHpRatio) {
        lowestHpRatio = ratio;
        lowestHpTarget = member;
      }
    }

    return lowestHpTarget;
  }

  /**
   * Encontra o party member com maior dano base (damage stat).
   * Usado pelo PROTETOR para neutralizar a maior ameaça ofensiva.
   */
  protected findHighestDamageTarget(party: ICombatantState[]): ICombatantState | null {
    if (party.length === 0) return null;

    let highestDamageTarget: ICombatantState = party[0];
    let highestDamage = party[0].stats.damage;

    for (let i = 1; i < party.length; i++) {
      const member = party[i];
      if (member.stats.damage > highestDamage) {
        highestDamage = member.stats.damage;
        highestDamageTarget = member;
      }
    }

    return highestDamageTarget;
  }

  /**
   * Filtra combatentes vivos (currentHp > 0) do array fornecido.
   */
  protected filterAlive(characters: ICombatantState[]): ICombatantState[] {
    return characters.filter((c) => c.stats.currentHp > 0);
  }
}

// ==================================================================
// ASSASSINO
// ==================================================================

/**
 * Comportamento ASSASSINO — Foca no party member com menor HP.
 * Estratégia: eliminar alvos frágeis primeiro para reduzir o número
 * de atacantes do grupo o mais rápido possível.
 *
 * - Se existe um alvo com HP < 35%, ataca-o com prioridade máxima.
 * - Caso contrário, ataca o party member com menor HP relativo.
 * - Usa a habilidade padrão de alto dano com penetração FÍSICA.
 */
class AssassinoBehavior extends EnemyBehavior {
  constructor(id: string = 'ASSASSINO_AI') {
    super(id, 'ASSASSINO');
  }

  public evaluateAction(
    enemies: ICombatantState[],
    party: ICombatantState[],
    _estafaBalance: number,
  ): { targetId: string; skillId: string; actionDescription: string } {
    // Validação de entrada
    if (!this.validateInputs(enemies, party)) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo disponível',
      };
    }

    const aliveParty = this.filterAlive(party);

    if (aliveParty.length === 0) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo vivo disponível',
      };
    }

    // Tenta encontrar um alvo com HP crítico (< 35%)
    const criticalTarget = aliveParty.find(
      (member) =>
        member.stats.currentHp / member.stats.maxHp < LOW_HP_THRESHOLD_RATIO,
    );

    if (criticalTarget) {
      return {
        targetId: criticalTarget.id,
        skillId: this.ability.id,
        actionDescription: `Ataca ${criticalTarget.id} — alvo com HP crítico (${Math.round((criticalTarget.stats.currentHp / criticalTarget.stats.maxHp) * 100)}%)`,
      };
    }

    // Alvo padrão: menor HP relativo
    const lowestHpTarget = this.findLowestHpTarget(aliveParty);

    if (lowestHpTarget) {
      return {
        targetId: lowestHpTarget.id,
        skillId: this.ability.id,
        actionDescription: `Ataca ${lowestHpTarget.id} — alvo com menor HP (${Math.round((lowestHpTarget.stats.currentHp / lowestHpTarget.stats.maxHp) * 100)}%)`,
      };
    }

    // Fallback: primeiro party member vivo
    return {
      targetId: aliveParty[0].id,
      skillId: this.ability.id,
      actionDescription: `Ataca ${aliveParty[0].id}`,
    };
  }
}

// ==================================================================
// PROTETOR
// ==================================================================

/**
 * Comportamento PROTETOR — Neutraliza a maior ameaça ofensiva do
 * grupo e protege inimigos aliados.
 *
 * Estratégia:
 * - Se existe um inimigo aliado com HP baixo, tenta atacar o party
 *   member com maior dano para reduzir a pressão sobre o aliado frágil.
 * - Caso contrário, ataca o party member com maior dano base.
 * - Usa habilidade com penetração MAGICA e deltaM negativo (desloca
 *   estafa para MATERNO).
 */
class ProtetorBehavior extends EnemyBehavior {
  constructor(id: string = 'PROTETOR_AI') {
    super(id, 'PROTETOR');
  }

  public evaluateAction(
    enemies: ICombatantState[],
    party: ICombatantState[],
    _estafaBalance: number,
  ): { targetId: string; skillId: string; actionDescription: string } {
    // Validação de entrada
    if (!this.validateInputs(enemies, party)) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo disponível',
      };
    }

    const aliveParty = this.filterAlive(party);
    const aliveEnemies = this.filterAlive(enemies);

    if (aliveParty.length === 0) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo vivo disponível',
      };
    }

    // Verifica se existe algum aliado inimigo com HP baixo
    const lowHpEnemyAlly = aliveEnemies.find(
      (enemy) =>
        enemy.stats.currentHp / enemy.stats.maxHp < LOW_HP_THRESHOLD_RATIO,
    );

    if (lowHpEnemyAlly) {
      // Protege o aliado frágil atacando a maior ameaça ofensiva
      const highestDamageTarget = this.findHighestDamageTarget(aliveParty);

      if (highestDamageTarget) {
        return {
          targetId: highestDamageTarget.id,
          skillId: this.ability.id,
          actionDescription: `Protege ${lowHpEnemyAlly.id} atacando ${highestDamageTarget.id} — maior ameaça ofensiva`,
        };
      }
    }

    // Ataque padrão: maior dano base do grupo
    const highestDamageTarget = this.findHighestDamageTarget(aliveParty);

    if (highestDamageTarget) {
      return {
        targetId: highestDamageTarget.id,
        skillId: this.ability.id,
        actionDescription: `Ataca ${highestDamageTarget.id} — maior dano do grupo (${highestDamageTarget.stats.damage})`,
      };
    }

    // Fallback: primeiro party member vivo
    return {
      targetId: aliveParty[0].id,
      skillId: this.ability.id,
      actionDescription: `Ataca ${aliveParty[0].id}`,
    };
  }
}

// ==================================================================
// DRENADOR_ESTAFA
// ==================================================================

/**
 * Comportamento DRENADOR_ESTAFA — Manipula o medidor de estafa dos
 * personagens do grupo para provocar estados de colapso.
 *
 * Estratégia:
 * - Se o saldo de estafa está próximo do limite superior (> 70),
 *   ataca para tentar levar o alvo à FRATURA_FRENESI.
 * - Se o saldo de estafa está próximo do limite inferior (< -70),
 *   ataca para tentar levar o alvo à ESTAGNACAO_TATICA.
 * - Caso contrário, ataca o party member com maior estafa absoluta
 *   (mais distante do neutro).
 * - Usa habilidade com penetração VERDADEIRA e alto deltaM,
 *   maximizando o deslocamento de estafa.
 */
class DrenadorEstafaBehavior extends EnemyBehavior {
  constructor(id: string = 'DRENADOR_ESTAFA_AI') {
    super(id, 'DRENADOR_ESTAFA');
  }

  public evaluateAction(
    enemies: ICombatantState[],
    party: ICombatantState[],
    estafaBalance: number,
  ): { targetId: string; skillId: string; actionDescription: string } {
    // Validação de entrada
    if (!this.validateInputs(enemies, party)) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo disponível',
      };
    }

    const aliveParty = this.filterAlive(party);

    if (aliveParty.length === 0) {
      return {
        targetId: 'NONE',
        skillId: this.ability.id,
        actionDescription: 'Nenhum alvo vivo disponível',
      };
    }

    // Caso 1: Estafa muito alta — tenta empurrar para FRATURA_FRENESI
    if (estafaBalance >= HIGH_ESTAFA_THRESHOLD) {
      const target = aliveParty.reduce((closest, member) => {
        const currentDiff = 100 - member.shortTermEstafa;
        const bestDiff = 100 - closest.shortTermEstafa;
        return currentDiff < bestDiff ? member : closest;
      });

      return {
        targetId: target.id,
        skillId: this.ability.id,
        actionDescription: `Drena estafa de ${target.id} — estafa alta (${target.shortTermEstafa}), visando FRATURA_FRENESI`,
      };
    }

    // Caso 2: Estafa muito baixa — tenta empurrar para ESTAGNACAO_TATICA
    if (estafaBalance <= LOW_ESTAFA_THRESHOLD) {
      const target = aliveParty.reduce((closest, member) => {
        const currentDiff = member.shortTermEstafa - (-100);
        const bestDiff = closest.shortTermEstafa - (-100);
        return currentDiff < bestDiff ? member : closest;
      });

      return {
        targetId: target.id,
        skillId: this.ability.id,
        actionDescription: `Drena estafa de ${target.id} — estafa baixa (${target.shortTermEstafa}), visando ESTAGNACAO_TATICA`,
      };
    }

    // Caso 3: Estafa moderada — ataca quem tem maior valor absoluto de estafa
    const target = aliveParty.reduce((highest, member) => {
      const currentAbs = Math.abs(member.shortTermEstafa);
      const highestAbs = Math.abs(highest.shortTermEstafa);
      return currentAbs > highestAbs ? member : highest;
    });

    return {
      targetId: target.id,
      skillId: this.ability.id,
      actionDescription: `Drena estafa de ${target.id} — maior desvio absoluto (${target.shortTermEstafa})`,
    };
  }
}

// ==================================================================
// FÁBRICA DE COMPORTAMENTOS
// ==================================================================

/**
 * Factory function para criar instâncias de EnemyBehavior com base
 * no arquétipo fornecido.
 *
 * @param archetype - O arquétipo de IA desejado
 * @param id        - Identificador opcional para a instância
 * @returns Uma instância concreta de EnemyBehavior
 */
export function createEnemyBehavior(
  archetype: AIArchetype,
  id?: string,
): IEnemyBehavior {
  switch (archetype) {
    case 'ASSASSINO':
      return new AssassinoBehavior(id);
    case 'PROTETOR':
      return new ProtetorBehavior(id);
    case 'DRENADOR_ESTAFA':
      return new DrenadorEstafaBehavior(id);
    default: {
      // Exaustividade garantida pelo tipo
      const _exhaustive: never = archetype;
      throw new Error(`Arquétipo desconhecido: ${_exhaustive}`);
    }
  }
}

/**
 * Registro de todos os comportamentos disponíveis, indexados por id.
 * Útil para lookup rápido e serialização.
 */
export const ENEMY_BEHAVIOR_REGISTRY: Record<string, IEnemyBehavior> = {
  ASSASSINO_AI: new AssassinoBehavior(),
  PROTETOR_AI: new ProtetorBehavior(),
  DRENADOR_ESTAFA_AI: new DrenadorEstafaBehavior(),
};