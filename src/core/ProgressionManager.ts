/**
 * ====================================================================
 * ProgressionManager.ts
 * --------------------------------------------------------------------
 * Gerenciamento de progressão de personagem no Projeto Aetheris.
 * Implementa a curva de XP polinomial-exponencial segmentada por Atos,
 * injeção de experiência com cascata de níveis, e escalabilidade de
 * atributos com retornos decrescentes (DRF).
 *
 * Fonte: docs/04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO (Sprint 3 — Progressão e Persistência)
 * ====================================================================
 */

import {
  ICharacterStats,
  EventIds,
} from '../types/aetheris.types';
import { CharacterState } from './CharacterState';

/**
 * Interface que define o callback para o barramento de eventos.
 */
export interface IEventBusCallback {
  (eventId: string, payload?: Record<string, unknown>): void;
}

/**
 * Interface que define o resultado da operação addExperience.
 */
export interface IAddExperienceResult {
  /** Quantidade de níveis ganhos no processo */
  levelsGained: number;
  /** Marcas de Aço geradas por overflow de XP no nível máximo */
  overflowMarks: number;
}

/**
 * Classe ProgressionManager
 * --------------------------------------------------------------------
 * Gerencia a progressão de nível dos personagens, incluindo:
 *
 * - Curva de XP polinomial-exponencial segmentada por Atos (1-5)
 * - Injeção de XP com processamento em cascata (multi-level-up)
 * - Disparo de EVT_REVELACAO_LINHAGEM ao cruzar nível 36
 * - Conversão de XP excedente no teto (nível 50) para Marcas de Aço (100:1)
 * - Escalabilidade de atributos com fator de retornos decrescentes (DRF ^ 0.7)
 * - Caps máximos canônicos: 250 Dano / 200 Defesa / 180 Resiliência
 *
 * Fonte: docs/04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md
 *        Seções 3.1 (Curva de XP), 4.1 (Injeção de XP), 5.1 (DRF)
 * ====================================================================
 */
export class ProgressionManager {
  // ==================================================================
  // CONSTANTES — CURVA DE XP SEGMENTADA POR ATOS
  // ==================================================================

  /** Coeficiente base da curva do Ato 1 (níveis 1-10) */
  private static readonly ACT1_COEFFICIENT = 50;
  /** Expoente da curva do Ato 1 */
  private static readonly ACT1_EXPONENT = 1.4;

  /** Coeficiente base da curva do Ato 2 (níveis 11-20) */
  private static readonly ACT2_COEFFICIENT = 120;
  /** Expoente da curva do Ato 2 */
  private static readonly ACT2_EXPONENT = 1.6;

  /** Coeficiente base da curva do Ato 3 (níveis 21-35) */
  private static readonly ACT3_COEFFICIENT = 85;
  /** Expoente da curva do Ato 3 */
  private static readonly ACT3_EXPONENT = 2.1;

  /** Coeficiente base da curva dos Atos 4-5 (níveis 36-49) */
  private static readonly ACT4_5_COEFFICIENT = 200;
  /** Expoente da curva dos Atos 4-5 */
  private static readonly ACT4_5_EXPONENT = 2.4;

  // ==================================================================
  // CONSTANTES — TETO E CONVERSÃO
  // ==================================================================

  /** Nível máximo (teto rígido) */
  public static readonly LEVEL_MAX = 50;

  /** Marca de revelação de linhagem (Ato 4) */
  public static readonly LINEAGE_UNLOCK_LEVEL = 36;

  /** Taxa de conversão: 100 XP = 1 Marca de Aço */
  public static readonly XP_TO_MARKS_RATE = 100;

  // ==================================================================
  // CONSTANTES — DRF E STAT CAPS
  // ==================================================================

  /** Expoente do fator de retornos decrescentes */
  public static readonly DRF_EXPONENT = 0.7;

  /** Cap máximo de Dano */
  public static readonly DAMAGE_CAP = 250;

