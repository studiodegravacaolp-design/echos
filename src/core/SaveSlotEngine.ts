/**
 * ====================================================================
 * SaveSlotEngine.ts
 * --------------------------------------------------------------------
 * Gerenciamento de Saves com Múltiplos Slots de Campanha.
 *
 * Persiste o estado completo do jogo em slots independentes
 * (SLOT_1..SLOT_3 + AUTOSAVE), cada um em seu próprio arquivo JSON,
 * com metadados de apresentação, checksum de integridade SHA-256 e
 * migração de saves antigos com campos faltantes.
 *
 * Distinto do SaveSystem.ts legado (save único). Constrói o payload a
 * partir da API pública do CampaignManager — incluindo os campos novos
 * (equipamentos duráveis e status táticos por personagem) que a
 * serialização legada não cobre.
 *
 * Fonte: docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md
 * ====================================================================
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import { CampaignManager, ICampaignProgress, IInventoryItem } from './CampaignManager';
import { LatentLineageAxis } from '../types/aetheris.types';
import type { CharacterState } from './CharacterState';
import type { IDurableEquipment } from './EquipmentEngine';
import type { ITacticalStatus } from './StatusEngine';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Versão atual do schema de save (para migração). */
export const SAVE_SCHEMA_VERSION = 1;

/** IDs de slot válidos. */
export const SAVE_SLOT_IDS = ['SLOT_1', 'SLOT_2', 'SLOT_3', 'AUTOSAVE'] as const;

/** Diretório-base padrão dos slots. */
const DEFAULT_SLOT_DIR = path.join(process.cwd(), 'saves', 'slots');

// ==================================================================
// TIPAGENS
// ==================================================================

export type SaveSlotId = 'SLOT_1' | 'SLOT_2' | 'SLOT_3' | 'AUTOSAVE';

/** Metadados de apresentação do save (não entram no checksum). */
export interface ISaveSlotMetadata {
    timestamp: number;
    playTimeSeconds: number;
    currentAreaName: string;
    partyLeaderName: string;
    estafaBalance: number;
    supplies: number;
}

/** Estado serializado de um personagem no save. */
export interface ISavedCharacter {
    id: string;
    level: number;
    hp: number;
    scrapCount: number;
    engineeringCharges: Record<string, number>;
    latentLineageAxis: LatentLineageAxis;
    durableEquipment: IDurableEquipment[];
    activeStatuses: ITacticalStatus[];
}

/** Payload completo do save (entra no checksum de integridade). */
export interface ISaveSlotPayload {
    progress: ICampaignProgress;
    globalInventory: IInventoryItem[];
    party: ISavedCharacter[];
    mapState: { currentNodeId: string; unlockedNodeIds: string[] };
}

/** Estrutura on-disk de um slot de save. */
export interface ISaveSlotData {
    slotId: SaveSlotId;
    schemaVersion: number;
    metadata: ISaveSlotMetadata;
    payload: ISaveSlotPayload;
    /** Checksum SHA-256 do payload (ausente em saves legados). */
    checksum?: string;
}

/** Resumo de um slot para a tela de seleção. */
export interface ISaveSlotSummary {
    slotId: SaveSlotId;
    empty: boolean;
    metadata?: ISaveSlotMetadata;
}

/** Resultado do carregamento de um slot. */
export interface ILoadSlotResult {
    success: boolean;
    slotId: SaveSlotId;
    metadata?: ISaveSlotMetadata;
    payload?: ISaveSlotPayload;
    /** true se o save passou por migração de campos faltantes. */
    migrated?: boolean;
    error?: string;
}

/** Opções de salvamento. */
export interface ISaveOptions {
    playTimeSeconds?: number;
    currentAreaName?: string;
}

// ==================================================================
// CLASSE — SaveSlotEngine
// ==================================================================

export class SaveSlotEngine {
    private readonly baseDir: string;

    /**
     * @param baseDir - Diretório-base dos slots (padrão: <cwd>/saves/slots).
     *                  Injetável para testes herméticos.
     */
    constructor(baseDir: string = DEFAULT_SLOT_DIR) {
        this.baseDir = baseDir;
    }

    // ==============================================================
    // UTILITÁRIOS INTERNOS
    // ==============================================================

    /** Caminho absoluto do arquivo de um slot. */
    private slotPath(slotId: SaveSlotId): string {
        return path.join(this.baseDir, `${slotId.toLowerCase()}.json`);
    }

    /** Deep clone via JSON (snapshot imutável). */
    private clone<T>(value: T): T {
        return JSON.parse(JSON.stringify(value));
    }

