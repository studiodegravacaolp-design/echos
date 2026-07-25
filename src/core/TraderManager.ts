import { CampaignManager, IInventoryItem } from './CampaignManager';

export interface ITradeOption {
    itemId: string;
    name: string;
    type: 'MATERIAL' | 'CONSUMABLE' | 'EQUIPMENT';
    scrapPrice: number;
    stock: number;
}

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
}