  /** Cap máximo de Defesa */
  public static readonly DEFENSE_CAP = 200;

  /** Cap máximo de Resiliência */
  public static readonly RESILIENCE_CAP = 180;

  // ==================================================================
  // PROPRIEDADES PRIVADAS
  // ==================================================================

  /** Mapa de XP acumulado por personagem (referência de objeto) */
  private xpMap: Map<object, number>;

  /** Callback para o barramento de eventos do motor */
  private _eventBusCallback: IEventBusCallback | null;

  // ==================================================================
  // CONSTRUTOR
  // ==================================================================

  /**
   * Cria uma nova instância de ProgressionManager.
   *
   * @param eventBusCallback - Callback opcional para disparo de eventos
   *                           no barramento de dados do motor
   */
  constructor(eventBusCallback?: IEventBusCallback) {
    this.xpMap = new Map<object, number>();
    this._eventBusCallback = eventBusCallback ?? null;
  }

  // ==================================================================
  // MÉTODO — calculateRequiredXp
  // ==================================================================

  /**
   * calculateRequiredXp(level)
   * ------------------------------------------------------------------
   * Calcula a quantidade de XP necessária para avançar do nível
   * informado para o próximo nível.
   *
   * Implementa a curva polinomial-exponencial segmentada por Atos:
   *
   *   Ato 1 (níveis 1-10):  Math.floor(50 * level^1.4)
   *   Ato 2 (níveis 11-20): Math.floor(120 * level^1.6)
   *   Ato 3 (níveis 21-35): Math.floor(85 * level^2.1)
   *   Atos 4-5 (níveis 36-49): Math.floor(200 * level^2.4)
   *   Nível >= 50 (Teto): 0
   *
   * Fonte: ENG-PROGRESSAO-NIVEIS Seção 3.1 (Tabela de Curva de XP)
   *
   * @param level - Nível atual do personagem (base 1.0)
   * @returns XP necessária para o próximo nível, ou 0 no teto
   */
  public calculateRequiredXp(level: number): number {
    // Validação de entrada — nível deve ser inteiro positivo
    if (!Number.isFinite(level) || level < 1) {
      return 0;
    }

    // Teto máximo — nível >= 50
    if (level >= ProgressionManager.LEVEL_MAX) {
      return 0;
    }

    // Arredonda para inteiro (segurança contra níveis fracionários)
    const safeLevel = Math.floor(level);

    // ================================================================
    // Segmentação por Atos (curva polinomial-exponencial)
    // ================================================================

    // Ato 1: Níveis 1 a 10
    if (safeLevel >= 1 && safeLevel <= 10) {
      return Math.floor(
        ProgressionManager.ACT1_COEFFICIENT *
        Math.pow(safeLevel, ProgressionManager.ACT1_EXPONENT),
      );
    }

    // Ato 2: Níveis 11 a 20
    if (safeLevel >= 11 && safeLevel <= 20) {
      return Math.floor(
        ProgressionManager.ACT2_COEFFICIENT *
        Math.pow(safeLevel, ProgressionManager.ACT2_EXPONENT),
      );
    }

    // Ato 3: Níveis 21 a 35
    if (safeLevel >= 21 && safeLevel <= 35) {
      return Math.floor(
        ProgressionManager.ACT3_COEFFICIENT *
        Math.pow(safeLevel, ProgressionManager.ACT3_EXPONENT),
      );
    }

    // Atos 4-5: Níveis 36 a 49
    if (safeLevel >= 36 && safeLevel <= 49) {
      return Math.floor(
        ProgressionManager.ACT4_5_COEFFICIENT *
        Math.pow(safeLevel, ProgressionManager.ACT4_5_EXPONENT),
      );
    }

    // Fallback de segurança (não deve ocorrer, mas cobre casos extremos)
    return 0;
  }