    /** Calcula o checksum SHA-256 de um payload. */
    private checksumOf(payload: ISaveSlotPayload): string {
        return crypto.createHash('sha256').update(JSON.stringify(payload)).digest('hex');
    }

    /** Valida se o id de slot é conhecido. */
    private isValidSlot(slotId: string): slotId is SaveSlotId {
        return (SAVE_SLOT_IDS as readonly string[]).includes(slotId);
    }

    // ==============================================================
    // [1] LISTAR SLOTS
    // ==============================================================

    /**
     * listSaveSlots()
     * ------------------------------------------------------------------
     * Retorna o resumo dos 4 slots. Slots livres (ou corrompidos) vêm
     * com `empty: true`; slots válidos trazem os metadados.
     */
    public listSaveSlots(): ISaveSlotSummary[] {
        return SAVE_SLOT_IDS.map((slotId) => {
            const filePath = this.slotPath(slotId);
            if (!fs.existsSync(filePath)) {
                return { slotId, empty: true };
            }
            try {
                const raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
                const result = this.validateAndMigrateSaveData(raw, slotId);
                if (!result.success || !result.data) {
                    return { slotId, empty: true };
                }
                return { slotId, empty: false, metadata: result.data.metadata };
            } catch {
                return { slotId, empty: true };
            }
        });
    }

    // ==============================================================
    // [2] SALVAR EM SLOT
    // ==============================================================

    /**
     * saveToSlot(slotId, campaign, options?)
     * ------------------------------------------------------------------
     * Serializa o estado atual do jogo, calcula metadados e checksum e
     * persiste no arquivo do slot (sobrescrevendo o conteúdo anterior).
     *
     * @returns true se persistido com sucesso.
     */
    public saveToSlot(
        slotId: string,
        campaign: CampaignManager,
        options: ISaveOptions = {},
    ): boolean {
        if (!this.isValidSlot(slotId)) return false;

        try {
            if (!fs.existsSync(this.baseDir)) {
                fs.mkdirSync(this.baseDir, { recursive: true });
            }

            const progress = campaign.getProgress();
            const party = campaign.getPartyState();
            const leader = party[0];

            const payload: ISaveSlotPayload = {
                progress: this.clone(progress),
                globalInventory: this.clone(campaign.getGlobalInventory()),
                party: party.map((c) => this.serializeCharacter(c)),
                mapState: {
                    currentNodeId: progress.currentNodeId,
                    unlockedNodeIds: [...progress.unlockedNodeIds],
                },
            };

            const metadata: ISaveSlotMetadata = {
                timestamp: Date.now(),
                playTimeSeconds: options.playTimeSeconds ?? 0,
                currentAreaName: options.currentAreaName ?? progress.currentNodeId,
                partyLeaderName: leader?.id ?? 'UNKNOWN',
                estafaBalance: progress.estafaBalance,
                supplies: progress.supplies ?? 0,
            };

            const data: ISaveSlotData = {
                slotId,
                schemaVersion: SAVE_SCHEMA_VERSION,
                metadata,
                payload,
                checksum: this.checksumOf(payload),
            };

            fs.writeFileSync(this.slotPath(slotId), JSON.stringify(data, null, 2), 'utf-8');
            return true;
        } catch (error) {
            console.error(`❌ Falha ao salvar no slot ${slotId}:`, error);
            return false;
        }
    }

    /** Serializa um CharacterState para o formato de save. */
    private serializeCharacter(c: CharacterState): ISavedCharacter {
        // toJSON() expõe o latentLineageAxis REAL (o getter mascara < nível 36).
        const rawLineage = (c.toJSON() as { latentLineageAxis?: LatentLineageAxis })
            .latentLineageAxis ?? LatentLineageAxis.NEUTRO_ABSOLUTO;

        return {
            id: c.id,
            level: c.currentLevel,
            hp: c.hp,
            scrapCount: c.scrapCount,
            engineeringCharges: { ...c.engineeringCharges },
            latentLineageAxis: rawLineage,
            durableEquipment: this.clone(c.durableEquipment),
            activeStatuses: this.clone(c.activeStatuses),
        };
    }

    // ==============================================================
    // [3] CARREGAR DE SLOT
    // ==============================================================

