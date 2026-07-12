/**
 * ====================================================================
 * salvageManager.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — SalvageManager.craftCharge.
 * Cobre:
 *   - Fabricação bem-sucedida (sucata suficiente, custo padrão e customizado)
 *   - Bloqueio por sucata insuficiente
 *   - Proteção contra scrapCost inválido
 *   - Integração real com EngineeringManager.reloadKit (respeita maxCharges)
 *
 * Fonte: src/modules/engineering/SalvageManager.ts
 *        src/modules/engineering/EngineeringManager.ts
 * ====================================================================
 */

import {
  SalvageManager,
  ISalvageInventory,
} from '../modules/engineering/SalvageManager';
import { IEngineeringKit } from '../modules/engineering/EngineeringManager';

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

function createKit(fire: number, ice: number, lightning: number, maxCharges?: number): IEngineeringKit {
  return {
    charges: { FIRE: fire, ICE: ice, LIGHTNING: lightning },
    maxCharges,
  };
}

// ====================================================================
// CENÁRIO A: FABRICAÇÃO BEM-SUCEDIDA
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — FABRICAÇÃO BEM-SUCEDIDA DE CARGA');

  printSubSection('A.1 — Custo padrão (20 sucata)');

  const inventory = createInventory(25);
  const kit = createKit(0, 0, 0);

  const result = SalvageManager.craftCharge(inventory, kit, 'FIRE');

  assert(result === true, `craftCharge retorna true: ${result}`);
  assert(inventory.scrapCount === 5, `Sucata deduzida (25 - 20 = 5): ${inventory.scrapCount}`);
  assert(kit.charges.FIRE === 1, `Carga de FIRE fabricada (0 → 1): ${kit.charges.FIRE}`);
  assert(kit.charges.ICE === 0 && kit.charges.LIGHTNING === 0,
    'Demais elementos do kit permanecem intocados');

  printSubSection('A.2 — Custo customizado (scrapCost explícito)');

  const inventoryCustom = createInventory(50);
  const kitCustom = createKit(0, 0, 0);

  const resultCustom = SalvageManager.craftCharge(inventoryCustom, kitCustom, 'ICE', 10);

  assert(resultCustom === true, `craftCharge com custo customizado retorna true: ${resultCustom}`);
  assert(inventoryCustom.scrapCount === 40, `Sucata deduzida (50 - 10 = 40): ${inventoryCustom.scrapCount}`);
  assert(kitCustom.charges.ICE === 1, `Carga de ICE fabricada (0 → 1): ${kitCustom.charges.ICE}`);
}

// ====================================================================
// CENÁRIO B: BLOQUEIO POR SUCATA INSUFICIENTE
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — BLOQUEIO POR SUCATA INSUFICIENTE');

  const inventory = createInventory(15); // Abaixo do custo padrão (20)
  const kit = createKit(0, 0, 0);

  const result = SalvageManager.craftCharge(inventory, kit, 'LIGHTNING');

  assert(result === false, `craftCharge retorna false (sucata insuficiente): ${result}`);
  assert(inventory.scrapCount === 15, `Sucata NÃO deduzida: ${inventory.scrapCount}`);
  assert(kit.charges.LIGHTNING === 0, `Kit permanece intocado: ${kit.charges.LIGHTNING}`);
}

// ====================================================================
// CENÁRIO C: PROTEÇÃO CONTRA scrapCost INVÁLIDO
// ====================================================================

function runTestC(): void {
  printSection('CENÁRIO C — PROTEÇÃO CONTRA scrapCost INVÁLIDO');

  const invalidCosts = [0, -10, NaN, Infinity, -Infinity];

  for (const invalidCost of invalidCosts) {
    const inventory = createInventory(1000); // Sucata de sobra — não é o motivo da falha
    const kit = createKit(0, 0, 0);

    const result = SalvageManager.craftCharge(inventory, kit, 'FIRE', invalidCost);

    assert(result === false, `scrapCost=${invalidCost}: craftCharge retorna false: ${result}`);
    assert(inventory.scrapCount === 1000, `scrapCost=${invalidCost}: sucata não deduzida: ${inventory.scrapCount}`);
    assert(kit.charges.FIRE === 0, `scrapCost=${invalidCost}: kit não alterado: ${kit.charges.FIRE}`);
  }
}

// ====================================================================
// CENÁRIO D: INTEGRAÇÃO REAL COM EngineeringManager.reloadKit (TETO)
// ====================================================================

function runTestD(): void {
  printSection('CENÁRIO D — INTEGRAÇÃO REAL: craftCharge RESPEITA O TETO DO KIT (maxCharges)');

  const inventory = createInventory(100);
  const kit = createKit(5, 0, 0, 5); // FIRE já no teto de 5

  const result = SalvageManager.craftCharge(inventory, kit, 'FIRE');

  assert(result === true, `craftCharge retorna true mesmo com o kit no teto: ${result}`);
  assert(inventory.scrapCount === 80, `Sucata deduzida normalmente (100 - 20 = 80): ${inventory.scrapCount}`);
  assert(kit.charges.FIRE === 5,
    `Carga de FIRE travada no teto de 5 (reloadKit real aplicado): ${kit.charges.FIRE}`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  SALVAGE MANAGER TEST SUITE — craftCharge`);
  console.log(`#  Motor: SalvageManager.ts / EngineeringManager.ts`);
  console.log(`${'#'.repeat(72)}\n`);

  runTestA();
  runTestB();
  runTestC();
  runTestD();

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
