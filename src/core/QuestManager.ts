/**
 * ====================================================================
 * QuestManager.ts
 * --------------------------------------------------------------------
 * Gerenciador de Missões do Projeto Aetheris.
 * Responsável por:
 *   - Registrar missões com metas progressivas
 *   - Controlar ciclo de vida: NOT_STARTED → ACTIVE → COMPLETED
 *   - Gerenciar progresso de metas (goals) individuais
 *   - Conceder recompensas (sucata para o herói + itens no inventário)
 *
 * Fonte: Sprint 16 — Quest Manager & Progression Integration
 * ====================================================================
 */

import { IItem } from '../types/aetheris.types';
import { CharacterState } from './CharacterState';
import { InventoryManager } from './InventoryManager';

/**
 * Enum QuestStatus
 * --------------------------------------------------------------------
 * Ciclo de vida de uma missão no Projeto Aetheris.
 */
export enum QuestStatus {
  NOT_STARTED = 'NOT_STARTED',
  ACTIVE = 'ACTIVE',
  COMPLETED = 'COMPLETED',
}

/**
 * Interface IQuestGoal
 * --------------------------------------------------------------------
 * Define uma meta progressiva dentro de uma missão.
 * current/required determinam o preenchimento da barra de progresso.
 */
/** Classificação de uma missão. */
export type QuestType = 'MAIN' | 'SIDE';

/** Tipo de meta, usado pelos gatilhos de progresso. */
export type QuestGoalType = 'REACH_NODE' | 'DEFEAT_ENEMIES' | 'KILL_BOSS' | 'TALK_NPC' | 'GENERIC';

export interface IQuestGoal {
  id: string;
  description: string;
  current: number;
  required: number;
  /** Tipo do gatilho que avança esta meta (padrão GENERIC). */
  type?: QuestGoalType;
  /** Alvo do gatilho (nodeId | templateId de inimigo/chefe | id do NPC/diálogo). */
  target?: string;
}

/**
 * Interface IQuestReward
 * --------------------------------------------------------------------
 * Recompensa concedida ao completar uma missão.
 * scrap é creditado no CharacterState.scrapCount;
 * items são inseridos no InventoryManager.
 */
export interface IQuestReward {
  scrap: number;
  items: Array<{ item: IItem; quantity: number }>;
  /** XP concedido a cada sobrevivente do grupo (opcional). */
  xp?: number;
  /** Mantimentos concedidos ao grupo (opcional). */
  supplies?: number;
}

/** Estado serializável de uma missão (para persistência). */
export interface IQuestSaveState {
  id: string;
  status: QuestStatus;
  goals: Array<{ id: string; current: number }>;
}

/**
 * Interface IQuest
 * --------------------------------------------------------------------
 * Contrato de dados completo de uma missão.
 */
export interface IQuest {
  id: string;
  name: string;
  description: string;
  status: QuestStatus;
  goals: IQuestGoal[];
  reward: IQuestReward;
  /** Classificação (MAIN | SIDE). Padrão: SIDE. */
  type?: QuestType;
}

/**
 * Interface IQuestProgressResult
 * --------------------------------------------------------------------
 * Resultado de operações de progresso (updateGoal / completeQuest).
 */
export interface IQuestProgressResult {
  success: boolean;
  message: string;
  questCompleted?: boolean;
  scrapAwarded?: number;
  itemsAwarded?: Array<{ item: IItem; quantity: number }>;
}

/**
 * Classe QuestManager
 * --------------------------------------------------------------------
 * Gerencia o ciclo de vida completo de missões.
 *
 * Funcionalidades:
 * - registerQuest: Registra uma nova missão no catálogo (status NOT_STARTED)
 * - startQuest: Transiciona uma missão para ACTIVE
 * - updateGoal: Atualiza o progresso de uma meta específica
 * - completeQuest: Finaliza a missão, concede recompensa e marca COMPLETED
 * - getQuest: Consulta o estado atual de uma missão
 */
export class QuestManager {
  /** Mapa de missões registradas indexadas por questId */
  private quests: Map<string, IQuest>;

  constructor() {
    this.quests = new Map<string, IQuest>();
  }