  // ==================================================================
  // MÉTODO — addExperience
  // ==================================================================

  /**
   * addExperience(character, xpGained)
   * ------------------------------------------------------------------
   * Injeta uma quantidade de XP no personagem, processando:
   *
   * 1. Se o personagem já está no nível 50:
   *    - Converte TODO o xpGained em Marcas de Aço (100 XP = 1 Marca)
   *    - Retorna levelsGained = 0 e overflowMarks calculado
   *
   * 2. Se o personagem está abaixo do nível 50:
   *    a. Acumula o XP no total do personagem
   *    b. Processa em cascata: enquanto houver XP suficiente para subir
   *       de nível (conforme calculateRequiredXp), aplica os ganhos
   *    c. Se durante a cascata o personagem cruzar o nível 36 (Ato 4),
   *       dispara EVT_REVELACAO_LINHAGEM no barramento de dados
   *    d. Se após a cascata o personagem atingir o nível 50 e ainda
   *       houver XP residual, converte o excedente em Marcas de Aço
   *
   * Fonte: ENG-PROGRESSAO-NIVEIS Seção 4.1 (Injeção de XP)
   *
   * @param character - Instância de CharacterState do personagem
   * @param xpGained - Quantidade de XP a injetar (deve ser >= 0)
   * @returns Objeto com { levelsGained, overflowMarks }
   */
  public addExperience(
    character: CharacterState,
    xpGained: number,
  ): IAddExperienceResult {
    // ================================================================
    // Validação de entrada
    // ================================================================

    if (!Number.isFinite(xpGained) || xpGained < 0) {
      return { levelsGained: 0, overflowMarks: 0 };
    }

    // ================================================================
    // Caso 1: Personagem já no nível máximo (teto 50)
    // Converte TODO o XP recebido em Marcas de Aço (100:1)
    // ================================================================

    if (character.currentLevel >= ProgressionManager.LEVEL_MAX) {
      const overflowMarks = Math.floor(
        xpGained / ProgressionManager.XP_TO_MARKS_RATE,
      );
      return { levelsGained: 0, overflowMarks };
    }

    // ================================================================
    // Caso 2: Personagem abaixo do nível 50
    // Processa acúmulo de XP com cascata de level-up
    // ================================================================

    // Obtém o XP atual do personagem (ou 0 se não registrado)
    const currentXp: number = this.xpMap.get(character) ?? 0;

    // Acumula o novo XP no total
    let totalXp: number = currentXp + xpGained;

    let levelsGained = 0;
    let overflowMarks = 0;
    let crossedLevel36 = false;

    // Guarda o nível inicial para referência de cruzamento
    const initialLevel: number = character.currentLevel;
    let currentLevel: number = initialLevel;

    // ================================================================
    // Processamento em cascata
    // Enquanto o personagem não atingir o teto E tiver XP suficiente,
    // avança níveis um a um.
    // ================================================================

    while (currentLevel < ProgressionManager.LEVEL_MAX) {
      const requiredXp: number = this.calculateRequiredXp(currentLevel);

      // Se o XP necessário é 0 ou insuficiente, interrompe
      if (requiredXp <= 0 || totalXp < requiredXp) {
        break;
      }

      // Deduz o XP necessário e avança o nível
      totalXp -= requiredXp;
      currentLevel++;
      levelsGained++;

      // ================================================================
      // Verificação de cruzamento da barreira do nível 36
      // Se o personagem ultrapassou o nível 36 durante a cascata,
      // marca a flag para disparar EVT_REVELACAO_LINHAGEM
      // ================================================================

      if (
        currentLevel === ProgressionManager.LINEAGE_UNLOCK_LEVEL ||
        (initialLevel < ProgressionManager.LINEAGE_UNLOCK_LEVEL &&
          currentLevel > ProgressionManager.LINEAGE_UNLOCK_LEVEL)
      ) {
        crossedLevel36 = true;
      }
    }

    // ================================================================
    // Aplica o nível final ao personagem
    // O setter de CharacterState já aplica teto rígido e validação
    // ================================================================

    character.currentLevel = currentLevel;

    // ================================================================
    // Conversão de XP residual no teto
    // Se após a cascata o personagem está no nível 50 e ainda há XP
    // restante, converte o excedente em Marcas de Aço (100:1)
    // ================================================================

    if (currentLevel >= ProgressionManager.LEVEL_MAX && totalXp > 0) {
      overflowMarks = Math.floor(
        totalXp / ProgressionManager.XP_TO_MARKS_RATE,
      );
      // Mantém o resto não conversível no mapa (perde-se fração < 100)
      totalXp = totalXp % ProgressionManager.XP_TO_MARKS_RATE;
    }

    // ================================================================
    // Armazena o XP residual para o personagem
    // ================================================================

    this.xpMap.set(character, totalXp);

    // ================================================================
    // Dispara EVT_REVELACAO_LINHAGEM se o nível 36 foi cruzado
    // ================================================================

    if (crossedLevel36) {
      this.dispatchEvent(EventIds.EVT_REVELACAO_LINHAGEM, {
        level: currentLevel,
        previousLevel: initialLevel,
        levelsGained,
        xpRemaining: totalXp,
        timestamp: Date.now(),
      });
    }

    return { levelsGained, overflowMarks };
  }

