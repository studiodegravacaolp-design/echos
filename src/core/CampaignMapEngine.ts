import { CampaignManager } from './CampaignManager';
import { EquipmentEngine } from './EquipmentEngine';

export type NodeType = 'COMBAT_ARENA' | 'SCRAP_TRADER' | 'SAFE_ZONE' | 'AMBUSH' | 'HAZARD';

export interface ICampaignNode {
    id: string;
    name: string;
    type: NodeType;
    connectedTo: string[];
    /** Nível de perigo do duto (0 = seguro … 3 = extremo). Padrão: 0. */
    hazardLevel?: number;
    /** Deslocamento direto de Estafa ao atravessar. Padrão: derivado do hazard. */
    estafaImpact?: number;
    /** Custo de mantimentos para atravessar. Padrão: derivado do hazard. */
    traversalSupplyCost?: number;
}

// ==================================================================
// CONSTANTES DE TRAVESSIA — ECONOMIA, DESGASTE E ESTAFA
// ==================================================================

/** Custo-base de mantimentos por travessia (antes do fator de perigo). */
const BASE_SUPPLY_COST = 5;
/** Mantimentos adicionais consumidos por nível de perigo. */
const SUPPLY_COST_PER_HAZARD = 5;

/** Desgaste-base de durabilidade por item equipado a cada travessia. */
const BASE_EQUIPMENT_WEAR = 2;
/** Desgaste adicional por nível de perigo. */
const EQUIPMENT_WEAR_PER_HAZARD = 3;

/** Deslocamento de Estafa (rumo ao Paterno) por nível de perigo, quando não explícito. */
const HAZARD_ESTAFA_UNIT = 4;

/** Penalidade extra de Estafa (rumo ao Materno) sob Escassez de Mantimentos. */
const SURVIVAL_CRISIS_ESTAFA_PENALTY = -15;

/**
 * Resultado de uma travessia de nó com integração de recursos/desgaste/estafa.
 */
export interface ITraversalResult {
    success: boolean;
    targetNodeId: string;
    /** Mantimentos efetivamente consumidos. */
    suppliesConsumed: number;
    /** Mantimentos restantes após a travessia. */
    suppliesRemaining: number;
    /** Número de itens duráveis degradados no grupo. */
    equipmentDegraded: number;
    /** Deslocamento total de Estafa aplicado (nó + penalidade de crise). */
    estafaShift: number;
    /** Novo saldo da Balança de Estafa do grupo. */
    newEstafaBalance: number;
    /** true se a travessia disparou SURVIVAL_CRISIS (mantimentos insuficientes). */
    survivalCrisis: boolean;
    message?: string;
}

export class CampaignMapEngine {
    private mapNodes: Map<string, ICampaignNode>;

    constructor() {
        this.mapNodes = new Map<string, ICampaignNode>();
        this.generateFactoryMap();
    }

    private generateFactoryMap(): void {
        // Monta o layout linear/ramificado da fábrica de Brenhold
        this.mapNodes.set('brenhold_entrance', {
            id: 'brenhold_entrance',
            name: 'Entrada de Brenhold',
            type: 'SAFE_ZONE',
            connectedTo: ['sector_01_combat'],
            hazardLevel: 0,
            estafaImpact: 0,
        });
        this.mapNodes.set('sector_01_combat', {
            id: 'sector_01_combat',
            name: 'Pátio de Fundição',
            type: 'COMBAT_ARENA',
            connectedTo: ['black_market_trader', 'sector_02_combat'],
            hazardLevel: 2,
            estafaImpact: 8, // travessia perigosa endurece o grupo (Paterno)
        });
        this.mapNodes.set('black_market_trader', {
            id: 'black_market_trader',
            name: 'Mercador de Sucata',
            type: 'SCRAP_TRADER',
            connectedTo: ['sector_02_combat'],
            hazardLevel: 0,
            estafaImpact: 0,
        });
        this.mapNodes.set('sector_02_combat', {
            id: 'sector_02_combat',
            name: 'Sala de Máquinas Principal',
            type: 'COMBAT_ARENA',
            connectedTo: ['deep_refuge', 'vapor_conduits'],
            hazardLevel: 3,
            estafaImpact: 12,
        });

        // ── Ato 2: profundezas de Brenhold ──
        this.mapNodes.set('deep_refuge', {
            id: 'deep_refuge',
            name: 'Refúgio Selado',
            type: 'SAFE_ZONE',
            connectedTo: ['foundry_depths'],
            hazardLevel: 0,
            estafaImpact: 0,
            traversalSupplyCost: 0,
        });
        this.mapNodes.set('vapor_conduits', {
            id: 'vapor_conduits',
            name: 'Condutos de Vapor',
            type: 'HAZARD',
            connectedTo: ['foundry_depths', 'rust_shrine'],
            hazardLevel: 3,
            estafaImpact: -8, // o medo do vapor puxa o grupo ao Materno (preservação)
        });
        this.mapNodes.set('foundry_depths', {
            id: 'foundry_depths',
            name: 'Profundezas da Fundição',
            type: 'COMBAT_ARENA',
            connectedTo: ['salvage_market', 'core_reactor'],
            hazardLevel: 4,
            estafaImpact: 14,
        });
        this.mapNodes.set('rust_shrine', {
            id: 'rust_shrine',
            name: 'Santuário Enferrujado',
            type: 'AMBUSH',
            connectedTo: ['core_reactor'],
            hazardLevel: 4,
            estafaImpact: 10,
        });
        this.mapNodes.set('salvage_market', {
            id: 'salvage_market',
            name: 'Mercado das Profundezas',
            type: 'SCRAP_TRADER',
            connectedTo: ['core_reactor'],
            hazardLevel: 1,
            estafaImpact: 0,
        });
        this.mapNodes.set('core_reactor', {
            id: 'core_reactor',
            name: 'Câmara do Reator Central',
            type: 'COMBAT_ARENA',
            connectedTo: [],
            hazardLevel: 5,
            estafaImpact: 18,
        });
    }

