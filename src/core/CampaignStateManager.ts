/**
 * ====================================================================
 * CampaignStateManager.ts
 * --------------------------------------------------------------------
 * Motor de persistência de dados de campanha do Projeto Aetheris.
 * Encapsula a serialização, validação de integridade e controle de
 * estado do savegame, com garantia de exclusão binária nas escolhas
 * de Clímax (Ato 5).
 *
 * Fonte: docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md
 *        docs/03_narrativa/EVT-ESCOLHA-FINAL-001.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO (Sprint 3 — Persistência de Campanha)
 * ====================================================================
 */

import * as crypto from 'crypto';
import { WorldState } from '../types/aetheris.types';

// ==================================================================
// CONSTANTES INTERNAS
// ==================================================================

/** Salt privado interno estável para o algoritmo de checksum.
 *  Este salt garante que hashes gerados externamente (save editing)
 *  não correspondam aos hashes legítimos do motor, mesmo que o
 *  algoritmo seja conhecido. */
const PRIVATE_CHECKSUM_SALT: string = 'AETHERIS_CAMPAIGN_SALT_V1_7F3A2B';

/** Flag de milestone que representa a escolha da Rota A (Kael). */
const MILESTONE_ROUTE_A: string = 'EVT-ESCOLHA-FINAL-001-A';

/** Flag de milestone que representa a escolha da Rota B (Elyra). */
const MILESTONE_ROUTE_B: string = 'EVT-ESCOLHA-FINAL-001-B';

// ==================================================================
// INTERFACE — ICampaignSave
// ==================================================================

/**
 * Interface ICampaignSave
 * --------------------------------------------------------------------
 * Estrutura do payload de salvamento de campanha. Este bloco é a
 * única fonte da verdade para o estado persistente da campanha.
 *
 * Campos:
 *   playerData          — JSON serializado do CharacterState
 *   worldState          — Estado final do mundo (ERA_DO_ACO | ESTASE_RUNICA)
 *   completedMilestones — Array de marcos narrativos concluídos
 *   checksum            — Hash SHA-256 determinístico para detecção
 *                         de adulteração (save editing)
 */
export interface ICampaignSave {
  /** JSON serializado do CharacterState do jogador */
  playerData: string;

  /** Estado final do mundo pós-Veredito */
  worldState: WorldState;

  /** Array de marcos narrativos concluídos (milestones) */
  completedMilestones: string[];

  /** Hash SHA-256 de integridade — gerado por generateChecksum() */
  checksum: string;
}

// ==================================================================
// INTERFACE — IValidateAndLoadResult
// ==================================================================

/**
 * Resultado da operação validateAndLoadSave.
 *
 * success — true se o save foi carregado e validado com sucesso
 * save    — O save desserializado (presente apenas se success === true)
 * error   — Mensagem de erro descritiva (presente apenas se success === false)
 */
export interface IValidateAndLoadResult {
  success: boolean;
  save?: ICampaignSave;
  error?: string;
}

// ==================================================================
// CLASSE — CampaignStateManager
// ==================================================================

/**
 * CampaignStateManager
 * --------------------------------------------------------------------
 * Singleton de sistema responsável por gerenciar a persistência
 * de dados de campanha. Provê métodos para:
 *
 * 1. Geração de checksum determinístico (SHA-256 + salt privado)
 * 2. Validação e carregamento de saves com verificação de integridade
 * 3. Travamento binário excludente de escolhas do Clímax (Ato 5)
 *
 * NENHUMA outra entidade no motor pode escrever diretamente nos
 * campos de estado de campanha sem passar por este gerenciador.
 *
 * Fonte: ENG-PERSISTENCIA-CAMPANHA.md Seção 3
 *        ENG-PERSISTENCIA-CAMPANHA.md Seção 6 (Travas de Segurança)
 */
export class CampaignStateManager {
  // ==================================================================
  // PROPRIEDADES PRIVADAS
  // ==================================================================

  /** Instância singleton do CampaignStateManager */
  private static _instance: CampaignStateManager | null = null;

  /** Trava de segurança — true após o Veredito ser finalizado */
  private _saveSealed: boolean;

  // ==================================================================
  // CONSTRUTOR (privado — singleton)
  // ==================================================================

  /**
   * Construtor privado para garantir o padrão singleton.
   * Use CampaignStateManager.getInstance() para obter a instância.
   */
  private constructor() {
    this._saveSealed = false;
  }

