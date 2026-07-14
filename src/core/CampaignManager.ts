/**
 * ====================================================================
 * CampaignManager.ts
 * --------------------------------------------------------------------
 * Gerenciador de campanha — coordena o estado da party, inventário
 * global e progresso narrativo da campanha.
 *
 * Responsabilidades:
 *   - Manter o estado da party (CharacterState[])
 *   - Gerenciar o inventário global do grupo (Map<string, IInventoryItem>)
 *   - Consolidar loot pós-batalha (scraps + itens) vindo do LootEngine
 *   - Rastrear progresso da campanha (nó atual, nós desbloqueados, batalhas)
 *
 * Fonte: docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CharacterState } from './CharacterState';

// ==================================================================
// INTERFACES PÚBLICAS
// ==================================================================

/**
 * Interface IInventoryItem
 * --------------------------------------------------------------------
 * Representa um item no inventário global da campanha.
 *
 * Campos:
 *   id       — Identificador único do item (ex: "scrap_iron", "gear_cog")
 *   name     — Nome legível do item
 *   type     — Categoria do item (MATERIAL | CONSUMABLE | EQUIPMENT)
 *   quantity — Quantidade atual no inventário
 */
export interface IInventoryItem {
  id: string;
  name: string;
  type: 'MATERIAL' | 'CONSUMABLE' | 'EQUIPMENT';
  quantity: number;
  /** Chave de textura para renderização (opcional — link com a Bíblia Visual) */
  spriteKey?: string;
}

/**
 * Interface ISaveData
 * --------------------------------------------------------------------
 * Estrutura de dados completa para serialização/deserialização
 * do estado da campanha (save/load).
 *
 * Campos:
 *   progress         — Progresso narrativo da campanha
 *   globalInventory   — Array de itens do inventário global
 *   partyStates      — Dados serializados de cada CharacterState
 */
export interface ISaveData {
  progress: ICampaignProgress;
  globalInventory: IInventoryItem[];
  partyStates: {
    id: string;
    hp: number;
    scrapCount: number;
    engineeringCharges: Record<string, number>;
  }[];
}

/**
 * Interface ICampaignProgress
 * --------------------------------------------------------------------
 * Representa o progresso narrativo da campanha em uma estrutura
 * de árvore/grafo de nós (node-based progression).
 *
 * Campos:
 *   currentNodeId          — ID do nó atual da campanha
 *   unlockedNodeIds        — Array de IDs de nós desbloqueados
 *   completedBattlesCount  — Número total de batalhas concluídas
 *   estafaBalance          — Balança de Estafa: -100 (Materno) a +100 (Paterno)
 */
export interface ICampaignProgress {
  currentNodeId: string;
  unlockedNodeIds: string[];
  completedBattlesCount: number;
  estafaBalance: number;
}

// ==================================================================
// CLASSE — CampaignManager
// ==================================================================

/**
 * CampaignManager
 * --------------------------------------------------------------------
 * Gerencia o estado coletivo da campanha: party, inventário global
 * e progresso narrativo.
 *
 * Atua como ponto central de coordenação entre:
 *   - CharacterState (estado individual dos personagens)
 *   - LootEngine (recompensas pós-batalha)
 *   - CampaignStateManager (persistência)
 *
 * NENHUM outro sistema deve modificar diretamente o inventário
 * global ou o progresso sem passar por esta classe.
 */
export class CampaignManager {
  private party: CharacterState[];
  private globalInventory: Map<string, IInventoryItem>;
  private progress: ICampaignProgress;

  /**
   * Cria uma nova instância de CampaignManager.
   *
   * @param initialParty - Array de CharacterState representando
   *                        a party inicial do jogador
   */
  constructor(initialParty: CharacterState[]) {
    this.party = initialParty;
    this.globalInventory = new Map<string, IInventoryItem>();
    this.progress = {
      currentNodeId: 'brenhold_entrance',
      unlockedNodeIds: ['brenhold_entrance'],
      completedBattlesCount: 0,
      estafaBalance: 0,
    };
  }

