/**
 * ====================================================================
 * statusEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — StatusEngine (Matriz de Efeitos de Status
 * Tecnológicos): TECH_BURN, TECH_SLOW, TECH_CONDUCTIVE.
 * Cobre:
 *   - Aplicação de cada condição e bloqueio de duplicação
 *   - processBurnTick (dano por turno)
 *   - getSlowSpeedMultiplier (redução de velocidade)
 *   - resolveIncomingDamage (amplificação e consumo de TECH_CONDUCTIVE)
 *
 * Fonte: src/modules/combat/StatusEngine.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import { StatusEngine, TECH_STATUS_IDS } from '../modules/combat/StatusEngine';
import { CharacterState } from '../core/CharacterState';
import { ICharacterStats, LatentLineageAxis } from '../types/aetheris.types';

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

function createCharacter(): CharacterState {
  return new CharacterState(createBaseStats(), LatentLineageAxis.NEUTRO_ABSOLUTO);
}

// ====================================================================
// CENÁRIO A: APLICAÇÃO DAS TRÊS CONDIÇÕES + BLOQUEIO DE DUPLICAÇÃO
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — APLICAÇÃO DAS CONDIÇÕES TECNOLÓGICAS');

  const statusIds = [TECH_STATUS_IDS.TECH_BURN, TECH_STATUS_IDS.TECH_SLOW, TECH_STATUS_IDS.TECH_CONDUCTIVE];

  for (const statusId of statusIds) {
    printSubSection(`A.${statusId} — aplicação e bloqueio de duplicação`);

    const character = createCharacter();

    const firstApply = StatusEngine.applyTechStatus(character, statusId);
    assert(firstApply === true, `${statusId}: primeira aplicação retorna true: ${firstApply}`);
    assert(character.hasStatusEffect(statusId), `${statusId}: hasStatusEffect === true`);

    const secondApply = StatusEngine.applyTechStatus(character, statusId);
    assert(secondApply === false,
      `${statusId}: segunda aplicação (já ativo) retorna false: ${secondApply}`);
  }
}

// ====================================================================
// CENÁRIO B: processBurnTick (TECH_BURN)
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — processBurnTick (DANO POR TURNO)');

  printSubSection('B.1 — Sem TECH_BURN ativo: nenhum dano, retorna 0');

  const characterNoBurn = createCharacter();
  const noBurnDamage = StatusEngine.processBurnTick(characterNoBurn);

  assert(noBurnDamage === 0, `Sem TECH_BURN: dano retornado === 0: ${noBurnDamage}`);
  assert(characterNoBurn.stats.currentHp === 1000, `Sem TECH_BURN: HP inalterado: ${characterNoBurn.stats.currentHp}`);

  printSubSection('B.2 — Com TECH_BURN ativo: aplica dano por turno');

  const characterWithBurn = createCharacter();
  StatusEngine.applyTechStatus(characterWithBurn, TECH_STATUS_IDS.TECH_BURN);

  const burnDamage = StatusEngine.processBurnTick(characterWithBurn);

  assert(burnDamage === 15, `Dano de TECH_BURN retornado: ${burnDamage} === 15`);
  assert(characterWithBurn.stats.currentHp === 985,
    `HP reduzido pelo tick de queimadura (1000 - 15 = 985): ${characterWithBurn.stats.currentHp}`);

  // Segundo tick — TECH_BURN continua ativo (remoção de duração não é
  // responsabilidade deste método) e aplica dano novamente
  const secondTickDamage = StatusEngine.processBurnTick(characterWithBurn);
  assert(secondTickDamage === 15, `Segundo tick também aplica 15 de dano: ${secondTickDamage}`);
  assert(characterWithBurn.stats.currentHp === 970,
    `HP após segundo tick (985 - 15 = 970): ${characterWithBurn.stats.currentHp}`);
}

// ====================================================================
// CENÁRIO C: getSlowSpeedMultiplier (TECH_SLOW)
// ====================================================================

function runTestC(): void {
  printSection('CENÁRIO C — getSlowSpeedMultiplier (REDUÇÃO DE VELOCIDADE)');

  printSubSection('C.1 — Sem TECH_SLOW ativo: multiplicador neutro (1.0)');

  const characterNoSlow = createCharacter();
  const noSlowMultiplier = StatusEngine.getSlowSpeedMultiplier(characterNoSlow);

  assert(noSlowMultiplier === 1.0, `Sem TECH_SLOW: multiplicador === 1.0: ${noSlowMultiplier}`);

  printSubSection('C.2 — Com TECH_SLOW ativo: multiplicador reduzido (0.7)');

  const characterWithSlow = createCharacter();
  StatusEngine.applyTechStatus(characterWithSlow, TECH_STATUS_IDS.TECH_SLOW);

  const slowMultiplier = StatusEngine.getSlowSpeedMultiplier(characterWithSlow);

  assert(slowMultiplier === 0.7, `Com TECH_SLOW: multiplicador === 0.7: ${slowMultiplier}`);
}

// ====================================================================
// CENÁRIO D: resolveIncomingDamage (TECH_CONDUCTIVE)
// ====================================================================

function runTestD(): void {
  printSection('CENÁRIO D — resolveIncomingDamage (AMPLIFICAÇÃO E CONSUMO DE TECH_CONDUCTIVE)');

  printSubSection('D.1 — TECH_CONDUCTIVE ativo + dano de LIGHTNING: amplifica 1.5x e consome o status');

  const characterConductive = createCharacter();
  StatusEngine.applyTechStatus(characterConductive, TECH_STATUS_IDS.TECH_CONDUCTIVE);

  const amplifiedDamage = StatusEngine.resolveIncomingDamage(characterConductive, 40, 'LIGHTNING');

  assert(amplifiedDamage === 60, `Dano amplificado (40 * 1.5 = 60): ${amplifiedDamage}`);
  assert(characterConductive.hasStatusEffect(TECH_STATUS_IDS.TECH_CONDUCTIVE) === false,
    'TECH_CONDUCTIVE foi consumido (removido) após o impacto de LIGHTNING');

  printSubSection('D.2 — Segundo impacto de LIGHTNING, sem TECH_CONDUCTIVE: sem amplificação');

  const secondHitDamage = StatusEngine.resolveIncomingDamage(characterConductive, 40, 'LIGHTNING');
  assert(secondHitDamage === 40, `Sem TECH_CONDUCTIVE (já consumido): dano permanece 40: ${secondHitDamage}`);

  printSubSection('D.3 — TECH_CONDUCTIVE ativo + dano de elemento diferente: sem amplificação, status preservado');

  const characterOtherElement = createCharacter();
  StatusEngine.applyTechStatus(characterOtherElement, TECH_STATUS_IDS.TECH_CONDUCTIVE);

  const fireDamage = StatusEngine.resolveIncomingDamage(characterOtherElement, 40, 'FIRE');

  assert(fireDamage === 40, `Dano de FIRE não amplificado: ${fireDamage}`);
  assert(characterOtherElement.hasStatusEffect(TECH_STATUS_IDS.TECH_CONDUCTIVE) === true,
    'TECH_CONDUCTIVE NÃO foi consumido por dano de elemento diferente de LIGHTNING');

  printSubSection('D.4 — Sem TECH_CONDUCTIVE: dano de LIGHTNING não amplificado');

  const characterNoConductive = createCharacter();
  const plainDamage = StatusEngine.resolveIncomingDamage(characterNoConductive, 40, 'LIGHTNING');

  assert(plainDamage === 40, `Sem TECH_CONDUCTIVE: dano de LIGHTNING permanece 40: ${plainDamage}`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  STATUS ENGINE TEST SUITE — TECH_BURN / TECH_SLOW / TECH_CONDUCTIVE`);
  console.log(`#  Motor: StatusEngine.ts / CharacterState.ts`);
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
