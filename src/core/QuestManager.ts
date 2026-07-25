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
export interface IQuestGoal {
  id: string;
  description: string;
  current: number;
  required: number;
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
}