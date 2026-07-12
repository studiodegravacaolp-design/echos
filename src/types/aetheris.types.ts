/**
 * ====================================================================
 * aetheris.types.ts
 * --------------------------------------------------------------------
 * Definições de tipos, enums e contratos de dados do Projeto Aetheris.
 * Fonte: docs/04_arquitetura_software/ENG-ESTRUTURA-DADOS.md
 *        docs/04_arquitetura_software/ENG-MOTOR-COMBATE.md
 *
 * Versão: 1.1.0
 * Status: IMPLEMENTADO (Sprint 2 — Equipamento, Fila e Atrito)
 * ====================================================================
 */

/**
 * Enum LatentLineageAxis
 * --------------------------------------------------------------------
 * Representa o eixo de linhagem latente do personagem.
 * Valores exatos conforme ENG-ESTRUTURA-DADOS Seção 3.1.
 */
export enum LatentLineageAxis {
  PATERNO_EMBER = 'PATERNO_EMBER',
  MATERNO_DOURADO = 'MATERNO_DOURADO',
  NEUTRO_ABSOLUTO = 'NEUTRO_ABSOLUTO',
}

/**
 * Enum WorldState
 * --------------------------------------------------------------------
 * Representa os estados de mundo do jogo.
 * Valores exatos conforme especificação de arquitetura.
 */
export enum WorldState {
  ERA_DO_ACO = 'ERA_DO_ACO',
  ESTASE_RUNICA = 'ESTASE_RUNICA',
}

/**
 * Enum AxisTag
 * --------------------------------------------------------------------
 * Tag de eixo utilizada nas habilidades para determinar o lado
 * da Balança de Estafa que a habilidade desloca.
 * Fonte: ENG-MOTOR-COMBATE Seção 3.4
 */
export enum AxisTag {
  PATERNO = 'PATERNO',
  MATERNO = 'MATERNO',
  NEUTRO = 'NEUTRO',
}

/**
 * Enum PenetrationType
 * --------------------------------------------------------------------
 * Tipo de penetração de uma habilidade, usado no cálculo de dano.
 */
export enum PenetrationType {
  FISICA = 'FISICA',
  MAGICA = 'MAGICA',
  VERDADEIRA = 'VERDADEIRA',
}

/**
 * Enum EnemyType
 * --------------------------------------------------------------------
 * Classificação de tipos de inimigos conforme ENG-MOTOR-COMBATE Seção 5.3.
 */
export enum EnemyType {
  NORMAL = 'NORMAL',
  ELITE = 'ELITE',
  BOSS = 'BOSS',
  LEGENDARY = 'LEGENDARY',
}

/**
 * Enum MaterialType
 * --------------------------------------------------------------------
 * Tipos de materiais para equipamentos, cada um com seu coeficiente
 * de atrito característico.
 * Fonte: ENG-MATEMATICA-COMBATE Seção 7 (Tabela de Materiais)
 */
export enum MaterialType {
  ACO = 'ACO',
  CHUMBO = 'CHUMBO',
  PEDRA = 'PEDRA',
  DIAPASAO = 'DIAPASAO',
}

/**
 * Coeficientes de atrito por material.
 * Fonte: ENG-MATEMATICA-COMBATE Seção 7.1
 */
export const MATERIAL_COEFFICIENTS: Record<MaterialType, number> = {
  [MaterialType.ACO]: 1.0,
  [MaterialType.CHUMBO]: 1.8,
  [MaterialType.PEDRA]: 1.5,
  [MaterialType.DIAPASAO]: 1.2,
};

/**
 * Enum Race
 * --------------------------------------------------------------------
 * Raça nativa do personagem — cânone das Seis Raças Fundadoras do
 * Projeto Aetheris. Usada pela Matriz de Fraqueza Elemental
 * (SkillEngine) para resolver fraquezas permanentes por raça,
 * independentes de status effects temporários.
 * Fonte: Débito técnico — Matriz de Fraqueza Elemental
 */
export enum Race {
  HUMAN = 'HUMAN',
  DWARF = 'DWARF',
  ELF = 'ELF',
  FAERIE = 'FAERIE',
  DRACONIAN = 'DRACONIAN',
  LURID = 'LURID',
}

/**
 * Elementos suportados pela Matriz de Fraqueza Elemental.
 * Fonte: Débito técnico — Matriz de Fraqueza Elemental (SkillEngine)
 */
export type ElementType = 'FIRE' | 'ICE' | 'LIGHTNING';

/**
 * Interface ICharacterStats
 * --------------------------------------------------------------------
 * Estatísticas base de um personagem (jogador ou inimigo).
 * Foco em damage, defense e resilience conforme especificado.
 */