  // ==================================================================
  // SINGLETON — getInstance
  // ==================================================================

  /**
   * getInstance()
   * ------------------------------------------------------------------
   * Retorna a instância única do CampaignStateManager (singleton).
   *
   * @returns Instância do CampaignStateManager
   */
  public static getInstance(): CampaignStateManager {
    if (CampaignStateManager._instance === null) {
      CampaignStateManager._instance = new CampaignStateManager();
    }
    return CampaignStateManager._instance;
  }

  // ==================================================================
  // MÉTODO — generateChecksum
  // ==================================================================

  /**
   * generateChecksum(saveData)
   * ------------------------------------------------------------------
   * Gera um hash SHA-256 determinístico para assinar digitalmente
   * o estado do jogo e evitar adulteração de save (save editing).
   *
   * Algoritmo:
   *   1. Concatena os campos estruturados (playerData, worldState,
   *      completedMilestones) em uma string canônica.
   *   2. Adiciona o salt privado interno estável.
   *   3. Aplica SHA-256 e retorna o hex digest.
   *
   * O salt privado garante que saves editados manualmente não
   * consigam reproduzir o hash legítimo.
   *
   * Fonte: ENG-PERSISTENCIA-CAMPANHA.md Seção 6.2 (Camada 3)
   *
   * @param saveData — Dados do save SEM o campo checksum
   * @returns Hex digest SHA-256 do bloco de dados + salt
   */
  public generateChecksum(
    saveData: Omit<ICampaignSave, 'checksum'>,
  ): string {
    // ================================================================
    // Construção da string canônica para hashing
    //
    // Ordem determinística dos campos:
    //   1. playerData (string JSON)
    //   2. worldState (enum string)
    //   3. completedMilestones (array, ordenado para consistência)
    //
    // O array é ordenado alfabeticamente para garantir que a ordem
    // dos milestones não afete o hash (determinismo puro).
    // ================================================================

    const canonicalMilestones: string =
      '[' +
      [...saveData.completedMilestones]
        .sort((a, b) => a.localeCompare(b))
        .join(',') +
      ']';

    const canonicalString: string =
      `playerData=${saveData.playerData}|` +
      `worldState=${saveData.worldState}|` +
      `completedMilestones=${canonicalMilestones}|` +
      `salt=${PRIVATE_CHECKSUM_SALT}`;

    // ================================================================
    // Aplicação do SHA-256
    // ================================================================

    const hash: string = crypto
      .createHash('sha256')
      .update(canonicalString, 'utf-8')
      .digest('hex');

    return hash;
  }

  // ==================================================================
  // MÉTODO — validateAndLoadSave
  // ==================================================================

