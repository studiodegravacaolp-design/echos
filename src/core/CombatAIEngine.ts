/**
 * ====================================================================
 * CombatAIEngine.ts
 * --------------------------------------------------------------------
 * Motor de IA de Combate — camada de integração entre o motor de
 * combate (CombatEngine) e os comportamentos modulares de inimigo
 * (EnemyBehavior.ts).
 *
 * Responsabilidades:
 *   1. Implementar IEnemyBehavior para uso direto com CharacterState.
 *   2. Adaptar CharacterState[] → ICombatantState[] para delegação
 *      aos comportamentos modulares.
 *   3. Expor método evaluateAction que CharacterState nativamente.
 *
 * Fonte: docs/04_arquitetura_software/ENG-MOTOR-COMBATE.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CharacterState } from './CharacterState';
import {
  AIArchetype,
  IEnemyBehavior,
  ICombatantState,
} from '../types/aetheris.types';
import { createEnemyBehavior } from '../modules/combat/EnemyBehavior';
import {
  EstafaCalculator,
  EstafaActionType,
} from '../mechanics/EstafaCalculator';

/**
 * Logger diegético para avisos de Insubordinação Tática.
 * (código, mensagem) → void. Padrão: console.warn.
 */
export type InsubordinationLogger = (code: string, message: string) => void;

/**
 * Resultado da resolução de um comando de combate à luz da Balança de Estafa.
 */
export interface ICommandResolution {
  /** ID da unidade que recebeu o comando. */
  actorId: string;
  /** Ação solicitada pelo jogador. */
  requestedAction: EstafaActionType;
  /** Se o comando foi executado como solicitado. */
  allowed: boolean;
  /** Se a psique da unidade forçou uma ação autônoma (comando incompatível). */
  insubordination: boolean;
  /** Aviso diegético do bloqueio, quando houver. */
  reason?: string;
  /** Ação autônoma modificada executada no lugar do comando bloqueado. */
  autonomousAlternative?: string;
}

/**
 * Classe CombatAIEngine
 * --------------------------------------------------------------------
 * Adapta a interface IEnemyBehavior (baseada em ICombatantState) para
 * uso direto com CharacterState no motor de combate.
 *
 * Uso:
 *   const ai = new CombatAIEngine('boss_01', 'ASSASSINO');
 *   const action = ai.evaluateAction(enemies, party, estafaBalance);
 */
export class CombatAIEngine implements IEnemyBehavior {
  public id: string;
  public archetype: AIArchetype;

  /** Comportamento modular delegado */
  private readonly behavior: IEnemyBehavior;

  constructor(id: string, archetype: AIArchetype) {
    this.id = id;
    this.archetype = archetype;
    this.behavior = createEnemyBehavior(archetype, id);
  }

  // ==================================================================
  // MÉTODO ESTÁTICO: resolvePlayerCommand (Insubordinação Tática)
  // ==================================================================

  /**
   * resolvePlayerCommand(actor, actionType, logger?)
   * ------------------------------------------------------------------
   * Submete um comando de combate à Balança de Estafa da unidade antes
   * de executá-lo. Delega a decisão ao EstafaCalculator.validateAction:
   *
   *   - Se a ação é compatível com a psique atual → allowed=true e o
   *     comando segue normalmente.
   *   - Se a ação é bloqueada (extremo Materno/Paterno incompatível) →
   *     registra o aviso diegético, loga a insubordinação e devolve a
   *     ação autônoma modificada (autonomousAlternative) para execução.
   *
   * Método estático e puro (exceto pelo efeito de log) — pode ser
   * chamado por qualquer camada de combate (GameLoop, CombatEngine)
   * sem instanciar o motor de IA.
   *
   * Fonte: AETHERIS_MASTER_INDEX.md §2 (Insubordinação Tática)
   *        docs/mechanics/ESTAFA_SYSTEM.md §4
   *
   * @param actor      - Unidade que recebeu o comando (CharacterState)
   * @param actionType - Tipo da ação solicitada pela UI
   * @param logger     - Logger opcional de insubordinação (padrão: console.warn)
   * @returns ICommandResolution — desfecho do comando
   */
  public static resolvePlayerCommand(
    actor: CharacterState,
    actionType: EstafaActionType,
    logger: InsubordinationLogger = (code, message) =>
      console.warn(`[${code}] ${message}`),
  ): ICommandResolution {
    const validation = EstafaCalculator.validateAction(
      actor.shortTermEstafa,
      actionType,
    );

    // Caminho feliz — a ação é compatível com a psique da unidade.
    if (validation.allowed) {
      return {
        actorId: actor.id,
        requestedAction: actionType,
        allowed: true,
        insubordination: false,
      };
    }

    // Ação bloqueada — loga a insubordinação e executa a alternativa autônoma.
    logger(
      'MOTOR-INSUB-001',
      `Insubordinação Tática de ${actor.id} (estafa=${actor.shortTermEstafa}): ` +
        `${validation.reason ?? 'ação incompatível com a psique atual.'} ` +
        `Ação autônoma: ${validation.autonomousAlternative ?? 'padrão'}.`,
    );

    return {
      actorId: actor.id,
      requestedAction: actionType,
      allowed: false,
      insubordination: true,
      reason: validation.reason,
      autonomousAlternative: validation.autonomousAlternative,
    };
  }