export interface ICharacterStats {
  /** Pontos de vida máximos */
  maxHp: number;
  /** Pontos de vida atuais */
  currentHp: number;
  /** Dano base de ataque */
  damage: number;
  /** Defesa base */
  defense: number;
  /** Resiliência — resistência a efeitos de estafa e colapso */
  resilience: number;
  /** Velocidade de movimento base */
  movementSpeed: number;
}

/**
 * Interface IAbility
 * --------------------------------------------------------------------
 * Contrato de dados de uma habilidade utilizável em combate.
 * Fonte: ENG-MOTOR-COMBATE Seção 3.3 (AbilityInstance).
 */
export interface IAbility {
  /** Identificador único da habilidade (ex: "HAB_FORJA_01") */
  id: string;
  /** Nome legível (ex: "Golpe de Forja") */
  name: string;
  /** Tag de Eixo: PATERNO | MATERNO | NEUTRO */
  axis: AxisTag;
  /** Valor de deslocamento no medidor de estafa */
  deltaM: number;
  /** Dano base da habilidade */
  baseDamage: number;
  /** Tipo de penetração da habilidade */
  penetrationType: PenetrationType;
  /** Tempo de recarga em segundos (opcional, padrão 0) */
  cooldown?: number;
  /** Custo de estamina (opcional, padrão 0) */
  staminaCost?: number;
}

/**
 * Interface IEquipment
 * --------------------------------------------------------------------
 * Contrato de dados de um equipamento utilizável por um combatente.
 * O peso e o coeficiente de material determinam o atrito físico
 * que reduz a velocidade de movimento em combate.
 *
 * Coeficientes de material:
 *   Aço     = 1.0
 *   Chumbo  = 1.8
 *   Pedra   = 1.5
 *   Diapasão = 1.2
 *
 * Fonte: ENG-MATEMATICA-COMBATE Seção 7 (Friction Profile)
 */
export interface IEquipment {
  /** Identificador único do equipamento (ex: "EQP_ARM_001") */
  id: string;
  /** Nome legível (ex: "Armadura de Aço Forjado") */
  name: string;
  /** Peso do equipamento em unidades de massa abstratas */
  weight: number;
  /** Coeficiente de atrito do material (Aço=1.0, Chumbo=1.8, Pedra=1.5, Diapasão=1.2) */
  materialCoefficient: number;
}

/**
 * Interface IProcessResult
 * --------------------------------------------------------------------
 * Resultado da rotina process_ability_delta.
 * Fonte: ENG-MOTOR-COMBATE Seção 3.5.
 */
export interface IProcessResult {
  success: boolean;
  errorCode: string | null;
  finalEstafa: number;
  deltaApplied?: number;
  previousEstafa?: number;
  clamped?: boolean;
  triggerEvent: string | null;
}

/**
 * Interface IOverloadResult
 * --------------------------------------------------------------------
 * Resultado da rotina check_overload_states.
 * Fonte: ENG-MOTOR-COMBATE Seção 4.4.
 */
export interface IOverloadResult {
  checked: boolean;
  currentEstafa: number;
  overloadActivated: boolean;
  overloadDeactivated: boolean;
  activeState: string | null;
}

/**
 * Interface IFractureResult
 * --------------------------------------------------------------------
 * Resultado da rotina apply_enemy_fracture.
 * Fonte: ENG-MOTOR-COMBATE Seção 5.4.
 */
export interface IFractureResult {
  success: boolean;
  errorCode: string | null;
  fractureApplied: boolean;
  enemyType?: EnemyType;
  isRestricted?: boolean;
  nominalWindow?: number;
  usefulVulnerabilityWindow?: number;
  ejectionAnimationDuration?: number;
  vulnerabilityRemaining?: number;
}

/**
 * Interface IStatusEffect
 * --------------------------------------------------------------------
 * Define um efeito de status aplicável a um combatente.
 */
export interface IStatusEffect {
  id: string;
  duration: number;
  remainingDuration: number;
  modifiers: Record<string, number>;
  flags: {
    blocksMovementInput: boolean;
    overridesMovementDirection: boolean;
    blocksAbilityAxis: AxisTag | null;
    freezesEstafaBar: boolean;
  };
}

/**
 * Interface ICombatVariables
 * --------------------------------------------------------------------
 * Agrega as variáveis de combate de curto prazo.
 * Fonte: ENG-ESTRUTURA-DADOS Seção 2.4.
 */
export interface ICombatVariables {
  shortTermEstafa: number;
  estafaFrozen: boolean;
}

/**
 * Interface ICharacterProfile
 * --------------------------------------------------------------------
 * Perfil completo do personagem, agregando estatísticas,
 * variáveis de combate e dados de linhagem.
 */
export interface ICharacterProfile {
  id: string;
  name: string;
  level: number;
  stats: ICharacterStats;
  combat: ICombatVariables;
  latentLineageAxis: LatentLineageAxis;
  statusEffects: IStatusEffect[];
}

