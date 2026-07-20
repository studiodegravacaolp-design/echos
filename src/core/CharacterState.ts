/**
 * ====================================================================
 * CharacterState.ts
 * --------------------------------------------------------------------
 * Implementação do estado do jogador no Projeto Aetheris.
 * Encapsula as variáveis do GDD:
 *   - short_term_estafa (medidor de estafa de curto prazo)
 *   - latent_lineage_axis (eixo de linhagem latente)
 *   - currentLevel (nível atual do personagem)
 *
 * Fonte: docs/04_arquitetura_software/ENG-ESTRUTURA-DADOS.md
 *        docs/04_arquitetura_software/ENG-MOTOR-COMBATE.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import {
  LatentLineageAxis,
  ICharacterStats,
  IStatusEffect,
  IEquipment,
  IEquipmentItem,
  IEquipmentStats,
  SlotType,
  ErrorCodes,
  EventIds,
  Race,
} from '../types/aetheris.types';
import {
  EstafaCalculator,
  EstafaModifiers,
} from '../mechanics/EstafaCalculator';

/**
 * Interface para callback de eventos disparados pelo CharacterState.
 */
export interface IStateEventCallback {
  (eventId: string, payload?: Record<string, unknown>): void;
}

/**
 * Interface para callback de log de segurança.
 */
export interface ISecurityLogCallback {
  (errorCode: string, message: string): void;
}

/**
 * Classe CharacterState
 * --------------------------------------------------------------------
 * Gerencia o estado encapsulado de um personagem, incluindo:
 * - Medidor de estafa de curto prazo (shortTermEstafa)
 * - Eixo de linhagem latente (latentLineageAxis) — oculto até level 36
 * - Nível atual (currentLevel) — iniciado em 1, teto rígido no 50
 *
 * Aplicação rigorosa de:
 *   - Clamp estrito em [-100, 100] para estafa via enforceEstafaOntologicalLock()
 *   - Ocultação de linhagem para level < 36
 *   - Eventos de borda (Fratura de Frenesi / Estagnação Tática)
 *   - Log de segurança MON-ERR-032 para acesso indevido à linhagem
 */
export class CharacterState {
  // ==================================================================
  // CONSTANTES
  // ==================================================================

  /** Clamp mínimo do medidor de estafa */
  public static readonly ESTAFA_MIN = -100;

  /** Clamp máximo do medidor de estafa */
  public static readonly ESTAFA_MAX = 100;

  /** Valor padrão do medidor de estafa */
  public static readonly ESTAFA_DEFAULT = 0;

  /** Nível inicial do personagem */
  public static readonly LEVEL_INITIAL = 1;

  /** Teto rígido de nível máximo */
  public static readonly LEVEL_MAX = 50;

  /** Nível mínimo para revelação da linhagem (Ato 4) */
  public static readonly LINEAGE_UNLOCK_LEVEL = 36;

  // ==================================================================
  // PROPRIEDADES PRIVADAS
  // ==================================================================

  /** Medidor de estafa de curto prazo — clamp obrigatório em [-100, 100] */
  private _shortTermEstafa: number;

  /** Eixo de linhagem latente — protegido até level >= 36 */
  private _latentLineageAxis: LatentLineageAxis;

  /** Nível atual do personagem — teto rígido no nível 50 */
  private _currentLevel: number;

  /** Estatísticas base do personagem */
  private _stats: ICharacterStats;

  /** Efeitos de status ativos no personagem */
  private _statusEffects: IStatusEffect[];

  /** Flag que indica se a barra de estafa está congelada (ESTAGNACAO_TATICA) */
  private _estafaFrozen: boolean;

  /** Flag que controla re-armamento do trigger de Fratura de Frenesi */
  private _frenesiTriggerArmed: boolean;

  /** Flag que controla re-armamento do trigger de Estagnação Tática */
  private _estagnacaoTriggerArmed: boolean;

  /** Equipamento ativo do personagem (armadura) */
  private _equipment: IEquipment | null;

  /** Peso cumulativo do inventário (injetado via syncWeightWithCharacter) */
  private _inventoryWeight: number;

  /** Callback externo para disparo de eventos do motor */
  private _eventCallback: IStateEventCallback | null;

  /** Callback externo para log de segurança */
  private _securityLogCallback: ISecurityLogCallback | null;

