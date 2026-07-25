/**
 * ====================================================================
 * CombatAbilities.ts
 * --------------------------------------------------------------------
 * Modelo e catálogo de HABILIDADES ATIVAS de combate do Aetheris.
 *
 * Diferente do SkillTreeEngine (nós passivos de atributo permanente),
 * estas são técnicas usadas em combate: gastam EP, têm cooldown,
 * deslocam a Balança de Estafa e podem infligir condições táticas
 * (StatusEngine) no alvo.
 *
 * Módulo-folha: importa apenas o TIPO StatusType (erased em runtime),
 * sem dependências de runtime — pode ser usado por CharacterState,
 * InteractiveCombatSession e SkillTreeEngine sem ciclos.
 * ====================================================================
 */

import type { StatusType } from './StatusEngine';

/** Categoria de habilidade — define a gating pela Balança de Estafa. */
export type AbilityCategory = 'AGGRESSIVE' | 'SUPPORT' | 'NEUTRAL';

/** Condição infligida por uma habilidade. */
export interface IAbilityStatusEffect {
    type: StatusType;
    duration: number;
    stacks: number;
    valuePerTurn: number;
}

/** Habilidade ativa de combate. */
export interface ICombatAbility {
    id: string;
    name: string;
    category: AbilityCategory;
    /** Custo-base de EP (o custo efetivo sobe no lado Paterno). */
    epCost: number;
    /** Recarga em turnos após o uso. */
    cooldown: number;
    /** Multiplicador de dano sobre o dano efetivo do usuário (0 = não-ofensiva). */
    damageMultiplier: number;
    /** Multiplicador de cura sobre o dano efetivo do usuário (0 = não-curativa). */
    healMultiplier: number;
    /** Deslocamento de Estafa ao executar (agressivas → +Paterno; suporte → −Materno). */
    estafaShift: number;
    /** Condição aplicada ao alvo (ofensivas) ao acertar. */
    inflictStatus?: IAbilityStatusEffect;
}

// ==================================================================
// CATÁLOGO CANÔNICO — KIT INICIAL DO ENGENHEIRO
// ==================================================================

export const CANONICAL_ABILITIES: Record<string, ICombatAbility> = {
    forja_strike: {
        id: 'forja_strike',
        name: 'Golpe de Forja',
        category: 'AGGRESSIVE',
        epCost: 30,
        cooldown: 1,
        damageMultiplier: 1.5,
        healMultiplier: 0,
        estafaShift: 8, // endurece rumo ao Paterno
        inflictStatus: { type: 'STEAM_BURN', duration: 2, stacks: 1, valuePerTurn: 4 },
    },
    rust_discharge: {
        id: 'rust_discharge',
        name: 'Descarga de Ferrugem',
        category: 'AGGRESSIVE',
        epCost: 40,
        cooldown: 2,
        damageMultiplier: 1.0,
        healMultiplier: 0,
        estafaShift: 6,
        inflictStatus: { type: 'RUST_LOCK', duration: 2, stacks: 1, valuePerTurn: 0 },
    },
    survival_weld: {
        id: 'survival_weld',
        name: 'Solda de Sobrevivência',
        category: 'SUPPORT',
        epCost: 35,
        cooldown: 2,
        damageMultiplier: 0,
        healMultiplier: 2.0,
        estafaShift: -10, // abranda rumo ao Materno
    },
    // Técnica avançada — aprendida dinamicamente (fora do kit inicial).
    pneumatic_burst: {
        id: 'pneumatic_burst',
        name: 'Rajada Pneumática',
        category: 'AGGRESSIVE',
        epCost: 50,
        cooldown: 3,
        damageMultiplier: 2.0,
        healMultiplier: 0,
        estafaShift: 10,
    },
};

/** IDs do kit inicial concedido ao herói. */
export const STARTER_ABILITY_IDS: string[] = ['forja_strike', 'rust_discharge', 'survival_weld'];
