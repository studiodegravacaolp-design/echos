/**
 * ====================================================================
 * StatusEngine.ts  (src/core)
 * --------------------------------------------------------------------
 * Motor de Status e Condições Táticas do Aetheris.
 *
 * Gerencia as condições táticas de combate empilháveis e com duração:
 *   - CHEMICAL_POISON  — dano químico contínuo (DoT).
 *   - STEAM_BURN       — queimadura de vapor: DoT + deformação de armadura
 *                        (penalidade de defesa).
 *   - SPARK_OVERCHARGE — sobrecarga elétrica: bônus ofensivo (dano).
 *   - RUST_LOCK        — travamento por oxidação: penalidade de defesa e
 *                        de velocidade de movimento.
 *
 * NOTA DE ARQUITETURA:
 *   - Este é um motor NOVO, distinto de src/modules/combat/StatusEngine.ts
 *     (condições tecnológicas TECH_* de Engenharia Elemental).
 *   - O modelo ITacticalStatus é DISTINTO do IStatusEffect legado
 *     (aetheris.types.ts), preservando o sistema de status já existente.
 *   - CharacterState é usado APENAS como tipo (import type) — sem
 *     dependência de runtime — para manter a dependência unidirecional
 *     (CharacterState → StatusEngine) e evitar ciclo de importação.
 * ====================================================================
 */

import type { CharacterState } from './CharacterState';

// ==================================================================
// TIPAGENS
// ==================================================================

/** Tipos de condição tática gerenciados por este motor. */
export type StatusType =
    | 'CHEMICAL_POISON'
    | 'STEAM_BURN'
    | 'SPARK_OVERCHARGE'
    | 'RUST_LOCK';

/** Condição tática empilhável com duração em turnos. */
export interface ITacticalStatus {
    id: string;
    type: StatusType;
    /** Duração restante em turnos. */
    duration: number;
    /** Número de acúmulos ativos. */
    stacks: number;
    /** Valor base por turno (dano de DoT, para tipos de dano contínuo). */
    valuePerTurn: number;
    /** ID da fonte que aplicou o status (personagem/habilidade). */
    sourceId: string;
}

/** Modificadores de atributos derivados dos status ativos (deltas). */
export interface IStatusModifiers {
    /** Delta de dano ofensivo. */
    damage: number;
    /** Delta de defesa física. */
    defense: number;
    /** Delta de velocidade de movimento. */
    movementSpeed: number;
}

/** Resultado do processamento de início de turno. */
export interface ITurnStartResult {
    /** Dano total de DoT aplicado ao alvo neste turno. */
    totalDamage: number;
    /** IDs dos status que expiraram e foram removidos. */
    expired: string[];
}

// ==================================================================
// CONSTANTES CANÔNICAS
// ==================================================================

/** Limite máximo de acúmulos por condição. */
export const MAX_STATUS_STACKS = 5;

/**
 * Tabela de modificadores de atributo POR STACK, por tipo de status.
 * Valores negativos são penalidades; positivos são bônus.
 */
const STATUS_MODIFIER_TABLE: Record<StatusType, IStatusModifiers> = {
    CHEMICAL_POISON: { damage: 0, defense: 0, movementSpeed: 0 }, // DoT puro
    STEAM_BURN: { damage: 0, defense: -2, movementSpeed: 0 }, // armadura empenada
    SPARK_OVERCHARGE: { damage: 3, defense: 0, movementSpeed: 0 }, // sobrecarga ofensiva
    RUST_LOCK: { damage: 0, defense: -3, movementSpeed: -2 }, // travamento mecânico
};

/** Conjunto de tipos que causam dano contínuo (DoT) via valuePerTurn. */
const DOT_STATUS_TYPES: ReadonlySet<StatusType> = new Set<StatusType>([
    'CHEMICAL_POISON',
    'STEAM_BURN',
]);

// ==================================================================
// CLASSE — StatusEngine
// ==================================================================

export class StatusEngine {
    /**
     * applyStatus(target, status)
     * ------------------------------------------------------------------
     * Aplica uma condição ao alvo. Se já houver uma condição do mesmo
     * `type`, incrementa os acúmulos (respeitando MAX_STATUS_STACKS) e
     * renova a duração (mantém a maior) e o valuePerTurn (mantém o maior).
     * Caso contrário, adiciona uma nova condição (com stacks clampados).
     *
     * @param target - Personagem alvo (mutado)
     * @param status - Condição a aplicar
     */
    public static applyStatus(target: CharacterState, status: ITacticalStatus): void {
        const list = target.activeStatuses;
        const existing = list.find((s) => s.type === status.type);

        if (existing) {
            existing.stacks = Math.min(MAX_STATUS_STACKS, existing.stacks + status.stacks);
            existing.duration = Math.max(existing.duration, status.duration);
            existing.valuePerTurn = Math.max(existing.valuePerTurn, status.valuePerTurn);
            return;
        }

        list.push({
            ...status,
            stacks: Math.min(MAX_STATUS_STACKS, Math.max(1, status.stacks)),
        });
    }

    /**
     * processTurnStart(target)
     * ------------------------------------------------------------------
     * Executa os efeitos de início de turno:
     *   1. Aplica dano de DoT (CHEMICAL_POISON, STEAM_BURN) = valuePerTurn * stacks.
     *   2. Decrementa a duração de todas as condições ativas.
     *   3. Remove as condições com duration <= 0.
     *
     * @param target - Personagem alvo (mutado)
     * @returns Dano total aplicado e IDs de status expirados
     */
    public static processTurnStart(target: CharacterState): ITurnStartResult {
        const list = target.activeStatuses;
        let totalDamage = 0;

        // 1 + 2: dano de DoT e decremento de duração.
        for (const status of list) {
            if (DOT_STATUS_TYPES.has(status.type)) {
                const dot = Math.max(0, status.valuePerTurn) * status.stacks;
                totalDamage += dot;
            }
            status.duration -= 1;
        }

        if (totalDamage > 0) {
            target.applyDirectDamage(totalDamage);
        }

        // 3: remoção limpa dos expirados (in-place), coletando os IDs.
        const expired: string[] = [];
        for (let i = list.length - 1; i >= 0; i--) {
            if (list[i].duration <= 0) {
                expired.push(list[i].id);
                list.splice(i, 1);
            }
        }

        return { totalDamage, expired };
    }

    /**
     * calculateStatusModifiers(activeStatus)
     * ------------------------------------------------------------------
     * Soma os modificadores de atributo de todas as condições ativas,
     * multiplicando o valor da tabela pelo número de acúmulos de cada uma.
     * Função pura — não muta nada nem depende de CharacterState.
     *
     * @param activeStatus - Lista de condições ativas
     * @returns Agregado IStatusModifiers (deltas de damage/defense/speed)
     */
    public static calculateStatusModifiers(activeStatus: ITacticalStatus[]): IStatusModifiers {
        const total: IStatusModifiers = { damage: 0, defense: 0, movementSpeed: 0 };

        for (const status of activeStatus) {
            const perStack = STATUS_MODIFIER_TABLE[status.type];
            if (!perStack) continue;
            total.damage += perStack.damage * status.stacks;
            total.defense += perStack.defense * status.stacks;
            total.movementSpeed += perStack.movementSpeed * status.stacks;
        }

        return total;
    }
}
