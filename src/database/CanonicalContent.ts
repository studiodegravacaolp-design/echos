/**
 * ====================================================================
 * CanonicalContent.ts
 * --------------------------------------------------------------------
 * Catálogo canônico de conteúdo de manufatura: materiais, equipamentos,
 * receitas de forja e arquétipos de inimigos expandidos.
 *
 * Fonte: src/types/aetheris.types.ts (IEquipmentItem, AIArchetype)
 *        src/core/CampaignManager.ts (IInventoryItem)
 *        src/core/CraftingEngine.ts (ICraftingRecipe)
 *
 * NOTA: 'recipe_bronze_armor' / 'eq_bronze_armor' / 'mat_bronze_plate'
 * já existem como receita padrão hardcoded dentro de
 * CraftingEngine.initializeDefaultRecipes(). Este catálogo os repete
 * deliberadamente (mesmo weight=1, para consistência) como a versão
 * canônica externa — CraftingEngine ainda não tem um loadRecipes()
 * que consuma este arquivo; a integração é um passo futuro.
 * ====================================================================
 */

import { IEquipmentItem, AIArchetype } from '../types/aetheris.types';
import { IInventoryItem } from '../core/CampaignManager';
import { ICraftingRecipe } from '../core/CraftingEngine';

// ====================================================================
// 1. EXTENSÃO DOS MATERIAIS DE MANUFATURA (BÍBLIA VISUAL)
// ====================================================================

export const CANONICAL_MATERIALS: Record<string, IInventoryItem> = {
    mat_bronze_plate: {
        id: 'mat_bronze_plate',
        name: 'Placa de Bronze Industrial',
        type: 'MATERIAL',
        quantity: 1,
        spriteKey: 'spr_mat_bronze_plate', // Link com a textura de bronze
    },
    mat_steel_bar: {
        id: 'mat_steel_bar',
        name: 'Barra de Aço de Alta Densidade',
        type: 'MATERIAL',
        quantity: 1,
        spriteKey: 'spr_mat_steel_bar', // Link com a textura de aço
    },
    mat_silicon_wafer: {
        id: 'mat_silicon_wafer',
        name: 'Placa de Silício Processado',
        type: 'MATERIAL',
        quantity: 1,
        spriteKey: 'spr_mat_silicon_wafer', // Link com a textura de silício/cristal
    },
    mat_lurid_crystal: {
        id: 'mat_lurid_crystal',
        name: 'Cristal de Ignição Lurídeo',
        type: 'MATERIAL',
        quantity: 1,
        spriteKey: 'spr_mat_lurid_crystal', // Link com o brilho lurídeo
    },
};

// ====================================================================
// 2. EXTENSÃO DOS EQUIPAMENTOS E ARSENAL (COM ATRIBUTOS E SPRITE KEYS)
// ====================================================================

export const CANONICAL_EQUIPMENT: Record<string, IEquipmentItem> = {
    eq_bronze_armor: {
        id: 'eq_bronze_armor',
        name: 'Chapa de Armadura de Bronze',
        weight: 1,
        maxStack: 1,
        slot: 'ARMOR',
        statsModifiers: { bonusMaxHp: 25, bonusAttack: 0, bonusDefense: 5 },
        spriteKey: 'spr_eq_bronze_armor',
    },
    eq_steel_blade: {
        id: 'eq_steel_blade',
        name: 'Lâmina de Aço de Brenhold',
        weight: 1,
        maxStack: 1,
        slot: 'WEAPON',
        statsModifiers: { bonusMaxHp: 0, bonusAttack: 15, bonusDefense: 0 },
        spriteKey: 'spr_eq_steel_blade',
    },
    eq_lurid_core: {
        id: 'eq_lurid_core',
        name: 'Núcleo Térmico Lurídeo',
        weight: 1,
        maxStack: 1,
        slot: 'CORE_MOD',
        statsModifiers: { bonusMaxHp: 10, bonusAttack: 5, bonusDefense: 0 },
        spriteKey: 'spr_eq_lurid_core',
    },
    eq_scrap_shield: {
        id: 'eq_scrap_shield',
        name: 'Placa de Sucata Industrial',
        weight: 1,
        maxStack: 1,
        slot: 'ARMOR',
        statsModifiers: { bonusMaxHp: 0, bonusAttack: 0, bonusDefense: 8 },
        spriteKey: 'spr_eq_scrap_shield',
    },
};

// ====================================================================
// 3. RECEITAS DE FORJA DO CRAFTING ENGINE
// ====================================================================

export const CANONICAL_RECIPES: ICraftingRecipe[] = [
    {
        recipeId: 'recipe_bronze_armor',
        requiredScrap: 30,
        requiredMaterials: [
            { materialId: 'mat_bronze_plate', quantity: 2 },
        ],
        resultItem: CANONICAL_EQUIPMENT.eq_bronze_armor,
    },
    {
        recipeId: 'recipe_steel_blade',
        requiredScrap: 25,
        requiredMaterials: [
            { materialId: 'mat_steel_bar', quantity: 1 },
        ],
        resultItem: CANONICAL_EQUIPMENT.eq_steel_blade,
    },
    {
        recipeId: 'recipe_lurid_core',
        requiredScrap: 35,
        requiredMaterials: [
            { materialId: 'mat_lurid_crystal', quantity: 1 },
            { materialId: 'mat_bronze_plate', quantity: 1 },
        ],
        resultItem: CANONICAL_EQUIPMENT.eq_lurid_core,
    },
    {
        recipeId: 'recipe_scrap_shield',
        requiredScrap: 15,
        requiredMaterials: [
            { materialId: 'mat_bronze_plate', quantity: 1 },
            { materialId: 'mat_steel_bar', quantity: 1 },
        ],
        resultItem: CANONICAL_EQUIPMENT.eq_scrap_shield,
    },
];

// ====================================================================
// 4. ARQUÉTIPOS EXPANDIDOS DE INIMIGOS
// ====================================================================

export interface ICanonicalEnemyArchetype {
    id: string;
    name: string;
    archetype: AIArchetype;
    baseHp: number;
    description: string;
}

export const CANONICAL_ENEMIES: ICanonicalEnemyArchetype[] = [
    {
        id: 'enemy_duct_scavenger',
        name: 'Catador de Dutos',
        archetype: 'ASSASSINO',
        baseHp: 50,
        description: 'Especialista em emboscadas que ataca chassis vulneráveis.',
    },
    {
        id: 'enemy_rogue_automaton',
        name: 'Autômato Desgovernado',
        archetype: 'PROTETOR',
        baseHp: 80,
        description: 'Unidade industrial blindada pesada programada para proteger sua área.',
    },
    {
        id: 'enemy_traitor_engineer',
        name: 'Engenheiro Desertor',
        archetype: 'DRENADOR_ESTAFA',
        baseHp: 65,
        description: 'Usa sobrecargas mentais e pressão tática para desestabilizar os heróis.',
    },
];
