/**
 * ====================================================================
 * EstafaCalculator.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Balança de Estafa.
 *
 * Cobre:
 *   A) Clamp — limitação estrita a [-100, +100] (inclui NaN → 0).
 *   B) calculateModifiers — bônus/penalidades para Materno (-100),
 *      Paterno (+100) e Neutro (0).
 *   C) getQuadrant — NEUTRAL, MATERNO_EXTREMO, PATERNO_EXTREMO.
 *   D) validateAction — bloqueios e autonomousAlternative.
 *
 * Execução (convenção do projeto): npx tsx src/mechanics/__tests__/EstafaCalculator.test.ts
 *
 * Fonte: src/mechanics/EstafaCalculator.ts
 *        AETHERIS_MASTER_INDEX.md §2, §3
 * ====================================================================
 */

import {
  EstafaCalculator,
  EstafaQuadrant,
  ESTAFA_MIN,
  ESTAFA_MAX,
} from '../EstafaCalculator';

// --------------------------------------------------------------------
// HARNESS DE TESTE (padrão do projeto — sem framework externo)
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

// ====================================================================
// A) CLAMP
// ====================================================================
function runTestA(): void {
  printSection('TESTE A — Clamp [-100, +100]');

  assert(EstafaCalculator.clamp(250) === ESTAFA_MAX, `250 → clamp em +${ESTAFA_MAX}`);
  assert(EstafaCalculator.clamp(-250) === ESTAFA_MIN, `-250 → clamp em ${ESTAFA_MIN}`);
  assert(EstafaCalculator.clamp(100) === 100, '100 permanece 100 (limite superior)');
  assert(EstafaCalculator.clamp(-100) === -100, '-100 permanece -100 (limite inferior)');
  assert(EstafaCalculator.clamp(0) === 0, '0 permanece 0');
  assert(EstafaCalculator.clamp(42) === 42, 'valor interno (42) inalterado');
  assert(EstafaCalculator.clamp(NaN) === 0, 'NaN → 0 (fallback seguro)');
}

// ====================================================================
// B) calculateModifiers
// ====================================================================
function runTestB(): void {
  printSection('TESTE B — calculateModifiers (Materno / Paterno / Neutro)');

  // --- Materno extremo (-100) ---
  const materno = EstafaCalculator.calculateModifiers(-100);
  assertApprox(materno.epRegenBonus, 50, 0.001, 'Materno(-100): epRegenBonus = +50%');
  assertApprox(materno.armorPenalty, 20, 0.001, 'Materno(-100): armorPenalty = 20%');
  assert(materno.physicalDefBonus === 0, 'Materno(-100): physicalDefBonus = 0');
  assert(materno.epCostIncrease === 0, 'Materno(-100): epCostIncrease = 0');

  // --- Paterno extremo (+100) ---
  const paterno = EstafaCalculator.calculateModifiers(100);
  assertApprox(paterno.physicalDefBonus, 40, 0.001, 'Paterno(+100): physicalDefBonus = +40%');
  assertApprox(paterno.epCostIncrease, 30, 0.001, 'Paterno(+100): epCostIncrease = +30%');
  assert(paterno.epRegenBonus === 0, 'Paterno(+100): epRegenBonus = 0');
  assert(paterno.armorPenalty === 0, 'Paterno(+100): armorPenalty = 0');

  // --- Neutro (0) ---
  const neutro = EstafaCalculator.calculateModifiers(0);
  assert(
    neutro.epRegenBonus === 0 &&
      neutro.armorPenalty === 0 &&
      neutro.physicalDefBonus === 0 &&
      neutro.epCostIncrease === 0,
    'Neutro(0): todos os modificadores zerados'
  );

  // --- Escala intermediária (fórmulas canônicas) ---
  const m60 = EstafaCalculator.calculateModifiers(-60);
  assertApprox(m60.epRegenBonus, 30, 0.001, 'Materno(-60): epRegenBonus = +30%');
  assertApprox(m60.armorPenalty, 12, 0.001, 'Materno(-60): armorPenalty = 12%');

  const p60 = EstafaCalculator.calculateModifiers(60);
  assertApprox(p60.physicalDefBonus, 24, 0.001, 'Paterno(+60): physicalDefBonus = +24%');
  assertApprox(p60.epCostIncrease, 18, 0.001, 'Paterno(+60): epCostIncrease = +18%');

  // --- Clamp aplicado antes do cálculo ---
  const overflow = EstafaCalculator.calculateModifiers(500);
  assertApprox(overflow.physicalDefBonus, 40, 0.001, 'Overflow(500) tratado como +100 (cap +40%)');
}

