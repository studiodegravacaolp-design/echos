/**
 * ====================================================================
 * combatSimulation.test.ts
 * --------------------------------------------------------------------
 * Suite de validação cruzada — Sprint 2 (Tarefa 2.3).
 * Simula cenários de combate extremos para homologação dos métodos:
 *   - calculateMovementSpeed (Atrito Físico)
 *   - generateTurnQueue (Fila de Iniciativa Dinâmica)
 *
 * Fonte: docs/04_arquitetura_software/ENG-MOTOR-COMBATE.md
 *        docs/01_sistemas/ENG-MATEMATICA-COMBATE.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CombatEngine } from '../core/CombatEngine';
import { CharacterState } from '../core/CharacterState';
import { StatusEngine, TECH_STATUS_IDS } from '../modules/combat/StatusEngine';
import { SkillEngine } from '../modules/skills/SkillEngine';
import { IEngineeringKit } from '../modules/engineering/EngineeringManager';
import { ISalvageInventory } from '../modules/engineering/SalvageManager';
import { skillDatabase, SKILL_ID_THERMITE_GRENADE } from '../modules/skills/SkillRegistry';
import {
  ICharacterStats,
  IEquipment,
  IStatusEffect,
  MaterialType,
  MATERIAL_COEFFICIENTS,
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

function assert(
  condition: boolean,
  description: string,
): void {
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

/**
 * Cria um conjunto de estatísticas base para testes.
 */
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
 * Cria um equipamento para testes.
 */
function createEquipment(
  id: string,
  name: string,
  weight: number,
  materialType: MaterialType,
): IEquipment {
  return {
    id,
    name,
    weight,
    materialCoefficient: MATERIAL_COEFFICIENTS[materialType],
  };
}

/**
 * Cria um efeito de status de ESTAGNACAO_TATICA.
 */
function createEstagnacaoEffect(): IStatusEffect {
  return {
    id: 'ESTAGNACAO_TATICA',
    duration: 10,
    remainingDuration: 10,
    modifiers: {},
    flags: {
      blocksMovementInput: true,
      overridesMovementDirection: false,
      blocksAbilityAxis: null,
      freezesEstafaBar: true,
    },
  };
}

/**
 * Cria um efeito de status de FRATURA_FRENESI.
 */
function createFraturaFrenesiEffect(): IStatusEffect {
  return {
    id: 'FRATURA_FRENESI',
    duration: 10,
    remainingDuration: 10,
    modifiers: {},
    flags: {
      blocksMovementInput: false,
      overridesMovementDirection: false,
      blocksAbilityAxis: null,
      freezesEstafaBar: false,
    },
  };
}

// ====================================================================
// CENÁRIO A: ATRITO DE CHUMBO
// ====================================================================

