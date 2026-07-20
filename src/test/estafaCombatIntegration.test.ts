/**
 * ====================================================================
 * estafaCombatIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Balança de Estafa no core de combate.
 *
 * Valida que a integração do EstafaCalculator com CharacterState e
 * CombatAIEngine se comporta ponta-a-ponta em um turno simulado:
 *
 *   A) Com Estafa = +100 (extremo Paterno), uma tentativa de cura
 *      compassiva (COMPASSIONATE_HEAL) é BLOQUEADA e redirecionada
 *      para a ação autônoma (Insubordinação Tática / Cálculo Tático).
 *   B) Com Estafa = +100, o custo de EP de habilidades sobe +30%.
 *   C) Complementos: defesa física efetiva (+40%) e caminho Materno.
 *
 * Execução: npx tsx src/test/estafaCombatIntegration.test.ts
 *
 * Fonte: src/core/CharacterState.ts
 *        src/core/CombatAIEngine.ts
 *        src/mechanics/EstafaCalculator.ts
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { CombatAIEngine } from '../core/CombatAIEngine';
import { ICharacterStats } from '../types/aetheris.types';

// --------------------------------------------------------------------
// HARNESS (padrão do projeto — sem framework externo)
// --------------------------------------------------------------------
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition: boolean, description: string): void {
  totalTests++;
  if (condition) {
    passedTests++;
    console.log(`  ✓ PASS: ${description}`);
  } else {
    failedTests++;
    console.log(`  ✗ FAIL: ${description}`);
  }
}

function assertApprox(
  actual: number,
  expected: number,
  tolerance: number,
  description: string
): void {
  const diff = Math.abs(actual - expected);
  assert(
    diff <= tolerance,
    `${description} (esperado=${expected}, atual=${actual}, tolerância=${tolerance})`
  );
}

function printSection(title: string): void {
  console.log(`\n${'='.repeat(72)}`);
  console.log(`  ${title}`);
  console.log(`${'='.repeat(72)}`);
}

// --------------------------------------------------------------------
// FÁBRICA DE PERSONAGEM
// --------------------------------------------------------------------
function baseStats(overrides?: Partial<ICharacterStats>): ICharacterStats {
  return {
    maxHp: 100,
    currentHp: 100,
    damage: 10,
    defense: 50,
    resilience: 5,
    movementSpeed: 10,
    ...overrides,
  };
}

function makeHero(id: string): CharacterState {
  return new CharacterState(
    baseStats(),
    undefined,
    undefined,
    undefined,
    null,
    id,
  );
}

// Silencia o logger de insubordinação durante o teste (mantém a saída limpa).
const silentLogger = (): void => {};

// ====================================================================
// TESTE — TURNO PATERNO (+100): CURA BLOQUEADA + EP +30%
// ====================================================================
function runPaternoTurn(): void {
  printSection('INTEGRAÇÃO A/B — Turno com Estafa = +100 (Paterno)');

  const hero = makeHero('hero_paterno_01');
  hero.shortTermEstafa = 100; // extremo Paterno
  assert(hero.shortTermEstafa === 100, 'Setup: estafa do herói = +100');

  // --- A) Comando de cura compassiva é redirecionado para ação autônoma ---
  const resolution = CombatAIEngine.resolvePlayerCommand(
    hero,
    'COMPASSIONATE_HEAL',
    silentLogger,
  );

  assert(resolution.allowed === false, 'A.1: COMPASSIONATE_HEAL bloqueada no Paterno');
  assert(resolution.insubordination === true, 'A.2: marca insubordinação tática');
  assert(!!resolution.reason, 'A.3: aviso diegético (reason) presente');
  assert(
    !!resolution.autonomousAlternative,
    'A.4: ação autônoma (autonomousAlternative) presente para execução'
  );
  assert(
    resolution.actorId === 'hero_paterno_01',
    'A.5: resolução referencia o ator correto'
  );

  // --- B) Custo de EP das habilidades sobe +30% ---
  const baseCost = 40;
  const effectiveCost = hero.getEffectiveEpCost(baseCost);
  assertApprox(effectiveCost, 52, 0.001, 'B.1: custo de EP 40 → 52 (+30%)');

  const epCostIncrease = hero.getEstafaModifiers().epCostIncrease;
  assertApprox(epCostIncrease, 30, 0.001, 'B.2: modificador epCostIncrease = +30%');

  // --- C) Defesa física efetiva sobe +40% (rigidez Paterna) ---
  const effectiveDef = hero.getEffectivePhysicalDefense();
  assertApprox(effectiveDef, 70, 0.001, 'C.1: defesa 50 → 70 (+40%) no Paterno');

  // --- Sanidade: ação padrão nunca é bloqueada ---
  const standard = CombatAIEngine.resolvePlayerCommand(hero, 'STANDARD', silentLogger);
  assert(standard.allowed === true && !standard.insubordination, 'C.2: STANDARD permitida');
}

// ====================================================================
// TESTE — TURNO MATERNO (-100): FRIEZA BLOQUEADA + EP REGEN
// ====================================================================
function runMaternoTurn(): void {
  printSection('INTEGRAÇÃO C — Turno com Estafa = -100 (Materno)');

  const hero = makeHero('hero_materno_01');
  hero.shortTermEstafa = -100; // extremo Materno
  assert(hero.shortTermEstafa === -100, 'Setup: estafa do herói = -100');

  // Execução a sangue-frio é bloqueada pela Empatia Ativa.
  const coldExec = CombatAIEngine.resolvePlayerCommand(
    hero,
    'COLD_EXECUTION',
    silentLogger,
  );
  assert(coldExec.insubordination === true, 'D.1: COLD_EXECUTION vira ação autônoma');
  assert(!!coldExec.autonomousAlternative, 'D.2: autonomousAlternative presente');

  // Bônus de regeneração de EP (+50%) e sem encarecimento de EP.
  assertApprox(hero.getEpRegenBonusPercent(), 50, 0.001, 'D.3: EP regen bonus = +50%');
  assertApprox(
    hero.getEffectiveEpCost(40),
    40,
    0.001,
    'D.4: custo de EP inalterado no Materno (40 → 40)'
  );

  // Cura compassiva é compatível com a psique Materna (permitida).
  const heal = CombatAIEngine.resolvePlayerCommand(hero, 'COMPASSIONATE_HEAL', silentLogger);
  assert(heal.allowed === true, 'D.5: COMPASSIONATE_HEAL permitida no Materno');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
  runPaternoTurn();
  runMaternoTurn();

  console.log(`\n${'='.repeat(72)}`);
  console.log(`  RELATÓRIO DE INTEGRAÇÃO — Estafa × Combate`);
  console.log(`${'='.repeat(72)}`);
  console.log(`  Total de testes:    ${totalTests}`);
  console.log(`  Aprovados (PASS):   ${passedTests}`);
  console.log(`  Reprovados (FAIL):  ${failedTests}`);
  console.log(
    `  Taxa de sucesso:    ${
      totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'
    }%`
  );
  console.log(`${'='.repeat(72)}`);

  if (failedTests > 0) {
    console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar integração.\n`);
    process.exit(1);
  } else {
    console.log(`\n  ✅ TODOS OS TESTES DE INTEGRAÇÃO PASSARAM\n`);
    process.exit(0);
  }
}

main();
