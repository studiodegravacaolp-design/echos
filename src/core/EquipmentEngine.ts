/**
 * ====================================================================
 * EquipmentEngine.ts
 * --------------------------------------------------------------------
 * Motor de equipamento — gerencia o arsenal dos personagens.
 *
 * Responsabilidades:
 *   - Equipar/Remover itens do inventário global da campanha em
 *     slots específicos do personagem (WEAPON | ARMOR | CORE_MOD)
 *   - Aplicar/recalcular bônus estatísticos (maxHp, attack, defense)
 *     concedidos pelos equipamentos ativos
 *   - Devolver itens removidos ao inventário global
 *
 * Fonte: docs/04_arquitetura_software/ENG-ESTRUTURA-DADOS.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CampaignManager, IInventoryItem } from './CampaignManager';
import { CharacterState } from './CharacterState';
import { IEquipmentItem, ICharacterStats, SlotType } from '../types/aetheris.types';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Tipo padrão para itens de equipamento no inventário global */
const EQUIPMENT_INVENTORY_TYPE = 'EQUIPMENT' as const;

/** Razão de durabilidade (current/max) igual ou abaixo da qual o item é Rusted. */
export const RUST_DURABILITY_THRESHOLD = 0.25;

/** Penalidade multiplicativa aplicada aos atributos de um item Rusted (50%). */
export const RUST_STAT_PENALTY = 0.5;

/** Durabilidade restaurada por unidade de sucata gasta no reparo. */
export const REPAIR_DURABILITY_PER_SCRAP = 5;

// ==================================================================
// MODELO DE DURABILIDADE (NOVO) — IDurableEquipment
// ==================================================================
// NOTA DE ARQUITETURA: este modelo é DISTINTO do IEquipmentItem legado
// (slot-based, em aetheris.types.ts), que permanece em uso por
// equipItem/unequipItem, CanonicalContent, GameLoop e o mapa de slots
// do CharacterState. O modelo abaixo adiciona material, durabilidade e
// baseStats sem quebrar o sistema de slots existente.
// ==================================================================

/** Categoria funcional do equipamento durável. */
export type DurableEquipmentType = 'WEAPON' | 'ARMOR' | 'ACCESSORY';

/** Material do equipamento (afeta identidade e futura mecânica de manufatura). */
export type EquipmentMaterial =
    | 'SCRAP_IRON'
    | 'REFINED_BRASS'
    | 'HEAVY_LEAD'
    | 'COPPER_CIRCUIT';

/** Item de equipamento com durabilidade e desgaste (oxidação). */
export interface IDurableEquipment {
    id: string;
    name: string;
    type: DurableEquipmentType;
    material: EquipmentMaterial;
    durability: { current: number; max: number };
    baseStats: ICharacterStats;
}

/** Resultado de uma operação de reparo. */
export interface IRepairResult {
    /** Item reparado (mesma referência, mutada). */
    item: IDurableEquipment;
    /** Sucata efetivamente consumida no reparo. */
    scrapSpent: number;
    /** Pontos de durabilidade efetivamente restaurados. */
    durabilityRestored: number;
}

// ==================================================================
// CLASSE — EquipmentEngine
// ==================================================================

/**
 * EquipmentEngine
 * --------------------------------------------------------------------
 * Gerencia o arsenal (equipar/desequipar) dos personagens da party.
 *
 * Fluxo canônico:
 *   1. equipItem()     → valida inventário → desequipa slot ocupado
 *                        → consome item do inventário → acopla ao slot
 *                        → recalcula bônus
 *   2. unequipItem()    → remove do slot → devolve ao inventário
 *                        → recalcula bônus
 *
 * NENHUM outro sistema deve modificar directly os slots equipados
 * sem passar por esta classe.
 */
export class EquipmentEngine {

    // ==============================================================
    // [0] DURABILIDADE E DESGASTE (OXIDAÇÃO) — API ESTÁTICA PURA
    // ==============================================================

    /**
     * isRusted(item)
     * ------------------------------------------------------------------
     * Retorna true se o item está oxidado/desgastado — durabilidade atual
     * igual ou abaixo de 25% do máximo (RUST_DURABILITY_THRESHOLD).
     * Um item com durabilidade máxima inválida (<= 0) é tratado como Rusted
     * por segurança.
     */
    public static isRusted(item: IDurableEquipment): boolean {
        if (item.durability.max <= 0) {
            return true;
        }
        return item.durability.current <= item.durability.max * RUST_DURABILITY_THRESHOLD;
    }