function runTestA(engine: CombatEngine): void {
  printSection('CENÁRIO A — ATRITO DE CHUMBO (ESTAGNACAO_TATICA)');

  // ----------------------------------------------------------------
  // Setup: Personagem com armadura pesada de Chumbo
  // ----------------------------------------------------------------
  const baseSpeed = 100;
  const stats = createBaseStats({ movementSpeed: baseSpeed });
  const character = new CharacterState(stats);

  // Equipa armadura de Chumbo (peso 25, coeficiente 1.8)
  const chumboArmor = createEquipment(
    'EQP_ARM_CHUMBO_001',
    'Armadura de Chumbo Pesado',
    25,
    MaterialType.CHUMBO,
  );
  character.equipment = chumboArmor;

  // ----------------------------------------------------------------
  // Subteste A.1: Velocidade sem estagnação
  // ----------------------------------------------------------------
  printSubSection('A.1 — Velocidade sem ESTAGNACAO_TATICA');

  const speedNoDebuff = engine.calculateMovementSpeed(
    baseSpeed,
    chumboArmor.weight,
    chumboArmor.materialCoefficient,
    false, // sem estagnação
  );

  // Cálculo esperado: 100 - (25 * 1.8) = 100 - 45 = 55
  const expectedNoDebuff = 100 - (25 * 1.8); // = 55
  assertApprox(speedNoDebuff, expectedNoDebuff, 0.001,
    `Velocidade sem debuff: ${speedNoDebuff} ≈ ${expectedNoDebuff}`);

  // Garantir que não violou o mínimo de 10%
  const minSpeed = baseSpeed * 0.10; // = 10
  assert(speedNoDebuff >= minSpeed,
    `Velocidade sem debuff (${speedNoDebuff}) >= mínimo de 10% (${minSpeed})`);

  // ----------------------------------------------------------------
  // Subteste A.2: Aplicar ESTAGNACAO_TATICA (estafa = -100)
  // ----------------------------------------------------------------
  printSubSection('A.2 — Aplicação de ESTAGNACAO_TATICA');

  // Força a barra de estafa para -100 (dispara o estado de colapso)
  // O setter aplica clamp e dispara eventos de borda
  character.shortTermEstafa = -100;

  // Verifica se o estado foi atingido
  assert(character.shortTermEstafa === -100,
    `Estafa após clamp: ${character.shortTermEstafa} === -100`);

  // Adiciona o efeito de status manualmente (simula o evento de borda)
  character.addStatusEffect(createEstagnacaoEffect());

  assert(character.hasStatusEffect('ESTAGNACAO_TATICA'),
    'Personagem possui status ESTAGNACAO_TATICA');

  // ----------------------------------------------------------------
  // Subteste A.3: Velocidade com estagnação (debuff 0.50x)
  // ----------------------------------------------------------------
  printSubSection('A.3 — Velocidade sob ESTAGNACAO_TATICA (debuff 0.50x)');

  const speedWithDebuff = engine.calculateMovementSpeed(
    baseSpeed,
    chumboArmor.weight,
    chumboArmor.materialCoefficient,
    true, // com estagnação
  );

  // Cálculo esperado:
  //   effectiveSpeed = 100 - (25 * 1.8) = 55
  //   effectiveSpeed *= 0.50 = 27.5
  //   minSpeed = 100 * 0.10 = 10
  //   max(27.5, 10) = 27.5
  const expectedWithDebuff = (100 - (25 * 1.8)) * 0.50; // = 27.5
  assertApprox(speedWithDebuff, expectedWithDebuff, 0.001,
    `Velocidade com debuff: ${speedWithDebuff} ≈ ${expectedWithDebuff}`);

  // Garantir que não violou o mínimo de 10%
  assert(speedWithDebuff >= minSpeed,
    `Velocidade com debuff (${speedWithDebuff}) >= mínimo de 10% (${minSpeed})`);

  // ----------------------------------------------------------------
  // Subteste A.4: Clamp mínimo — velocidade não pode ir abaixo de 10%
  // ----------------------------------------------------------------
  printSubSection('A.4 — Garantia de clamp mínimo (10% da baseSpeed)');

  // Testa com armadura extremamente pesada que deveria reduzir a velocidade
  // a valores negativos, mas o clamp deve segurar em 10%
  const ultraHeavyArmor = createEquipment(
    'EQP_ARM_ULTRA_001',
    'Armadura Ultra Pesada',
    200,  // peso extremo
    MaterialType.CHUMBO,
  );

  const speedUltraHeavy = engine.calculateMovementSpeed(
    baseSpeed,
    ultraHeavyArmor.weight,
    ultraHeavyArmor.materialCoefficient,
    false,
  );

  // Cálculo bruto: 100 - (200 * 1.8) = 100 - 360 = -260
  // Clamp mínimo: max(-260, 10) = 10
  assertApprox(speedUltraHeavy, minSpeed, 0.001,
    `Clamp mínimo com peso extremo: ${speedUltraHeavy} === ${minSpeed}`);

  // ----------------------------------------------------------------
  // Subteste A.5: Proteção contra entradas inválidas
  // ----------------------------------------------------------------
  printSubSection('A.5 — Proteção contra entradas inválidas');

  const speedNaN = engine.calculateMovementSpeed(
    NaN,
    chumboArmor.weight,
    chumboArmor.materialCoefficient,
    false,
  );
  assert(speedNaN === 0.0,
    `BaseSpeed NaN retorna 0: ${speedNaN}`);

  const speedNegative = engine.calculateMovementSpeed(
    -50,
    chumboArmor.weight,
    chumboArmor.materialCoefficient,
    false,
  );
  assert(speedNegative === 0.0,
    `BaseSpeed negativa retorna 0: ${speedNegative}`);

  const speedInf = engine.calculateMovementSpeed(
    Infinity,
    chumboArmor.weight,
    chumboArmor.materialCoefficient,
    false,
  );
  assert(speedInf === 0.0,
    `BaseSpeed Infinity retorna 0: ${speedInf}`);
}