  // ==================================================================
  // MÉTODO — scaleStatsWithDiminishingReturns
  // ==================================================================

  /**
   * scaleStatsWithDiminishingReturns(baseStats, currentLevel)
   * ------------------------------------------------------------------
   * Aplica o multiplicador de escalabilidade de atributos com fator
   * de amortecimento por retornos decrescentes (DRF).
   *
   * Fórmula:
   *   drf = Math.pow(currentLevel, 0.7)
   *   statEscalado = Math.min(capMaximo, Math.floor(statBase * drf))
   *
   * O expoente 0.7 garante que o crescimento dos atributos desacelere
   * conforme o personagem avança de nível (lei dos rendimentos
   * decrescentes).
   *
   * Caps máximos canônicos (aplicados após o cálculo):
   *   - Dano:      250
   *   - Defesa:    200
   *   - Resiliência: 180
   *
   * ATENÇÃO: maxHp, currentHp e movementSpeed NÃO são escalados por
   * este método — retornam os valores base inalterados.
   *
   * Fonte: ENG-PROGRESSAO-NIVEIS Seção 5.1 (DRF e Stat Caps)
   *
   * @param baseStats - Estatísticas base do personagem
   * @param currentLevel - Nível atual do personagem
   * @returns Cópia das estatísticas com escalabilidade aplicada e caps
   */
  public scaleStatsWithDiminishingReturns(
    baseStats: ICharacterStats,
    currentLevel: number,
  ): ICharacterStats {
    // Validação de nível — proteção contra níveis inválidos
    const safeLevel: number =
      Number.isFinite(currentLevel) && currentLevel >= 1
        ? Math.floor(currentLevel)
        : 1;

    // ================================================================
    // Cálculo do DRF (Diminishing Returns Factor)
    // drf = level^0.7
    // Quanto maior o nível, menor o ganho relativo por nível adicional
    // ================================================================

    const drf: number = Math.pow(safeLevel, ProgressionManager.DRF_EXPONENT);

    // ================================================================
    // Escalabilidade com aplicação dos caps máximos
    // ================================================================

    // Dano: cap 250
    const scaledDamage: number = Math.min(
      ProgressionManager.DAMAGE_CAP,
      Math.floor(baseStats.damage * drf),
    );

    // Defesa: cap 200
    const scaledDefense: number = Math.min(
      ProgressionManager.DEFENSE_CAP,
      Math.floor(baseStats.defense * drf),
    );

    // Resiliência: cap 180
    const scaledResilience: number = Math.min(
      ProgressionManager.RESILIENCE_CAP,
      Math.floor(baseStats.resilience * drf),
    );

    // ================================================================
    // Retorna cópia completa das estatísticas com valores escalados
    // maxHp, currentHp e movementSpeed permanecem inalterados
    // ================================================================

    return {
      maxHp: baseStats.maxHp,
      currentHp: baseStats.currentHp,
      damage: scaledDamage,
      defense: scaledDefense,
      resilience: scaledResilience,
      movementSpeed: baseStats.movementSpeed,
    };
  }

