/**
 * EstafaCalculator.ts
 *
 * Módulo puro de cálculo da Balança de Estafa do Aetheris.
 *
 * A Balança de Estafa oscila em um eixo dinâmico de -100 (Materno) a +100 (Paterno)
 * e molda tanto o combate (modificadores de atributos) quanto a UI diegética
 * (Insubordinação Tática / bloqueio de ações incompatíveis com a psique do líder).
 *
 * Referências canônicas:
 *   - AETHERIS_MASTER_INDEX.md § 2 (System Matrix)
 *   - docs/mechanics/ESTAFA_SYSTEM.md
 *
 * Todos os métodos são estáticos e puros (sem estado, sem efeitos colaterais)
 * para garantir facilidade de teste e desacoplamento dos motores de jogo.
 */

// ---------------------------------------------------------------------------
// LIMITES CANÔNICOS
// ---------------------------------------------------------------------------

/** Limite mínimo do medidor de estafa (extremo Materno). */
export const ESTAFA_MIN = -100;

/** Limite máximo do medidor de estafa (extremo Paterno). */
export const ESTAFA_MAX = 100;

// ---------------------------------------------------------------------------
// TIPAGENS E ENUMS
// ---------------------------------------------------------------------------

/**
 * Quadrantes psicológicos da Balança de Estafa.
 * Define o "humor tático" da unidade líder e quais ações a UI libera ou trava.
 */
export enum EstafaQuadrant {
  /** Zona equilibrada (-20 a +20): nenhuma restrição diegética. */
  NEUTRAL = 'NEUTRAL',
  /** Empatia Ativa (<= -60): foco em preservação; bloqueia frieza/execução. */
  MATERNO_EXTREMO = 'MATERNO_EXTREMO',
  /** Cálculo Tático (>= +60): foco em rigidez; bloqueia compaixão/partilha. */
  PATERNO_EXTREMO = 'PATERNO_EXTREMO',
}

/**
 * Modificadores de combate derivados do valor atual da estafa.
 * Todos os campos são porcentagens (ex.: 25 = +25%).
 */
export interface EstafaModifiers {
  /** Bônus de regeneração de EP por turno (lado Materno). */
  epRegenBonus: number;
  /** Penalidade de eficiência de armadura física (lado Materno). */
  armorPenalty: number;
  /** Bônus de resistência/defesa física (lado Paterno). */
  physicalDefBonus: number;
  /** Aumento no custo de EP de habilidades mágicas/complexas (lado Paterno). */
  epCostIncrease: number;
}

/**
 * Resultado da validação de uma ação solicitada pelo jogador,
 * considerando a psique atual do líder (Insubordinação Tática).
 */
export interface ActionValidationResult {
  /** Se a ação é permitida diretamente pela UI. */
  allowed: boolean;
  /** Motivo do bloqueio, quando aplicável. */
  reason?: string;
  /** Ação autônoma/modificada que a unidade executa se o comando for forçado. */
  autonomousAlternative?: string;
}

/** Tipos de ação sujeitos à validação psicológica da estafa. */
export type EstafaActionType =
  | 'SACRIFICE'
  | 'COLD_EXECUTION'
  | 'COMPASSIONATE_HEAL'
  | 'SHARE_ITEM'
  | 'STANDARD';

// ---------------------------------------------------------------------------
// CLASSE PRINCIPAL
// ---------------------------------------------------------------------------

export class EstafaCalculator {
  /** Limiar de entrada nos quadrantes extremos (magnitude). */
  private static readonly EXTREME_THRESHOLD = 60;

  /** Limiar da zona neutra (magnitude). */
  private static readonly NEUTRAL_THRESHOLD = 20;

  // Coeficientes das fórmulas canônicas (System Matrix).
  private static readonly EP_REGEN_COEFF = 0.5; // Materno: +(|estafa| * 0.5)%
  private static readonly PHYS_DEF_COEFF = 0.4; // Paterno: +(estafa * 0.4)%
  private static readonly MAX_ARMOR_PENALTY = 20; // Max (-100): -20% armadura
  private static readonly MAX_EP_COST_INCREASE = 30; // Max (+100): +30% custo EP

  /**
   * Restringe (clamp) um valor de estafa ao intervalo canônico [-100, +100].
   * Função pura utilitária usada por todos os demais cálculos.
   */
  public static clamp(value: number): number {
    if (Number.isNaN(value)) return 0;
    return Math.max(ESTAFA_MIN, Math.min(ESTAFA_MAX, value));
  }