    /**
     * calculateEquipmentModifiers(equippedItems)
     * ------------------------------------------------------------------
     * Soma os baseStats de todos os itens equipados, aplicando penalidade
     * de 50% (RUST_STAT_PENALTY) por item que estiver Rusted. Retorna um
     * agregado ICharacterStats representando o modificador total.
     *
     * Função pura — não muta os itens nem depende de CharacterState.
     */
    public static calculateEquipmentModifiers(
        equippedItems: IDurableEquipment[],
    ): ICharacterStats {
        const total: ICharacterStats = {
            maxHp: 0,
            currentHp: 0,
            damage: 0,
            defense: 0,
            resilience: 0,
            movementSpeed: 0,
        };

        for (const item of equippedItems) {
            const factor = EquipmentEngine.isRusted(item) ? RUST_STAT_PENALTY : 1;
            total.maxHp += item.baseStats.maxHp * factor;
            total.currentHp += item.baseStats.currentHp * factor;
            total.damage += item.baseStats.damage * factor;
            total.defense += item.baseStats.defense * factor;
            total.resilience += item.baseStats.resilience * factor;
            total.movementSpeed += item.baseStats.movementSpeed * factor;
        }

        return total;
    }

    /**
     * degradeEquipment(item, amount)
     * ------------------------------------------------------------------
     * Reduz a durabilidade atual do item pelo valor informado, com clamp
     * mínimo em 0. Valores inválidos (NaN, <= 0) são no-op seguro.
     * Muta e retorna o próprio item para encadeamento.
     */
    public static degradeEquipment(
        item: IDurableEquipment,
        amount: number,
    ): IDurableEquipment {
        if (!Number.isFinite(amount) || amount <= 0) {
            return item;
        }
        item.durability.current = Math.max(0, item.durability.current - amount);
        return item;
    }

    /**
     * repairEquipment(item, scrapAvailable)
     * ------------------------------------------------------------------
     * Consome sucata para restaurar durabilidade, à taxa de
     * REPAIR_DURABILITY_PER_SCRAP pontos por unidade de sucata. O reparo
     * é limitado tanto pela sucata disponível quanto pela durabilidade
     * faltante (não ultrapassa o máximo).
     *
     * @param item          - Item a reparar (mutado)
     * @param scrapAvailable - Sucata disponível no inventário
     * @returns IRepairResult com sucata gasta e durabilidade restaurada
     */
    public static repairEquipment(
        item: IDurableEquipment,
        scrapAvailable: number,
    ): IRepairResult {
        const missing = item.durability.max - item.durability.current;

        // Nada a reparar ou sem sucata — no-op.
        if (missing <= 0 || !Number.isFinite(scrapAvailable) || scrapAvailable <= 0) {
            return { item, scrapSpent: 0, durabilityRestored: 0 };
        }

        // Sucata necessária para encher (arredonda para cima) vs. disponível.
        const scrapNeededToFull = Math.ceil(missing / REPAIR_DURABILITY_PER_SCRAP);
        const scrapSpent = Math.min(Math.floor(scrapAvailable), scrapNeededToFull);

        // Durabilidade restaurada não ultrapassa o que falta.
        const durabilityRestored = Math.min(missing, scrapSpent * REPAIR_DURABILITY_PER_SCRAP);
        item.durability.current += durabilityRestored;

        return { item, scrapSpent, durabilityRestored };
    }

    // ==============================================================
    // [1] EQUIPAR
    // ==============================================================

    /**
     * equipItem(campaign, characterId, equipment)
     * ------------------------------------------------------------------
     * Equipa um item do inventário global em um personagem específico.
     *
     * Fluxo:
     *   1. Verifica se o item existe no inventário global (quantity > 0)
     *   2. Verifica se o personagem existe na party
     *   3. Inicializa o mapa de equipamentos se necessário
     *   4. Se já houver item no slot, desequipa ele primeiro
     *      (devolvendo-o ao inventário)
     *   5. Remove 1 unidade do item do inventário global
     *   6. Acopla o equipamento ao slot do personagem
     *   7. Recalcula todos os bônus dos equipamentos ativos
     *
     * @param campaign    - Instância do CampaignManager da campanha
     * @param characterId - ID do personagem alvo
     * @param equipment   - Item de equipamento a ser montado
     * @returns true se o equipamento foi montado com sucesso,
     *          false caso contrário (item sem estoque, personagem
     *          não encontrado, etc.)
     */
    public equipItem(
        campaign: CampaignManager,
        characterId: string,
        equipment: IEquipmentItem,
    ): boolean {
        const inventory = campaign.getGlobalInventory();
        const itemInStock = inventory.find(i => i.id === equipment.id && i.quantity > 0);

        if (!itemInStock) {
            return false; // Item não está disponível no inventário global
        }

        const targetChar = campaign.getPartyState().find(char => char.id === characterId);
        if (!targetChar) {
            return false; // Personagem não encontrado na party
        }

        // Se já houver um item naquele slot, desequipa ele primeiro
        const oldItem = targetChar.equippedItems[equipment.slot];
        if (oldItem) {
            this.unequipItem(campaign, characterId, equipment.slot);
        }

        // Remove 1 unidade do item do inventário global da campanha
        // Constroi um objeto compatível com IInventoryItem para
        // a operação de consolidação (quantidade negativa = remoção)
        campaign.consolidateLoot(0, [
            this.makeInventoryDelta(equipment, -1),
        ]);

        // Acopla o novo equipamento ao slot do personagem
        // (mutação direta no objeto interno — permitida pelo getter)
        targetChar.equippedItems[equipment.slot] = equipment;

        // Recalcula os modificadores nos atributos dinâmicos
        this.applyStatsModifiers(targetChar);

        return true;
    }