// ====================================================================
// CENÁRIO B: ORDENAÇÃO CRÍTICA DE FILA
// ====================================================================

function runTestB(engine: CombatEngine): void {
  printSection('CENÁRIO B — ORDENAÇÃO CRÍTICA DE FILA (INICIATIVA DINÂMICA)');

  // ----------------------------------------------------------------
  // Setup: 3 personagens com perfis distintos
  // ----------------------------------------------------------------

  // Personagem 1: Sapador Supremo — alta velocidade base, mas sob FRATURA_FRENESI
  //   Penalidade de -50 na iniciativa
  const statsSapador = createBaseStats({
    movementSpeed: 120,
    maxHp: 800,
    currentHp: 800,
    damage: 70,
    defense: 20,
  });
  const sapador = new CharacterState(statsSapador);
  const sapadorArmor = createEquipment(
    'EQP_ARM_ACO_001',
    'Armadura de Aço do Sapador',
    15,
    MaterialType.ACO,
  );
  sapador.equipment = sapadorArmor;
  sapador.addStatusEffect(createFraturaFrenesiEffect());
  // Força estafa para +100 para ativar o estado de Fratura
  sapador.shortTermEstafa = 100;

  // Personagem 2: Batedor Leve — velocidade alta, armadura leve de Aço
  const statsBatedor = createBaseStats({
    movementSpeed: 150,
    maxHp: 600,
    currentHp: 600,
    damage: 40,
    defense: 15,
  });
  const batedor = new CharacterState(statsBatedor);
  const batedorArmor = createEquipment(
    'EQP_ARM_ACO_002',
    'Armadura Leve de Aço',
    8,
    MaterialType.ACO,
  );
  batedor.equipment = batedorArmor;

  // Personagem 3: Inimigo Elite — velocidade baixa, armadura pesada de Pedra
  const statsElite = createBaseStats({
    movementSpeed: 60,
    maxHp: 2000,
    currentHp: 2000,
    damage: 90,
    defense: 50,
  });
  const elite = new CharacterState(statsElite);
  const eliteArmor = createEquipment(
    'EQP_ARM_PEDRA_001',
    'Armadura de Pedra do Elite',
    20,
    MaterialType.PEDRA,
  );
  elite.equipment = eliteArmor;

  const characters = [sapador, batedor, elite];

  // ----------------------------------------------------------------
  // Subteste B.1: Cálculo manual das iniciativas esperadas
  // ----------------------------------------------------------------
  printSubSection('B.1 — Cálculo manual das iniciativas esperadas');

  // Batedor: 150 - (8 * 1.0) = 142, sem estagnação, sem fratura
  const expectedBatedorInitiative = 150 - (8 * 1.0); // = 142

  // Sapador: 120 - (15 * 1.0) = 105, sem estagnação, com fratura → 105 - 50 = 55
  const expectedSapadorInitiative = (120 - (15 * 1.0)) - 50; // = 55

  // Elite: 60 - (20 * 1.5) = 60 - 30 = 30, sem estagnação, sem fratura
  const expectedEliteInitiative = 60 - (20 * 1.5); // = 30

  console.log(`  Iniciativa esperada — Batedor: ${expectedBatedorInitiative}`);
  console.log(`  Iniciativa esperada — Sapador: ${expectedSapadorInitiative}`);
  console.log(`  Iniciativa esperada — Elite:   ${expectedEliteInitiative}`);

  // ----------------------------------------------------------------
  // Subteste B.2: Executar generateTurnQueue
  // ----------------------------------------------------------------
  printSubSection('B.2 — Execução de generateTurnQueue');

  const sortedQueue = engine.generateTurnQueue(characters);

  assert(sortedQueue.length === 3,
    `Fila gerada contém ${sortedQueue.length} personagens (esperado: 3)`);

  // ----------------------------------------------------------------
  // Subteste B.3: Validação da ordem decrescente de iniciativa
  // ----------------------------------------------------------------
  printSubSection('B.3 — Validação da ordem decrescente');

  // A ordem esperada é: [Batedor, Sapador, Elite]
  // (maior iniciativa age primeiro)

  // Verifica se o primeiro da fila é o Batedor (maior iniciativa)
  assert(
    sortedQueue[0] === batedor,
    `Primeiro da fila é o Batedor (iniciativa ${expectedBatedorInitiative})`,
  );

  // Verifica se o segundo da fila é o Sapador
  assert(
    sortedQueue[1] === sapador,
    `Segundo da fila é o Sapador (iniciativa ${expectedSapadorInitiative})`,
  );

  // Verifica se o terceiro da fila é o Elite
  assert(
    sortedQueue[2] === elite,
    `Terceiro da fila é o Elite (iniciativa ${expectedEliteInitiative})`,
  );

  // ----------------------------------------------------------------
  // Subteste B.4: Verificação de que a ordem é estritamente decrescente
  // ----------------------------------------------------------------
  printSubSection('B.4 — Estrita prioridade decrescente');

  // Reordena para verificar consistência
  const reSorted = engine.generateTurnQueue(characters);
  for (let i = 0; i < reSorted.length; i++) {
    assert(
      reSorted[i] === sortedQueue[i],
      `Re-ordenacão consistente — posição ${i} mantida`,
    );
  }

  // ----------------------------------------------------------------
  // Subteste B.5: Array vazio e inválido
  // ----------------------------------------------------------------
  printSubSection('B.5 — Proteção contra entradas inválidas');

  const emptyQueue = engine.generateTurnQueue([]);
  assert(Array.isArray(emptyQueue) && emptyQueue.length === 0,
    'Array vazio retorna array vazio');

  const nullQueue = engine.generateTurnQueue(null as unknown as CharacterState[]);
  assert(Array.isArray(nullQueue) && nullQueue.length === 0,
    'Null retorna array vazio');
}

