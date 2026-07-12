/**
 * ====================================================================
 * skillEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — SkillEngine.executeSkill / Matriz de Fraqueza
 * Elemental (raça nativa + status effect simulado) / Regra do
 * Retrocesso (Backlash).
 *
 * NOTA: SkillEngine.hasElementalWeakness é um método privado — não é
 * testável diretamente. Esta suite valida seu comportamento de forma
 * indireta, observando o efeito público que ele produz em
 * executeSkill: amplificação de actualDamage (fraqueza do target) e
 * de backlashDamage (fraqueza do caster).
 *
 * Fonte: src/modules/skills/SkillEngine.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import { SkillEngine } from '../modules/skills/SkillEngine';
import { CharacterState } from '../core/CharacterState';
import {
  ICharacterStats,
  ISkillOrSpell,
  Race,
  LatentLineageAxis,
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

function assertApprox(
  actual: number,
  expected: number,
  tolerance: number,
  description: string,
): void {
  const diff = Math.abs(actual - expected);
  assert(diff <= tolerance, `${description} (esperado=${expected}, atual=${actual}, tolerância=${tolerance})`);
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

/**
 * Cria um CharacterState com raça opcional, sem precisar repassar
 * manualmente os parâmetros intermediários do construtor
 * (latentLineageAxis, eventCallback, securityLogCallback).
 */
function createCharacter(
  race: Race | null = null,
  statsOverrides?: Partial<ICharacterStats>,
): CharacterState {
  return new CharacterState(
    createBaseStats(statsOverrides),
    LatentLineageAxis.NEUTRO_ABSOLUTO,
    undefined,
    undefined,
    race,
  );
}

/**
 * Cria uma ISkillOrSpell de teste com dano fixo retornado por execute().
 */
function createSkill(
  estafaCost: number,
  fixedDamage: number,
  overrides?: Partial<ISkillOrSpell>,
): ISkillOrSpell {
  return {
    id: 'SKL_TEST_001',
    name: 'Skill de Teste',
    description: 'Skill fabricada para homologação do SkillEngine',
    estafaCost,
    minRequiredLevel: 1,
    cooldownTurns: 1,
    effectType: 'DAMAGE',
    execute: () => fixedDamage,
    ...overrides,
  };
}

// ====================================================================
// MATRIZ RACIAL COMPARTILHADA — Seis Raças Fundadoras
// Reutilizada pelos Cenários A (dano cruzado) e B (backlash), para
// que as três raças novas sejam validadas exatamente pelo mesmo
// caminho de código que ELF/DWARF/HUMAN.
// ====================================================================

const racialMatrix: Array<{ race: Race; weakElement: 'FIRE' | 'ICE' | 'LIGHTNING'; strongElement: 'FIRE' | 'ICE' | 'LIGHTNING' }> = [
  { race: Race.ELF, weakElement: 'FIRE', strongElement: 'ICE' },
  { race: Race.DWARF, weakElement: 'ICE', strongElement: 'LIGHTNING' },
  { race: Race.HUMAN, weakElement: 'LIGHTNING', strongElement: 'FIRE' },
  { race: Race.FAERIE, weakElement: 'ICE', strongElement: 'FIRE' },
  { race: Race.DRACONIAN, weakElement: 'LIGHTNING', strongElement: 'ICE' },
  { race: Race.LURID, weakElement: 'FIRE', strongElement: 'LIGHTNING' },
];

// ====================================================================
// CENÁRIO A: FRAQUEZAS ELEMENTAIS NATIVAS POR RAÇA (DANO CRUZADO)
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — FRAQUEZAS ELEMENTAIS NATIVAS POR RAÇA (DANO CRUZADO NO TARGET)');

  const BASE_DAMAGE = 40;
  const AMPLIFIED_DAMAGE = BASE_DAMAGE * 1.5; // 60

  for (const { race, weakElement, strongElement } of racialMatrix) {
    printSubSection(`A.${race} — elemento nativo ${weakElement}`);

    // Caster neutro (sem raça), estafa/custo baixos para não disparar backlash
    const caster = createCharacter(null);
    const skill = createSkill(10, BASE_DAMAGE);

    // Subteste 1: elemento que É a fraqueza nativa da raça → amplifica
    const targetWeak = createCharacter(race);
    const resultWeak = SkillEngine.executeSkill(skill, caster, targetWeak, weakElement);

    assertApprox(
      resultWeak.actualDamage,
      AMPLIFIED_DAMAGE,
      0.001,
      `${race} vs ${weakElement} (fraqueza nativa): actualDamage amplificado`,
    );
    assert(
      resultWeak.backlashDamage === 0,
      `${race} vs ${weakElement}: sem backlash (estafa não estourou)`,
    );

    // Subteste 2: elemento que NÃO é a fraqueza da raça → sem amplificação
    const targetStrong = createCharacter(race);
    const resultStrong = SkillEngine.executeSkill(skill, caster, targetStrong, strongElement);

    assertApprox(
      resultStrong.actualDamage,
      BASE_DAMAGE,
      0.001,
      `${race} vs ${strongElement} (não é fraqueza): actualDamage não amplificado`,
    );
  }
}

