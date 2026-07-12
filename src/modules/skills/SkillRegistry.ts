/**
 * ====================================================================
 * SkillRegistry.ts
 * --------------------------------------------------------------------
 * Registro central das habilidades iniciais do jogo (early game).
 * Centraliza:
 *   - skillDatabase — dicionário de ISkillOrSpell por skillId
 *   - initialSkillNodes — cadeia de dependências de desbloqueio
 *     (ISkillNode), consumível diretamente por SkillTreeManager
 *
 * Cadeia de dependências:
 *   SPARK (sem pré-requisitos) -> ICE_SPIKE (requer SPARK)
 *                              -> FIREBALL (requer ICE_SPIKE)
 *
 * Fonte: src/types/aetheris.types.ts (ISkillOrSpell, ISkillNode,
 *        ElementType, ISkillDamageResult)
 *        src/modules/skills/SkillEngine.ts (consumidor)
 *        src/modules/skills/SkillTreeManager.ts (consumidor)
 * ====================================================================
 */

import {
  ISkillOrSpell,
  ISkillNode,
  ISkillDamageResult,
  ElementType,
} from '../../types/aetheris.types';

// ====================================================================
// IDs DAS HABILIDADES INICIAIS
// ====================================================================

export const SKILL_ID_SPARK = 'SPARK';
export const SKILL_ID_ICE_SPIKE = 'ICE_SPIKE';
export const SKILL_ID_FIREBALL = 'FIREBALL';

// Habilidades tecnológicas — canônicas da Engenharia Elemental
// (HUMAN/DWARF), mas com estafaCost padrão para retrocompatibilidade:
// funcionam normalmente via fluxo místico quando usadas sem kit ou por
// outra raça.
export const SKILL_ID_THERMITE_GRENADE = 'THERMITE_GRENADE';
export const SKILL_ID_CRYO_DISCHARGER = 'CRYO_DISCHARGER';
export const SKILL_ID_TESLA_COIL = 'TESLA_COIL';

// ====================================================================
// FÁBRICA: createDamageSkill
// ====================================================================

/**
 * createDamageSkill(...)
 * ------------------------------------------------------------------
 * Constrói uma ISkillOrSpell de dano cujo execute() retorna o formato
 * padrão ISkillDamageResult, reconhecido nativamente por
 * SkillEngine.executeSkill (ETAPA 2).
 */
function createDamageSkill(
  id: string,
  name: string,
  description: string,
  element: ElementType,
  estafaCost: number,
  minRequiredLevel: number,
  baseDamage: number,
  cooldownTurns: number,
): ISkillOrSpell {
  return {
    id,
    name,
    description,
    estafaCost,
    minRequiredLevel,
    cooldownTurns,
    effectType: 'DAMAGE',
    element,
    execute: (): ISkillDamageResult => ({
      baseDamage,
    }),
  };
}

// ====================================================================
// CONSTANTE: skillDatabase
// ====================================================================

/**
 * Dicionário central das habilidades iniciais do jogo, indexado por
 * skillId. Consumido por SkillEngine.executeSkill (dados da skill) e
 * SkillTreeManager.canUnlock/unlockSkill (minRequiredLevel).
 */
export const skillDatabase: Map<string, ISkillOrSpell> = new Map([
  [
    SKILL_ID_SPARK,
    createDamageSkill(
      SKILL_ID_SPARK,
      'Faísca',
      'Descarga elétrica rápida e barata em estafa.',
      'LIGHTNING',
      15,
      1,
      25,
      1,
    ),
  ],
  [
    SKILL_ID_ICE_SPIKE,
    createDamageSkill(
      SKILL_ID_ICE_SPIKE,
      'Espinho de Gelo',
      'Projétil de gelo que perfura defesas leves.',
      'ICE',
      35,
      3,
      45,
      2,
    ),
  ],
  [
    SKILL_ID_FIREBALL,
    createDamageSkill(
      SKILL_ID_FIREBALL,
      'Bola de Fogo',
      'Explosão de fogo de alto custo e alto dano.',
      'FIRE',
      60,
      5,
      75,
      3,
    ),
  ],
  [
    SKILL_ID_THERMITE_GRENADE,
    createDamageSkill(
      SKILL_ID_THERMITE_GRENADE,
      'Granada de Termite',
      'Carga incendiária de engenharia HUMAN/DWARF. estafaCost padrão ' +
        'mantido para retrocompatibilidade — funciona via fluxo místico ' +
        'quando usada sem kit de Engenharia Elemental ou por outra raça.',
      'FIRE',
      60,
      5,
      80,
      3,
    ),
  ],
  [
    SKILL_ID_CRYO_DISCHARGER,
    createDamageSkill(
      SKILL_ID_CRYO_DISCHARGER,
      'Descarregador Criogênico',
      'Dispositivo de engenharia que libera um jato de frio concentrado.',
      'ICE',
      35,
      3,
      45,
      2,
    ),
  ],
  [
    SKILL_ID_TESLA_COIL,
    createDamageSkill(
      SKILL_ID_TESLA_COIL,
      'Bobina de Tesla',
      'Dispositivo portátil de engenharia que descarrega um arco elétrico.',
      'LIGHTNING',
      15,
      1,
      25,
      1,
    ),
  ],
]);

// ====================================================================
// CONSTANTE: initialSkillNodes
// ====================================================================

/**
 * Cadeia de dependências de desbloqueio das habilidades iniciais,
 * pronta para ser carregada em SkillTreeManager (via constructor ou
 * loadNodes):
 *   SPARK -> ICE_SPIKE -> FIREBALL
 */
export const initialSkillNodes: ISkillNode[] = [
  {
    skillId: SKILL_ID_SPARK,
    isUnlocked: false,
    prerequisites: [],
  },
  {
    skillId: SKILL_ID_ICE_SPIKE,
    isUnlocked: false,
    prerequisites: [SKILL_ID_SPARK],
  },
  {
    skillId: SKILL_ID_FIREBALL,
    isUnlocked: false,
    prerequisites: [SKILL_ID_ICE_SPIKE],
  },
];