// ====================================================================
// CENÁRIO C: CONEXÃO DA MATRIZ DE STATUS TECNOLÓGICOS NO COMBATENGINE
// ====================================================================

function runTestC(engine: CombatEngine): void {
  printSection('CENÁRIO C — CONEXÃO TECH_SLOW / TECH_BURN NO COMBATENGINE');

  // ----------------------------------------------------------------
  // Subteste C.1: calculateMovementSpeed aceita techSlowMultiplier
  // ----------------------------------------------------------------
  printSubSection('C.1 — calculateMovementSpeed aplica o redutor de TECH_SLOW');

  const slowedSpeed = engine.calculateMovementSpeed(100, 0, 0, false, 0, 0.7);
  assertApprox(slowedSpeed, 70, 0.001, `Velocidade com TECH_SLOW (0.7x): ${slowedSpeed} ≈ 70`);

  const normalSpeed = engine.calculateMovementSpeed(100, 0, 0, false, 0, 1.0);
  assertApprox(normalSpeed, 100, 0.001, `Velocidade sem TECH_SLOW (1.0x): ${normalSpeed} ≈ 100`);

  const invalidMultiplierSpeed = engine.calculateMovementSpeed(100, 0, 0, false, 0, NaN);
  assertApprox(invalidMultiplierSpeed, 100, 0.001,
    `Multiplicador inválido (NaN) tratado como 1.0: ${invalidMultiplierSpeed} ≈ 100`);

  // ----------------------------------------------------------------
  // Subteste C.2: generateTurnQueue consulta StatusEngine.getSlowSpeedMultiplier
  // ----------------------------------------------------------------
  printSubSection('C.2 — generateTurnQueue penaliza a iniciativa de quem está sob TECH_SLOW');

  const statsEqual = createBaseStats({ movementSpeed: 100 });
  const slowedCharacter = new CharacterState(statsEqual);
  const normalCharacter = new CharacterState(statsEqual);

  StatusEngine.applyTechStatus(slowedCharacter, TECH_STATUS_IDS.TECH_SLOW);

  assert(slowedCharacter.hasStatusEffect('TECH_SLOW'), 'TECH_SLOW aplicado ao personagem lento');

  const queue = engine.generateTurnQueue([slowedCharacter, normalCharacter]);

  assert(queue[0] === normalCharacter,
    'Personagem sem TECH_SLOW (iniciativa 100) age primeiro');
  assert(queue[1] === slowedCharacter,
    'Personagem com TECH_SLOW (iniciativa 70) age depois');

  // ----------------------------------------------------------------
  // Subteste C.3: processTurnStartEffects aplica o tick de TECH_BURN
  // ----------------------------------------------------------------
  printSubSection('C.3 — processTurnStartEffects aplica dano de TECH_BURN via StatusEngine');

  const burningStats = createBaseStats({ currentHp: 1000, maxHp: 1000 });
  const burningCharacter = new CharacterState(burningStats);

  StatusEngine.applyTechStatus(burningCharacter, TECH_STATUS_IDS.TECH_BURN);

  const burnDamage = engine.processTurnStartEffects(burningCharacter);

  assert(burnDamage === 15, `Dano de TECH_BURN aplicado pelo CombatEngine: ${burnDamage} === 15`);
  assert(burningCharacter.stats.currentHp === 985,
    `HP reduzido pelo tick de TECH_BURN via CombatEngine: ${burningCharacter.stats.currentHp} === 985`);

  // Personagem sem TECH_BURN: nenhum dano
  const healthyCharacter = new CharacterState(createBaseStats({ currentHp: 1000, maxHp: 1000 }));
  const noDamage = engine.processTurnStartEffects(healthyCharacter);

  assert(noDamage === 0, `Sem TECH_BURN: processTurnStartEffects retorna 0: ${noDamage}`);
  assert(healthyCharacter.stats.currentHp === 1000,
    `Sem TECH_BURN: HP inalterado: ${healthyCharacter.stats.currentHp} === 1000`);
}

