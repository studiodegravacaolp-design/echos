/**
 * ====================================================================
 * inventoryCombat.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — Débito técnico: Carga Máxima (Max Load).
 * Valida:
 *   - Bloqueio de addItem() quando o peso potencial excede a Carga
 *     Máxima (_maxWeightPenalty) do InventoryManager
 *   - Integridade dos slots após uma inserção rejeitada por peso
 *   - Sincronização correta de peso via syncWeightWithCharacter
 *     quando a Carga Máxima está dentro do limite
 *
 * Fonte: src/core/InventoryManager.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import {
  InventoryManager,
  syncWeightWithCharacter,
} from '../core/InventoryManager';
import { CharacterState } from '../core/CharacterState';
import { ICharacterStats, IItem } from '../types/aetheris.types';

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

function createItem(id: string, name: string, weight: number, maxStack: number): IItem {
  return { id, name, weight, maxStack };
}

// ====================================================================
// CENÁRIO A: BLOQUEIO DE ADIÇÃO POR CARGA MÁXIMA EXCEDIDA
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — BLOQUEIO DE ADIÇÃO POR CARGA MÁXIMA EXCEDIDA');

  // ----------------------------------------------------------------
  // Setup: Inventário com Carga Máxima de 150 (padrão)
  // ----------------------------------------------------------------
  const inventory = new InventoryManager(30);

  assert(inventory.maxWeightPenalty === 150,
    `Carga Máxima padrão: ${inventory.maxWeightPenalty} === 150`);

  // ----------------------------------------------------------------
  // Subteste A.1: Adição dentro da Carga Máxima é aceita
  // ----------------------------------------------------------------
  printSubSection('A.1 — Adição dentro da Carga Máxima (peso 100)');

  const lingote = createItem('ITEM_LINGOTE_001', 'Lingote de Ferro', 10, 20);
  const addedOk = inventory.addItem(lingote, 10); // peso total: 100

  assert(addedOk === true,
    `addItem(peso=100) dentro da Carga Máxima retorna true: ${addedOk}`);
  assert(inventory.calculateTotalWeight() === 100,
    `Peso total após inserção válida: ${inventory.calculateTotalWeight()} === 100`);

  // ----------------------------------------------------------------
  // Subteste A.2: Adição que excede a Carga Máxima é REJEITADA
  // ----------------------------------------------------------------
  printSubSection('A.2 — Adição que excede a Carga Máxima (100 + 60 > 150)');

  const weightBefore = inventory.calculateTotalWeight();
  const slotsBefore = inventory.occupiedSlots;

  // Peso potencial: 100 (atual) + (10 * 6) = 160 > 150 (Carga Máxima)
  const rejected = inventory.addItem(lingote, 6);

  assert(rejected === false,
    `addItem(peso potencial=160) excede Carga Máxima e retorna false: ${rejected}`);

  // ----------------------------------------------------------------
  // Subteste A.3: Inserção rejeitada NÃO deve alterar o estado do inventário
  // ----------------------------------------------------------------
  printSubSection('A.3 — Integridade do inventário após rejeição');

  assert(inventory.calculateTotalWeight() === weightBefore,
    `Peso total inalterado após rejeição: ${inventory.calculateTotalWeight()} === ${weightBefore}`);
  assert(inventory.occupiedSlots === slotsBefore,
    `Slots ocupados inalterados após rejeição: ${inventory.occupiedSlots} === ${slotsBefore}`);

  // ----------------------------------------------------------------
  // Subteste A.4: Adição exatamente no limite da Carga Máxima é aceita
  // ----------------------------------------------------------------
  printSubSection('A.4 — Adição exatamente no limite da Carga Máxima (100 + 50 === 150)');

  const exactFit = inventory.addItem(lingote, 5); // peso total: 100 + 50 = 150

  assert(exactFit === true,
    `addItem(peso potencial=150) no limite exato retorna true: ${exactFit}`);
  assert(inventory.calculateTotalWeight() === 150,
    `Peso total no limite exato: ${inventory.calculateTotalWeight()} === 150`);

  // ----------------------------------------------------------------
  // Subteste A.5: Qualquer adição adicional agora é rejeitada
  // ----------------------------------------------------------------
  printSubSection('A.5 — Inventário saturado rejeita qualquer novo peso');

  const overflowSingleUnit = inventory.addItem(lingote, 1); // 150 + 10 = 160

  assert(overflowSingleUnit === false,
    `addItem(1 unidade) com inventário saturado retorna false: ${overflowSingleUnit}`);
}

// ====================================================================
// CENÁRIO B: CARGA MÁXIMA CUSTOMIZADA E SINCRONIZAÇÃO
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — CARGA MÁXIMA CUSTOMIZADA E SINCRONIZAÇÃO COM CharacterState');

  // ----------------------------------------------------------------
  // Setup: Inventário com Carga Máxima customizada (50) e personagem
  // ----------------------------------------------------------------
  printSubSection('B.1 — Construtor aceita Carga Máxima customizada');

  const inventory = new InventoryManager(30, 50);
  assert(inventory.maxWeightPenalty === 50,
    `Carga Máxima customizada: ${inventory.maxWeightPenalty} === 50`);

  const stats = createBaseStats({ movementSpeed: 100 });
  const character = new CharacterState(stats);

  const espada = createItem('ITEM_ESPADA_001', 'Espada Longa', 15, 1);

  // ----------------------------------------------------------------
  // Subteste B.2: Adição válida sincroniza corretamente com o personagem
  // ----------------------------------------------------------------
  printSubSection('B.2 — Sincronização de peso válido com CharacterState');

  const added = inventory.addItem(espada, 3); // peso: 45 <= 50
  assert(added === true, `addItem(peso=45) dentro da Carga Máxima (50): ${added}`);

  syncWeightWithCharacter(inventory, character);

  assert(character.inventoryWeight === 45,
    `character.inventoryWeight sincronizado: ${character.inventoryWeight} === 45`);

  // ----------------------------------------------------------------
  // Subteste B.3: Tentativa de exceder a Carga Máxima customizada é bloqueada
  // ----------------------------------------------------------------
  printSubSection('B.3 — Bloqueio respeita a Carga Máxima customizada (45 + 15 > 50)');

  const blocked = inventory.addItem(espada, 1); // peso potencial: 45 + 15 = 60 > 50
  assert(blocked === false,
    `addItem(peso potencial=60) excede Carga Máxima customizada (50): ${blocked}`);

  // ----------------------------------------------------------------
  // Subteste B.4: Peso do personagem permanece consistente após bloqueio
  // ----------------------------------------------------------------
  printSubSection('B.4 — CharacterState não reflete peso rejeitado');

  syncWeightWithCharacter(inventory, character);
  assert(character.inventoryWeight === 45,
    `character.inventoryWeight permanece inalterado: ${character.inventoryWeight} === 45`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  INVENTORY COMBAT TEST SUITE — DÉBITO TÉCNICO: CARGA MÁXIMA`);
  console.log(`#  Motor: InventoryManager.ts / CombatEngine.ts`);
  console.log(`${'#'.repeat(72)}\n`);

  runTestA();
  runTestB();

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
