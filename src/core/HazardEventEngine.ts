/**
 * ====================================================================
 * HazardEventEngine.ts
 * --------------------------------------------------------------------
 * Anomalias de Duto — eventos ambientais aleatórios disparados durante
 * a travessia entre nós (nós com hazardLevel > 0).
 *
 * Cada anomalia oferece escolhas de mitigação com consequências táticas:
 * gasto de recurso (Mantimento/Sucata), status deferido para o próximo
 * combate (aplicado no CharacterState.activeStatuses, consumido pela
 * InteractiveCombatSession), dano direto, deslocamento de Estafa,
 * ganho de EP ou desgaste de equipamento.
 *
 * Motor headless e determinístico (RNG injetável) — testável sem CLI.
 * ====================================================================
 */

import { CampaignManager } from './CampaignManager';
import { StatusEngine } from './StatusEngine';
import { StatusType } from './StatusEngine';

// ==================================================================
// TIPAGENS
// ==================================================================

export type HazardEventType =
    | 'CHEMICAL_GAS_LEAK'
    | 'STEAM_CONDUIT_OVERLOAD'
    | 'STATIC_ELECTRIC_SURGE';

/** Uma opção de mitigação apresentada ao jogador. */
export interface IHazardOption {
    id: string;
    label: string;
}

/** Definição de uma anomalia (narrativa + opções). */
export interface IHazardEvent {
    type: HazardEventType;
    title: string;
    narrative: string;
    options: IHazardOption[];
}

/** Resultado da resolução de uma opção de anomalia. */
export interface IHazardResolution {
    type: HazardEventType;
    optionId: string;
    /** true se a opção foi aplicada (recurso suficiente, quando exigido). */
    success: boolean;
    message: string;
    suppliesSpent?: number;
    scrapSpent?: number;
    epGained?: number;
    hpDamage?: number;
    estafaShift?: number;
    statusApplied?: StatusType;
    durabilityReducedPct?: number;
}

// ==================================================================
// CONSTANTES
// ==================================================================

/** Probabilidade de anomalia por nível de perigo (com teto). */
const HAZARD_PROB_PER_LEVEL = 0.15;
const HAZARD_PROB_CAP = 0.6;

const FILTER_SUPPLY_COST = 1;
const DIVERT_SCRAP_COST = 1;
const DETOUR_SUPPLY_COST = 1;
const DIVERT_EP_GAIN = 5;
const SEVERE_ESTAFA_SHIFT = 10;
const SEVERE_HP_DAMAGE = 15;
const STATIC_DURABILITY_PCT = 0.05;
/** Status deferido: duração/stacks/dano por turno no próximo combate. */
const HAZARD_STATUS_DURATION = 2;
const HAZARD_STATUS_STACKS = 1;
const HAZARD_STATUS_DOT = 5;

const HAZARD_TYPES: HazardEventType[] = [
    'CHEMICAL_GAS_LEAK',
    'STEAM_CONDUIT_OVERLOAD',
    'STATIC_ELECTRIC_SURGE',
];

// ==================================================================
// CLASSE — HazardEventEngine
// ==================================================================

export class HazardEventEngine {
    /**
     * rollEvent(hazardLevel, rng?)
     * ------------------------------------------------------------------
     * Sorteia uma anomalia com probabilidade proporcional ao perigo do
     * nó. Retorna null se o nó é seguro (hazard 0) ou se o sorteio falhar.
     *
     * @param hazardLevel - Nível de perigo do nó de destino.
     * @param rng         - Gerador injetável (padrão Math.random).
     */
    public rollEvent(hazardLevel: number, rng: () => number = Math.random): IHazardEvent | null {
        const hazard = Number.isFinite(hazardLevel) ? Math.max(0, Math.floor(hazardLevel)) : 0;
        if (hazard <= 0) return null;

        const probability = Math.min(HAZARD_PROB_CAP, hazard * HAZARD_PROB_PER_LEVEL);
        if (rng() >= probability) return null;

        const index = Math.min(HAZARD_TYPES.length - 1, Math.floor(rng() * HAZARD_TYPES.length));
        return this.getEvent(HAZARD_TYPES[index]);
    }

    /** Definição estática de uma anomalia (narrativa + opções). */
    public getEvent(type: HazardEventType): IHazardEvent {
        switch (type) {
            case 'CHEMICAL_GAS_LEAK':
                return {
                    type,
                    title: '☠️ Vazamento de Gás Químico',
                    narrative: 'Uma névoa esverdeada sibila de uma válvula rompida. O ar corrói a garganta.',
                    options: [
                        { id: 'filter', label: '😷 Usar filtro (−1 mantimento) — sem penalidade' },
                        { id: 'run', label: '🏃 Atravessar correndo — envenena o grupo no próximo combate' },
                        { id: 'severe', label: '🔩 Selar a válvula à força — +10 Paterno e dano ao líder' },
                    ],
                };
            case 'STEAM_CONDUIT_OVERLOAD':
                return {
                    type,
                    title: '♨️ Sobrecarga de Conduto de Vapor',
                    narrative: 'Os manômetros estouram no vermelho; jatos de vapor escaldante rasgam o corredor.',
                    options: [
                        { id: 'divert', label: '⚡ Desviar energia com sucata (−1 sucata) — evita e +5 EP' },
                        { id: 'force', label: '💪 Atravessar na força — queima o grupo (STEAM_BURN)' },
                    ],
                };
            case 'STATIC_ELECTRIC_SURGE':
                return {
                    type,
                    title: '⚡ Surtos Elétricos Estáticos',
                    narrative: 'Arcos elétricos dançam pelas grades de metal, buscando um caminho ao chão.',
                    options: [
                        { id: 'discharge', label: '🛡️ Descarregar na armadura — −5% durabilidade' },
                        { id: 'detour', label: '↩️ Recuar e contornar — +1 mantimento consumido' },
                    ],
                };
        }
    }