  /**
   * consolidateLoot(scrapsGained, itemsGained)
   * ------------------------------------------------------------------
   * Transfere os recursos coletados no LootEngine (sucatas e itens)
   * para a party e o inventário persistente do grupo após a vitória.
   *
   * Fluxo:
   *   1. Distribui a sucata igualmente entre todos os membros da party
   *      (incrementa scrapCount de cada CharacterState).
   *   2. Agrupa os itens coletados no inventário central (Map), somando
   *      quantidades se o item já existir.
   *
   * @param scrapsGained - Quantidade total de sucata ganha na batalha
   * @param itemsGained  - Array de itens coletados na batalha
   */
  public consolidateLoot(
    scrapsGained: number,
    itemsGained: IInventoryItem[],
  ): void {
    // Distribui a sucata igualmente entre os membros da party
    const scrapPerMember =
      this.party.length > 0
        ? Math.floor(scrapsGained / this.party.length)
        : 0;

    this.party.forEach((char) => {
      if (char.scrapCount !== undefined) {
        char.scrapCount += scrapPerMember;
      }
    });

    // Agrupa os itens coletados no inventário central
    itemsGained.forEach((item) => {
      const existing = this.globalInventory.get(item.id);
      if (existing) {
        existing.quantity += item.quantity;
      } else {
        this.globalInventory.set(item.id, { ...item });
      }
    });
  }

  /**
   * getPartyState()
   * ------------------------------------------------------------------
   * Retorna o array de CharacterState da party atual.
   *
   * @returns Cópia do array de estados dos personagens
   */
  public getPartyState(): CharacterState[] {
    return this.party;
  }

  /**
   * getGlobalInventory()
   * ------------------------------------------------------------------
   * Retorna o inventário global do grupo como um array de IInventoryItem.
   *
   * @returns Array com todos os itens do inventário global
   */
  public getGlobalInventory(): IInventoryItem[] {
    return Array.from(this.globalInventory.values());
  }

  /**
   * getProgress()
   * ------------------------------------------------------------------
   * Retorna uma cópia do objeto de progresso da campanha.
   *
   * @returns Cópia do progresso atual
   */
  public getProgress(): ICampaignProgress {
    return { ...this.progress, unlockedNodeIds: [...this.progress.unlockedNodeIds] };
  }

  /**
   * setCurrentNode(nodeId)
   * ------------------------------------------------------------------
   * Avança o nó atual da campanha para o ID especificado.
   * Se o nó ainda não estiver desbloqueado, ele é adicionado
   * automaticamente à lista de nós desbloqueados.
   *
   * @param nodeId - ID do nó para onde a campanha avançou
   */
  public setCurrentNode(nodeId: string): void {
    this.progress.currentNodeId = nodeId;

    if (!this.progress.unlockedNodeIds.includes(nodeId)) {
      this.progress.unlockedNodeIds.push(nodeId);
    }
  }

  /**
   * incrementBattleCount()
   * ------------------------------------------------------------------
   * Incrementa em 1 o contador de batalhas concluídas.
   */
  public incrementBattleCount(): void {
    this.progress.completedBattlesCount += 1;
  }

  /**
   * modifyEstafaBalance(amount)
   * ------------------------------------------------------------------
   * Modifica o equilíbrio da Balança de Estafa com travas de segurança.
   * O valor é limitado ao intervalo [-100, +100]:
   *   - Valores negativos tendem ao Materno
   *   - Valores positivos tendem ao Paterno
   *
   * @param amount - Valor a ser adicionado ao saldo atual
   */
  public modifyEstafaBalance(amount: number): void {
    this.progress.estafaBalance = Math.max(-100, Math.min(100, this.progress.estafaBalance + amount));
  }

  // ==================================================================
  // [A] LÓGICA DE CONSUMÍVEIS FORA DE COMBATE
  // ==================================================================

