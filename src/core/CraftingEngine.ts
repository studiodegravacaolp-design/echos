/**
 * ====================================================================
 * CraftingEngine.ts
 * --------------------------------------------------------------------
 * Motor de manufatura — gerencia receitas de forja e criação de
 * equipamentos fora de combate.
 *
 * Responsabilidades:
 *   - Gerenciar receitas de manufatura (recipes)
 *   - Validar materiais e sucata do engenheiro
 *   - Deduzir recursos e forjar o item no inventário global
 *
 * Fonte: docs/01_sistemas/SYS-MANUFATURA-MIDGAME.md
 *        docs/01_sistemas/SYS-MANUFATURA-ATO4.md
 *        docs/01_sistemas/SYS-MANUFATURA-ENDGAME.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CampaignManager, IInventoryItem } from './CampaignManager';
import { ICraftingRecipe } from '../types/aetheris.types';
import { CANONICAL_RECIPES } from '../database/CanonicalContent';

// Re-exportado por compatibilidade — a definição canônica de
// ICraftingRecipe agora vive em src/types/aetheris.types.ts (movida
// para quebrar dependência circular com CanonicalContent.ts).
export type { ICraftingRecipe };

// ==================================================================
// CLASSE — CraftingEngine
// ==================================================================

/**
 * CraftingEngine
 * --------------------------------------------------------------------
 * Gerencia o sistema de manufatura: criação de equipamentos a
 * partir de receitas que consomem sucata e materiais do inventário
 * global da campanha.
 *
 * Fluxo canônico:
 *   1. craftItem()    → valida receita → verifica sucata do engenheiro
 *                        → valida materiais no inventário → deduz recursos
 *                        → forja o item no inventário global
 *
 * NENHUM outro sistema deve modificar as receitas ou forjar itens
 * sem passar por esta classe.
 */
export class CraftingEngine {
    private recipes: Map<string, ICraftingRecipe>;

    /**
     * Cria uma nova instância de CraftingEngine, já carregada com o
     * catálogo canônico de receitas (CanonicalContent.CANONICAL_RECIPES).
     */
    constructor() {
        this.recipes = new Map<string, ICraftingRecipe>();
        this.loadRecipes(CANONICAL_RECIPES);
    }

    /**
     * loadRecipes(recipes)
     * ------------------------------------------------------------------
     * Carrega (ou sobrescreve, por recipeId) um conjunto de receitas
     * no motor. Usado pelo construtor para injetar o catálogo canônico
     * de CanonicalContent.ts — CraftingEngine não hardcoda mais
     * nenhuma receita internamente.
     *
     * @param recipes - Receitas a carregar
     */
    public loadRecipes(recipes: ICraftingRecipe[]): void {
        for (const recipe of recipes) {
            this.recipes.set(recipe.recipeId, recipe);
        }
    }

    // ==============================================================
    // [1] MANUFATURAR UM ITEM
    // ==============================================================

    /**
     * craftItem(campaign, characterId, recipeId)
     * ------------------------------------------------------------------
     * Executa uma receita de manufatura: valida recursos, deduz
     * materiais e sucata, e forja o equipamento no inventário global.
     *
     * [2] LÓGICA DE MANUFATURA E FORJA FORA DE COMBATE
     *
     * Fluxo:
     *   1. Verifica se a receita existe
     *   2. Verifica se o personagem existe e tem sucata suficiente
     *   3. Verifica se o inventário global tem todos os materiais
     *   4. Deduz a sucata do personagem
     *   5. Deduz os materiais do inventário global (delta negativo)
     *   6. Forja o equipamento no inventário global (delta positivo)
     *
     * @param campaign    - Instância do CampaignManager da campanha
     * @param characterId - ID do personagem engenheiro
     * @param recipeId    - ID da receita a ser executada
     * @returns true se o item foi forjado com sucesso,
     *          false caso contrário (receita inválida, recursos
     *          insuficientes, etc.)
     */
    public craftItem(
        campaign: CampaignManager,
        characterId: string,
        recipeId: string,
    ): boolean {
        const recipe = this.recipes.get(recipeId);
        if (!recipe) return false;

        const party = campaign.getPartyState();
        const crafter = party.find(char => char.id === characterId);
        if (!crafter || crafter.scrapCount === undefined || crafter.scrapCount < recipe.requiredScrap) {
            return false; // Engenheiro sem sucata suficiente
        }

        // Valida se o inventário global tem todos os materiais necessários
        const inventory = campaign.getGlobalInventory();
        for (const req of recipe.requiredMaterials) {
            const invItem = inventory.find(i => i.id === req.materialId);
            if (!invItem || invItem.quantity < req.quantity) {
                return false; // Falta material de manufatura
            }
        }

        // Deduz a sucata do engenheiro
        crafter.scrapCount -= recipe.requiredScrap;

        // Deduz os materiais do inventário global da campanha usando
        // delta negativo (consolidateLoot soma quantidades)
        const materialDeltas: IInventoryItem[] = recipe.requiredMaterials.map(req => ({
            id: req.materialId,
            name: '', // Nome não impacta na consolidação por ID
            type: 'MATERIAL',
            quantity: -req.quantity,
        }));
        campaign.consolidateLoot(0, materialDeltas);

        // Forja o novo equipamento e adiciona ao inventário global
        // Converte IEquipmentItem → IInventoryItem compatível
        campaign.consolidateLoot(0, [{
            id: recipe.resultItem.id,
            name: recipe.resultItem.name,
            type: 'EQUIPMENT' as const,
            quantity: 1,
        }]);

        return true;
    }

    // ==============================================================
    // [2] CONSULTAR RECEITAS
    // ==============================================================

    /**
     * getAvailableRecipes()
     * ------------------------------------------------------------------
     * Retorna todas as receitas de manufatura disponíveis.
     *
     * @returns Array de ICraftingRecipe com todas as receitas
     *          registradas no motor
     */
    public getAvailableRecipes(): ICraftingRecipe[] {
        return Array.from(this.recipes.values());
    }
}