    /**
     * loadFromSlot(slotId, campaign?)
     * ------------------------------------------------------------------
     * Carrega o payload do slot, valida integridade e migra campos
     * faltantes. Se `campaign` for fornecido, restaura o estado nele
     * (a party-esqueleto deve conter os mesmos ids de personagem).
     *
     * @param slotId   - Id do slot
     * @param campaign - Campanha alvo para restauração (opcional)
     */
    public loadFromSlot(slotId: string, campaign?: CampaignManager): ILoadSlotResult {
        if (!this.isValidSlot(slotId)) {
            return { success: false, slotId: 'SLOT_1', error: `Slot inválido: ${slotId}` };
        }

        const filePath = this.slotPath(slotId);
        if (!fs.existsSync(filePath)) {
            return { success: false, slotId, error: 'PERSIST-ERR-404: Slot vazio.' };
        }

        let raw: unknown;
        try {
            raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
        } catch {
            return { success: false, slotId, error: 'PERSIST-ERR-008: JSON do slot corrompido.' };
        }

        const validation = this.validateAndMigrateSaveData(raw, slotId);
        if (!validation.success || !validation.data) {
            return { success: false, slotId, error: validation.error };
        }

        const data = validation.data;

        // Restaura o estado no CampaignManager fornecido.
        if (campaign) {
            this.applyPayloadToCampaign(campaign, data.payload);
        }

        return {
            success: true,
            slotId,
            metadata: data.metadata,
            payload: data.payload,
            migrated: validation.migrated,
        };
    }

    /**
     * applyPayloadToCampaign(campaign, payload)
     * ------------------------------------------------------------------
     * Restaura progresso, inventário e party. Reutiliza o
     * CampaignManager.loadGameState (testado) para progresso/inventário/
     * party básica e aplica os campos adicionais (nível, linhagem,
     * equipamentos duráveis e status táticos) por personagem.
     */
    private applyPayloadToCampaign(campaign: CampaignManager, payload: ISaveSlotPayload): void {
        // 1. Progresso + inventário + party básica via serialização legada.
        const legacySave = {
            progress: payload.progress,
            globalInventory: payload.globalInventory,
            partyStates: payload.party.map((p) => ({
                id: p.id,
                hp: p.hp,
                scrapCount: p.scrapCount,
                engineeringCharges: p.engineeringCharges,
            })),
        };
        campaign.loadGameState(JSON.stringify(legacySave));

        // 2. Campos adicionais por personagem (por id).
        const partyById = new Map(campaign.getPartyState().map((c) => [c.id, c]));
        for (const saved of payload.party) {
            const char = partyById.get(saved.id);
            if (!char) continue;

            char.currentLevel = saved.level;
            char.latentLineageAxis = saved.latentLineageAxis;

            // Equipamentos duráveis: limpa e reaplica (clones defensivos).
            for (const existing of char.durableEquipment) {
                char.unequipDurable(existing.id);
            }
            for (const item of saved.durableEquipment) {
                char.equipDurable(this.clone(item));
            }

            // Status táticos: substitui o array interno.
            const statuses = char.activeStatuses;
            statuses.length = 0;
            for (const s of saved.activeStatuses) {
                statuses.push(this.clone(s));
            }
        }
    }

    // ==============================================================
    // [4] DELETAR SLOT
    // ==============================================================

    /**
     * deleteSlot(slotId)
     * ------------------------------------------------------------------
     * Remove o arquivo do slot. Retorna true se removido ou já inexistente.
     */
    public deleteSlot(slotId: string): boolean {
        if (!this.isValidSlot(slotId)) return false;
        try {
            const filePath = this.slotPath(slotId);
            if (fs.existsSync(filePath)) {
                fs.unlinkSync(filePath);
            }
            return true;
        } catch (error) {
            console.error(`❌ Falha ao deletar slot ${slotId}:`, error);
            return false;
        }
    }

    // ==============================================================
    // VALIDAÇÃO E MIGRAÇÃO
    // ==============================================================