// ====================================================================
// C) getQuadrant
// ====================================================================
function runTestC(): void {
  printSection('TESTE C — getQuadrant');

  // NEUTRAL
  assert(EstafaCalculator.getQuadrant(0) === EstafaQuadrant.NEUTRAL, 'q(0) = NEUTRAL');
  assert(EstafaCalculator.getQuadrant(-59) === EstafaQuadrant.NEUTRAL, 'q(-59) = NEUTRAL');
  assert(EstafaCalculator.getQuadrant(59) === EstafaQuadrant.NEUTRAL, 'q(+59) = NEUTRAL');

  // MATERNO_EXTREMO (<= -60)
  assert(
    EstafaCalculator.getQuadrant(-60) === EstafaQuadrant.MATERNO_EXTREMO,
    'q(-60) = MATERNO_EXTREMO (limite)'
  );
  assert(
    EstafaCalculator.getQuadrant(-100) === EstafaQuadrant.MATERNO_EXTREMO,
    'q(-100) = MATERNO_EXTREMO'
  );

  // PATERNO_EXTREMO (>= +60)
  assert(
    EstafaCalculator.getQuadrant(60) === EstafaQuadrant.PATERNO_EXTREMO,
    'q(+60) = PATERNO_EXTREMO (limite)'
  );
  assert(
    EstafaCalculator.getQuadrant(100) === EstafaQuadrant.PATERNO_EXTREMO,
    'q(+100) = PATERNO_EXTREMO'
  );
}

// ====================================================================
// D) validateAction
// ====================================================================
function runTestD(): void {
  printSection('TESTE D — validateAction (Insubordinação Tática)');

  // --- STANDARD sempre permitida ---
  assert(
    EstafaCalculator.validateAction(-100, 'STANDARD').allowed === true,
    'STANDARD permitida no extremo Materno'
  );
  assert(
    EstafaCalculator.validateAction(100, 'STANDARD').allowed === true,
    'STANDARD permitida no extremo Paterno'
  );

  // --- Empatia Ativa (Materno bloqueia frieza) ---
  const sacrifice = EstafaCalculator.validateAction(-80, 'SACRIFICE');
  assert(sacrifice.allowed === false, 'Materno(-80): SACRIFICE bloqueado');
  assert(!!sacrifice.reason, 'Materno(-80): SACRIFICE possui reason');
  assert(
    !!sacrifice.autonomousAlternative,
    'Materno(-80): SACRIFICE possui autonomousAlternative'
  );

  const coldExec = EstafaCalculator.validateAction(-100, 'COLD_EXECUTION');
  assert(coldExec.allowed === false, 'Materno(-100): COLD_EXECUTION bloqueado');
  assert(
    !!coldExec.autonomousAlternative,
    'Materno(-100): COLD_EXECUTION possui autonomousAlternative'
  );

  // --- Cálculo Tático (Paterno bloqueia compaixão) ---
  const heal = EstafaCalculator.validateAction(75, 'COMPASSIONATE_HEAL');
  assert(heal.allowed === false, 'Paterno(+75): COMPASSIONATE_HEAL bloqueado');
  assert(
    !!heal.autonomousAlternative,
    'Paterno(+75): COMPASSIONATE_HEAL possui autonomousAlternative'
  );

  const share = EstafaCalculator.validateAction(100, 'SHARE_ITEM');
  assert(share.allowed === false, 'Paterno(+100): SHARE_ITEM bloqueado');
  assert(!!share.reason, 'Paterno(+100): SHARE_ITEM possui reason');

  // --- Compatibilidade cruzada (não deve bloquear) ---
  assert(
    EstafaCalculator.validateAction(-100, 'COMPASSIONATE_HEAL').allowed === true,
    'Materno(-100): COMPASSIONATE_HEAL é compatível (permitido)'
  );
  assert(
    EstafaCalculator.validateAction(100, 'SACRIFICE').allowed === true,
    'Paterno(+100): SACRIFICE é compatível (permitido)'
  );

  // --- Zona neutra não bloqueia nada ---
  assert(
    EstafaCalculator.validateAction(0, 'SACRIFICE').allowed === true &&
      EstafaCalculator.validateAction(0, 'COMPASSIONATE_HEAL').allowed === true,
    'Neutro(0): nenhuma ação é bloqueada'
  );
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
  runTestA();
  runTestB();
  runTestC();
  runTestD();

  console.log(`\n${'='.repeat(72)}`);
  console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — EstafaCalculator`);
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
    console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar implementação.\n`);
    process.exit(1);
  } else {
    console.log(`\n  ✅ TODOS OS TESTES PASSARAM — HOMOLOGAÇÃO APROVADA\n`);
    process.exit(0);
  }
}

main();