  // ==================================================================
  // MÉTODOS DE GERENCIAMENTO DE XP
  // ==================================================================

  /**
   * getXp(character)
   * ------------------------------------------------------------------
   * Obtém a quantidade atual de XP acumulada de um personagem.
   *
   * @param character - Instância de CharacterState do personagem
   * @returns XP acumulado (0 se não registrado)
   */
  public getXp(character: CharacterState): number {
    return this.xpMap.get(character) ?? 0;
  }

  /**
   * setXp(character, xp)
   * ------------------------------------------------------------------
   * Define diretamente a quantidade de XP acumulada de um personagem.
   * Útil para inicialização de saves ou testes.
   *
   * NOTA: Este método NÃO processa cascata de level-up. Para injeção
   * de XP com processamento completo, use addExperience().
   *
   * @param character - Instância de CharacterState do personagem
   * @param xp - Novo valor de XP (deve ser >= 0)
   */
  public setXp(character: CharacterState, xp: number): void {
    if (!Number.isFinite(xp) || xp < 0) {
      return;
    }
    this.xpMap.set(character, Math.floor(xp));
  }

  /**
   * resetXp(character)
   * ------------------------------------------------------------------
   * Reseta o XP acumulado de um personagem para zero.
   *
   * @param character - Instância de CharacterState do personagem
   */
  public resetXp(character: CharacterState): void {
    this.xpMap.delete(character);
  }

  // ==================================================================
  // MÉTODOS DE EVENTO
  // ==================================================================

  /**
   * dispatchEvent(eventId, payload)
   * ------------------------------------------------------------------
   * Dispara um evento no barramento de dados do motor, se um callback
   * estiver registrado.
   *
   * @param eventId - ID do evento (ex: "EVT_REVELACAO_LINHAGEM")
   * @param payload - Dados adicionais do evento
   */
  private dispatchEvent(
    eventId: string,
    payload?: Record<string, unknown>,
  ): void {
    if (this._eventBusCallback) {
      try {
        this._eventBusCallback(eventId, payload);
      } catch (error) {
        // Falha no callback não deve quebrar o estado do ProgressionManager
        console.error(
          `[ProgressionManager] Erro ao disparar evento ${eventId}:`,
          error,
        );
      }
    }
  }

  // ==================================================================
  // MÉTODOS DE UTILIDADE E SERIALIZAÇÃO
  // ==================================================================

  /**
   * getXpMap()
   * ------------------------------------------------------------------
   * Retorna uma cópia do mapa de XP para fins de persistência.
   *
   * NOTA: Como as chaves são referências de objeto, este método
   * retorna um array de pares [level, xp] serializáveis.
   * Para reconstituição, use setXp() para cada personagem.
   *
   * @returns Array de pares [levelAtual, xp] para serialização
   */
  public getXpSnapshot(): Array<{ level: number; xp: number }> {
    const snapshot: Array<{ level: number; xp: number }> = [];
    this.xpMap.forEach((xp) => {
      snapshot.push({ level: 0, xp }); // level placeholder (não armazenamos level no mapa)
    });
    return snapshot;
  }

  /**
   * clear()
   * ------------------------------------------------------------------
   * Limpa todos os dados de XP gerenciados por esta instância.
   * Útil para resetar o estado entre sessões de teste.
   */
  public clear(): void {
    this.xpMap.clear();
  }
}