  /**
   * validateAndLoadSave(jsonString)
   * ------------------------------------------------------------------
   * Recebe a string JSON do arquivo de save, realiza o parse defensivo,
   * recalcula o checksum e compara com o hash presente no arquivo.
   *
   * Fluxo de validação:
   *   1. Parse do JSON em bloco try/catch — se falhar, retorna erro
   *      de formato inválido.
   *   2. Verifica se todos os campos obrigatórios estão presentes.
   *   3. Recalcula o checksum a partir dos dados (excluindo o campo
   *      checksum original).
   *   4. Compara o hash recalculado com o hash armazenado.
   *      - Se divergirem, rejeita o carregamento (save corrompido ou
   *        adulterado).
   *   5. Se tudo ok, retorna o save desserializado.
   *
   * Fonte: ENG-PERSISTENCIA-CAMPANHA.md Seção 6.2 (Camada 3)
   *        PERSIST-ERR-008 na Tabela de Códigos de Erro
   *
   * @param jsonString — String JSON completa do arquivo de save
   * @returns Objeto com { success, save?, error? }
   */
  public validateAndLoadSave(
    jsonString: string,
  ): IValidateAndLoadResult {
    // ================================================================
    // ETAPA 1: Parse defensivo do JSON
    // ================================================================

    let parsedData: Record<string, unknown>;

    try {
      parsedData = JSON.parse(jsonString) as Record<string, unknown>;
    } catch (parseError) {
      const errorMessage =
        parseError instanceof Error
          ? parseError.message
          : 'Erro desconhecido no parse do JSON';

      return {
        success: false,
        error: `PERSIST-ERR-008: Falha no parse do JSON do save. ${errorMessage}`,
      };
    }

    // ================================================================
    // ETAPA 2: Validação dos campos obrigatórios
    // ================================================================

    if (typeof parsedData.playerData !== 'string') {
      return {
        success: false,
        error:
          'PERSIST-ERR-008: Campo "playerData" ausente ou inválido no save.',
      };
    }

    if (
      typeof parsedData.worldState !== 'string' ||
      !this.isValidWorldState(parsedData.worldState as string)
    ) {
      return {
        success: false,
        error:
          'PERSIST-ERR-008: Campo "worldState" ausente ou inválido no save.',
      };
    }

    if (
      !Array.isArray(parsedData.completedMilestones) ||
      !parsedData.completedMilestones.every(
        (item: unknown) => typeof item === 'string',
      )
    ) {
      return {
        success: false,
        error:
          'PERSIST-ERR-008: Campo "completedMilestones" ausente ou malformado no save.',
      };
    }

    if (typeof parsedData.checksum !== 'string') {
      return {
        success: false,
        error:
          'PERSIST-ERR-008: Campo "checksum" ausente ou inválido no save.',
      };
    }

    // ================================================================
    // ETAPA 3: Extração dos dados e montagem do objeto ICampaignSave
    // ================================================================

    const storedChecksum: string = parsedData.checksum as string;

    const saveData: Omit<ICampaignSave, 'checksum'> = {
      playerData: parsedData.playerData as string,
      worldState: parsedData.worldState as WorldState,
      completedMilestones: parsedData.completedMilestones as string[],
    };

    // ================================================================
    // ETAPA 4: Recalcula o checksum e compara com o armazenado
    // ================================================================

    const recalculatedChecksum: string =
      this.generateChecksum(saveData);

    if (storedChecksum !== recalculatedChecksum) {
      return {
        success: false,
        error:
          `PERSIST-ERR-008: Hash de integridade não corresponde. ` +
          `Armazenado=${storedChecksum}, Recalculado=${recalculatedChecksum}. ` +
          `O arquivo de salvamento parece estar corrompido ou foi adulterado.`,
      };
    }

    // ================================================================
    // ETAPA 5: Sucesso — retorna o save validado
    // ================================================================

    const validatedSave: ICampaignSave = {
      ...saveData,
      checksum: storedChecksum,
    };

    return {
      success: true,
      save: validatedSave,
    };
  }

  // ==================================================================
  // MÉTODO — commitNarrativeChoice
  // ==================================================================