  /**
   * registerQuest(quest)
   * ------------------------------------------------------------------
   * Registra uma nova missão no catálogo.
   * Se o status não for definido, inicia como NOT_STARTED.
   * Retorna false se a missão já existir.
   *
   * @param quest - Dados completos da missão
   * @returns true se registrada, false se já existia
   */
  public registerQuest(quest: IQuest): boolean {
    if (this.quests.has(quest.id)) {
      return false;
    }

    // Se o status não foi definido, inicia como NOT_STARTED
    const normalizedQuest: IQuest = {
      ...quest,
      status: quest.status ?? QuestStatus.NOT_STARTED,
    };

    this.quests.set(quest.id, normalizedQuest);
    return true;
  }

  /**
   * startQuest(questId)
   * ------------------------------------------------------------------
   * Transiciona uma missão registrada de NOT_STARTED para ACTIVE.
   *
   * @param questId - ID da missão
   * @returns true se a transição foi bem-sucedida
   */
  public startQuest(questId: string): boolean {
    const quest = this.quests.get(questId);
    if (!quest) return false;
    if (quest.status !== QuestStatus.NOT_STARTED) return false;

    quest.status = QuestStatus.ACTIVE;
    return true;
  }

  /**
   * updateGoal(questId, goalId, progress)
   * ------------------------------------------------------------------
   * Atualiza o progresso atual de uma meta específica dentro de uma
   * missão ativa. O valor é acumulado (soma ao current existente)
   * e truncado ao limite required.
   *
   * Se após a atualização TODAS as metas da missão estiverem completas
   * (current >= required), retorna questCompleted = true no resultado.
   *
   * @param questId - ID da missão
   * @param goalId  - ID da meta a ser atualizada
   * @param progress - Quantidade de progresso a adicionar (>= 0)
   * @returns IQuestProgressResult com status da operação
   */
  public updateGoal(questId: string, goalId: string, progress: number): IQuestProgressResult {
    const quest = this.quests.get(questId);
    if (!quest) {
      return { success: false, message: 'Missão não encontrada.' };
    }
    if (quest.status !== QuestStatus.ACTIVE) {
      return { success: false, message: 'Missão não está ativa.' };
    }

    const goal = quest.goals.find(g => g.id === goalId);
    if (!goal) {
      return { success: false, message: 'Meta não encontrada na missão.' };
    }

    if (!Number.isFinite(progress) || progress < 0) {
      return { success: false, message: 'Progresso inválido (deve ser >= 0).' };
    }

    // Acumula progresso com cap no required
    goal.current = Math.min(goal.current + progress, goal.required);

    // Verifica se todas as metas foram cumpridas
    const allGoalsCompleted = quest.goals.every(g => g.current >= g.required);

    return {
      success: true,
      message: allGoalsCompleted
        ? 'Todas as metas da missão foram cumpridas!'
        : `Progresso da meta '${goal.description}' atualizado para ${goal.current}/${goal.required}.`,
      questCompleted: allGoalsCompleted,
    };
  }

  /**
   * completeQuest(questId, hero, inventory)
   * ------------------------------------------------------------------
   * Finaliza uma missão ativa, concede as recompensas e marca como
   * COMPLETED.
   *
   * Condições para finalização:
   * 1. Missão deve estar registrada e no estado ACTIVE
   * 2. Todas as metas devem estar cumpridas (current >= required)
   *
   * Recompensas:
   * - scrap: Creditado diretamente no CharacterState.scrapCount
   * - items: Inseridos no InventoryManager via addItem
   *
   * @param questId  - ID da missão a completar
   * @param hero     - Estado do personagem principal (recebe sucata)
   * @param inventory - Inventário global (recebe itens)
   * @returns IQuestProgressResult com detalhes das recompensas
   */
  public completeQuest(
    questId: string,
    hero: CharacterState,
    inventory: InventoryManager,
  ): IQuestProgressResult {
    const quest = this.quests.get(questId);
    if (!quest) {
      return { success: false, message: 'Missão não encontrada.' };
    }
    if (quest.status !== QuestStatus.ACTIVE) {
      return { success: false, message: 'Missão não está ativa.' };
    }

    // Verifica se todas as metas foram cumpridas
    const allGoalsCompleted = quest.goals.every(g => g.current >= g.required);
    if (!allGoalsCompleted) {
      return { success: false, message: 'Nem todas as metas da missão foram cumpridas.' };
    }

    // Concede recompensa de sucata ao herói principal
    hero.scrapCount += quest.reward.scrap;

    // Concede itens ao inventário global
    for (const rewardItem of quest.reward.items) {
      const added = inventory.addItem(rewardItem.item, rewardItem.quantity);
      if (!added) {
        // Se falhar ao adicionar, estorna a sucata e reverte
        hero.scrapCount -= quest.reward.scrap;
        quest.status = QuestStatus.ACTIVE;
        return {
          success: false,
          message: `Falha ao adicionar '${rewardItem.item.name}' ao inventário. Operação revertida.`,
        };
      }
    }

    // Marca a missão como COMPLETED
    quest.status = QuestStatus.COMPLETED;

    return {
      success: true,
      message: `Missão '${quest.name}' concluída com sucesso!`,
      questCompleted: true,
      scrapAwarded: quest.reward.scrap,
      itemsAwarded: [...quest.reward.items],
    };
  }

