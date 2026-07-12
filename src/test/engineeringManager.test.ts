/**
 * ====================================================================
 * engineeringManager.test.ts
 * --------------------------------------------------------------------
 * Suite de validação — EngineeringManager.processEngineeringUsage.
 * Cobre:
 *   - Consumo correto de carga física por HUMAN/DWARF
 *   - Bloqueio por falta de carga (HUMAN/DWARF sem suprimento)
 *   - Bypass limpo para raças místicas (ELF, FAERIE, DRACONIAN,
 *     LURID, e personagem sem raça definida)
 *   - Garantia de que shortTermEstafa nunca é tocado por este método
 *   - reloadKit: recarga segura de cargas físicas, com e sem teto
 *
 * Fonte: src/modules/engineering/EngineeringManager.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import {
  EngineeringManager,
  IEngineeringKit,
} from '../modules/engineering/EngineeringManager';
import { CharacterState } from '../core/CharacterState';
import {
  ICharacterStats,
  ISkillOrSpell,
  ElementType,
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

function createCharacter(race: Race | null = null): CharacterState {
  return new CharacterState(
    createBaseStats(),
    LatentLineageAxis.NEUTRO_ABSOLUTO,
    undefined,
    undefined,
    race,
  );
}

function createSkill(element?: ElementType, estafaCost = 40): ISkillOrSpell {
  return {
    id: 'SKL_ENG_TEST',
    name: 'Skill de Teste de Engenharia',
    description: 'Skill fabricada para homologação do EngineeringManager',
    estafaCost,
    minRequiredLevel: 1,
    cooldownTurns: 1,
    effectType: 'DAMAGE',
    element,
    execute: () => 0,
  };
}

/** Kit de engenharia com cargas explícitas para os três elementos físicos */
function createKit(fire: number, ice: number, lightning: number): IEngineeringKit {
  return {
    charges: {
      FIRE: fire,
      ICE: ice,
      LIGHTNING: lightning,
    },
  };
}

// ====================================================================
// CENÁRIO A: CONSUMO CORRETO DE CARGA POR HUMAN/DWARF
// ====================================================================

function runTestA(): void {
  printSection('CENÁRIO A — CONSUMO CORRETO DE CARGA FÍSICA (HUMAN/DWARF)');

  const engineeringMatrix: Array<{ race: Race; element: ElementType }> = [
    { race: Race.HUMAN, element: 'LIGHTNING' },
    { race: Race.DWARF, element: 'ICE' },
  ];

  for (const { race, element } of engineeringMatrix) {
    printSubSection(`A.${race} — carga de ${element} disponível`);

    const character = createCharacter(race);
    const initialEstafa = character.shortTermEstafa;
    const skill = createSkill(element, 40);
    const kit = createKit(2, 2, 2);

    const result = EngineeringManager.processEngineeringUsage(character, skill, kit);

    assert(result === true, `${race}: processEngineeringUsage retorna true: ${result}`);
    assert(kit.charges[element] === 1,
      `${race}: carga de ${element} decrementada de 2 para 1: ${kit.charges[element]}`);
    assert(character.shortTermEstafa === initialEstafa,
      `${race}: shortTermEstafa não foi tocado (custo de estafa desconsiderado): ${character.shortTermEstafa} === ${initialEstafa}`);

    // As demais cargas do kit permanecem intactas
    const otherElements = (['FIRE', 'ICE', 'LIGHTNING'] as ElementType[]).filter((e) => e !== element);
    for (const other of otherElements) {
      assert(kit.charges[other] === 2,
        `${race}: carga de ${other} permanece intacta (2): ${kit.charges[other]}`);
    }
  }
}

// ====================================================================
// CENÁRIO B: BLOQUEIO POR FALTA DE CARGA
// ====================================================================

function runTestB(): void {
  printSection('CENÁRIO B — BLOQUEIO POR FALTA DE CARGA (HUMAN/DWARF)');

  printSubSection('B.1 — HUMAN sem carga do elemento da skill (FIRE = 0)');

  const humanChar = createCharacter(Race.HUMAN);
  const initialEstafaHuman = humanChar.shortTermEstafa;
  const fireSkill = createSkill('FIRE', 40);
  const emptyKit = createKit(0, 3, 3);

  const resultNoCharge = EngineeringManager.processEngineeringUsage(humanChar, fireSkill, emptyKit);

  assert(resultNoCharge === false,
    `HUMAN sem carga de FIRE: processEngineeringUsage retorna false: ${resultNoCharge}`);
  assert(emptyKit.charges.FIRE === 0,
    `Carga de FIRE permanece em 0 (nenhum decremento abaixo de zero): ${emptyKit.charges.FIRE}`);
  assert(humanChar.shortTermEstafa === initialEstafaHuman,
    `shortTermEstafa não foi tocado mesmo na falha: ${humanChar.shortTermEstafa} === ${initialEstafaHuman}`);

  printSubSection('B.2 — DWARF com skill sem elemento definido');

  const dwarfChar = createCharacter(Race.DWARF);
  const skillNoElement = createSkill(undefined, 40);
  const fullKit = createKit(5, 5, 5);

  const resultNoElement = EngineeringManager.processEngineeringUsage(dwarfChar, skillNoElement, fullKit);

  assert(resultNoElement === false,
    `DWARF com skill sem elemento: processEngineeringUsage retorna false: ${resultNoElement}`);
  assert(fullKit.charges.FIRE === 5 && fullKit.charges.ICE === 5 && fullKit.charges.LIGHTNING === 5,
    'Nenhuma carga do kit foi consumida quando a skill não tem elemento definido');
}

