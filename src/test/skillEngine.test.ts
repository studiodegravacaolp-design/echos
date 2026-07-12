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
import {
  EngineeringManager,
  IEngineeringKit,
} from '../modules/engineering/EngineeringManager';
import { skillDatabase, SKILL_ID_THERMITE_GRENADE } from '../modules/skills/SkillRegistry';
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

/** Kit de Engenharia Elemental com cargas explícitas para os três elementos físicos */
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
// CENÁRIO D: INTEGRAÇÃO DE ENGENHARIA ELEMENTAL NO SKILLENGINE
// ====================================================================

function runTestD(): void {
  printSection('CENÁRIO D — INTEGRAÇÃO DE ENGENHARIA ELEMENTAL (PONTA A PONTA)');

  const initialHp = 1000;

  // ------------------------------------------------------------------
  // D.1 — HUMAN com carga disponível: bypass total do custo místico,
  // mesmo numa skill cujo estafaCost causaria Backlash amplificado
  // (HUMAN é nativamente fraco a LIGHTNING — ver RACIAL_ELEMENTAL_WEAKNESS)
  // ------------------------------------------------------------------
  printSubSection('D.1 — HUMAN com carga de LIGHTNING: bypass do custo místico e do Backlash');

  const humanCaster = createCharacter(Race.HUMAN, { currentHp: initialHp, maxHp: initialHp });
  const humanTarget = createCharacter(null);
  // estafaCost 150 → se processado misticamente, estouraria o piso em 50
  // e, por HUMAN ser fraco a LIGHTNING, o backlash seria amplificado (75)
  const lightningSkill = createSkill(150, 40, { element: 'LIGHTNING' });
  const humanKit = createKit(0, 0, 2);

  const humanResult = SkillEngine.executeSkill(lightningSkill, humanCaster, humanTarget, undefined, humanKit);

  assert(humanResult.success === true, `D.1: success === true: ${humanResult.success}`);
  assert(humanResult.backlashDamage === 0,
    `D.1: backlashDamage bypassado (0, mesmo com estafaCost 150): ${humanResult.backlashDamage}`);
  assert(humanCaster.shortTermEstafa === 0,
    `D.1: shortTermEstafa do caster intocado: ${humanCaster.shortTermEstafa} === 0`);
  assert(humanCaster.stats.currentHp === initialHp,
    `D.1: HP do caster intocado (sem backlash): ${humanCaster.stats.currentHp} === ${initialHp}`);
  assert(humanKit.charges.LIGHTNING === 1,
    `D.1: carga de LIGHTNING decrementada de 2 para 1: ${humanKit.charges.LIGHTNING}`);
  assert(humanResult.actualDamage === 40,
    `D.1: actualDamage aplicado normalmente ao target: ${humanResult.actualDamage} === 40`);

  // ------------------------------------------------------------------
  // D.2 — DWARF sem carga do elemento da skill: falha por falta de
  // suprimento, execução interrompida antes de qualquer efeito
  // ------------------------------------------------------------------
  printSubSection('D.2 — DWARF sem carga de ICE: falha por falta de suprimento');

  const dwarfCaster = createCharacter(Race.DWARF, { currentHp: initialHp, maxHp: initialHp });
  const dwarfTarget = createCharacter(null);
  const iceSkill = createSkill(20, 40, { element: 'ICE' });
  const emptyKit = createKit(0, 0, 0);

  const dwarfResult = SkillEngine.executeSkill(iceSkill, dwarfCaster, dwarfTarget, undefined, emptyKit);

  assert(dwarfResult.success === false, `D.2: success === false: ${dwarfResult.success}`);
  assert(dwarfResult.backlashDamage === 0, `D.2: backlashDamage === 0: ${dwarfResult.backlashDamage}`);
  assert(dwarfResult.actualDamage === 0, `D.2: actualDamage === 0 (skill.execute nunca rodou): ${dwarfResult.actualDamage}`);
  assert(dwarfCaster.shortTermEstafa === 0,
    `D.2: shortTermEstafa do caster intocado (execução interrompida antes da ETAPA 1): ${dwarfCaster.shortTermEstafa} === 0`);
  assert(dwarfCaster.stats.currentHp === initialHp,
    `D.2: HP do caster intocado: ${dwarfCaster.stats.currentHp} === ${initialHp}`);
  assert(emptyKit.charges.ICE === 0, `D.2: carga de ICE permanece em 0: ${emptyKit.charges.ICE}`);

  // ------------------------------------------------------------------
  // D.3 — Bypass automático para raças místicas (ELF/FAERIE): o kit é
  // ignorado por completo, e o fluxo místico padrão (com Backlash e
  // fraqueza racial) continua operando normalmente
  // ------------------------------------------------------------------
  const mysticMatrix: Array<{ race: Race; weakElement: ElementType }> = [
    { race: Race.ELF, weakElement: 'FIRE' },
    { race: Race.FAERIE, weakElement: 'ICE' },
  ];

  for (const { race, weakElement } of mysticMatrix) {
    printSubSection(`D.3.${race} — kit fornecido mas ignorado: fluxo místico padrão prevalece`);

    const mysticCaster = createCharacter(race, { currentHp: initialHp, maxHp: initialHp });
    mysticCaster.shortTermEstafa = -90;

    const mysticTarget = createCharacter(null);
    // estafaCost 30 → potentialEstafa = -90 - 30 = -120 (estoura o piso em 20)
    const weaknessSkill = createSkill(30, 10, { element: weakElement });
    // Kit generosamente abastecido — se fosse consultado, jamais falharia;
    // o teste prova que ele nem é tocado para raças místicas.
    const mysticKit = createKit(5, 5, 5);

    const mysticResult = SkillEngine.executeSkill(
      weaknessSkill,
      mysticCaster,
      mysticTarget,
      undefined,
      mysticKit,
    );

    assert(mysticResult.success === true, `D.3.${race}: success === true: ${mysticResult.success}`);
    assert(mysticCaster.shortTermEstafa === -100,
      `D.3.${race}: estafa travada em -100 (fluxo místico NÃO foi pulado): ${mysticCaster.shortTermEstafa}`);

    // Excedente bruto 20 → amplificado por fraqueza racial: 20 * 1.5 = 30
    const expectedBacklash = 20 * 1.5;
    assertApprox(mysticResult.backlashDamage, expectedBacklash, 0.001,
      `D.3.${race}: backlashDamage amplificado normalmente: ${mysticResult.backlashDamage}`);
    assertApprox(mysticCaster.stats.currentHp, initialHp - expectedBacklash, 0.001,
      `D.3.${race}: HP reduzido pelo backlash normal: ${mysticCaster.stats.currentHp}`);

    assert(
      mysticKit.charges.FIRE === 5 && mysticKit.charges.ICE === 5 && mysticKit.charges.LIGHTNING === 5,
      `D.3.${race}: kit permanece 100% intocado (nunca consultado para raça mística)`,
    );
  }
}