// ====================================================================
// CENÁRIO B: RETROCESSO (BACKLASH) AMPLIFICADO POR FRAQUEZA RACIAL
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — RETROCESSO AMPLIFICADO POR FRAQUEZA RACIAL (TODAS AS SEIS RAÇAS)');

  const initialHp = 1000;

  for (const { race, weakElement } of racialMatrix) {
    printSubSection(`B.${race} — conjurando ${weakElement} (fraqueza nativa) além de -100`);

    // ----------------------------------------------------------------
    // Setup: personagem da raça com estafa já baixa (-90), prestes a
    // estourar o piso
    // ----------------------------------------------------------------
    const caster = createCharacter(race, { currentHp: initialHp, maxHp: initialHp });
    caster.shortTermEstafa = -90;

    assert(caster.shortTermEstafa === -90,
      `${race}: estafa inicial do caster: ${caster.shortTermEstafa} === -90`);

    const target = createCharacter(null);

    // estafaCost 30 → potentialEstafa = -90 - 30 = -120 (estoura o piso em 20)
    const skill = createSkill(30, 10);

    const result = SkillEngine.executeSkill(skill, caster, target, weakElement);

    // Estafa travada em -100 (piso ontológico)
    assert(caster.shortTermEstafa === -100,
      `${race}: estafa do caster travada: ${caster.shortTermEstafa} === -100`);

    // backlashDamage amplificado 1.5x (raça vulnerável ao próprio elemento conjurado)
    // Excedente bruto: -100 - (-120) = 20 → amplificado: 20 * 1.5 = 30
    const expectedBacklash = 20 * 1.5;

    assertApprox(result.backlashDamage, expectedBacklash, 0.001,
      `${race}: backlashDamage amplificado 1.5x (${weakElement}): ${result.backlashDamage} ≈ ${expectedBacklash}`);

    // HP do caster reduzido exatamente pelo backlash amplificado
    const expectedHp = initialHp - expectedBacklash;

    assertApprox(caster.stats.currentHp, expectedHp, 0.001,
      `${race}: HP do caster após backlash: ${caster.stats.currentHp} ≈ ${expectedHp}`);
  }
}

// ====================================================================
// CENÁRIO C: FLUXO BASE — SEM ESTOURO DE ESTAFA, SEM FRAQUEZAS
// ====================================================================

function runTestC(): void {
  printSection('CENÁRIO C — FLUXO BASE (SEM ESTOURO, SEM FRAQUEZAS, SEM ELEMENTO)');

  const initialHp = 1000;
  const caster = createCharacter(null, { currentHp: initialHp, maxHp: initialHp });
  const target = createCharacter(null);

  // Estafa inicial 0, custo 20 → potentialEstafa = -20 (dentro do piso -100)
  const skill = createSkill(20, 50);

  printSubSection('C.1 — Execução sem parâmetro de elemento');

  // `element` omitido de propósito — nenhum multiplicador deve ser aplicado
  const result = SkillEngine.executeSkill(skill, caster, target);

  printSubSection('C.2 — Sem backlash: estafa apenas desloca normalmente');

  assert(caster.shortTermEstafa === -20, `Estafa do caster após cast: ${caster.shortTermEstafa} === -20`);
  assert(result.backlashDamage === 0, `backlashDamage no fluxo base: ${result.backlashDamage} === 0`);
  assert(caster.stats.currentHp === initialHp,
    `HP do caster inalterado: ${caster.stats.currentHp} === ${initialHp}`);

  printSubSection('C.3 — Dano efetivo sem amplificação');

  assert(result.actualDamage === 50, `actualDamage sem amplificação: ${result.actualDamage} === 50`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  SKILL ENGINE TEST SUITE — MATRIZ DE FRAQUEZA ELEMENTAL / BACKLASH`);
  console.log(`#  Motor: SkillEngine.ts / CharacterState.ts`);
  console.log(`${'#'.repeat(72)}\n`);

  runTestA();
  runTestB();
  runTestC();

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