  /**
   * getQuest(questId)
   * ------------------------------------------------------------------
   * Retorna uma cópia dos dados da missão, ou undefined se não existir.
   *
   * @param questId - ID da missão
   * @returns Cópia da IQuest ou undefined
   */
  public getQuest(questId: string): IQuest | undefined {
    const quest = this.quests.get(questId);
    if (!quest) return undefined;

    // Retorna cópia defensiva
    return {
      ...quest,
      goals: quest.goals.map(g => ({ ...g })),
      reward: {
        ...quest.reward,
        items: quest.reward.items.map(ri => ({ item: { ...ri.item }, quantity: ri.quantity })),
      },
    };
  }

  /**
   * getQuestsByStatus(status)
   * ------------------------------------------------------------------
   * Retorna todas as missões que estão em um determinado estado.
   *
   * @param status - Filtro de status (ACTIVE, COMPLETED, NOT_STARTED)
   * @returns Array de cópias das IQuest no status informado
   */
  public getQuestsByStatus(status: QuestStatus): IQuest[] {
    const result: IQuest[] = [];
    for (const quest of this.quests.values()) {
      if (quest.status === status) {
        result.push({
          ...quest,
          goals: quest.goals.map(g => ({ ...g })),
          reward: {
            ...quest.reward,
            items: quest.reward.items.map(ri => ({ item: { ...ri.item }, quantity: ri.quantity })),
          },
        });
      }
    }
    return result;
  }

  /**
   * clear()
   * ------------------------------------------------------------------
   * Remove todas as missões registradas. Útil para resetar estado
   * entre sessões de teste.
   */
  public clear(): void {
    this.quests.clear();
  }

  // ==================================================================
  // GATILHOS DE PROGRESSO E CONSULTAS DE ALTO NÍVEL
  // ==================================================================

  /** Retorna a Missão Principal ativa (primeira ACTIVE do tipo MAIN), se houver. */
  public getActiveMainQuest(): IQuest | undefined {
    for (const q of this.quests.values()) {
      if (q.status === QuestStatus.ACTIVE && q.type === 'MAIN') {
        return this.getQuest(q.id);
      }
    }
    return undefined;
  }

  /** Primeira meta ainda incompleta de uma missão (para exibir a etapa atual). */
  public getCurrentGoal(questId: string): IQuestGoal | undefined {
    const quest = this.quests.get(questId);
    if (!quest) return undefined;
    const goal = quest.goals.find((g) => g.current < g.required);
    return goal ? { ...goal } : undefined;
  }

  /**
   * notifyNodeVisited(nodeId)
   * ------------------------------------------------------------------
   * Gatilho de travessia: avança metas REACH_NODE cujo alvo é o nó.
   * @returns IDs das missões que ficaram totalmente satisfeitas.
   */
  public notifyNodeVisited(nodeId: string): string[] {
    return this.advanceMatchingGoals(
      (g) => g.type === 'REACH_NODE' && g.target === nodeId,
      1,
    );
  }