// ====================================================================
// CENÁRIO E: SIMULAÇÃO DE COMBATE MULTI-TURNO — THERMITE_GRENADE
// (skill real do SkillRegistry) COM CONSUMO E RECARGA DE KIT
// ====================================================================

function runTestE(): void {
  printSection('CENÁRIO E — COMBATE MULTI-TURNO: THERMITE_GRENADE (REGISTRY REAL) + reloadKit');

  const thermiteGrenade = skillDatabase.get(SKILL_ID_THERMITE_GRENADE);

  assert(thermiteGrenade !== undefined,
    `THERMITE_GRENADE está cadastrada em skillDatabase: ${thermiteGrenade !== undefined}`);

  if (!thermiteGrenade) {
    return; // Guarda de tipo — os asserts acima já reportaram a falha
  }

  const initialHp = 1000;
  const dwarfCaster = createCharacter(Race.DWARF, { currentHp: initialHp, maxHp: initialHp });
  const target = createCharacter(null);
  const initialEstafa = dwarfCaster.shortTermEstafa;

  // Kit com exatamente 1 carga de FIRE — força depleção já no turno 2
  const kit: IEngineeringKit = { charges: { FIRE: 1, ICE: 0, LIGHTNING: 0 } };

  // ------------------------------------------------------------------
  // Turno 1 — kit tem 1 carga de FIRE: disparo bem-sucedido via Engenharia
  // ------------------------------------------------------------------
  printSubSection('E.1 — Turno 1: THERMITE_GRENADE com carga disponível');

  const turn1 = SkillEngine.executeSkill(thermiteGrenade, dwarfCaster, target, undefined, kit);

  assert(turn1.success === true, `Turno 1: success === true: ${turn1.success}`);
  assert(kit.charges.FIRE === 0, `Turno 1: carga de FIRE consumida (1 → 0): ${kit.charges.FIRE}`);
  assert(turn1.backlashDamage === 0, `Turno 1: sem backlash (Engenharia bypassou a ETAPA 1): ${turn1.backlashDamage}`);
  assert(turn1.actualDamage === 80, `Turno 1: actualDamage === baseDamage da skill (80): ${turn1.actualDamage}`);
  assert(dwarfCaster.shortTermEstafa === initialEstafa,
    `Turno 1: shortTermEstafa intocado: ${dwarfCaster.shortTermEstafa} === ${initialEstafa}`);
  assert(dwarfCaster.stats.currentHp === initialHp,
    `Turno 1: HP do caster intocado: ${dwarfCaster.stats.currentHp} === ${initialHp}`);

  // ------------------------------------------------------------------
  // Turno 2 — kit depletado (0 cargas de FIRE): falha por falta de suprimento
  // ------------------------------------------------------------------
  printSubSection('E.2 — Turno 2: kit depletado, disparo bloqueado');

  const turn2 = SkillEngine.executeSkill(thermiteGrenade, dwarfCaster, target, undefined, kit);

  assert(turn2.success === false, `Turno 2: success === false (sem suprimento): ${turn2.success}`);
  assert(turn2.actualDamage === 0, `Turno 2: actualDamage === 0 (execução interrompida): ${turn2.actualDamage}`);
  assert(turn2.backlashDamage === 0, `Turno 2: backlashDamage === 0: ${turn2.backlashDamage}`);
  assert(kit.charges.FIRE === 0, `Turno 2: carga de FIRE permanece em 0: ${kit.charges.FIRE}`);
  assert(dwarfCaster.shortTermEstafa === initialEstafa,
    `Turno 2: shortTermEstafa continua intocado: ${dwarfCaster.shortTermEstafa} === ${initialEstafa}`);
  assert(dwarfCaster.stats.currentHp === initialHp,
    `Turno 2: HP do caster continua intocado: ${dwarfCaster.stats.currentHp} === ${initialHp}`);

  // ------------------------------------------------------------------
  // Reabastecimento — item consumível de recarga usa reloadKit()
  // ------------------------------------------------------------------
  printSubSection('E.3 — Reabastecimento via reloadKit (item consumível)');

  EngineeringManager.reloadKit(kit, 'FIRE', 1);

  assert(kit.charges.FIRE === 1, `Kit reabastecido: carga de FIRE volta a 1: ${kit.charges.FIRE}`);

  // ------------------------------------------------------------------
  // Turno 3 — kit reabastecido: disparo volta a funcionar via Engenharia
  // ------------------------------------------------------------------
  printSubSection('E.4 — Turno 3: THERMITE_GRENADE dispara novamente após recarga');

  const turn3 = SkillEngine.executeSkill(thermiteGrenade, dwarfCaster, target, undefined, kit);

  assert(turn3.success === true, `Turno 3: success === true: ${turn3.success}`);
  assert(kit.charges.FIRE === 0, `Turno 3: carga de FIRE consumida novamente (1 → 0): ${kit.charges.FIRE}`);
  assert(turn3.backlashDamage === 0, `Turno 3: sem backlash: ${turn3.backlashDamage}`);
  assert(turn3.actualDamage === 80, `Turno 3: actualDamage === 80 novamente: ${turn3.actualDamage}`);
  assert(dwarfCaster.shortTermEstafa === initialEstafa,
    `Turno 3: shortTermEstafa permanece intocado ao longo de todo o combate: ${dwarfCaster.shortTermEstafa} === ${initialEstafa}`);
  assert(dwarfCaster.stats.currentHp === initialHp,
    `Turno 3: HP do caster permanece intocado ao longo de todo o combate: ${dwarfCaster.stats.currentHp} === ${initialHp}`);
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
  runTestD();
  runTestE();

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
