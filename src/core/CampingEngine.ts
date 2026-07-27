/**
 * ====================================================================
 * CampingEngine.ts
 * --------------------------------------------------------------------
 * Lógica de Acampamento e Gestão de Grupo (nós REST_SITE).
 *
 * Fornece as operações puras usadas pela tela de acampamento do CLI:
 *   - restAndFeed:     consome mantimentos para restaurar HP + EP.
 *   - fieldRepair:     repara equipamento durável gastando sucata.
 *   - adjustFormation: reordena a linha de batalha (Vanguarda/Retaguarda).
 *   - campConversation: desloca a Balança de Estafa (+Paterno / −Materno).
 *
 * Headless e testável — sem readline. Reutiliza EquipmentEngine
 * (reparo) e a API do CampaignManager (recursos, party, estafa).
 * ====================================================================
 */

import { CampaignManager } from './CampaignManager';
import { EquipmentEngine } from './EquipmentEngine';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Mantimentos consumidos por um descanso completo. */
export const REST_SUPPLY_COST = 2;
/** Fração do HP máximo restaurada ao descansar com alimento. */
export const REST_HP_FRACTION = 0.4;
/** Fração do EP máximo restaurada ao descansar. */
export const REST_EP_FRACTION = 0.5;
/** Deslocamento de Estafa das conversas de acampamento. */
export const CAMP_CONVERSATION_SHIFT = 10;

// ==================================================================
// TIPAGENS
// ==================================================================

export type CampConversationTone = 'PATERNO' | 'MATERNO';

/** Resultado de um descanso. */
export interface IRestResult {
    /** true se havia mantimentos e o descanso foi completo (HP + EP). */
    fed: boolean;
    suppliesConsumed: number;
    hpRestoredTotal: number;
    epRestoredTotal: number;
    /** true se o descanso foi parcial (sem mantimentos) — risco de escassez. */
    survivalRisk: boolean;
}

/** Resultado de um reparo de campo. */
export interface IFieldRepairResult {
    success: boolean;
    scrapSpent: number;
    durabilityRestored: number;
    /** true se o item saiu do estado Rusted após o reparo. */
    rustCleared: boolean;
}

// ==================================================================
// CLASSE — CampingEngine
// ==================================================================

export class CampingEngine {
    /**
     * restAndFeed(campaign)
     * ------------------------------------------------------------------
     * Descanso: se houver mantimentos suficientes, consome-os e restaura
     * 40% do HP e 50% do EP de todos os heróis. Sem mantimentos, restaura
     * apenas o EP (descanso parcial) e sinaliza risco de escassez.
     */
    public restAndFeed(campaign: CampaignManager): IRestResult {
        const party = campaign.getPartyState();
        const fed = campaign.getSupplies() >= REST_SUPPLY_COST;

        let hpRestoredTotal = 0;
        let epRestoredTotal = 0;
        let suppliesConsumed = 0;

        if (fed) {
            suppliesConsumed = campaign.consumeSupplies(REST_SUPPLY_COST);
        }

        for (const hero of party) {
            // EP sempre é restaurado (descanso mental).
            const epBefore = hero.currentEp;
            hero.currentEp = hero.currentEp + Math.round(hero.maxEp * REST_EP_FRACTION);
            epRestoredTotal += hero.currentEp - epBefore;

            // HP só é restaurado com alimento.
            if (fed) {
                const hpBefore = hero.hp;
                hero.hp = hero.hp + Math.round(hero.maxHp * REST_HP_FRACTION);
                hpRestoredTotal += hero.hp - hpBefore;
            }
        }

        return {
            fed,
            suppliesConsumed,
            hpRestoredTotal,
            epRestoredTotal,
            survivalRisk: !fed,
        };
    }

    /**
     * fieldRepair(campaign, ownerId, itemId)
     * ------------------------------------------------------------------
     * Repara um equipamento durável do dono gastando sucata (via
     * EquipmentEngine.repairEquipment). Remove o estado Rusted se o item
     * ultrapassar 25% de durabilidade.
     */
    public fieldRepair(
        campaign: CampaignManager,
        ownerId: string,
        itemId: string,
    ): IFieldRepairResult {
        const fail: IFieldRepairResult = { success: false, scrapSpent: 0, durabilityRestored: 0, rustCleared: false };

        const owner = campaign.getPartyState().find((c) => c.id === ownerId);
        if (!owner) return fail;

        // durableEquipment retorna cópia do array, mas os itens são refs reais.
        const item = owner.durableEquipment.find((e) => e.id === itemId);
        if (!item) return fail;
        if (item.durability.current >= item.durability.max || owner.scrapCount < 1) return fail;

        const wasRusted = EquipmentEngine.isRusted(item);
        const result = EquipmentEngine.repairEquipment(item, owner.scrapCount);
        if (result.scrapSpent <= 0) return fail;

        owner.scrapCount -= result.scrapSpent;
        const rustCleared = wasRusted && !EquipmentEngine.isRusted(item);

        return {
            success: true,
            scrapSpent: result.scrapSpent,
            durabilityRestored: result.durabilityRestored,
            rustCleared,
        };
    }

    /**
     * adjustFormation(campaign, orderedIds)
     * ------------------------------------------------------------------
     * Reordena a linha de batalha (índice 0 = Vanguarda). Delegado ao
     * CampaignManager.reorderParty.
     */
    public adjustFormation(campaign: CampaignManager, orderedIds: string[]): boolean {
        return campaign.reorderParty(orderedIds);
    }

    /**
     * campConversation(campaign, tone)
     * ------------------------------------------------------------------
     * Uma conversa de acampamento desloca a Balança de Estafa do grupo:
     * PATERNO (+10) endurece; MATERNO (−10) abranda.
     *
     * @returns O novo saldo da Balança de Estafa.
     */
    public campConversation(campaign: CampaignManager, tone: CampConversationTone): number {
        const shift = tone === 'PATERNO' ? CAMP_CONVERSATION_SHIFT : -CAMP_CONVERSATION_SHIFT;
        campaign.modifyEstafaBalance(shift);
        return campaign.getProgress().estafaBalance;
    }
}