    /**
     * [2] GERADOR E VALIDADOR DE ENCONTROS DO MAPA
     */
    public travelToNode(campaign: CampaignManager, targetNodeId: string): { success: boolean; eventType: NodeType; message?: string } {
        const progress = campaign.getProgress();
        const currentNode = this.mapNodes.get(progress.currentNodeId);
        const targetNode = this.mapNodes.get(targetNodeId);

        if (!currentNode || !targetNode) return { success: false, eventType: 'SAFE_ZONE' };
        if (!currentNode.connectedTo.includes(targetNodeId)) return { success: false, eventType: 'SAFE_ZONE' };

        campaign.setCurrentNode(targetNodeId);

        // Se o destino não for uma zona segura, há 30% de chance de um perigo na travessia
        if (targetNode.type !== 'SAFE_ZONE') {
            const roll = Math.random();
            
            if (roll < 0.15) {
                // 15% de chance de Emboscada Lurídea
                return {
                    success: true,
                    eventType: 'AMBUSH',
                    message: "⚠️ Alerta! Sua travessia foi interrompida por uma emboscada nos dutos de ventilação!"
                };
            } else if (roll < 0.30) {
                // 15% de chance de Perigo Ambiental (Vazamento de Vapor)
                const party = campaign.getPartyState();
                const target = party[Math.floor(Math.random() * party.length)];
                if (target) {
                    // Causa 15 de dano direto devido ao vapor corrosivo, respeitando o mínimo de 1 HP
                    target.hp = Math.max(1, target.hp - 15);
                }
                return {
                    success: true,
                    eventType: 'HAZARD',
                    message: `⚠️ Perigo! Um jato de vapor superaquecido atingiu ${target?.id}, causando 15 de dano ao chassi!`
                };
            }
        }

        return {
            success: true,
            eventType: targetNode.type
        };
    }

