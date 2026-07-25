/**
 * ====================================================================
 * BestiaryEngine.ts
 * --------------------------------------------------------------------
 * Bestiário e Gerador de Inimigos do Aetheris.
 *
 * Define os templates canônicos das criaturas de Brenhold, instancia
 * inimigos com atributos escalados por nível de perigo (hazardLevel) e
 * nível médio do grupo, e semeia condições táticas ambientais (ex.:
 * RUST_LOCK em autômatos oxidados).
 *
 * A geração é DETERMINÍSTICA por padrão (seleção de templates sem
 * aleatoriedade); a semeadura de status aceita um RNG injetável para
 * modelar a chance em jogo mantendo os testes estáveis.
 *
 * ARQUITETURA: usa StatusType/ITacticalStatus apenas como TIPO
 * (import type) — sem dependência de runtime, sem ciclos.
 * ====================================================================
 */

import { ICharacterStats } from '../types/aetheris.types';
import type { StatusType, ITacticalStatus } from './StatusEngine';

// ==================================================================
// TIPAGENS
// ==================================================================

/** Categoria biológica/mecânica do inimigo. */
export type EnemyCategory = 'MUTANT' | 'AUTOMATON' | 'SCAVENGER';

/**
 * Arquétipo de IA do bestiário. Distinto do AIArchetype de combate
 * (ASSASSINO/PROTETOR/DRENADOR_ESTAFA) — ver ENEMY_TO_COMBAT_ARCHETYPE.
 */
export type EnemyAIArchetype = 'AGGRESSIVE' | 'TACTICAL_DEBUFF' | 'DESPERATE';

/** Entrada de tabela de drop de um inimigo. */
export interface IEnemyDrop {
    itemId: string;
    name: string;
    type: 'MATERIAL' | 'CONSUMABLE' | 'EQUIPMENT';
    /** Probabilidade de queda (0..1). */
    chance: number;
    /** Quantidade concedida quando o drop ocorre. */
    quantity: number;
}

/** Definição estática (template) de um inimigo. */
export interface IEnemyTemplate {
    id: string;
    name: string;
    category: EnemyCategory;
    /** Tier de dificuldade base (1 a 5). */
    tier: number;
    baseStats: ICharacterStats;
    archetypeAI: EnemyAIArchetype;
    /** Condições táticas que este inimigo pode infligir. */
    statusCapabilities: StatusType[];
    /** Itens que o inimigo pode largar ao ser derrotado. */
    dropTable: IEnemyDrop[];
}

/** Instância concreta de um inimigo gerada para um encontro. */
export interface IEnemyInstance {
    instanceId: string;
    templateId: string;
    name: string;
    category: EnemyCategory;
    archetypeAI: EnemyAIArchetype;
    /** Nível efetivo do inimigo (derivado de partyLevel + hazard). */
    level: number;
    /** Atributos já escalados. */
    stats: ICharacterStats;
    statusCapabilities: StatusType[];
    /** Condições ativas na criação (ex.: RUST_LOCK ambiental). */
    activeStatuses: ITacticalStatus[];
    /** Tabela de drop herdada do template (itens possíveis ao derrotar). */
    dropTable: IEnemyDrop[];
}

/** Opções de geração de encontro. */
export interface IEncounterOptions {
    estafaBalance?: number;
}

/** Opções de semeadura de status ambiental. */
export interface IApplyStatusOptions {
    /** Nível de oxidação da área (0..1). */
    oxidationLevel?: number;
    /** RNG injetável (padrão Math.random) para a chance. */
    rng?: () => number;
}

// ==================================================================
// CONSTANTES DE ESCALAMENTO
// ==================================================================

/** Ganho de atributos por nível acima de 1. */
const LEVEL_SCALE_PER_LEVEL = 0.10;
/** Ganho de atributos por nível de perigo acima de 1. */
const HAZARD_SCALE_PER_TIER = 0.15;
/** Bônus de dano quando o líder está em Estafa extrema (|estafa| >= 60). */
const EXTREME_ESTAFA_DAMAGE_BONUS = 0.10;
/** Limiar de Estafa extrema. */
const EXTREME_ESTAFA_THRESHOLD = 60;
/** Tamanho máximo de um grupo de encontro. */
const MAX_ENCOUNTER_SIZE = 4;

/** Duração inicial do RUST_LOCK ambiental. */
const AMBIENT_RUST_DURATION = 3;

/**
 * Mapa do arquétipo do bestiário para o AIArchetype de combate legado,
 * para futura integração com CombatAIEngine/EnemyBehavior.
 */
export const ENEMY_TO_COMBAT_ARCHETYPE: Record<EnemyAIArchetype, 'ASSASSINO' | 'PROTETOR' | 'DRENADOR_ESTAFA'> = {
    AGGRESSIVE: 'ASSASSINO',
    TACTICAL_DEBUFF: 'DRENADOR_ESTAFA',
    DESPERATE: 'PROTETOR',
};