    // ==============================================================
    // [2] DESEQUIPAR
    // ==============================================================

    /**
     * unequipItem(campaign, characterId, slot)
     * ------------------------------------------------------------------
     * Remove um equipamento de um slot e o devolve ao inventário global.
     *
     * Fluxo:
     *   1. Verifica se o personagem existe e possui item no slot
     *   2. Devolve o item com quantidade 1 para o inventário global
     *   3. Limpa o slot
     *   4. Recalcula os bônus dos equipamentos restantes
     *
     * @param campaign    - Instância do CampaignManager da campanha
     * @param characterId - ID do personagem alvo
     * @param slot        - Slot de onde remover o equipamento
     * @returns true se o item foi removido com sucesso,
     *          false caso contrário
     */
    public unequipItem(
        campaign: CampaignManager,
        characterId: string,
        slot: SlotType,
    ): boolean {
        const targetChar = campaign.getPartyState().find(char => char.id === characterId);
        if (!targetChar || !targetChar.equippedItems || !targetChar.equippedItems[slot]) {
            return false;
        }

        const itemToReturn = targetChar.equippedItems[slot]!;

        // Devolve o item com quantidade 1 para o inventário global
        campaign.consolidateLoot(0, [
            this.makeInventoryDelta(itemToReturn, 1),
        ]);

        // Limpa o slot
        delete targetChar.equippedItems[slot];

        // Recalcula os bônus dos equipamentos restantes
        this.applyStatsModifiers(targetChar);

        return true;
    }

    // ==============================================================
    // [3] RECÁLCULO DE BÔNUS
    // ==============================================================

    /**
     * applyStatsModifiers(character)
     * ------------------------------------------------------------------
     * Varre os itens equipados no personagem e recalcula do zero
     * os bônus de atributos concedidos pelos equipamentos ativos.
     *
     * Modifica:
     *   - character.equipmentBonusStats (maxHp, attack, defense)
     *   - character.maxHp (reflete automaticamente via getter que
     *     soma baseMaxHp + equipmentBonusStats.bonusMaxHp)
     *
     * @param character - Estado do personagem a ter os bônus recalculados
     */
    public applyStatsModifiers(character: CharacterState): void {
        // Reseta os bônus para recalcular do zero
        character.equipmentBonusStats = { bonusMaxHp: 0, bonusAttack: 0, bonusDefense: 0 };

        const equipped = character.equippedItems;
        if (!equipped) return;

        Object.values(equipped).forEach((item: IEquipmentItem | undefined) => {
            if (!item || !item.statsModifiers) return;

            const mods = item.statsModifiers;

            if (mods.bonusMaxHp) {
                character.equipmentBonusStats = {
                    ...character.equipmentBonusStats,
                    bonusMaxHp: (character.equipmentBonusStats.bonusMaxHp ?? 0) + mods.bonusMaxHp,
                };
            }

            if (mods.bonusAttack) {
                character.equipmentBonusStats = {
                    ...character.equipmentBonusStats,
                    bonusAttack: (character.equipmentBonusStats.bonusAttack ?? 0) + mods.bonusAttack,
                };
            }

            if (mods.bonusDefense) {
                character.equipmentBonusStats = {
                    ...character.equipmentBonusStats,
                    bonusDefense: (character.equipmentBonusStats.bonusDefense ?? 0) + mods.bonusDefense,
                };
            }
        });

        // O getter maxHp do CharacterState já soma
        // stats.maxHp + equipmentBonusStats.bonusMaxHp automaticamente,
        // então não é necessário uma atribuição adicional aqui.
    }

    // ==============================================================
    // [4] MÉTODO AUXILIAR
    // ==============================================================

    /**
     * makeInventoryDelta(equipment, deltaQuantity)
     * ------------------------------------------------------------------
     * Cria um objeto compatível com IInventoryItem para operações
     * de consolidação de loot (adição/remoção) a partir de um
     * IEquipmentItem.
     *
     * @param equipment      - Item de equipamento base
     * @param deltaQuantity  - Variação de quantidade (+1 para adicionar,
     *                         -1 para remover)
     * @returns Objeto compatível com IInventoryItem
     */
    private makeInventoryDelta(
        equipment: IEquipmentItem,
        deltaQuantity: number,
    ): IInventoryItem {
        return {
            id: equipment.id,
            name: equipment.name,
            type: EQUIPMENT_INVENTORY_TYPE as 'MATERIAL' | 'CONSUMABLE' | 'EQUIPMENT',
            quantity: deltaQuantity,
        };
    }
}