// ====================================================================
// CENÁRIO D: LOOP DE PONTA A PONTA — TECH_BURN AUTOMÁTICO + LOOT PÓS-BATALHA
// ====================================================================

function runTestD(engine: CombatEngine): void {
  printSection('CENÁRIO D — COMBATE COMPLETO: TECH_BURN AUTOMÁTICO ➔ DERROTA ➔ SUCATA');

  const thermiteGrenade = skillDatabase.get(SKILL_ID_THERMITE_GRENADE);
  assert(thermiteGrenade !== undefined, `THERMITE_GRENADE cadastrada: ${thermiteGrenade !== undefined}`);

  if (!thermiteGrenade) {
    return; // Guarda de tipo — o assert acima já reportou a falha
  }

  // ------------------------------------------------------------------
  // D.1 — Engenheiro HUMAN aplica TECH_BURN no inimigo via THERMITE_GRENADE
  // ------------------------------------------------------------------
  printSubSection('D.1 — Engenheiro HUMAN dispara THERMITE_GRENADE e aplica TECH_BURN');

  const engineer = new CharacterState(
    createBaseStats({ movementSpeed: 100 }),
    LatentLineageAxis.NEUTRO_ABSOLUTO,
    undefined,
    undefined,
    Race.HUMAN,
  );
  const enemy = new CharacterState(createBaseStats({ currentHp: 100, maxHp: 100, movementSpeed: 80 }));

  const kit: IEngineeringKit = { charges: { FIRE: 1, ICE: 0, LIGHTNING: 0 } };

  const strikeResult = SkillEngine.executeSkill(thermiteGrenade, engineer, enemy, undefined, kit);

  assert(strikeResult.success === true, `Disparo bem-sucedido: ${strikeResult.success}`);
  assert(strikeResult.appliedStatus === TECH_STATUS_IDS.TECH_BURN,
    `TECH_BURN aplicado: ${strikeResult.appliedStatus}`);
  assert(enemy.hasStatusEffect(TECH_STATUS_IDS.TECH_BURN), 'Inimigo está queimando (TECH_BURN ativo)');

  // O motor de skills apenas CALCULA actualDamage — quem aplica ao HP é
  // o chamador (aqui, a simulação de combate), assim como
  // calculateMitigatedDamage não aplica dano sozinho.
  enemy.applyDirectDamage(strikeResult.actualDamage);

  assert(enemy.stats.currentHp === 20,
    `HP do inimigo após o impacto direto (100 - 80 = 20): ${enemy.stats.currentHp}`);

  // ------------------------------------------------------------------
  // D.2 — A rodada passa: generateTurnQueue aplica o tick de TECH_BURN
  // automaticamente (sem qualquer chamada manual a processTurnStartEffects)
  // ------------------------------------------------------------------
  printSubSection('D.2 — Rodada 1: tick de TECH_BURN automático via generateTurnQueue');

  engine.generateTurnQueue([engineer, enemy]);

  assert(enemy.stats.currentHp === 5,
    `HP do inimigo após tick automático de TECH_BURN (20 - 15 = 5): ${enemy.stats.currentHp}`);

  // ------------------------------------------------------------------
  // D.3 — O inimigo é derrotado por um segundo tick de TECH_BURN
  // ------------------------------------------------------------------
  printSubSection('D.3 — Rodada 2: segundo tick de TECH_BURN derrota o inimigo');

  engine.generateTurnQueue([engineer, enemy]);

  assert(enemy.stats.currentHp === 0,
    `HP do inimigo zerado pelo segundo tick (5 - 15, travado em 0): ${enemy.stats.currentHp}`);
  assert(enemy.stats.currentHp <= 0, 'Inimigo derrotado (HP <= 0)');

  // ------------------------------------------------------------------
  // D.4 — Encerramento de combate: o motor calcula e concede a sucata
  // automaticamente ao inventário do grupo
  // ------------------------------------------------------------------
  printSubSection('D.4 — resolveVictoryLoot concede sucata ao inventário do grupo');

  const partyInventory: ISalvageInventory = { scrapCount: 0 };

  const scrapAwarded = engine.resolveVictoryLoot(5, true, partyInventory);

  assert(scrapAwarded === 50, `Sucata calculada (nível 5, mecânico: 5 * 5 * 2 = 50): ${scrapAwarded}`);
  assert(partyInventory.scrapCount === 50,
    `Sucata concedida automaticamente ao inventário do grupo: ${partyInventory.scrapCount}`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  COMBAT SIMULATION TEST SUITE — SPRINT 2 (TAREFA 2.3)`);
  console.log(`#  Motor: CombatEngine.ts v1.0.0`);
  console.log(`#  Data:  ${new Date().toISOString()}`);
  console.log(`${'#'.repeat(72)}\n`);

  const engine = new CombatEngine();

  // Executa Cenário A
  runTestA(engine);

  // Executa Cenário B
  runTestB(engine);

  // Executa Cenário C
  runTestC(engine);

  // Executa Cenário D
  runTestD(engine);

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

// Executa
main();