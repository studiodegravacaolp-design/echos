/**
 * ====================================================================
 * skillTreeManager.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — SkillTreeManager.canUnlock / unlockSkill.
 * Monta uma árvore encadeada de 2 nós (Skill A -> Skill B) e valida:
 *   - Bloqueio por pré-requisito não desbloqueado
 *   - Bloqueio por nível insuficiente
 *   - Desbloqueio atômico com sucesso
 *   - Idempotência de unlockSkill em nós já desbloqueados
 *
 * Fonte: src/modules/skills/SkillTreeManager.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import { SkillTreeManager } from '../modules/skills/SkillTreeManager';
import { CharacterState } from '../core/CharacterState';
import {
  ICharacterStats,
  ISkillNode,
  ISkillOrSpell,
} from '../types/aetheris.types';

// ====================================================================
// CONSTANTES DE TESTE
// ====================================================================

const TEST_PASSED = 'PASS';
const TEST_FAILED = 'FAIL';

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

// ====================================================================
// FUNÇÕES AUXILIARES DE ASSERTIVA
// ====================================================================

function assert(condition: boolean, description: string): void {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  ✓ ${TEST_PASSED}: ${description}`);
  } else {
    failedTests++;
    console.log(`  ✗ ${TEST_FAILED}: ${description}`);
  }
}

function printSection(title: string): void {
  console.log(`\n${'='.repeat(72)}`);
  console.log(`  ${title}`);
  console.log(`${'='.repeat(72)}`);
}

function printSubSection(title: string): void {
  console.log(`\n  --- ${title} ---`);
}

// ====================================================================
// HELPERS DE CRIAÇÃO DE ESTADO
// ====================================================================

function createBaseStats(overrides?: Partial<ICharacterStats>): ICharacterStats {
  return {
    maxHp: 1000,
    currentHp: 1000,
    damage: 50,
    defense: 30,
    resilience: 20,
    movementSpeed: 100,
    ...overrides,
  };
}

function createSkillData(
  id: string,
  minRequiredLevel: number,
): ISkillOrSpell {
  return {
    id,
    name: `Skill ${id}`,
    description: 'Skill fabricada para homologação do SkillTreeManager',
    estafaCost: 10,
    minRequiredLevel,
    cooldownTurns: 1,
    effectType: 'DAMAGE',
    execute: () => 0,
  };
}

function createSkillNode(
  skillId: string,
  prerequisites: string[],
): ISkillNode {
  return {
    skillId,
    isUnlocked: false,
    prerequisites,
  };
}

// ====================================================================
// CENÁRIO ÚNICO: ÁRVORE ENCADEADA SKILL A -> SKILL B
// ====================================================================

function runTests(): void {
  printSection('SKILL TREE — ÁRVORE ENCADEADA: SKILL A (lvl 1) -> SKILL B (lvl 5, requer A)');

  // ----------------------------------------------------------------
  // Setup (item 1): Skill A sem requisito (level 1), Skill B requer
  // Skill A desbloqueada e level 5
  // ----------------------------------------------------------------
  const SKILL_A_ID = 'SKL_A';
  const SKILL_B_ID = 'SKL_B';

  const skillData = new Map<string, ISkillOrSpell>([
    [SKILL_A_ID, createSkillData(SKILL_A_ID, 1)],
    [SKILL_B_ID, createSkillData(SKILL_B_ID, 5)],
  ]);

  const manager = new SkillTreeManager([
    createSkillNode(SKILL_A_ID, []),
    createSkillNode(SKILL_B_ID, [SKILL_A_ID]),
  ]);

  const character = new CharacterState(createBaseStats());

  assert(manager.isSkillUnlocked(SKILL_A_ID) === false,
    'Setup: Skill A carregada como bloqueada (isUnlocked=false)');
  assert(manager.isSkillUnlocked(SKILL_B_ID) === false,
    'Setup: Skill B carregada como bloqueada (isUnlocked=false)');

  // ----------------------------------------------------------------
  // Item 2: canUnlock bloqueia Skill B — nível 5, mas Skill A NÃO
  // desbloqueada
  // ----------------------------------------------------------------
  printSubSection('2 — Bloqueio por pré-requisito ausente (level 5, Skill A bloqueada)');

  character.currentLevel = 5;

  assert(character.currentLevel === 5, `Nível do personagem: ${character.currentLevel} === 5`);
  assert(manager.canUnlock(SKILL_B_ID, character, skillData) === false,
    'canUnlock(SKL_B) === false: nível suficiente, mas Skill A ainda bloqueada');

  // ----------------------------------------------------------------
  // Item 3: canUnlock bloqueia Skill B — Skill A desbloqueada, mas
  // personagem no nível 3 (abaixo do minRequiredLevel=5)
  // ----------------------------------------------------------------
  printSubSection('3 — Bloqueio por nível insuficiente (Skill A desbloqueada, level 3)');

  // Desbloqueia Skill A (minRequiredLevel=1, satisfeito mesmo em level 5)
  const unlockedA = manager.unlockSkill(SKILL_A_ID, character, skillData);
  assert(unlockedA === true, `unlockSkill(SKL_A) retorna true: ${unlockedA}`);
  assert(manager.isSkillUnlocked(SKILL_A_ID) === true,
    'Skill A agora está desbloqueada');

  // Reduz o nível do personagem para 3
  character.currentLevel = 3;
  assert(character.currentLevel === 3, `Nível do personagem: ${character.currentLevel} === 3`);

  assert(manager.canUnlock(SKILL_B_ID, character, skillData) === false,
    'canUnlock(SKL_B) === false: Skill A desbloqueada, mas nível 3 < minRequiredLevel 5');
  assert(manager.isSkillUnlocked(SKILL_B_ID) === false,
    'Skill B permanece bloqueada após a tentativa de validação (canUnlock não muta estado)');

  // ----------------------------------------------------------------
  // Item 4: Desbloqueio atômico com sucesso + idempotência
  // ----------------------------------------------------------------
  printSubSection('4 — Desbloqueio atômico completo + idempotência da re-execução');

  // Eleva o personagem ao nível 5 — agora ambas as condições são satisfeitas
  character.currentLevel = 5;
  assert(character.currentLevel === 5, `Nível do personagem: ${character.currentLevel} === 5`);

  assert(manager.canUnlock(SKILL_B_ID, character, skillData) === true,
    'canUnlock(SKL_B) === true: Skill A desbloqueada e nível 5 satisfeito');

  const unlockedB = manager.unlockSkill(SKILL_B_ID, character, skillData);
  assert(unlockedB === true, `unlockSkill(SKL_B) retorna true: ${unlockedB}`);
  assert(manager.isSkillUnlocked(SKILL_B_ID) === true,
    'Skill B agora está desbloqueada');

  // Re-execução: chamar unlockSkill novamente em um nó já desbloqueado
  // deve continuar retornando true, de forma idempotente, sem lançar
  // exceção e sem alterar o restante da árvore.
  const unlockedBAgain = manager.unlockSkill(SKILL_B_ID, character, skillData);
  assert(unlockedBAgain === true,
    `Re-execução idempotente de unlockSkill(SKL_B) retorna true: ${unlockedBAgain}`);
  assert(manager.isSkillUnlocked(SKILL_B_ID) === true,
    'Skill B continua desbloqueada após a re-execução');
  assert(manager.isSkillUnlocked(SKILL_A_ID) === true,
    'Skill A permanece desbloqueada (nenhum efeito colateral na re-execução de B)');

  // Sanidade final: o nó armazenado internamente reflete o estado esperado
  const finalNodeB = manager.getNode(SKILL_B_ID);
  assert(finalNodeB !== null && finalNodeB.isUnlocked === true,
    'getNode(SKL_B) retorna nó com isUnlocked=true após desbloqueio');
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  SKILL TREE MANAGER TEST SUITE — canUnlock / unlockSkill`);
  console.log(`#  Motor: SkillTreeManager.ts / CharacterState.ts`);
  console.log(`${'#'.repeat(72)}\n`);

  runTests();

  // ================================================================
  // RELATÓRIO FINAL
  // ================================================================
  console.log(`\n${'='.repeat(72)}`);
  console.log(`  RELATÓRIO DE HOMOLOGAÇÃO`);
  console.log(`${'='.repeat(72)}`);
  console.log(`  Total de testes:    ${totalTests}`);
  console.log(`  Aprovados (PASS):   ${passedTests}`);
  console.log(`  Reprovados (FAIL):  ${failedTests}`);
  console.log(`  Taxa de sucesso:    ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
  console.log(`${'='.repeat(72)}`);

  if (failedTests > 0) {
    console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar implementação.\n`);
    process.exit(1);
  } else {
    console.log(`\n  ✅ TODOS OS TESTES PASSARAM — HOMOLOGAÇÃO APROVADA\n`);
    process.exit(0);
  }
}

main();