  // ==================================================================
  // MÉTODO: evaluateAction (API CharacterState)
  // ==================================================================

  /**
   * evaluateAction(enemies, party, estafaBalance)
   * ------------------------------------------------------------------
   * Avalia o estado da mesa e escolhe o alvo ideal baseado no
   * arquétipo. Aceita CharacterState[] diretamente e faz a adaptação
   * interna para ICombatantState[].
   *
   * VALIDAÇÕES:
   *   - Se party está vazia, lança erro (não há alvos válidos).
   *   - Se enemies está vazia, o comportamento usa fallback seguro.
   *
   * @param enemies      - Lista de estados dos inimigos vivos (CharacterState[])
   * @param party        - Lista de estados dos personagens do grupo (CharacterState[])
   * @param estafaBalance - Saldo atual do medidor de estafa (curto prazo)
   * @returns Objeto com targetId, skillId e descrição da ação
   */
  public evaluateAction(
    enemies: CharacterState[],
    party: CharacterState[],
    estafaBalance: number,
  ): { targetId: string; skillId: string; actionDescription: string } {
    // ================================================================
    // ETAPA 1: VALIDAÇÃO DE ENTRADA
    // ================================================================

    if (!Array.isArray(party) || party.length === 0) {
      throw new Error('Não há alvos válidos na party do jogador!');
    }

    // ================================================================
    // ETAPA 2: ADAPTAÇÃO CharacterState → ICombatantState
    // ================================================================

    const adaptedEnemies: ICombatantState[] = enemies.map((cs) =>
      this.adaptCharacterState(cs),
    );
    const adaptedParty: ICombatantState[] = party.map((cs) =>
      this.adaptCharacterState(cs),
    );

    // ================================================================
    // ETAPA 3: DELEGAÇÃO AO COMPORTAMENTO MODULAR
    // ================================================================

    return this.behavior.evaluateAction(adaptedEnemies, adaptedParty, estafaBalance);
  }

  // ==================================================================
  // MÉTODO AUXILIAR: adaptCharacterState
  // ==================================================================

  /**
   * adaptCharacterState(cs)
   * ------------------------------------------------------------------
   * Converte um CharacterState para o formato leve ICombatantState,
   * extraindo apenas os campos necessários para a lógica de IA.
   *
   * Regras:
   *   - maxHp: usa o getter de CharacterState (já inclui bônus de equipamento).
   *   - currentHp: usa o getter hp (alias para stats.currentHp).
   *   - damage: usa stats.damage + bônus de ataque do equipamento (se houver).
   *   - defense: usa stats.defense + bônus de defesa do equipamento (se houver).
   *   - shortTermEstafa: mapeia diretamente do getter homônimo.
   *
   * @param cs - Estado do personagem (CharacterState)
   * @returns ICombatantState — visão estrutural mínima
   */
  private adaptCharacterState(cs: CharacterState): ICombatantState {
    const bonusStats = cs.equipmentBonusStats;

    return {
      id: cs.id,
      stats: {
        maxHp: cs.maxHp,
        currentHp: cs.hp,
        damage: cs.stats.damage + (bonusStats?.bonusAttack ?? 0),
        defense: cs.stats.defense + (bonusStats?.bonusDefense ?? 0),
        resilience: cs.stats.resilience,
        movementSpeed: cs.stats.movementSpeed,
      },
      shortTermEstafa: cs.shortTermEstafa,
    };
  }
}