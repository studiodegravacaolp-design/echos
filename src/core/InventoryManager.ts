/**
 * ====================================================================
 * InventoryManager.ts
 * --------------------------------------------------------------------
 * Gerenciador de Inventário do Projeto Aetheris.
 * Responsável por:
 *   - Adicionar/remover itens com empilhamento respeitando maxStack
 *   - Cálculo de peso dinâmico cumulativo
 *   - Sincronização do peso total com o CharacterState
 *
 * Fonte: Sprint 4 — Inventory Manager (Tarefa 4.1)
 * ====================================================================
 */

import {
  IItem,
  IInventorySlot,
} from '../types/aetheris.types';
import { CharacterState } from './CharacterState';

/**
 * Classe InventoryManager
 * --------------------------------------------------------------------
 * Gerencia o inventário do personagem através de um mapeamento
 * de índice de slot para slot de inventário.
 *
 * Funcionalidades:
 * - addItem: Adiciona itens com empilhamento automático respeitando
 *   o limite maxStack de cada item. Se não houver espaço em slots
 *   existentes, ocupa um novo slot vazio até o teto de _maxSlots.
 * - removeItem: Remove uma quantidade específica de um slot,
 *   limpando o slot do mapa se a quantidade chegar a zero.
 * - calculateTotalWeight: Itera sobre todos os slots ativos e
 *   retorna a soma exata de (slot.item.weight * slot.quantity).
 */
export class InventoryManager {
  // ==================================================================
  // PROPRIEDADES PRIVADAS
  // ==================================================================

  /** Mapeamento de índice de slot para o slot de inventário */
  private _slots: Map<number, IInventorySlot>;

  /** Teto máximo de slots do inventário (padrão: 30) */
  private _maxSlots: number;

  /**
   * Teto máximo de peso cumulativo do inventário (Carga Máxima).
   * Calibrado para permanecer dentro do clamp de velocidade mínima
   * (10% da baseSpeed) do CombatEngine — ver ENG-MATEMATICA-COMBATE
   * Seção 7.3. Padrão: 150 unidades de massa abstratas.
   */
  private _maxWeightPenalty: number;

  // ==================================================================
  // CONSTRUTOR
  // ==================================================================

  /**
   * Cria uma nova instância de InventoryManager.
   *
   * @param maxSlots - Número máximo de slots (padrão: 30)
   * @param maxWeightPenalty - Peso máximo cumulativo do inventário,
   *                           a Carga Máxima (padrão: 150)
   */
  constructor(maxSlots: number = 30, maxWeightPenalty: number = 150) {
    this._slots = new Map<number, IInventorySlot>();
    this._maxSlots = maxSlots < 1 ? 1 : maxSlots;
    this._maxWeightPenalty = maxWeightPenalty <= 0 ? 150 : maxWeightPenalty;
  }

  // ==================================================================
  // GETTERS
  // ==================================================================

  /**
   * Obtém uma cópia do mapeamento de slots atual.
   * Retorna um novo Map para evitar mutação externa direta.
   */
  get slots(): Map<number, IInventorySlot> {
    return new Map(this._slots);
  }

  /**
   * Obtém o número máximo de slots configurado.
   */
  get maxSlots(): number {
    return this._maxSlots;
  }

  /**
   * Obtém o número de slots atualmente ocupados.
   */
  get occupiedSlots(): number {
    return this._slots.size;
  }

  /**
   * Obtém o teto máximo de peso do inventário (Carga Máxima).
   */
  get maxWeightPenalty(): number {
    return this._maxWeightPenalty;
  }

  // ==================================================================
  // MÉTODO: addItem
  // ==================================================================

  /**
   * addItem(item, quantity)
   * ------------------------------------------------------------------
   * Adiciona uma quantidade de um item ao inventário.
   *
   * Estratégia de empilhamento:
   * 1. Calcula o peso potencial (peso atual + peso do lote a inserir).
   *    Se exceder a Carga Máxima (_maxWeightPenalty), rejeita a
   *    inserção inteira ANTES de tocar nos slots.
   * 2. Tenta empilhar o item em slots existentes que contenham o
   *    mesmo item e ainda tenham espaço (quantity < maxStack).
   * 3. Se ainda restar quantidade após preencher slots existentes,
   *    ocupa novos slots vazios até o limite de _maxSlots.
   * 4. Retorna false se o inventário estiver absolutamente lotado
   *    e não for possível adicionar toda a quantidade.
   *
   * @param item - O item a ser adicionado
   * @param quantity - A quantidade a ser adicionada (deve ser > 0)
   * @returns true se toda a quantidade foi adicionada, false caso contrário
   */
  public addItem(item: IItem, quantity: number): boolean {
    // Validação de parâmetros
    if (quantity <= 0) {
      return false;
    }

    // ================================================================
    // Fase 0: Validação de Carga Máxima
    // Calcula o peso potencial ANTES de qualquer mutação de slots.
    // Se o peso resultante exceder o teto, rejeita a inserção inteira.
    // Fonte: Débito técnico — Sprint 4 (Carga Máxima)
    // ================================================================

    const potentialWeight = this.calculateTotalWeight() + (item.weight * quantity);

    if (potentialWeight > this._maxWeightPenalty) {
      return false; // Carga Máxima excedida — inserção rejeitada
    }

    let remaining = quantity;

    // ================================================================
    // Fase 1: Empilhar em slots existentes com o mesmo item
    // ================================================================

    for (const [, slot] of this._slots) {
      if (remaining <= 0) {
        break; // Já alocou tudo
      }

      // Só empilha se for o mesmo item (mesmo id) e ainda há espaço
      if (slot.item.id === item.id && slot.quantity < slot.item.maxStack) {
        const availableSpace = slot.item.maxStack - slot.quantity;
        const toAdd = Math.min(remaining, availableSpace);

        slot.quantity += toAdd;
        remaining -= toAdd;
      }
    }

    // ================================================================
    // Fase 2: Ocupar novos slots vazios se ainda restar quantidade
    // ================================================================

    while (remaining > 0) {
      // Verifica se ainda há slots disponíveis
      if (this._slots.size >= this._maxSlots) {
        return false; // Inventário lotado — não foi possível alocar tudo
      }

      // Encontra o menor índice de slot vazio disponível
      const newSlotIndex = this.findEmptySlotIndex();

      const toAdd = Math.min(remaining, item.maxStack);

      this._slots.set(newSlotIndex, {
        item: { ...item },
        quantity: toAdd,
      });

      remaining -= toAdd;
    }

    return true;
  }