// ==================================================================
// TEMPLATES CANÔNICOS DE BRENHOLD
// ==================================================================

const CANONICAL_ENEMIES: Record<string, IEnemyTemplate> = {
    rato_quimico: {
        id: 'rato_quimico',
        name: 'Rato Químico',
        category: 'MUTANT',
        tier: 1,
        baseStats: { maxHp: 30, currentHp: 30, damage: 6, defense: 2, resilience: 3, movementSpeed: 14 },
        archetypeAI: 'AGGRESSIVE',
        statusCapabilities: ['CHEMICAL_POISON'],
        dropTable: [
            { itemId: 'mat_steel_bar', name: 'Barra de Aço de Alta Densidade', type: 'MATERIAL', chance: 0.5, quantity: 1 },
        ],
    },
    batedor_catador: {
        id: 'batedor_catador',
        name: 'Batedor Catador',
        category: 'SCAVENGER',
        tier: 2,
        baseStats: { maxHp: 45, currentHp: 45, damage: 9, defense: 5, resilience: 4, movementSpeed: 12 },
        archetypeAI: 'DESPERATE',
        statusCapabilities: ['CHEMICAL_POISON'],
        // Catadores acumulam suprimentos.
        dropTable: [
            { itemId: 'medkit_standard', name: 'Medkit Padrão', type: 'CONSUMABLE', chance: 0.4, quantity: 1 },
            { itemId: 'mat_bronze_plate', name: 'Placa de Bronze Industrial', type: 'MATERIAL', chance: 0.5, quantity: 1 },
        ],
    },
    automato_oxidado: {
        id: 'automato_oxidado',
        name: 'Autômato Oxidado',
        category: 'AUTOMATON',
        tier: 2,
        baseStats: { maxHp: 70, currentHp: 70, damage: 10, defense: 12, resilience: 6, movementSpeed: 6 },
        archetypeAI: 'TACTICAL_DEBUFF',
        statusCapabilities: ['RUST_LOCK', 'SPARK_OVERCHARGE'],
        dropTable: [
            { itemId: 'mat_silicon_wafer', name: 'Placa de Silício Processado', type: 'MATERIAL', chance: 0.6, quantity: 1 },
            { itemId: 'eq_scrap_shield', name: 'Placa de Sucata Industrial', type: 'EQUIPMENT', chance: 0.15, quantity: 1 },
        ],
    },
    guardiao_vapor: {
        id: 'guardiao_vapor',
        name: 'Guardião de Vapor',
        category: 'AUTOMATON',
        tier: 3,
        baseStats: { maxHp: 110, currentHp: 110, damage: 16, defense: 14, resilience: 8, movementSpeed: 7 },
        archetypeAI: 'AGGRESSIVE',
        statusCapabilities: ['STEAM_BURN'],
        dropTable: [
            { itemId: 'mat_steel_bar', name: 'Barra de Aço de Alta Densidade', type: 'MATERIAL', chance: 0.7, quantity: 2 },
            { itemId: 'eq_bronze_armor', name: 'Chapa de Armadura de Bronze', type: 'EQUIPMENT', chance: 0.2, quantity: 1 },
        ],
    },
};

// ==================================================================
// CLASSE — BestiaryEngine
// ==================================================================

export class BestiaryEngine {
    private instanceCounter = 0;

    // --------------------------------------------------------------
    // TEMPLATES
    // --------------------------------------------------------------

    /** Recupera a definição (clone defensivo) de um inimigo, ou undefined. */
    public getEnemyTemplate(templateId: string): IEnemyTemplate | undefined {
        const t = CANONICAL_ENEMIES[templateId];
        return t ? this.cloneTemplate(t) : undefined;
    }

    /** Lista todos os templates canônicos (clones). */
    public listTemplates(): IEnemyTemplate[] {
        return Object.values(CANONICAL_ENEMIES).map((t) => this.cloneTemplate(t));
    }

    private cloneTemplate(t: IEnemyTemplate): IEnemyTemplate {
        return {
            ...t,
            baseStats: { ...t.baseStats },
            statusCapabilities: [...t.statusCapabilities],
            dropTable: t.dropTable.map((d) => ({ ...d })),
        };
    }

    // --------------------------------------------------------------
    // GERAÇÃO DE ENCONTRO
    // --------------------------------------------------------------