    /**
     * validateAndMigrateSaveData(raw, slotId)
     * ------------------------------------------------------------------
     * Valida a integridade (checksum, quando presente) e migra saves
     * antigos preenchendo campos faltantes com padrões seguros.
     *
     * Regras:
     *   - Estrutura mínima ausente → falha.
     *   - Checksum presente e divergente do payload → falha (adulteração).
     *   - Checksum ausente (save legado) → aceito, marcado como migrado.
     *   - Campos faltantes (supplies, durableEquipment, activeStatuses, …)
     *     → preenchidos com defaults; `migrated: true`.
     */
    public validateAndMigrateSaveData(
        raw: unknown,
        slotId: SaveSlotId,
    ): { success: boolean; data?: ISaveSlotData; migrated?: boolean; error?: string } {
        if (!raw || typeof raw !== 'object') {
            return { success: false, error: 'PERSIST-ERR-010: Save vazio ou inválido.' };
        }

        const obj = raw as Partial<ISaveSlotData>;
        if (!obj.payload || typeof obj.payload !== 'object') {
            return { success: false, error: 'PERSIST-ERR-010: Payload ausente.' };
        }

        let migrated = false;

        // --- Integridade: valida checksum se presente ---
        if (typeof obj.checksum === 'string') {
            const expected = this.checksumOf(obj.payload as ISaveSlotPayload);
            if (expected !== obj.checksum) {
                return { success: false, error: 'PERSIST-ERR-011: Checksum inválido (save adulterado).' };
            }
        } else {
            // Save legado sem checksum — aceito, mas exige migração.
            migrated = true;
        }

        // --- Migração do payload ---
        const p = obj.payload as Partial<ISaveSlotPayload>;

        // Progresso.
        const progress = (p.progress ?? {}) as Partial<ICampaignProgress>;
        const currentNodeId = progress.currentNodeId ?? 'brenhold_entrance';
        const migratedProgress: ICampaignProgress = {
            currentNodeId,
            unlockedNodeIds: progress.unlockedNodeIds ?? [currentNodeId],
            completedBattlesCount: progress.completedBattlesCount ?? 0,
            estafaBalance: progress.estafaBalance ?? 0,
            supplies:
                typeof progress.supplies === 'number'
                    ? progress.supplies
                    : CampaignManager.STARTING_SUPPLIES,
            survivalCrisis: progress.survivalCrisis ?? false,
        };
        if (
            progress.supplies === undefined ||
            progress.survivalCrisis === undefined ||
            progress.unlockedNodeIds === undefined ||
            progress.completedBattlesCount === undefined ||
            progress.estafaBalance === undefined
        ) {
            migrated = true;
        }

        // Party.
        const rawParty = Array.isArray(p.party) ? p.party : [];
        const migratedParty: ISavedCharacter[] = rawParty.map((c) => {
            const sc = (c ?? {}) as Partial<ISavedCharacter>;
            if (
                sc.durableEquipment === undefined ||
                sc.activeStatuses === undefined ||
                sc.level === undefined ||
                sc.latentLineageAxis === undefined ||
                sc.engineeringCharges === undefined
            ) {
                migrated = true;
            }
            return {
                id: sc.id ?? 'unknown',
                level: sc.level ?? 1,
                hp: sc.hp ?? 0,
                scrapCount: sc.scrapCount ?? 0,
                engineeringCharges: sc.engineeringCharges ?? {},
                latentLineageAxis: sc.latentLineageAxis ?? LatentLineageAxis.NEUTRO_ABSOLUTO,
                durableEquipment: sc.durableEquipment ?? [],
                activeStatuses: sc.activeStatuses ?? [],
            };
        });

        // Inventário e mapa.
        const migratedInventory = Array.isArray(p.globalInventory) ? p.globalInventory : [];
        if (p.globalInventory === undefined) migrated = true;

        const migratedMapState = p.mapState ?? {
            currentNodeId,
            unlockedNodeIds: migratedProgress.unlockedNodeIds,
        };
        if (p.mapState === undefined) migrated = true;

        const migratedPayload: ISaveSlotPayload = {
            progress: migratedProgress,
            globalInventory: migratedInventory,
            party: migratedParty,
            mapState: migratedMapState,
        };

        // --- Metadados ---
        const rawMeta = (obj.metadata ?? {}) as Partial<ISaveSlotMetadata>;
        if (obj.metadata === undefined) migrated = true;
        const migratedMeta: ISaveSlotMetadata = {
            timestamp: rawMeta.timestamp ?? 0,
            playTimeSeconds: rawMeta.playTimeSeconds ?? 0,
            currentAreaName: rawMeta.currentAreaName ?? currentNodeId,
            partyLeaderName: rawMeta.partyLeaderName ?? migratedParty[0]?.id ?? 'UNKNOWN',
            estafaBalance: rawMeta.estafaBalance ?? migratedProgress.estafaBalance,
            supplies: rawMeta.supplies ?? migratedProgress.supplies,
        };

        const data: ISaveSlotData = {
            slotId,
            schemaVersion: obj.schemaVersion ?? SAVE_SCHEMA_VERSION,
            metadata: migratedMeta,
            payload: migratedPayload,
            checksum: obj.checksum,
        };

        return { success: true, data, migrated };
    }
}