    /**
     * [3] TRAVESSIA INTEGRADA — RECURSOS, DESGASTE E ESTAFA
     * ------------------------------------------------------------------
     * traverseToNode(campaign, targetNodeId)
     *
     * Move o grupo para o nó destino aplicando, de forma determinística,
     * o custo da jornada pelos dutos:
     *   1. Consome mantimentos do grupo (custo derivado do perigo do nó).
     *      Se insuficientes, dispara SURVIVAL_CRISIS e aplica penalidade
     *      extra de Estafa (rumo ao Materno — exaustão/desespero).
     *   2. Degrada a durabilidade de todos os equipamentos duráveis
     *      equipados nos personagens do grupo (EquipmentEngine.degradeEquipment).
     *   3. Aplica o deslocamento de Estafa do nó (perigo endurece → Paterno)
     *      somado à eventual penalidade de crise.
     *   4. Atualiza o nó atual da campanha.
     *
     * Diferente de travelToNode (encontros aleatórios), esta rotina é
     * determinística — adequada para simulação e testes.
     *
     * @param campaign     - Estado da campanha
     * @param targetNodeId - Nó destino conectado ao nó atual
     */
    public traverseToNode(
        campaign: CampaignManager,
        targetNodeId: string,
    ): ITraversalResult {
        const progress = campaign.getProgress();
        const currentNode = this.mapNodes.get(progress.currentNodeId);
        const targetNode = this.mapNodes.get(targetNodeId);

        // Validação de conectividade.
        if (!currentNode || !targetNode || !currentNode.connectedTo.includes(targetNodeId)) {
            return {
                success: false,
                targetNodeId,
                suppliesConsumed: 0,
                suppliesRemaining: campaign.getSupplies(),
                equipmentDegraded: 0,
                estafaShift: 0,
                newEstafaBalance: progress.estafaBalance,
                survivalCrisis: campaign.isSurvivalCrisis(),
                message: 'Travessia inválida: nós não conectados.',
            };
        }

        const hazard = Math.max(0, targetNode.hazardLevel ?? 0);

        // --- 1. Consumo de mantimentos e detecção de escassez ---
        const supplyCost =
            targetNode.traversalSupplyCost ?? BASE_SUPPLY_COST + hazard * SUPPLY_COST_PER_HAZARD;
        const suppliesBefore = campaign.getSupplies();
        const survivalCrisis = suppliesBefore < supplyCost;
        const suppliesConsumed = campaign.consumeSupplies(supplyCost); // clampa em 0
        campaign.setSurvivalCrisis(survivalCrisis);

        // --- 2. Desgaste de durabilidade dos equipamentos duráveis ---
        const wear = BASE_EQUIPMENT_WEAR + hazard * EQUIPMENT_WEAR_PER_HAZARD;
        let equipmentDegraded = 0;
        for (const member of campaign.getPartyState()) {
            // durableEquipment retorna cópia do array, mas os itens são
            // referências compartilhadas — a degradação persiste no estado real.
            for (const item of member.durableEquipment) {
                EquipmentEngine.degradeEquipment(item, wear);
                equipmentDegraded++;
            }
        }

        // --- 3. Deslocamento de Estafa (nó + penalidade de crise) ---
        const nodeEstafa = targetNode.estafaImpact ?? hazard * HAZARD_ESTAFA_UNIT;
        const crisisPenalty = survivalCrisis ? SURVIVAL_CRISIS_ESTAFA_PENALTY : 0;
        const estafaShift = nodeEstafa + crisisPenalty;
        if (estafaShift !== 0) {
            campaign.modifyEstafaBalance(estafaShift);
        }

        // --- 4. Move o grupo ---
        campaign.setCurrentNode(targetNodeId);

        const message = survivalCrisis
            ? `⚠️ Escassez de Mantimentos! O grupo cruza ${targetNode.name} esfomeado e exausto.`
            : `Travessia concluída até ${targetNode.name}.`;

        return {
            success: true,
            targetNodeId,
            suppliesConsumed,
            suppliesRemaining: campaign.getSupplies(),
            equipmentDegraded,
            estafaShift,
            newEstafaBalance: campaign.getProgress().estafaBalance,
            survivalCrisis,
            message,
        };
    }

    /**
     * getTraversalPreview(targetNodeId)
     * ------------------------------------------------------------------
     * Retorna o custo estimado de mantimentos, o nível de perigo e o
     * impacto de Estafa de atravessar até um nó — para a UI confirmar
     * antes da travessia. Usa as mesmas fórmulas de traverseToNode.
     *
     * @returns Preview do destino, ou null se o nó não existir.
     */
    public getTraversalPreview(
        targetNodeId: string,
    ): { node: ICampaignNode; hazardLevel: number; supplyCost: number; estafaImpact: number } | null {
        const node = this.mapNodes.get(targetNodeId);
        if (!node) return null;

        const hazardLevel = Math.max(0, node.hazardLevel ?? 0);
        const supplyCost =
            node.traversalSupplyCost ?? BASE_SUPPLY_COST + hazardLevel * SUPPLY_COST_PER_HAZARD;
        const estafaImpact = node.estafaImpact ?? hazardLevel * HAZARD_ESTAFA_UNIT;

        return { node, hazardLevel, supplyCost, estafaImpact };
    }

    /**
     * registerNode(node)
     * ------------------------------------------------------------------
     * Registra (ou substitui) um nó do mapa. Útil para conteúdo dinâmico
     * e para testes que injetam topologias controladas.
     */
    public registerNode(node: ICampaignNode): void {
        this.mapNodes.set(node.id, node);
    }

    public getNodeDetails(nodeId: string): ICampaignNode | undefined {
        return this.mapNodes.get(nodeId);
    }
}