  /**
   * commitNarrativeChoice(save, choiceId)
   * ------------------------------------------------------------------
   * Implementa a lógica de trava binária excludente para as escolhas
   * do Clímax (Ato 5).
   *
   * REGRA DE EXCLUSÃO BINÁRIA:
   *   Se o choiceId for EVT-ESCOLHA-FINAL-001-A (Rota Kael), o sistema
   *   deve injetar a flag no array de milestones e bloquear
   *   PERMANENTEMENTE qualquer inserção futura do polo B
   *   (EVT-ESCOLHA-FINAL-001-B) no mesmo save, forçando o isolamento
   *   narrativo determinado no GDD.
   *
   *   Reciprocamente, se EVT-ESCOLHA-FINAL-001-B for inserida primeiro,
   *   o sistema bloqueia permanentemente EVT-ESCOLHA-FINAL-001-A.
   *
   * MECANISMO:
   *   1. Verifica se o choiceId é um dos dois polos válidos.
   *   2. Se o choiceId já estiver presente em completedMilestones,
   *      a operação é rejeitada (escolha já registrada).
   *   3. Se o polo OPOSTO já estiver presente em completedMilestones,
   *      a operação é rejeitada com erro PERSIST-ERR-003
   *      (exclusão binária violada).
   *   4. Caso contrário, adiciona o choiceId ao array de milestones.
   *
   * Fonte: ENG-PERSISTENCIA-CAMPANHA.md Seção 6.1 e 6.2
   *        EVT-ESCOLHA-FINAL-001.md — Tabela de Estados Finais
   *
   * @param save     — O save da campanha a ser modificado
   * @param choiceId — ID da escolha narrativa (EVT-ESCOLHA-FINAL-001-A
   *                   ou EVT-ESCOLHA-FINAL-001-B)
   * @throws Error com código PERSIST-ERR-003 se a exclusão binária
   *         for violada ou a escolha já estiver registrada
   */
  public commitNarrativeChoice(
    save: ICampaignSave,
    choiceId: string,
  ): void {
    // ================================================================
    // Validação do choiceId — apenas os dois polos são aceitos
    // ================================================================

    if (choiceId !== MILESTONE_ROUTE_A && choiceId !== MILESTONE_ROUTE_B) {
      throw new Error(
        `PERSIST-ERR-002: ID de escolha inválido "${choiceId}". ` +
        `Apenas ${MILESTONE_ROUTE_A} e ${MILESTONE_ROUTE_B} são permitidos.`,
      );
    }

    // ================================================================
    // Determina o polo oposto para verificação de exclusão binária
    // ================================================================

    const oppositePole: string =
      choiceId === MILESTONE_ROUTE_A
        ? MILESTONE_ROUTE_B
        : MILESTONE_ROUTE_A;

    // ================================================================
    // Verificação 1: Escolha já registrada?
    // Se o choiceId já existe no array, rejeita duplicação
    // ================================================================

    if (save.completedMilestones.includes(choiceId)) {
      throw new Error(
        `PERSIST-ERR-003: A escolha "${choiceId}" já foi registrada ` +
        `neste save. Não é possível registrar a mesma escolha duas vezes.`,
      );
    }

    // ================================================================
    // Verificação 2: Exclusão binária — o polo oposto já foi escolhido?
    //
    // Se o polo oposto já estiver presente no array de milestones,
    // a inserção é BLOQUEADA. A campanha é uma linha do tempo única
    // e irreversível — ambas as rotas NÃO podem coexistir no mesmo
    // bloco de save.
    //
    // Fonte: ENG-PERSISTENCIA-CAMPANHA.md Seção 6.1
    //        "O bloco de memória de save campaign_state NUNCA pode
    //         conter dois WorldStates distintos."
    // ================================================================

    if (save.completedMilestones.includes(oppositePole)) {
      throw new Error(
        `PERSIST-ERR-003: Violação de exclusão binária. ` +
        `O save já contém a escolha "${oppositePole}" (rota oposta). ` +
        `Não é possível registrar "${choiceId}" no mesmo save. ` +
        `A campanha não pode conter ambas as rotas simultaneamente.`,
      );
    }

    // ================================================================
    // Verificação 3: Trava de save selado
    //
    // Se o save já foi finalizado (saveSealed), não permite novas
    // inserções de escolhas narrativas.
    // ================================================================

    if (this._saveSealed) {
      throw new Error(
        'PERSIST-ERR-003: Save já selado. Não é possível registrar ' +
        'novas escolhas narrativas após a finalização da campanha.',
      );
    }

    // ================================================================
    // Injeção da escolha no array de milestones
    // ================================================================

    save.completedMilestones.push(choiceId);

    // ================================================================
    // Pós-condição: se esta é a escolha de Clímax (Ato 5),
    // sela o save para impedir qualquer alteração futura
    // ================================================================

    this._saveSealed = true;
  }

  // ==================================================================
  // MÉTODO — reset
  // ==================================================================

  /**
   * reset()
   * ------------------------------------------------------------------
   * Reinicia o estado interno do CampaignStateManager.
   * Útil para testes ou início de uma nova campanha.
   *
   * NOTA: Este método NÃO modifica nenhum save já persistido em
   * disco. Ele apenas reseta o estado em memória do singleton.
   */
  public reset(): void {
    this._saveSealed = false;
  }

  // ==================================================================
  // GETTER — saveSealed
  // ==================================================================

  /**
   * saveSealed
   * ------------------------------------------------------------------
   * Indica se o save atual está selado (não pode mais ser alterado).
   *
   * @returns true se o save foi selado após o Veredito
   */
  public get saveSealed(): boolean {
    return this._saveSealed;
  }

  // ==================================================================
  // MÉTODO AUXILIAR — isValidWorldState
  // ==================================================================

  /**
   * isValidWorldState(value)
   * ------------------------------------------------------------------
   * Verifica se um valor string corresponde a um WorldState válido.
   *
   * @param value — String a ser validada
   * @returns true se o valor é ERA_DO_ACO ou ESTASE_RUNICA
   */
  private isValidWorldState(value: string): value is WorldState {
    return (
      value === WorldState.ERA_DO_ACO ||
      value === WorldState.ESTASE_RUNICA
    );
  }
}