  /**
   * notifyEnemiesDefeated(enemies)
   * ------------------------------------------------------------------
   * Gatilho de combate: avança DEFEAT_ENEMIES (por contagem) e KILL_BOSS
   * (por templateId correspondente).
   * @returns IDs das missões que ficaram totalmente satisfeitas.
   */
  public notifyEnemiesDefeated(enemies: Array<{ templateId: string }>): string[] {
    const completed = new Set<string>();
    for (const quest of this.quests.values()) {
      if (quest.status !== QuestStatus.ACTIVE) continue;
      const wasDone = this.allGoalsDone(quest);
      let changed = false;
      for (const g of quest.goals) {
        if (g.type === 'DEFEAT_ENEMIES') {
          const inc = enemies.filter((e) => !g.target || g.target === 'ANY' || g.target === e.templateId).length;
          if (inc > 0) { g.current = Math.min(g.required, g.current + inc); changed = true; }
        } else if (g.type === 'KILL_BOSS') {
          const inc = enemies.filter((e) => e.templateId === g.target).length;
          if (inc > 0) { g.current = Math.min(g.required, g.current + inc); changed = true; }
        }
      }
      if (changed && !wasDone && this.allGoalsDone(quest)) {
        completed.add(quest.id);
      }
    }
    return [...completed];
  }

  /**
   * notifyNpcTalked(npcId)
   * ------------------------------------------------------------------
   * Gatilho de diálogo: avança metas TALK_NPC cujo alvo é o NPC/diálogo.
   */
  public notifyNpcTalked(npcId: string): string[] {
    return this.advanceMatchingGoals(
      (g) => g.type === 'TALK_NPC' && g.target === npcId,
      1,
    );
  }

  /**
   * claimQuestReward(questId)
   * ------------------------------------------------------------------
   * Se a missão está ativa e com todas as metas cumpridas, marca como
   * COMPLETED e devolve a recompensa (para o grupo aplicar XP/Sucata/
   * Mantimentos/itens). Não credita nada por si só.
   *
   * @returns A recompensa, ou null se ainda não elegível.
   */
  public claimQuestReward(questId: string): IQuestReward | null {
    const quest = this.quests.get(questId);
    if (!quest || quest.status !== QuestStatus.ACTIVE || !this.allGoalsDone(quest)) {
      return null;
    }
    quest.status = QuestStatus.COMPLETED;
    return {
      ...quest.reward,
      items: quest.reward.items.map((ri) => ({ item: { ...ri.item }, quantity: ri.quantity })),
    };
  }

  // ==================================================================
  // PERSISTÊNCIA
  // ==================================================================

  /** Serializa o estado (status + progresso de metas) de todas as missões. */
  public serializeState(): IQuestSaveState[] {
    return Array.from(this.quests.values()).map((q) => ({
      id: q.id,
      status: q.status,
      goals: q.goals.map((g) => ({ id: g.id, current: g.current })),
    }));
  }

  /**
   * restoreState(states)
   * ------------------------------------------------------------------
   * Reidrata status e progresso de metas das missões JÁ REGISTRADAS.
   * Missões ausentes no catálogo atual são ignoradas.
   */
  public restoreState(states: IQuestSaveState[]): void {
    for (const saved of states) {
      const quest = this.quests.get(saved.id);
      if (!quest) continue;
      quest.status = saved.status;
      for (const savedGoal of saved.goals) {
        const goal = quest.goals.find((g) => g.id === savedGoal.id);
        if (goal) {
          goal.current = Math.min(goal.required, Math.max(0, savedGoal.current));
        }
      }
    }
  }

  // ==================================================================
  // AUXILIARES INTERNOS
  // ==================================================================

  private allGoalsDone(quest: IQuest): boolean {
    return quest.goals.every((g) => g.current >= g.required);
  }

  /**
   * Avança as metas ativas que satisfazem o predicado (por `amount`) e
   * retorna os IDs das missões que ficaram totalmente satisfeitas agora.
   */
  private advanceMatchingGoals(
    predicate: (goal: IQuestGoal) => boolean,
    amount: number,
  ): string[] {
    const completed: string[] = [];
    for (const quest of this.quests.values()) {
      if (quest.status !== QuestStatus.ACTIVE) continue;
      const wasDone = this.allGoalsDone(quest);
      let changed = false;
      for (const g of quest.goals) {
        if (predicate(g) && g.current < g.required) {
          g.current = Math.min(g.required, g.current + amount);
          changed = true;
        }
      }
      if (changed && !wasDone && this.allGoalsDone(quest)) {
        completed.push(quest.id);
      }
    }
    return completed;
  }
}