  /**
   * useConsumableOutOfCombat(characterId, itemId)
   * ------------------------------------------------------------------
   * Usa um item consumível do inventário global em um personagem
   * fora de combate.
   *
   * Itens suportados:
   *   - 'medkit_standard'        : Cura 35 de HP (limitado ao maxHp)
   *   - 'elemental_charge_capsule' : Recarrega +1 carga para cada
   *                                   elemento do kit de engenharia
   *
   * @param characterId - ID do personagem alvo
   * @param itemId      - ID do item consumível no inventário global
   * @returns true se o consumo foi bem-sucedido, false caso contrário
   */
  public useConsumableOutOfCombat(characterId: string, itemId: string): boolean {
    const item = this.globalInventory.get(itemId);
    if (!item || item.type !== 'CONSUMABLE' || item.quantity <= 0) {
      return false; // Item não encontrado ou sem estoque
    }

    const targetChar = this.party.find(char => char.id === characterId);
    if (!targetChar) return false;

    // Aplicação de Efeitos baseada no ID do Item Canônico
    if (itemId === 'medkit_standard') {
      if (targetChar.hp >= 100) return false; // Já está com vida cheia
      targetChar.hp = Math.min(100, targetChar.hp + 35); // Cura 35 de HP
    } else if (itemId === 'elemental_charge_capsule') {
      // Recarrega uma carga para cada tipo de kit de engenharia do personagem
      if (targetChar.engineeringCharges) {
        Object.keys(targetChar.engineeringCharges).forEach(key => {
          targetChar.engineeringCharges = {
            ...targetChar.engineeringCharges,
            [key]: targetChar.engineeringCharges[key] + 1,
          };
        });
      }
    } else {
      return false; // Consumível desconhecido
    }

    // Deduz o item consumido do inventário global
    item.quantity--;
    if (item.quantity === 0) {
      this.globalInventory.delete(itemId);
    }
    return true;
  }

  // ==================================================================
  // [B] SISTEMA DE GRAVAÇÃO E CARGA (SAVE/LOAD STATE)
  // ==================================================================

  /**
   * saveGameState()
   * ------------------------------------------------------------------
   * Serializa o estado completo da campanha em uma string JSON.
   *
   * Inclui:
   *   - progress (nó atual, nós desbloqueados, contagem de batalhas)
   *   - globalInventory (todos os itens do inventário do grupo)
   *   - partyStates (id, hp, scrapCount, engineeringCharges de cada
   *     personagem)
   *
   * @returns String JSON com o estado completo da campanha
   */
  public saveGameState(): string {
    const saveData: ISaveData = {
      progress: this.progress,
      globalInventory: this.getGlobalInventory(),
      partyStates: this.party.map(char => ({
        id: char.id,
        hp: char.hp,
        scrapCount: char.scrapCount,
        engineeringCharges: char.engineeringCharges,
      })),
    };
    return JSON.stringify(saveData);
  }

  /**
   * loadGameState(jsonString)
   * ------------------------------------------------------------------
   * Desserializa e restaura o estado da campanha a partir de uma
   * string JSON previamente salva com saveGameState().
   *
   * Restaura:
   *   - progress
   *   - globalInventory (Map reconstruído a partir do array)
   *   - partyStates (hp, scrapCount, engineeringCharges de cada
   *     personagem, identificado por id)
   *
   * @param jsonString - String JSON com o estado salvo
   * @returns true se o carregamento foi bem-sucedido, false se o
   *          JSON estiver corrompido ou inválido
   */
  public loadGameState(jsonString: string): boolean {
    try {
      const data: ISaveData = JSON.parse(jsonString);
      if (!data.progress || !data.globalInventory || !data.partyStates) return false;

      // Restaura o progresso
      this.progress = data.progress;

      // Reconstrói o Map do inventário
      this.globalInventory.clear();
      data.globalInventory.forEach(item => {
        this.globalInventory.set(item.id, item);
      });

      // Restaura o estado de cada membro da party
      data.partyStates.forEach(savedChar => {
        const char = this.party.find(p => p.id === savedChar.id);
        if (char) {
          char.hp = savedChar.hp;
          char.scrapCount = savedChar.scrapCount;
          char.engineeringCharges = savedChar.engineeringCharges;
        }
      });

      return true;
    } catch (e) {
      return false; // JSON corrompido ou inválido
    }
  }
}
