/**
 * ====================================================================
 * SaveSystem.ts
 * --------------------------------------------------------------------
 * Sistema de persistência em disco para o Projeto Aetheris.
 * Encapsula operações de save/load em arquivo JSON, integrando:
 *   - CampaignManager (estado da campanha, party, inventário)
 *   - CampaignStateManager (checksum SHA-256, validação de integridade)
 *
 * Fluxo:
 *   saveGame()  → serializa via CampaignManager → gera checksum → persiste
 *   loadGame()  → lê do disco → valida checksum → desserializa
 *
 * Fonte: docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import * as fs from 'fs';
import * as path from 'path';
import { CampaignManager } from './CampaignManager';
import { CampaignStateManager, ICampaignSave } from './CampaignStateManager';
import { WorldState } from '../types/aetheris.types';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Diretório onde os saves são armazenados */
const SAVE_DIR = path.join(process.cwd(), 'saves');

/** Nome do arquivo de save padrão */
const SAVE_FILE = 'savegame.json';

/** Caminho completo do arquivo de save */
const SAVE_FILE_PATH = path.join(SAVE_DIR, SAVE_FILE);

// ==================================================================
// INTERFACE — ISaveMetadata
// ==================================================================

/**
 * Metadados do save utilizados internamente para auditoria.
 */
interface ISaveMetadata {
  /** Timestamp Unix do momento do salvamento */
  savedAt: number;
  /** Versão do schema de save (para migrações futuras) */
  schemaVersion: number;
}

// ==================================================================
// CLASSE — SaveSystem
// ==================================================================

export class SaveSystem {
  /**
   * saveGame(campaign)
   * ------------------------------------------------------------------
   * Serializa o estado completo da campanha em um arquivo JSON com
   * checksum de integridade SHA-256.
   *
   * Inclui:
   *   - Dados serializados do CampaignManager (progresso, inventário,
   *     estado da party)
   *   - Metadados de auditoria (timestamp, versão do schema)
   *   - Checksum SHA-256 (via CampaignStateManager) para detecção
   *     de adulteração
   *
   * @param campaign - Instância do CampaignManager com o estado atual
   * @param worldState - Estado do mundo (ERA_DO_ACO | ESTASE_RUNICA)
   * @param completedMilestones - Array de marcos narrativos concluídos
   * @returns true se o save foi persistido com sucesso, false caso contrário
   */
  public static saveGame(
    campaign: CampaignManager,
    worldState: WorldState = WorldState.ERA_DO_ACO,
    completedMilestones: string[] = [],
  ): boolean {
    try {
      // Garante que o diretório de saves existe
      if (!fs.existsSync(SAVE_DIR)) {
        fs.mkdirSync(SAVE_DIR, { recursive: true });
      }

      // Serializa o estado da campanha via CampaignManager
      const playerData: string = campaign.saveGameState();

      // Constrói o payload para checksum (sem checksum ainda)
      const savePayload: Omit<ICampaignSave, 'checksum'> = {
        playerData,
        worldState,
        completedMilestones,
      };

      // Gera checksum de integridade via CampaignStateManager
      const stateManager = CampaignStateManager.getInstance();
      const checksum: string = stateManager.generateChecksum(savePayload);

      // Monta o bloco completo de save
      const saveBlock: ICampaignSave = {
        ...savePayload,
        checksum,
      };

      // Metadados de auditoria (não entram no checksum)
      const metadata: ISaveMetadata = {
        savedAt: Date.now(),
        schemaVersion: 1,
      };

      // Estrutura final do arquivo on-disk
      const diskBlock = {
        metadata,
        save: saveBlock,
      };

      // Persiste em disco (pretty-print para legibilidade)
      fs.writeFileSync(
        SAVE_FILE_PATH,
        JSON.stringify(diskBlock, null, 2),
        'utf-8',
      );

      return true;
    } catch (error) {
      console.error('❌ Falha ao gravar savegame:', error);
      return false;
    }
  }

  /**
   * loadGame()
   * ------------------------------------------------------------------
   * Carrega e valida o arquivo de save do disco.
   *
   * Fluxo:
   *   1. Verifica se o arquivo existe
   *   2. Faz parse do JSON (on-disk format)
   *   3. Valida checksum via CampaignStateManager.validateAndLoadSave()
   *   4. Se válido, desserializa o playerData em um objeto
   *
   * @returns Objeto com { success, save?, error? } — mesmo contrato
   *          de IValidateAndLoadResult
   */
  public static loadGame(): {
    success: boolean;
    save?: ICampaignSave;
    error?: string;
  } {
    try {
      // Verifica se o arquivo existe
      if (!fs.existsSync(SAVE_FILE_PATH)) {
        return {
          success: false,
          error: 'Nenhum save encontrado.',
        };
      }

      // Lê o conteúdo do arquivo
      const rawData: string = fs.readFileSync(SAVE_FILE_PATH, 'utf-8');

      // Faz parse do bloco on-disk (metadados + save)
      let diskBlock: { metadata: ISaveMetadata; save: ICampaignSave };

      try {
        diskBlock = JSON.parse(rawData);
      } catch {
        return {
          success: false,
          error: 'PERSIST-ERR-008: Falha no parse do JSON do save. Arquivo corrompido.',
        };
      }

      // Valida a estrutura do bloco
      if (!diskBlock.save || !diskBlock.metadata) {
        return {
          success: false,
          error: 'PERSIST-ERR-008: Estrutura do arquivo de save inválida.',
        };
      }

      // Serializa o save block de volta para string para validação
      const saveJsonString: string = JSON.stringify(diskBlock.save);

      // Valida checksum via CampaignStateManager
      const stateManager = CampaignStateManager.getInstance();
      const validationResult = stateManager.validateAndLoadSave(saveJsonString);

      if (!validationResult.success) {
        return {
          success: false,
          error: validationResult.error,
        };
      }

      return {
        success: true,
        save: validationResult.save,
      };
    } catch (error) {
      console.error('❌ Falha ao ler savegame:', error);
      return {
        success: false,
        error: `Erro inesperado: ${error instanceof Error ? error.message : String(error)}`,
      };
    }
  }

  /**
   * deleteSave()
   * ------------------------------------------------------------------
   * Remove o arquivo de save do disco.
   *
   * @returns true se o save foi removido ou não existia,
   *          false se houve erro na remoção
   */
  public static deleteSave(): boolean {
    try {
      if (fs.existsSync(SAVE_FILE_PATH)) {
        fs.unlinkSync(SAVE_FILE_PATH);
      }
      return true;
    } catch (error) {
      console.error('❌ Falha ao remover savegame:', error);
      return false;
    }
  }

  /**
   * saveExists()
   * ------------------------------------------------------------------
   * Verifica se existe um arquivo de save no disco.
   *
   * @returns true se o arquivo existe
   */
  public static saveExists(): boolean {
    return fs.existsSync(SAVE_FILE_PATH);
  }

  /**
   * getSaveFilePath()
   * ------------------------------------------------------------------
   * Retorna o caminho absoluto do arquivo de save atual.
   *
   * @returns Caminho completo do save
   */
  public static getSaveFilePath(): string {
    return SAVE_FILE_PATH;
  }
}