  // ==================================================================
  // MÉTODO: removeItem
  // ==================================================================

  /**
   * removeItem(slotIndex, quantity)
   * ------------------------------------------------------------------
   * Remove uma quantidade específica de um slot do inventário.
   *
   * Regras:
   * - Se a quantidade a remover for maior ou igual à quantidade atual
   *   do slot, o slot inteiro é removido do mapa.
   * - Se a quantidade a remover for menor, apenas decrementa.
   * - Retorna false se o slot não existir ou a quantidade for inválida.
   *
   * @param slotIndex - Índice do slot a remover
   * @param quantity - Quantidade a remover (deve ser > 0)
   * @returns true se a remoção foi bem-sucedida, false caso contrário
   */
  public removeItem(slotIndex: number, quantity: number): boolean {
    // Validação de parâmetros
    if (quantity <= 0) {
      return false;
    }

    const slot = this._slots.get(slotIndex);

    // Slot não encontrado
    if (!slot) {
      return false;
    }

    // Se a quantidade a remover é maior ou igual à quantidade atual,
    // remove o slot inteiro
    if (quantity >= slot.quantity) {
      this._slots.delete(slotIndex);
      return true;
    }

    // Caso contrário, apenas decrementa
    slot.quantity -= quantity;
    return true;
  }

  // ==================================================================
  // MÉTODO: calculateTotalWeight
  // ==================================================================

  /**
   * calculateTotalWeight()
   * ------------------------------------------------------------------
   * Calcula o peso total cumulativo de todos os itens no inventário.
   *
   * A fórmula é: Σ (slot.item.weight * slot.quantity) para cada slot
   * ativo no mapa.
   *
   * @returns O peso total do inventário (sempre >= 0)
   */
  public calculateTotalWeight(): number {
    let totalWeight = 0;

    for (const [, slot] of this._slots) {
      totalWeight += slot.item.weight * slot.quantity;
    }

    return totalWeight;
  }

  // ==================================================================
  // MÉTODO AUXILIAR: findEmptySlotIndex
  // ==================================================================

  /**
   * findEmptySlotIndex()
   * ------------------------------------------------------------------
   * Encontra o menor índice de slot não ocupado no intervalo [0, _maxSlots).
   *
   * @returns O menor índice de slot vazio
   */
  private findEmptySlotIndex(): number {
    for (let i = 0; i < this._maxSlots; i++) {
      if (!this._slots.has(i)) {
        return i;
      }
    }
    // Caso de segurança: retorna o tamanho atual (não deve chegar aqui
    // pois o chamador já verificou _slots.size < _maxSlots)
    return this._slots.size;
  }

  // ==================================================================
  // MÉTODO DE UTILIDADE: clear
  // ==================================================================

  /**
   * clear()
   * ------------------------------------------------------------------
   * Remove todos os itens do inventário, resetando-o ao estado vazio.
   */
  public clear(): void {
    this._slots.clear();
  }
}

// ==================================================================
// FUNÇÃO DE SINCRONIZAÇÃO: syncWeightWithCharacter
// ==================================================================

/**
 * syncWeightWithCharacter(character)
 * ------------------------------------------------------------------
 * Sincroniza o peso total do inventário com o personagem.
 *
 * Esta função:
 * 1. Calcula o peso total do inventário via calculateTotalWeight()
 * 2. Injeta o valor no modificador de peso do personagem através
 *    do setter character.inventoryWeight
 *
 * O peso de carga injetado pode ser usado pelo CharacterState no
 * cálculo de velocidade e atrito final de turno, permitindo que
 * personagens mais carregados tenham penalidades de movimento.
 *
 * @param inventory - O InventoryManager contendo os itens
 * @param character - O CharacterState do personagem
 */
export function syncWeightWithCharacter(
  inventory: InventoryManager,
  character: CharacterState,
): void {
  const totalWeight = inventory.calculateTotalWeight();
  character.inventoryWeight = totalWeight;
}