    /**
     * generateEncounter(hazardLevel, partyLevel, options?)
     * ------------------------------------------------------------------
     * Gera um grupo balanceado de inimigos escalados. Determinístico:
     *   - Tamanho do grupo cresce com o perigo (1..4).
     *   - Elegibilidade por tier: só spawnam templates de tier <= hazard.
     *   - Atributos escalam com nível efetivo (partyLevel + hazard) e perigo.
     *
     * @param hazardLevel - Nível de perigo do nó (1 a 5).
     * @param partyLevel  - Nível médio do grupo.
     * @param options     - { estafaBalance } — Estafa extrema endurece inimigos.
     */
    public generateEncounter(
        hazardLevel: number,
        partyLevel: number,
        options: IEncounterOptions = {},
    ): IEnemyInstance[] {
        const hazard = this.clampHazard(hazardLevel);
        const size = Math.max(1, Math.min(hazard, MAX_ENCOUNTER_SIZE));

        // Templates elegíveis: tier <= hazard (fallback ao menor tier).
        const eligible = this.getEligibleTemplates(hazard);

        const encounter: IEnemyInstance[] = [];
        for (let i = 0; i < size; i++) {
            const template = eligible[i % eligible.length];
            encounter.push(this.instantiateEnemy(template.id, hazard, partyLevel, options));
        }
        return encounter;
    }

    /** Templates de tier <= hazard, ordenados por tier; fallback ao menor tier. */
    private getEligibleTemplates(hazard: number): IEnemyTemplate[] {
        const all = Object.values(CANONICAL_ENEMIES).sort((a, b) => a.tier - b.tier);
        const eligible = all.filter((t) => t.tier <= hazard);
        return eligible.length > 0 ? eligible : [all[0]];
    }

    /**
     * instantiateEnemy(templateId, hazardLevel, partyLevel, options?)
     * ------------------------------------------------------------------
     * Cria uma instância escalada de um template específico.
     */
    public instantiateEnemy(
        templateId: string,
        hazardLevel: number,
        partyLevel: number,
        options: IEncounterOptions = {},
    ): IEnemyInstance {
        const template = CANONICAL_ENEMIES[templateId];
        if (!template) {
            throw new Error(`BestiaryEngine: template desconhecido '${templateId}'.`);
        }

        const hazard = this.clampHazard(hazardLevel);
        const safePartyLevel = Number.isFinite(partyLevel) && partyLevel >= 1 ? Math.floor(partyLevel) : 1;
        const level = Math.max(1, safePartyLevel + (hazard - 1));

        const levelFactor = 1 + (level - 1) * LEVEL_SCALE_PER_LEVEL;
        const hazardFactor = 1 + (hazard - 1) * HAZARD_SCALE_PER_TIER;
        const estafa = options.estafaBalance ?? 0;
        const estafaDamageFactor =
            Math.abs(estafa) >= EXTREME_ESTAFA_THRESHOLD ? 1 + EXTREME_ESTAFA_DAMAGE_BONUS : 1;

        const base = template.baseStats;
        const combined = levelFactor * hazardFactor;
        const maxHp = Math.round(base.maxHp * combined);
        const stats: ICharacterStats = {
            maxHp,
            currentHp: maxHp,
            damage: Math.round(base.damage * combined * estafaDamageFactor),
            defense: Math.round(base.defense * combined),
            resilience: base.resilience,
            movementSpeed: base.movementSpeed,
        };

        this.instanceCounter += 1;
        return {
            instanceId: `${template.id}#${this.instanceCounter}`,
            templateId: template.id,
            name: template.name,
            category: template.category,
            archetypeAI: template.archetypeAI,
            level,
            stats,
            statusCapabilities: [...template.statusCapabilities],
            activeStatuses: [],
            dropTable: template.dropTable.map((d) => ({ ...d })),
        };
    }

    // --------------------------------------------------------------
    // STATUS AMBIENTAL
    // --------------------------------------------------------------

    /**
     * applyEncounterStatus(enemy, options?)
     * ------------------------------------------------------------------
     * Autômatos com capacidade de RUST_LOCK, gerados em áreas de alta
     * oxidação, têm CHANCE de iniciar já travados por ferrugem. A chance
     * é igual ao oxidationLevel (0..1); usa RNG injetável para testes.
     *
     * @returns true se o RUST_LOCK ambiental foi aplicado.
     */
    public applyEncounterStatus(enemy: IEnemyInstance, options: IApplyStatusOptions = {}): boolean {
        if (enemy.category !== 'AUTOMATON') return false;
        if (!enemy.statusCapabilities.includes('RUST_LOCK')) return false;

        const oxidation = Math.max(0, Math.min(1, options.oxidationLevel ?? 0));
        if (oxidation <= 0) return false;

        const rng = options.rng ?? Math.random;
        if (rng() >= oxidation) return false;

        enemy.activeStatuses.push({
            id: `ambient_rust_${enemy.instanceId}`,
            type: 'RUST_LOCK',
            duration: AMBIENT_RUST_DURATION,
            stacks: 1,
            valuePerTurn: 0,
            sourceId: 'ENVIRONMENT_OXIDATION',
        });
        return true;
    }

    // --------------------------------------------------------------
    // UTIL
    // --------------------------------------------------------------

    private clampHazard(hazardLevel: number): number {
        if (!Number.isFinite(hazardLevel)) return 1;
        return Math.max(1, Math.min(5, Math.floor(hazardLevel)));
    }
}