/**
 * Interface IItem
 * --------------------------------------------------------------------
 * Contrato de dados de um item armazenável no inventário.
 * Fonte: Sprint 4 — Inventory Manager
 */
export interface IItem {
  /** Identificador único do item (ex: "ITEM_POCAO_001") */
  id: string;
  /** Nome legível do item (ex: "Poção de Cura") */
  name: string;
  /** Peso unitário do item em unidades de massa abstratas */
  weight: number;
  /** Quantidade máxima empilhável por slot */
  maxStack: number;
}

/**
 * Interface IInventorySlot
 * --------------------------------------------------------------------
 * Contrato de dados de um slot de inventário.
 * Mapeia um item a uma quantidade.
 * Fonte: Sprint 4 — Inventory Manager
 */
export interface IInventorySlot {
  /** Item armazenado no slot */
  item: IItem;
  /** Quantidade atual do item no slot */
  quantity: number;
}

/**
 * Interface ISkillOrSpell
 * --------------------------------------------------------------------
 * Contrato de dados de uma habilidade/feitiço da árvore de progressão.
 * Distinta de IAbility (habilidade de combate ligada ao eixo/deltaM):
 * ISkillOrSpell representa o nó de gameplay que, ao ser executado,
 * pode aplicar deltaM de estafa via CombatEngine.processAbilityDelta.
 */
export interface ISkillOrSpell {
  id: string;
  name: string;
  description: string;
  /** O deltaM que deslocará a estafa do personagem */
  estafaCost: number;
  minRequiredLevel: number;
  cooldownTurns: number;
  effectType: 'DAMAGE' | 'HEAL' | 'BUFF' | 'DEBUFF';
  /**
   * Elemento associado à skill, consultado pela Matriz de Fraqueza
   * Elemental (SkillEngine.executeSkill). Opcional — skills sem
   * elemento (ex: efeitos puramente físicos) omitem este campo.
   */
  element?: ElementType;
  /** Execução isolada do efeito */
  execute(caster: any, target: any): any;
}

/**
 * Interface ISkillDamageResult
 * --------------------------------------------------------------------
 * Formato padrão de retorno de ISkillOrSpell.execute() para efeitos
 * de dano. SkillEngine.executeSkill reconhece este formato (além de
 * um number bruto, mantido por compatibilidade) para resolver
 * `actualDamage`.
 */
export interface ISkillDamageResult {
  /** Dano bruto do efeito, antes da Matriz de Fraqueza Elemental */
  baseDamage: number;
}

/**
 * Interface ISkillNode
 * --------------------------------------------------------------------
 * Contrato de dados de um nó da árvore de habilidades.
 * Referencia uma ISkillOrSpell por id e controla seu estado de
 * desbloqueio e dependências (prerequisites).
 */
export interface ISkillNode {
  skillId: string;
  isUnlocked: boolean;
  /** IDs de skills que precisam ser liberadas antes */
  prerequisites: string[];
}

/**
 * Códigos de erro do motor de combate.
 * Fonte: ENG-MOTOR-COMBATE Seção 7.
 */
export const ErrorCodes = {
  MOTOR_ERR_001: 'MOTOR-ERR-001',
  MOTOR_ERR_002: 'MOTOR-ERR-002',
  MOTOR_ERR_003: 'MOTOR-ERR-003',
  MOTOR_ERR_010: 'MOTOR-ERR-010',
  MOTOR_ERR_011: 'MOTOR-ERR-011',
  BOUNDS_001: 'BOUNDS-001',
  MON_ERR_032: 'MON-ERR-032',
} as const;

/**
 * IDs de eventos do sistema.
 * Fonte: ENG-ESTRUTURA-DADOS Seção 2.3 e ENG-MOTOR-COMBATE.
 */
export const EventIds = {
  EVT_FRATURA_FRENESI: 'EVT_FRATURA_FRENESI',
  EVT_ESTAGNACAO_TATICA: 'EVT_ESTAGNACAO_TATICA',
  EVT_REVELACAO_LINHAGEM: 'EVT_REVELACAO_LINHAGEM',
  EVT_ENEMY_FRACTURE: 'EVT_ENEMY_FRACTURE',
  EVT_UI_STATUS_APPLIED: 'EVT_UI_STATUS_APPLIED',
  EVT_UI_STATUS_EXPIRED: 'EVT_UI_STATUS_EXPIRED',
  EVT_UI_EJECTION_CHUMBO_START: 'EVT_UI_EJECTION_CHUMBO_START',
  EVT_UI_VULNERABILITY_WINDOW_OPEN: 'EVT_UI_VULNERABILITY_WINDOW_OPEN',
  EVT_UI_VULNERABILITY_WINDOW_CLOSE: 'EVT_UI_VULNERABILITY_WINDOW_CLOSE',
} as const;