  /**
   * Calcula os modificadores dinâmicos de combate a partir do valor de estafa.
   *
   * - Lado Materno (valor < 0): ganha regeneração de EP, perde armadura física.
   * - Lado Paterno (valor > 0): ganha defesa física, encarece habilidades mágicas.
   * - Zona neutra (valor == 0): todos os modificadores zerados.
   *
   * @param value Valor bruto da estafa (será limitado a [-100, +100]).
   */
  public static calculateModifiers(value: number): EstafaModifiers {
    const estafa = this.clamp(value);

    // Base zerada — apenas o lado ativo recebe modificadores.
    const modifiers: EstafaModifiers = {
      epRegenBonus: 0,
      armorPenalty: 0,
      physicalDefBonus: 0,
      epCostIncrease: 0,
    };

    if (estafa < 0) {
      // Lado Materno: usa a magnitude absoluta.
      const magnitude = Math.abs(estafa);
      modifiers.epRegenBonus = magnitude * this.EP_REGEN_COEFF; // até +50% em -100
      // Penalidade de armadura escala linearmente até o máximo em -100.
      modifiers.armorPenalty =
        (magnitude / Math.abs(ESTAFA_MIN)) * this.MAX_ARMOR_PENALTY;
    } else if (estafa > 0) {
      // Lado Paterno.
      modifiers.physicalDefBonus = estafa * this.PHYS_DEF_COEFF; // até +40% em +100
      // Encarecimento de EP mágico escala linearmente até o máximo em +100.
      modifiers.epCostIncrease =
        (estafa / ESTAFA_MAX) * this.MAX_EP_COST_INCREASE;
    }

    return modifiers;
  }

  /**
   * Retorna o quadrante psicológico atual da Balança de Estafa.
   *
   * - NEUTRAL:          -20 a +20
   * - MATERNO_EXTREMO:  <= -60
   * - PATERNO_EXTREMO:  >= +60
   *
   * A faixa intermediária (±21 a ±59) é tratada como transição e mantém o
   * comportamento neutro em termos de bloqueio de UI, embora os modificadores
   * de combate já estejam ativos (ver calculateModifiers).
   */
  public static getQuadrant(value: number): EstafaQuadrant {
    const estafa = this.clamp(value);

    if (estafa <= -this.EXTREME_THRESHOLD) return EstafaQuadrant.MATERNO_EXTREMO;
    if (estafa >= this.EXTREME_THRESHOLD) return EstafaQuadrant.PATERNO_EXTREMO;
    return EstafaQuadrant.NEUTRAL;
  }

  /**
   * Valida se uma ação solicitada é compatível com a psique atual do líder.
   *
   * Regras de Insubordinação Tática:
   *   - Extremo Materno bloqueia ações frias (SACRIFICE, COLD_EXECUTION):
   *     "Empatia Ativa".
   *   - Extremo Paterno bloqueia ações compassivas (COMPASSIONATE_HEAL,
   *     SHARE_ITEM): "Cálculo Tático".
   *   - STANDARD e ações compatíveis são sempre permitidas.
   *
   * Quando bloqueada, o resultado inclui uma `autonomousAlternative`: se o
   * jogador forçar o comando, a unidade executa uma ação autônoma modificada.
   *
   * @param value      Valor atual da estafa.
   * @param actionType Tipo da ação solicitada pela UI.
   */
  public static validateAction(
    value: number,
    actionType: EstafaActionType
  ): ActionValidationResult {
    const quadrant = this.getQuadrant(value);

    // Ações padrão nunca são travadas pela psique.
    if (actionType === 'STANDARD') {
      return { allowed: true };
    }

    // Empatia Ativa — o líder Materno recusa a frieza.
    if (quadrant === EstafaQuadrant.MATERNO_EXTREMO) {
      if (actionType === 'SACRIFICE') {
        return {
          allowed: false,
          reason:
            'Empatia Ativa: no extremo Materno a unidade se recusa a sacrificar aliados.',
          autonomousAlternative:
            'A unidade ignora a ordem e prioriza a preservação/proteção do alvo.',
        };
      }
      if (actionType === 'COLD_EXECUTION') {
        return {
          allowed: false,
          reason:
            'Empatia Ativa: no extremo Materno a execução a sangue-frio é bloqueada.',
          autonomousAlternative:
            'A unidade neutraliza o alvo de forma não-letal, poupando a vida.',
        };
      }
    }

    // Cálculo Tático — o líder Paterno recusa a compaixão.
    if (quadrant === EstafaQuadrant.PATERNO_EXTREMO) {
      if (actionType === 'COMPASSIONATE_HEAL') {
        return {
          allowed: false,
          reason:
            'Cálculo Tático: no extremo Paterno a cura compassiva é bloqueada.',
          autonomousAlternative:
            'A unidade redireciona os recursos para um golpe ofensivo eficiente.',
        };
      }
      if (actionType === 'SHARE_ITEM') {
        return {
          allowed: false,
          reason:
            'Cálculo Tático: no extremo Paterno a partilha de itens é bloqueada.',
          autonomousAlternative:
            'A unidade retém o item, avaliando-o como recurso estratégico próprio.',
        };
      }
    }

    // Em qualquer outro caso a ação é compatível com a psique atual.
    return { allowed: true };
  }
}