  /** Raça nativa do personagem (fraquezas elementais permanentes) */
  private _race: Race | null;

  /** Identificador único do personagem (usado para referência externa) */
  private _id: string;

  /** Contagem de sucata acumulada (ISalvageInventory.scrapCount) */
  private _scrapCount: number;

  /** Cargas do kit de Engenharia Elemental por elemento */
  private _engineeringCharges: Record<string, number>;

  /** Mapa de equipamentos ativos indexados por slot (WEAPON | ARMOR | CORE_MOD) */
  private _equippedItems: Partial<Record<SlotType, IEquipmentItem>>;

  /** Bônus cumulativos de atributos concedidos pelos equipamentos ativos */
  private _equipmentBonusStats: IEquipmentStats;

  // ==================================================================
  // CONSTRUTOR
  // ==================================================================

  /**
   * Cria uma nova instância de CharacterState.
   *
   * @param stats - Estatísticas base do personagem
   * @param latentLineageAxis - Eixo de linhagem latente (padrão: NEUTRO_ABSOLUTO)
   * @param eventCallback - Callback opcional para disparo de eventos
   * @param securityLogCallback - Callback opcional para log de segurança
   * @param race - Raça nativa do personagem (padrão: null — sem raça definida)
   * @param id - Identificador único do personagem (gerado automaticamente se omitido)
   */
  constructor(
    stats: ICharacterStats,
    latentLineageAxis: LatentLineageAxis = LatentLineageAxis.NEUTRO_ABSOLUTO,
    eventCallback?: IStateEventCallback,
    securityLogCallback?: ISecurityLogCallback,
    race: Race | null = null,
    id?: string,
  ) {
    this._shortTermEstafa = CharacterState.ESTAFA_DEFAULT;
    this._latentLineageAxis = latentLineageAxis;
    this._currentLevel = CharacterState.LEVEL_INITIAL;
    this._stats = { ...stats };
    this._statusEffects = [];
    this._estafaFrozen = false;
    this._frenesiTriggerArmed = true;
    this._estagnacaoTriggerArmed = true;
    this._equipment = null;
    this._inventoryWeight = 0;
    this._eventCallback = eventCallback ?? null;
    this._securityLogCallback = securityLogCallback ?? null;
    this._race = race;
    this._id = id ?? `char_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    this._scrapCount = 0;
    this._engineeringCharges = {};
    this._equippedItems = {};
    this._equipmentBonusStats = {};
  }

  // ==================================================================
  // GETTERS E SETTERS — SHORT_TERM_ESTAFA
  // ==================================================================

  /**
   * Obtém o valor atual do medidor de estafa de curto prazo.
   */
  get shortTermEstafa(): number {
    return this._shortTermEstafa;
  }

  /**
   * Define o valor do medidor de estafa de curto prazo.
   *
   * Aplica clamp estrito via enforceEstafaOntologicalLock().
   * Se a barra estiver congelada (ESTAGNACAO_TATICA), o valor NÃO é alterado.
   * Dispara eventos de borda se os limites forem atingidos.
   *
   * @param value - Novo valor desejado para o medidor
   */
  set shortTermEstafa(value: number) {
    // ================================================================
    // Verificação de congelamento da barra (ESTAGNACAO_TATICA)
    // Enquanto o estado estiver ativo, nenhum delta_m é aplicado.
    // Fonte: ENG-MOTOR-COMBATE Seção 4.3.2
    // ================================================================
    if (this._estafaFrozen) {
      return;
    }

    // Armazena o valor anterior para o log de depuração
    const previousValue = this._shortTermEstafa;

    // Aplica o novo valor (ainda sem clamp)
    this._shortTermEstafa = value;

    // ================================================================
    // enforceEstafaOntologicalLock()
    // Garante bounds safety absoluta e dispara triggers de borda.
    // O clamp DEVE ser aplicado ANTES de qualquer propagação de evento.
    // Fonte: ENG-ESTRUTURA-DADOS Seção 2.2
    // ================================================================
    this.enforceEstafaOntologicalLock(previousValue);
  }

  // ==================================================================
  // GETTERS E SETTERS — LATENT_LINEAGE_AXIS
  // ==================================================================

  /**
   * Obtém o eixo de linhagem latente.
   *
   * REGRA DE OCULTAÇÃO (MON-ERR-032):
   * - Se _currentLevel < 36, retorna OBRIGATORIAMENTE NEUTRO_ABSOLUTO.
   * - Isso blinda o pool de dados de UI e leitura de IAs inimigas
   *   contra vazamentos prematuros de lore.
   * Fonte: ENG-ESTRUTURA-DADOS Seção 3.2.3
   */
  get latentLineageAxis(): LatentLineageAxis {
    if (this._currentLevel < CharacterState.LINEAGE_UNLOCK_LEVEL) {
      return LatentLineageAxis.NEUTRO_ABSOLUTO;
    }
    return this._latentLineageAxis;
  }

  /**
   * Define o eixo de linhagem latente.
   * Apenas sistemas autorizados (narrativa, salvamento) devem chamar este setter.
   *
   * @param value - Novo valor do eixo de linhagem
   */
  set latentLineageAxis(value: LatentLineageAxis) {
    this._latentLineageAxis = value;

    // Se o nível já for >= 36, dispara o evento de revelação
    if (this._currentLevel >= CharacterState.LINEAGE_UNLOCK_LEVEL) {
      this.dispatchEvent(EventIds.EVT_REVELACAO_LINHAGEM, {
        lineageAxis: value,
        level: this._currentLevel,
      });
    }
  }

  // ==================================================================
  // GETTERS E SETTERS — CURRENT_LEVEL
  // ==================================================================

  /**
   * Obtém o nível atual do personagem.
   */
  get currentLevel(): number {
    return this._currentLevel;
  }

  /**
   * Define o nível atual do personagem.
   *
   * REGRAS:
   * - Nível inicial: 1
   * - Teto rígido: nível 50 (qualquer valor acima é truncado)
   * - Se o nível cruzar o patamar 36 (>= 36) e a linhagem já estiver
   *   definida como não-neutra, dispara EVT_REVELACAO_LINHAGEM.
   *
   * @param value - Novo nível desejado
   */
  set currentLevel(value: number) {
    const previousLevel = this._currentLevel;

    // Teto rígido no nível 50
    if (value > CharacterState.LEVEL_MAX) {
      value = CharacterState.LEVEL_MAX;
    }

    // Piso no nível 1
    if (value < CharacterState.LEVEL_INITIAL) {
      value = CharacterState.LEVEL_INITIAL;
    }

    this._currentLevel = value;

    // Verifica se o nível cruzou o patamar 36 (revelação da linhagem)
    if (
      previousLevel < CharacterState.LINEAGE_UNLOCK_LEVEL &&
      this._currentLevel >= CharacterState.LINEAGE_UNLOCK_LEVEL &&
      this._latentLineageAxis !== LatentLineageAxis.NEUTRO_ABSOLUTO
    ) {
      this.dispatchEvent(EventIds.EVT_REVELACAO_LINHAGEM, {
        lineageAxis: this._latentLineageAxis,
        level: this._currentLevel,
      });
    }
  }

  // ==================================================================
  // GETTERS — STATS E STATUS EFFECTS
  // ==================================================================

  /**
   * Obtém as estatísticas base do personagem (cópia defensiva).
   */
  get stats(): ICharacterStats {
    return { ...this._stats };
  }

  /**
   * Obtém a lista de efeitos de status ativos (cópia defensiva).
   */
  get statusEffects(): IStatusEffect[] {
    return [...this._statusEffects];
  }

  /**
   * Obtém a flag de congelamento da barra de estafa.
   */
  get estafaFrozen(): boolean {
    return this._estafaFrozen;
  }

  /**
   * Define a flag de congelamento da barra de estafa.
   * Usado pelo estado ESTAGNACAO_TATICA.
   */
  set estafaFrozen(value: boolean) {
    this._estafaFrozen = value;
  }

  // ==================================================================
  // GETTERS E SETTERS — INVENTORY WEIGHT
  // ==================================================================

  /**
   * Obtém o peso cumulativo do inventário.
   * Este valor é injetado externamente via syncWeightWithCharacter.
   */
  get inventoryWeight(): number {
    return this._inventoryWeight;
  }

  /**
   * Define o peso cumulativo do inventário.
   * Usado pelo InventoryManager.syncWeightWithCharacter() para
   * propagar o peso total da carga no personagem.
   *
   * @param value - Peso total do inventário
   */
  set inventoryWeight(value: number) {
    this._inventoryWeight = value < 0 ? 0 : value;
  }

  // ==================================================================
  // GETTERS E SETTERS — EQUIPMENT
  // ==================================================================

  /**
   * Obtém o equipamento ativo do personagem.
   * Retorna null se nenhum equipamento estiver equipado.
   */
  get equipment(): IEquipment | null {
    return this._equipment ? { ...this._equipment } : null;
  }

  /**
   * Define o equipamento ativo do personagem.
   * O equipamento influencia o cálculo de velocidade de movimento
   * através do atrito físico (peso × coeficiente de material).
   *
   * @param value - Equipamento a equipar, ou null para remover
   */
  set equipment(value: IEquipment | null) {
    this._equipment = value ? { ...value } : null;
  }

  // ==================================================================
  // GETTER — RACE
  // ==================================================================

  /**
   * Obtém a raça nativa do personagem, ou null se não definida.
   * Raça é imutável após a criação do personagem (definida apenas
   * via construtor) — não há setter público.
   */
  get race(): Race | null {
    return this._race;
  }

  // ==================================================================
  // MÉTODOS DE GERENCIAMENTO DE PONTOS DE VIDA
  // ==================================================================

  /**
   * applyDirectDamage(amount)
   * ------------------------------------------------------------------
   * Aplica dano direto aos pontos de vida atuais do personagem,
   * ignorando mitigação de armadura (usado por efeitos que já
   * calcularam o dano final, ex: Regra do Retrocesso de skills).
   *
   * `stats` é exposto apenas como cópia defensiva (getter), então
   * este é o único caminho externo válido para reduzir currentHp.
   *
   * @param amount - Quantidade de dano a aplicar (deve ser > 0)
   */
  public applyDirectDamage(amount: number): void {
    if (!Number.isFinite(amount) || amount <= 0) {
      return;
    }

    this._stats.currentHp = Math.max(0, this._stats.currentHp - amount);
  }

  // ==================================================================
  // MÉTODO DE SEGURANÇA RÍGIDO — enforceEstafaOntologicalLock
  // ==================================================================

  /**
   * enforceEstafaOntologicalLock()
   * ------------------------------------------------------------------
   * Garante bounds safety absoluta do medidor de estafa.
   * Deve ser chamado a cada alteração do _shortTermEstafa.
   *
   * Regras:
   * 1. Se _shortTermEstafa > 100: trunca para 100 e dispara EVT_FRATURA_FRENESI
   * 2. Se _shortTermEstafa < -100: trunca para -100 e dispara EVT_ESTAGNACAO_TATICA
   * 3. Nenhuma operação pode exceder os limites — truncamento obrigatório
   * 4. Violação NÃO DEVE causar overflow ou wrap-around
   * 5. Re-armamento: o trigger só re-dispara após sair completamente do estado
   *
   * Fonte: ENG-ESTRUTURA-DADOS Seção 2.2 e 2.3
   *        ENG-MOTOR-COMBATE Seção 4.5 (re-armamento)
   *
   * @param previousValue - Valor anterior do medidor (para logging)
   */
  public enforceEstafaOntologicalLock(previousValue?: number): void {
    const prev = previousValue ?? this._shortTermEstafa;

    // ================================================================
    // Verificação de clamp — limite SUPERIOR (+100)
    // Dispara EVT_FRATURA_FRENESI se o limite for atingido/excedido
    // ================================================================

    if (this._shortTermEstafa > CharacterState.ESTAFA_MAX) {
      this._shortTermEstafa = CharacterState.ESTAFA_MAX;

      // Log de warning BOUNDS-001
      this.logSecurityWarning(
        ErrorCodes.BOUNDS_001,
        `short_term_estafa excedeu limite superior (+100). Truncado para 100. ` +
        `Previous: ${prev}, Attempted: ${this._shortTermEstafa}`,
      );

      // Dispara trigger apenas se o re-armamento estiver ativo
      if (this._frenesiTriggerArmed) {
        this._frenesiTriggerArmed = false; // Desarma até sair do estado
        this._estagnacaoTriggerArmed = true; // Re-armamento do outro estado

        this.dispatchEvent(EventIds.EVT_FRATURA_FRENESI, {
          source: 'CharacterState.enforceEstafaOntologicalLock',
          previousValue: prev,
          finalValue: this._shortTermEstafa,
          timestamp: Date.now(),
        });
      }
    }

    // ================================================================
    // Verificação de clamp — limite INFERIOR (-100)
    // Dispara EVT_ESTAGNACAO_TATICA se o limite for atingido/excedido
    // ================================================================

    if (this._shortTermEstafa < CharacterState.ESTAFA_MIN) {
      this._shortTermEstafa = CharacterState.ESTAFA_MIN;

      // Log de warning BOUNDS-001
      this.logSecurityWarning(
        ErrorCodes.BOUNDS_001,
        `short_term_estafa excedeu limite inferior (-100). Truncado para -100. ` +
        `Previous: ${prev}, Attempted: ${this._shortTermEstafa}`,
      );

      // Dispara trigger apenas se o re-armamento estiver ativo
      if (this._estagnacaoTriggerArmed) {
        this._estagnacaoTriggerArmed = false; // Desarma até sair do estado
        this._frenesiTriggerArmed = true; // Re-armamento do outro estado

        this.dispatchEvent(EventIds.EVT_ESTAGNACAO_TATICA, {
          source: 'CharacterState.enforceEstafaOntologicalLock',
          previousValue: prev,
          finalValue: this._shortTermEstafa,
          timestamp: Date.now(),
        });
      }
    }

    // ================================================================
    // Re-armamento de triggers quando o medidor sai da zona de colapso
    // Se o valor atual está dentro dos limites normais, re-arma ambos
    // ================================================================

    if (
      this._shortTermEstafa > CharacterState.ESTAFA_MIN &&
      this._shortTermEstafa < CharacterState.ESTAFA_MAX &&
      (!this._frenesiTriggerArmed || !this._estagnacaoTriggerArmed)
    ) {
      this._frenesiTriggerArmed = true;
      this._estagnacaoTriggerArmed = true;
    }
  }

  // ==================================================================
  // MÉTODO DE ACESSO SEGURO À LINHAGEM — getSafeLatentLineage
  // ==================================================================

  /**
   * getSafeLatentLineage(requestingSystem)
   * ------------------------------------------------------------------
   * Método protegido de acesso à linhagem que implementa as regras
   * de segurança MON-ERR-032.
   *
   * Sistemas de IA e UI recebem null e têm o erro registrado.
   * Sistemas autorizados (narrativa, salvamento) recebem o valor real
   * apenas se level >= 36.
   *
   * Fonte: ENG-ESTRUTURA-DADOS Seção 3.2.2
   *
   * @param requestingSystem - String identificando o sistema requisitante
   *                           ("AI", "UI", "NARRATIVE", "SAVE_SYSTEM", etc.)
   * @returns O valor do eixo de linhagem, ou NEUTRO_ABSOLUTO se bloquear
   */
  public getSafeLatentLineage(requestingSystem: string): LatentLineageAxis {
    // ================================================================
    // Bloqueio para sistemas não autorizados (IA e UI)
    // Fonte: ENG-ESTRUTURA-DADOS Seção 3.2.2
    // ================================================================

    if (requestingSystem === 'AI' || requestingSystem === 'UI') {
      this.logSecurityError(
        ErrorCodes.MON_ERR_032,
        `Tentativa de acesso a latent_lineage_axis por sistema não autorizado: ${requestingSystem}. ` +
        `Personagem: ${this._stats.currentHp > 0 ? 'vivo' : 'morto'}.`,
      );
      return LatentLineageAxis.NEUTRO_ABSOLUTO;
    }

    // ================================================================
    // Bloqueio por nível — liberado apenas a partir do nível 36 (Ato 4)
    // Fonte: ENG-ESTRUTURA-DADOS Seção 3.2.3
    // ================================================================

    if (this._currentLevel < CharacterState.LINEAGE_UNLOCK_LEVEL) {
      return LatentLineageAxis.NEUTRO_ABSOLUTO;
    }

    // ================================================================
    // Acesso autorizado — retorna o valor real
    // ================================================================

    return this._latentLineageAxis;
  }

  // ==================================================================
  // MÉTODOS DE GERENCIAMENTO DE STATUS EFFECTS
  // ==================================================================

  /**
   * Adiciona um efeito de status ao personagem.
   *
   * @param effect - Efeito de status a ser aplicado
   * @returns true se o efeito foi aplicado, false se já existia
   */
  public addStatusEffect(effect: IStatusEffect): boolean {
    const existingIndex = this._statusEffects.findIndex(
      (e) => e.id === effect.id,
    );

    if (existingIndex >= 0) {
      return false; // Já existe — não duplica
    }

    this._statusEffects.push({ ...effect });

    // Se o efeito congela a barra, atualiza a flag
    if (effect.flags.freezesEstafaBar) {
      this._estafaFrozen = true;
    }

    return true;
  }

  /**
   * Remove um efeito de status do personagem.
   *
   * @param effectId - ID do efeito a ser removido
   * @returns true se o efeito foi removido, false se não encontrado
   */
  public removeStatusEffect(effectId: string): boolean {
    const index = this._statusEffects.findIndex((e) => e.id === effectId);

    if (index < 0) {
      return false;
    }

    const removedEffect = this._statusEffects[index];

    // Se o efeito congelava a barra, descongela
    if (removedEffect.flags.freezesEstafaBar) {
      this._estafaFrozen = false;
    }

    this._statusEffects.splice(index, 1);
    return true;
  }

  /**
   * Verifica se o personagem possui um efeito de status específico.
   *
   * @param effectId - ID do efeito a verificar
   * @returns true se o efeito está ativo
   */
  public hasStatusEffect(effectId: string): boolean {
    return this._statusEffects.some((e) => e.id === effectId);
  }

  /**
   * decrementStatusEffectDuration(effectId)
   * ------------------------------------------------------------------
   * Decrementa em 1 a duração restante (remainingDuration) de um
   * efeito de status ativo. Remove o efeito automaticamente
   * (via removeStatusEffect) se a duração chegar a zero ou menos.
   *
   * Muta o efeito internamente — não passa pela cópia defensiva do
   * getter `statusEffects`.
   *
   * @param effectId - ID do efeito a decrementar
   * @returns true se o efeito estava ativo e foi decrementado, false
   *          se o efeito não estava ativo
   */
  public decrementStatusEffectDuration(effectId: string): boolean {
    const effect = this._statusEffects.find((e) => e.id === effectId);

    if (!effect) {
      return false;
    }

    effect.remainingDuration -= 1;

    if (effect.remainingDuration <= 0) {
      this.removeStatusEffect(effectId);
    }

    return true;
  }

  // ==================================================================
  // MÉTODOS DE EVENTO E LOG
  // ==================================================================

  /**
   * Dispara um evento no barramento global do motor, se um callback
   * estiver registrado.
   *
   * @param eventId - ID do evento (ex: "EVT_FRATURA_FRENESI")
   * @param payload - Dados adicionais do evento
   */
  private dispatchEvent(
    eventId: string,
    payload?: Record<string, unknown>,
  ): void {
    if (this._eventCallback) {
      try {
        this._eventCallback(eventId, payload);
      } catch (error) {
        // Falha no callback não deve quebrar o estado do personagem
        this.logSecurityError(
          'EVENT-DISPATCH-ERR',
          `Falha ao disparar evento ${eventId}: ${String(error)}`,
        );
      }
    }
  }

  /**
   * Registra um erro de segurança no log.
   *
   * @param errorCode - Código do erro (ex: "MON-ERR-032")
   * @param message - Mensagem descritiva do erro
   */
  private logSecurityError(errorCode: string, message: string): void {
    if (this._securityLogCallback) {
      try {
        this._securityLogCallback(errorCode, message);
      } catch {
        // Falha no log não deve quebrar o estado
      }
    }
  }

  /**
   * Registra um aviso de segurança no log.
   *
   * @param errorCode - Código do warning (ex: "BOUNDS-001")
   * @param message - Mensagem descritiva do warning
   */
  private logSecurityWarning(errorCode: string, message: string): void {
    if (this._securityLogCallback) {
      try {
        this._securityLogCallback(errorCode, message);
      } catch {
        // Falha no log não deve quebrar o estado
      }
    }
  }

  // ==================================================================
  // MÉTODOS DE UTILIDADE E SERIALIZAÇÃO
  // ==================================================================

  /**
   * Reinicia o medidor de estafa para o valor padrão (0).
   * Útil ao iniciar um novo combate.
   */
  public resetEstafa(): void {
    this._shortTermEstafa = CharacterState.ESTAFA_DEFAULT;
    this._estafaFrozen = false;
    this._frenesiTriggerArmed = true;
    this._estagnacaoTriggerArmed = true;
  }

  /**
   * Verifica se o personagem está em estado de colapso (overload).
   *
   * @returns O ID do estado de colapso ativo, ou null se nenhum
   */
  public getActiveOverloadState(): string | null {
    if (this.hasStatusEffect('FRATURA_FRENESI')) {
      return 'FRATURA_FRENESI';
    }
    if (this.hasStatusEffect('ESTAGNACAO_TATICA')) {
      return 'ESTAGNACAO_TATICA';
    }
    return null;
  }

  // ==================================================================
  // GETTER — ID
  // ==================================================================

  /**
   * Obtém o identificador único do personagem.
   */
  get id(): string {
    return this._id;
  }

  // ==================================================================
  // GETTERS CONVENIENTES — HP / MAX_HP
  // ==================================================================

  /**
   * Obtém os pontos de vida atuais do personagem.
   * Atalho para stats.currentHp.
   */
  get hp(): number {
    return this._stats.currentHp;
  }

  /**
   * Define os pontos de vida atuais do personagem.
   * Atalho para stats.currentHp (clamp automático em [0, maxHp]).
   * O clamp considera o maxHp expandido por equipamentos.
   */
  set hp(value: number) {
    this._stats.currentHp = Math.max(0, Math.min(this.maxHp, value));
  }

  /**
   * Obtém os pontos de vida máximos do personagem.
   * Soma o valor base (stats.maxHp) com os bônus de equipamento.
   * Usado pelo EquipmentEngine para expandir o limite tático.
   */
  get maxHp(): number {
    return this._stats.maxHp + (this._equipmentBonusStats.bonusMaxHp ?? 0);
  }

  // ==================================================================
  // ATRIBUTOS DINÂMICOS — MODULADOS PELA BALANÇA DE ESTAFA
  // ==================================================================
  // Delegam ao EstafaCalculator (src/mechanics/EstafaCalculator.ts) para
  // aplicar os bônus/penalidades dinâmicos definidos na System Matrix
  // (AETHERIS_MASTER_INDEX.md §2) sobre os atributos finais da unidade.
  // Todos os métodos são consultas puras — não mutam o estado base.
  // ==================================================================

  /**
   * getEstafaModifiers()
   * ------------------------------------------------------------------
   * Retorna os modificadores dinâmicos da Balança de Estafa para o
   * valor atual do medidor de curto prazo.
   */
  public getEstafaModifiers(): EstafaModifiers {
    return EstafaCalculator.calculateModifiers(this._shortTermEstafa);
  }

  /**
   * getEffectivePhysicalDefense()
   * ------------------------------------------------------------------
   * Defesa física efetiva = (defesa base + bônus de equipamento) ajustada
   * pela Estafa. O lado Paterno concede physicalDefBonus (rigidez); o
   * lado Materno aplica armorPenalty (perda de eficiência de armadura).
   * Apenas um dos lados está ativo por vez (ver EstafaCalculator).
   */
  public getEffectivePhysicalDefense(): number {
    const baseDefense =
      this._stats.defense + (this._equipmentBonusStats.bonusDefense ?? 0);
    const mods = this.getEstafaModifiers();
    const factor = 1 + mods.physicalDefBonus / 100 - mods.armorPenalty / 100;
    return Math.max(0, baseDefense * factor);
  }

  /**
   * getEpRegenBonusPercent()
   * ------------------------------------------------------------------
   * Bônus percentual de regeneração de EP por turno concedido pela
   * Estafa (lado Materno). Zero fora do lado Materno.
   */
  public getEpRegenBonusPercent(): number {
    return this.getEstafaModifiers().epRegenBonus;
  }

  /**
   * getEffectiveEpCost(baseCost)
   * ------------------------------------------------------------------
   * Custo de EP efetivo de uma habilidade após o encarecimento imposto
   * pelo lado Paterno (epCostIncrease). No extremo Paterno (+100) o custo
   * de habilidades mágicas/complexas sobe +30%.
   *
   * @param baseCost - Custo base de EP da habilidade (deve ser > 0)
   */
  public getEffectiveEpCost(baseCost: number): number {
    if (!Number.isFinite(baseCost) || baseCost <= 0) {
      return 0;
    }
    const mods = this.getEstafaModifiers();
    return baseCost * (1 + mods.epCostIncrease / 100);
  }

  // ==================================================================
  // GETTERS — EQUIPMENT SLOTS & BONUS
  // ==================================================================

  /**
   * Obtém o mapa de equipamentos ativos indexados por slot.
   * Retorna o objeto interno diretamente — o EquipmentEngine precisa
   * de acesso de mutação para operações de equipar/desequipar.
   */
  get equippedItems(): Partial<Record<SlotType, IEquipmentItem>> {
    return this._equippedItems;
  }

  /**
   * Obtém os bônus cumulativos de atributos concedidos pelos equipamentos ativos.
   */
  get equipmentBonusStats(): IEquipmentStats {
    return { ...this._equipmentBonusStats };
  }

  /**
   * Define os bônus cumulativos de atributos.
   * Usado exclusivamente pelo EquipmentEngine.applyStatsModifiers().
   */
  set equipmentBonusStats(value: IEquipmentStats) {
    this._equipmentBonusStats = { ...value };
  }

  // ==================================================================
  // CAMPOS DE PERSISTÊNCIA DE ENGENHARIA — ISalvageInventory e IEngineeringKit
  // ==================================================================

  /**
   * Obtém a contagem de sucata acumulada.
   */
  get scrapCount(): number {
    return this._scrapCount;
  }

  /**
   * Define a contagem de sucata acumulada.
   * @param value - Novo valor de sucata (não pode ser negativo)
   */
  set scrapCount(value: number) {
    this._scrapCount = value < 0 ? 0 : value;
  }

  /**
   * Obtém uma cópia das cargas do kit de engenharia.
   */
  get engineeringCharges(): Record<string, number> {
    return { ...this._engineeringCharges };
  }

  /**
   * Define as cargas do kit de engenharia.
   * @param charges - Mapa de elemento para quantidade de cargas
   */
  set engineeringCharges(charges: Record<string, number>) {
    this._engineeringCharges = { ...charges };
  }

  /**
   * Retorna uma representação serializável do estado do personagem
   * para persistência em save game.
   *
   * NOTA: O medidor shortTermEstafa NÃO persiste entre sessões.
   * Fonte: ENG-ESTRUTURA-DADOS Seção 2.1
   * Sprint 10: Inclui scrapCount e engineeringCharges nativamente.
   */
  public toJSON(): Record<string, unknown> {
    return {
      id: this._id,
      level: this._currentLevel,
      stats: { ...this._stats },
      latentLineageAxis: this._latentLineageAxis,
      scrapCount: this._scrapCount,
      engineeringCharges: { ...this._engineeringCharges },
    };
  }

  /**
   * Cria uma instância de CharacterState a partir de dados serializados.
   *
   * @param data - Dados serializados do personagem
   * @param stats - Estatísticas base do personagem
   * @param eventCallback - Callback opcional para eventos
   * @param securityLogCallback - Callback opcional para log de segurança
   * @returns Nova instância de CharacterState
   */
  public static fromJSON(
    data: { id?: string; level?: number; latentLineageAxis?: LatentLineageAxis; scrapCount?: number; engineeringCharges?: Record<string, number> },
    stats: ICharacterStats,
    eventCallback?: IStateEventCallback,
    securityLogCallback?: ISecurityLogCallback,
  ): CharacterState {
    const state = new CharacterState(
      stats,
      data.latentLineageAxis ?? LatentLineageAxis.NEUTRO_ABSOLUTO,
      eventCallback,
      securityLogCallback,
      undefined,
      data.id,
    );

    if (data.level !== undefined) {
      state._currentLevel = Math.max(
        CharacterState.LEVEL_INITIAL,
        Math.min(CharacterState.LEVEL_MAX, data.level),
      );
    }

    // Sprint 10: Restaura campos de engenharia salvos
    state._scrapCount = Number.isFinite(data.scrapCount) && data.scrapCount! >= 0 ? Math.floor(data.scrapCount!) : 0;
    state._engineeringCharges = data.engineeringCharges !== undefined ? { ...data.engineeringCharges } : {};

    return state;
  }
}