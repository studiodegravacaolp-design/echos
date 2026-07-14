/**
 * ====================================================================
 * lootEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — LootEngine.calculateBattleLoot / awardSalvage.
 * Cobre:
 *   - Cálculo proporcional ao nível, com e sem multiplicador mecânico
 *   - Proteção contra enemyLevel inválido
 *   - Concessão de sucata ao inventário, com proteção contra valores inválidos
 *
 * Fonte: src/modules/combat/LootEngine.ts
 *        src/modules/engineering/SalvageManager.ts (ISalvageInventory)
 * ====================================================================
 */

import { LootEngine } from '../modules/combat/LootEngine';
import { ISalvageInventory } from '../modules/engineering/SalvageManager';

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

function createInventory(scrapCount: number): ISalvageInventory {
  return { scrapCount };
}

// ====================================================================
// CENÁRIO A: calculateBattleLoot — CÁLCULO PROPORCIONAL AO NÍVEL
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — calculateBattleLoot: PROPORCIONAL AO NÍVEL E TIPO DO INIMIGO');

  printSubSection('A.1 — Inimigo não-mecânico (multiplicador 1.0x, escalabilidade exponencial)');

  // Fórmula (Sprint 10): round(nível^1.15 * 5 * multiplicador)
  const lootLevel5 = LootEngine.calculateBattleLoot(5, false);
  assert(lootLevel5 === 32, `Nível 5, não-mecânico: round(5^1.15 * 5) = 32: ${lootLevel5}`);

  const lootLevel10 = LootEngine.calculateBattleLoot(10, false);
  assert(lootLevel10 === 71, `Nível 10, não-mecânico: round(10^1.15 * 5) = 71: ${lootLevel10}`);

  printSubSection('A.2 — Inimigo mecânico (multiplicador 2.0x, escalabilidade exponencial)');

  const lootMechanicalLevel5 = LootEngine.calculateBattleLoot(5, true);
  assert(lootMechanicalLevel5 === 64, `Nível 5, mecânico: round(5^1.15 * 5 * 2) = 64: ${lootMechanicalLevel5}`);

  const lootMechanicalLevel10 = LootEngine.calculateBattleLoot(10, true);
  assert(lootMechanicalLevel10 === 141, `Nível 10, mecânico: round(10^1.15 * 5 * 2) = 141: ${lootMechanicalLevel10}`);

  printSubSection('A.3 — Inimigo mecânico concede exatamente o dobro do não-mecânico');

  assert(lootMechanicalLevel5 === lootLevel5 * 2,
    `Mecânico (${lootMechanicalLevel5}) === 2x não-mecânico (${lootLevel5 * 2})`);
}

// ====================================================================
// CENÁRIO B: calculateBattleLoot — PROTEÇÃO CONTRA enemyLevel INVÁLIDO
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — calculateBattleLoot: PROTEÇÃO CONTRA enemyLevel INVÁLIDO');

  const invalidLevels = [0, -5, NaN, -Infinity];

  for (const invalidLevel of invalidLevels) {
    const lootNonMechanical = LootEngine.calculateBattleLoot(invalidLevel, false);
    const lootMechanical = LootEngine.calculateBattleLoot(invalidLevel, true);

    assert(lootNonMechanical === 0, `enemyLevel=${invalidLevel}, não-mecânico: loot === 0: ${lootNonMechanical}`);
    assert(lootMechanical === 0, `enemyLevel=${invalidLevel}, mecânico: loot === 0: ${lootMechanical}`);
  }

  printSubSection('B.1 — Infinity positivo não gera loot infinito/NaN corrompido');

  const lootInfinity = LootEngine.calculateBattleLoot(Infinity, true);
  assert(lootInfinity === 0, `enemyLevel=Infinity: loot === 0 (rejeitado por Number.isFinite): ${lootInfinity}`);
}

// ====================================================================
// CENÁRIO C: awardSalvage — CONCESSÃO SEGURA DE SUCATA
// ====================================================================

function runTestC(): void {
  printSection('CENÁRIO C — awardSalvage: CONCESSÃO SEGURA DE SUCATA');

  printSubSection('C.1 — Concessão válida soma ao inventário existente');

  const inventory = createInventory(10);
  LootEngine.awardSalvage(inventory, 50);

  assert(inventory.scrapCount === 60, `Sucata concedida (10 + 50 = 60): ${inventory.scrapCount}`);

  printSubSection('C.2 — Concessões sucessivas acumulam');

  LootEngine.awardSalvage(inventory, 25);
  assert(inventory.scrapCount === 85, `Segunda concessão acumula (60 + 25 = 85): ${inventory.scrapCount}`);

  printSubSection('C.3 — Proteção contra scrapAmount inválido (no-op seguro)');

  const invalidAmounts = [0, -10, NaN, Infinity, -Infinity];

  for (const invalidAmount of invalidAmounts) {
    const before = inventory.scrapCount;
    LootEngine.awardSalvage(inventory, invalidAmount);

    assert(inventory.scrapCount === before,
      `scrapAmount=${invalidAmount}: inventário inalterado: ${inventory.scrapCount} === ${before}`);
  }
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  LOOT ENGINE TEST SUITE — calculateBattleLoot / awardSalvage`);
  console.log(`#  Motor: LootEngine.ts / SalvageManager.ts`);
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
