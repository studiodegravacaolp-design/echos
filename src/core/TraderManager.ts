import { CampaignManager, IInventoryItem } from './CampaignManager';
import { EquipmentEngine, IDurableEquipment, REPAIR_DURABILITY_PER_SCRAP } from './EquipmentEngine';

export interface ITradeOption {
    itemId: string;
    name: string;
    type: 'MATERIAL' | 'CONSUMABLE' | 'EQUIPMENT';
    scrapPrice: number;
    stock: number;
}

/** Resultado de compra de mantimentos. */
export interface IBuySuppliesResult {
    success: boolean;
    scrapSpent: number;
    suppliesBought: number;
}

/** Resultado de reparo de equipamento. */
export interface IRepairResult {
    success: boolean;
    scrapSpent: number;
    durabilityRestored: number;
}

/** Custo em sucata por unidade de mantimento. */
export const SCRAP_PER_SUPPLY = 1;

export class TraderManager {
    private currentStoreStock: Map<string, ITradeOption>;

    constructor() {
        this.currentStoreStock = new Map<string, ITradeOption>();
        this.initializeDefaultStock();
    }

    private initializeDefaultStock(): void {
        this.currentStoreStock.set('medkit_standard', {
            itemId: 'medkit_standard',
            name: 'Kit Médico Padrão',
            type: 'CONSUMABLE',
            scrapPrice: 25, // Custa 25 sucatas
            stock: 4
        });
        this.currentStoreStock.set('elemental_charge_capsule', {
            itemId: 'elemental_charge_capsule',
            name: 'Cápsula de Carga Elementar',
            type: 'CONSUMABLE',
            scrapPrice: 40, // Custa 40 sucatas
            stock: 2
        });
        this.currentStoreStock.set('eq_scrap_shield', {
            itemId: 'eq_scrap_shield',
            name: 'Placa de Sucata Industrial',
            type: 'EQUIPMENT',
            scrapPrice: 60,
            stock: 1
        });
    }

    /**
     * [1] LÓGICA DE COMPRA E ESCAMBO DE SUCATA
     */
    public buyItem(campaign: CampaignManager, buyerCharacterId: string, itemId: string): boolean {
        const option = this.currentStoreStock.get(itemId);
        if (!option || option.stock <= 0) return false;

        const party = campaign.getPartyState();
        const buyer = party.find(char => char.id === buyerCharacterId);
        if (!buyer || buyer.scrapCount === undefined || buyer.scrapCount < option.scrapPrice) {
            return false; // Engenheiro não tem sucata suficiente ou não existe
        }

        // Deduz a moeda do personagem e o estoque do mercador
        buyer.scrapCount -= option.scrapPrice;
        option.stock--;

        // Converte em item e joga no inventário global da campanha
        const newItem: IInventoryItem = {
            id: option.itemId,
            name: option.name,
            type: option.type,
            quantity: 1
        };
        campaign.consolidateLoot(0, [newItem]); // Consolida com 0 sucata bônus, apenas o item
        
        return true;
    }

    public getAvailableStock(): ITradeOption[] {
        return Array.from(this.currentStoreStock.values());
    }

    /**
     * [2] COMPRA DE MANTIMENTOS COM SUCATA
     * ------------------------------------------------------------------
     * Converte a sucata de um comprador em mantimentos do grupo (à taxa
     * SCRAP_PER_SUPPLY). Compra apenas o que a sucata permite (parcial).
     *
     * @returns Resultado com sucata gasta e mantimentos comprados.
     */
    public buySupplies(
        campaign: CampaignManager,
        buyerCharacterId: string,
        desiredAmount: number,
    ): IBuySuppliesResult {
        const buyer = campaign.getPartyState().find((c) => c.id === buyerCharacterId);
        if (!buyer || !Number.isFinite(desiredAmount) || desiredAmount <= 0) {
            return { success: false, scrapSpent: 0, suppliesBought: 0 };
        }

        // Limita pela sucata disponível.
        const affordable = Math.floor(buyer.scrapCount / SCRAP_PER_SUPPLY);
        const suppliesBought = Math.min(Math.floor(desiredAmount), affordable);
        if (suppliesBought <= 0) {
            return { success: false, scrapSpent: 0, suppliesBought: 0 };
        }

        const scrapSpent = suppliesBought * SCRAP_PER_SUPPLY;
        buyer.scrapCount -= scrapSpent;
        campaign.addSupplies(suppliesBought);

        return { success: true, scrapSpent, suppliesBought };
    }

    /**
     * [3] REPARO DE EQUIPAMENTO DURÁVEL COM SUCATA
     * ------------------------------------------------------------------
     * Repara um equipamento durável (ex.: oxidado/desgastado) do dono,
     * consumindo sucata do comprador via EquipmentEngine.repairEquipment.
     *
     * @param ownerCharacterId - Dono do equipamento durável.
     * @param itemId           - Id do equipamento a reparar.
     */
    public repairEquipment(
        campaign: CampaignManager,
        ownerCharacterId: string,
        itemId: string,
    ): IRepairResult {
        const owner = campaign.getPartyState().find((c) => c.id === ownerCharacterId);
        if (!owner) {
            return { success: false, scrapSpent: 0, durabilityRestored: 0 };
        }
        // durableEquipment retorna cópia do array, mas os itens são refs reais.
        const item: IDurableEquipment | undefined = owner.durableEquipment.find((e) => e.id === itemId);
        if (!item) {
            return { success: false, scrapSpent: 0, durabilityRestored: 0 };
        }
        if (item.durability.current >= item.durability.max || owner.scrapCount < 1) {
            return { success: false, scrapSpent: 0, durabilityRestored: 0 };
        }

        const result = EquipmentEngine.repairEquipment(item, owner.scrapCount);
        owner.scrapCount -= result.scrapSpent;

        return {
            success: result.scrapSpent > 0,
            scrapSpent: result.scrapSpent,
            durabilityRestored: result.durabilityRestored,
        };
    }

    /** Custo de reparo completo estimado (sucata) de um item. */
    public estimateRepairCost(item: IDurableEquipment): number {
        const missing = Math.max(0, item.durability.max - item.durability.current);
        return Math.ceil(missing / REPAIR_DURABILITY_PER_SCRAP);
    }
}