// ====================================================================
// CENÁRIO C: BYPASS LIMPO PARA RAÇAS MÍSTICAS
// ====================================================================

function runTestC(): void {
  printSection('CENÁRIO C — BYPASS LIMPO PARA RAÇAS MÍSTICAS (FLUXO PADRÃO DE ESTAFA)');

  const mysticRaces: Array<Race | null> = [
    Race.ELF,
    Race.FAERIE,
    Race.DRACONIAN,
    Race.LURID,
    null, // personagem sem raça definida
  ];

  for (const race of mysticRaces) {
    const label = race ?? 'null (sem raça)';
    printSubSection(`C.${label} — deve autorizar o fluxo místico sem tocar no kit`);

    const character = createCharacter(race);
    const initialEstafa = character.shortTermEstafa;
    // Elemento arbitrário e kit vazio — não deve importar para raças místicas
    const skill = createSkill('FIRE', 40);
    const emptyKit = createKit(0, 0, 0);

    const result = EngineeringManager.processEngineeringUsage(character, skill, emptyKit);

    assert(result === true,
      `${label}: processEngineeringUsage retorna true mesmo com kit vazio: ${result}`);
    assert(
      emptyKit.charges.FIRE === 0 && emptyKit.charges.ICE === 0 && emptyKit.charges.LIGHTNING === 0,
      `${label}: kit permanece intocado (bypass não consome cargas)`,
    );
    assert(character.shortTermEstafa === initialEstafa,
      `${label}: shortTermEstafa não foi tocado por este gate: ${character.shortTermEstafa} === ${initialEstafa}`);
  }
}

// ====================================================================
// CENÁRIO D: RELOADKIT — RECARGA SEGURA DE CARGAS FÍSICAS
// ====================================================================

function runTestD(): void {
  printSection('CENÁRIO D — reloadKit: RECARGA SEGURA DE CARGAS FÍSICAS');

  printSubSection('D.1 — Recarga simples, sem teto definido (maxCharges omitido)');

  const kitNoLimit = createKit(1, 2, 3);
  EngineeringManager.reloadKit(kitNoLimit, 'FIRE', 3);

  assert(kitNoLimit.charges.FIRE === 4, `FIRE recarregado de 1 para 4: ${kitNoLimit.charges.FIRE}`);
  assert(kitNoLimit.charges.ICE === 2, `ICE permanece intocado: ${kitNoLimit.charges.ICE}`);
  assert(kitNoLimit.charges.LIGHTNING === 3, `LIGHTNING permanece intocado: ${kitNoLimit.charges.LIGHTNING}`);

  printSubSection('D.2 — Recarga respeita o teto (maxCharges) quando o amount excede o espaço restante');

  const kitWithCap: IEngineeringKit = { charges: { FIRE: 4, ICE: 0, LIGHTNING: 0 }, maxCharges: 5 };
  EngineeringManager.reloadKit(kitWithCap, 'FIRE', 10);

  assert(kitWithCap.charges.FIRE === 5,
    `FIRE travado no teto de 5 (não 14): ${kitWithCap.charges.FIRE}`);

  printSubSection('D.3 — Recarga em elemento já no teto não estoura o limite');

  const kitAtCap: IEngineeringKit = { charges: { FIRE: 0, ICE: 5, LIGHTNING: 0 }, maxCharges: 5 };
  EngineeringManager.reloadKit(kitAtCap, 'ICE', 1);

  assert(kitAtCap.charges.ICE === 5, `ICE permanece em 5 (já estava no teto): ${kitAtCap.charges.ICE}`);

  printSubSection('D.4 — Proteção contra amount inválido (no-op seguro)');

  const invalidAmounts = [-5, 0, NaN, Infinity, -Infinity];

  for (const invalidAmount of invalidAmounts) {
    const kit = createKit(2, 2, 2);
    EngineeringManager.reloadKit(kit, 'LIGHTNING', invalidAmount);

    assert(kit.charges.LIGHTNING === 2,
      `amount=${invalidAmount}: reloadKit é no-op, carga permanece em 2: ${kit.charges.LIGHTNING}`);
  }
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  ENGINEERING MANAGER TEST SUITE — processEngineeringUsage`);
  console.log(`#  Motor: EngineeringManager.ts / CharacterState.ts`);
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