    /**
     * resolveEvent(campaign, type, optionId)
     * ------------------------------------------------------------------
     * Aplica a consequência da opção escolhida ao grupo/campanha.
     */
    public resolveEvent(
        campaign: CampaignManager,
        type: HazardEventType,
        optionId: string,
    ): IHazardResolution {
        const party = campaign.getPartyState();
        const base: IHazardResolution = { type, optionId, success: false, message: 'Opção inválida.' };

        // ---- Vazamento de Gás Químico ----
        if (type === 'CHEMICAL_GAS_LEAK') {
            if (optionId === 'filter') {
                if (campaign.getSupplies() < FILTER_SUPPLY_COST) {
                    return { ...base, message: 'Sem mantimentos para acionar o filtro.' };
                }
                const spent = campaign.consumeSupplies(FILTER_SUPPLY_COST);
                return { ...base, success: true, message: 'O filtro segura os gases. Travessia limpa.', suppliesSpent: spent };
            }
            if (optionId === 'run') {
                this.applyGroupStatus(party, 'CHEMICAL_POISON');
                return { ...base, success: true, message: 'Vocês correm — mas o veneno gruda nos pulmões.', statusApplied: 'CHEMICAL_POISON' };
            }
            if (optionId === 'severe') {
                campaign.modifyEstafaBalance(SEVERE_ESTAFA_SHIFT);
                const leader = party[0];
                let hpDamage = 0;
                if (leader) {
                    const before = leader.hp;
                    leader.hp = Math.max(1, leader.hp - SEVERE_HP_DAMAGE);
                    hpDamage = before - leader.hp;
                }
                return { ...base, success: true, message: 'O líder sela a válvula com as próprias mãos — endurecido e ferido.', estafaShift: SEVERE_ESTAFA_SHIFT, hpDamage };
            }
            return base;
        }

        // ---- Sobrecarga de Conduto de Vapor ----
        if (type === 'STEAM_CONDUIT_OVERLOAD') {
            if (optionId === 'divert') {
                const leader = party[0];
                if (!leader || leader.scrapCount < DIVERT_SCRAP_COST) {
                    return { ...base, message: 'Sem sucata para desviar a energia.' };
                }
                leader.scrapCount -= DIVERT_SCRAP_COST;
                for (const hero of party) {
                    hero.currentEp = hero.currentEp + DIVERT_EP_GAIN;
                }
                return { ...base, success: true, message: 'A energia é redirecionada — o grupo recupera o fôlego.', scrapSpent: DIVERT_SCRAP_COST, epGained: DIVERT_EP_GAIN };
            }
            if (optionId === 'force') {
                this.applyGroupStatus(party, 'STEAM_BURN');
                return { ...base, success: true, message: 'Vocês forçam a passagem sob o vapor escaldante.', statusApplied: 'STEAM_BURN' };
            }
            return base;
        }

        // ---- Surtos Elétricos Estáticos ----
        if (type === 'STATIC_ELECTRIC_SURGE') {
            if (optionId === 'discharge') {
                for (const hero of party) {
                    for (const item of hero.durableEquipment) {
                        const loss = Math.max(1, Math.round(item.durability.max * STATIC_DURABILITY_PCT));
                        item.durability.current = Math.max(0, item.durability.current - loss);
                    }
                }
                return { ...base, success: true, message: 'A carga é aterrada pela armadura — o metal range e enferruja.', durabilityReducedPct: STATIC_DURABILITY_PCT * 100 };
            }
            if (optionId === 'detour') {
                const spent = campaign.consumeSupplies(DETOUR_SUPPLY_COST);
                return { ...base, success: true, message: 'Vocês recuam e contornam — uma marcha extra pelos dutos.', suppliesSpent: spent };
            }
            return base;
        }

        return base;
    }

    /** Aplica um status tático deferido a todo o grupo (consumido no próximo combate). */
    private applyGroupStatus(party: ReturnType<CampaignManager['getPartyState']>, statusType: StatusType): void {
        for (const hero of party) {
            StatusEngine.applyStatus(hero, {
                id: `hazard_${statusType}_${hero.id}`,
                type: statusType,
                duration: HAZARD_STATUS_DURATION,
                stacks: HAZARD_STATUS_STACKS,
                valuePerTurn: HAZARD_STATUS_DOT,
                sourceId: 'DUCT_HAZARD',
            });
        }
    }
}
