/**
 * ====================================================================
 * massCombatStress.test.ts
 * --------------------------------------------------------------------
 * Teste de estresse massivo — Sprint 10.
 * Executa 1.000 simulações completas de combate de ponta a ponta,
 * misturando heróis engenheiros (HUMAN/DWARF) e feitiçaria (ELF/FAERIE),
 * usando os status tecnológicos e coleta de loot automáticos.
 *
 * Valida defensivamente que em nenhuma das 1.000 execuções o motor
 * disparou exceções não tratadas, valores nulos corrompidos ou falhas
 * de estouro de estafa indevidas.
 *
 * Exibe um log simples de telemetria no console informando a taxa de
 * sucesso.
 *
 * Fonte: Sprint 10 — Simulador Massivo de Stress
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { CombatEngine } from '../core/CombatEngine';
import { LootEngine } from '../modules/combat/LootEngine';
import { StatusEngine } from '../modules/combat/StatusEngine';
import { EngineeringManager, IEngineeringKit } from '../modules/engineering/EngineeringManager';
import { SalvageManager, ISalvageInventory } from '../modules/engineering/SalvageManager';
import {
  ICharacterStats,
  IAbility,
  AxisTag,
  PenetrationType,
  Race,
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
 * Cria uma habilidade de combate para simulação.
 */
function createAbility(
  id: string,
  name: string,
  axis: AxisTag,
  deltaM: number,
  baseDamage: number,
  penetrationType: PenetrationType = PenetrationType.FISICA,
): IAbility {
  return { id, name, axis, deltaM, baseDamage, penetrationType };
}

/**
 * Cria um inventário de sucata.
 */
function createSalvageInventory(initialScrap: number = 100): ISalvageInventory {
  return { scrapCount: initialScrap };
}

// ====================================================================
// CENÁRIO: SIMULAÇÃO DE COMBATE COM HERÓI ENGENHEIRO (HUMAN)
// ====================================================================

function simulateEngineerCombat(
  heroLevel: number,
  enemyLevel: number,
  isMechanical: boolean,
): { success: boolean; heroWon: boolean; rounds: number; scrapEarned: number; error: string | null } {
  try {
    // Cria herói engenheiro (HUMAN)
    const heroStats = createBaseStats({ maxHp: 800, currentHp: 800, damage: 40, defense: 25 });
    const hero = new CharacterState(heroStats, undefined, undefined, undefined, Race.HUMAN);
    hero.currentLevel = heroLevel;

    // Cria inventário de sucata
    const salvageInv = createSalvageInventory(50);

    // Cria inimigo escalado
    const enemyData = CombatEngine.createScaledEnemy(enemyLevel, isMechanical);
    const enemy = enemyData.character;

    // Habilidades
    const heroAbility = createAbility('HAB_ENG_FIRE_01', 'Golpe de Forja Ígnea', AxisTag.PATERNO, 15, 35, PenetrationType.FISICA);
    const enemyAbility = createAbility('HAB_ENEMY_01', 'Ataque Selvagem', AxisTag.MATERNO, -10, 20, PenetrationType.FISICA);

    // Aplica status tecnológico no inimigo (TECH_BURN)
    StatusEngine.applyTechStatus(enemy, 'TECH_BURN');

    // Simula combate completo
    const result = CombatEngine.simulateFullCombat(hero, enemy, heroAbility, enemyAbility, 15);

    // Se herói venceu, coleta loot
    let scrapEarned = 0;
    if (result.heroWon) {
      scrapEarned = LootEngine.calculateBattleLoot(enemyLevel, isMechanical);
      LootEngine.awardSalvage(salvageInv, scrapEarned);
    }

    // Validações defensivas
    if (!Number.isFinite(result.heroHpRemaining) || result.heroHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'heroHpRemaining inválido' };
    }
    if (!Number.isFinite(result.enemyHpRemaining) || result.enemyHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'enemyHpRemaining inválido' };
    }
    if (!Number.isFinite(result.rounds) || result.rounds < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'rounds inválido' };
    }

    // Valida estafa dentro dos limites
    if (hero.shortTermEstafa < -100 || hero.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa fora dos limites: ${hero.shortTermEstafa}` };
    }
    if (enemy.shortTermEstafa < -100 || enemy.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa do inimigo fora dos limites: ${enemy.shortTermEstafa}` };
    }

    return { success: true, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: null };
  } catch (err) {
    return { success: false, heroWon: false, rounds: 0, scrapEarned: 0, error: `Exceção: ${String(err)}` };
  }
}

// ====================================================================
// CENÁRIO: SIMULAÇÃO DE COMBATE COM HERÓI FEITICEIRO (ELF)
// ====================================================================

function simulateSorceryCombat(
  heroLevel: number,
  enemyLevel: number,
  isMechanical: boolean,
): { success: boolean; heroWon: boolean; rounds: number; scrapEarned: number; error: string | null } {
  try {
    // Cria herói feiticeiro (ELF)
    const heroStats = createBaseStats({ maxHp: 600, currentHp: 600, damage: 60, defense: 15 });
    const hero = new CharacterState(heroStats, undefined, undefined, undefined, Race.ELF);
    hero.currentLevel = heroLevel;

    // Cria inventário de sucata
    const salvageInv = createSalvageInventory(30);

    // Cria inimigo escalado
    const enemyData = CombatEngine.createScaledEnemy(enemyLevel, isMechanical);
    const enemy = enemyData.character;

    // Habilidades mágicas
    const heroAbility = createAbility('HAB_SORC_ICE_01', 'Estalactite Arcano', AxisTag.MATERNO, -20, 50, PenetrationType.MAGICA);
    const enemyAbility = createAbility('HAB_ENEMY_02', 'Golpe Brutal', AxisTag.PATERNO, 15, 25, PenetrationType.FISICA);

    // Aplica status tecnológico no inimigo (TECH_SLOW)
    StatusEngine.applyTechStatus(enemy, 'TECH_SLOW');

    // Simula combate completo
    const result = CombatEngine.simulateFullCombat(hero, enemy, heroAbility, enemyAbility, 20);

    // Se herói venceu, coleta loot
    let scrapEarned = 0;
    if (result.heroWon) {
      scrapEarned = LootEngine.calculateBattleLoot(enemyLevel, isMechanical);
      LootEngine.awardSalvage(salvageInv, scrapEarned);
    }

    // Validações defensivas
    if (!Number.isFinite(result.heroHpRemaining) || result.heroHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'heroHpRemaining inválido' };
    }
    if (!Number.isFinite(result.enemyHpRemaining) || result.enemyHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'enemyHpRemaining inválido' };
    }
    if (!Number.isFinite(result.rounds) || result.rounds < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'rounds inválido' };
    }

    // Valida estafa dentro dos limites
    if (hero.shortTermEstafa < -100 || hero.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa fora dos limites: ${hero.shortTermEstafa}` };
    }
    if (enemy.shortTermEstafa < -100 || enemy.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa do inimigo fora dos limites: ${enemy.shortTermEstafa}` };
    }

    return { success: true, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: null };
  } catch (err) {
    return { success: false, heroWon: false, rounds: 0, scrapEarned: 0, error: `Exceção: ${String(err)}` };
  }
}

// ====================================================================
// CENÁRIO: SIMULAÇÃO DE COMBATE COM HERÓI FAERIE (TECH_CONDUCTIVE)
// ====================================================================

function simulateFaerieTechCombat(
  heroLevel: number,
  enemyLevel: number,
  isMechanical: boolean,
): { success: boolean; heroWon: boolean; rounds: number; scrapEarned: number; error: string | null } {
  try {
    // Cria herói FAERIE (suporte tecnológico)
    const heroStats = createBaseStats({ maxHp: 500, currentHp: 500, damage: 70, defense: 12 });
    const hero = new CharacterState(heroStats, undefined, undefined, undefined, Race.FAERIE);
    hero.currentLevel = heroLevel;

    // Cria inventário de sucata
    const salvageInv = createSalvageInventory(20);

    // Cria inimigo escalado
    const enemyData = CombatEngine.createScaledEnemy(enemyLevel, isMechanical);
    const enemy = enemyData.character;

    // Habilidades
    const heroAbility = createAbility('HAB_FAE_LIGHT_01', 'Raio Condutor', AxisTag.PATERNO, 25, 60, PenetrationType.MAGICA);
    const enemyAbility = createAbility('HAB_ENEMY_03', 'Investida', AxisTag.MATERNO, -12, 22, PenetrationType.FISICA);

    // Aplica TECH_CONDUCTIVE no inimigo (amplifica dano de LIGHTNING)
    StatusEngine.applyTechStatus(enemy, 'TECH_CONDUCTIVE');

    // Simula combate completo
    const result = CombatEngine.simulateFullCombat(hero, enemy, heroAbility, enemyAbility, 20);

    // Se herói venceu, coleta loot
    let scrapEarned = 0;
    if (result.heroWon) {
      scrapEarned = LootEngine.calculateBattleLoot(enemyLevel, isMechanical);
      LootEngine.awardSalvage(salvageInv, scrapEarned);
    }

    // Validações defensivas
    if (!Number.isFinite(result.heroHpRemaining) || result.heroHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'heroHpRemaining inválido' };
    }
    if (!Number.isFinite(result.enemyHpRemaining) || result.enemyHpRemaining < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'enemyHpRemaining inválido' };
    }
    if (!Number.isFinite(result.rounds) || result.rounds < 0) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: 'rounds inválido' };
    }

    // Valida estafa dentro dos limites
    if (hero.shortTermEstafa < -100 || hero.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa fora dos limites: ${hero.shortTermEstafa}` };
    }
    if (enemy.shortTermEstafa < -100 || enemy.shortTermEstafa > 100) {
      return { success: false, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: `estafa do inimigo fora dos limites: ${enemy.shortTermEstafa}` };
    }

    return { success: true, heroWon: result.heroWon, rounds: result.rounds, scrapEarned, error: null };
  } catch (err) {
    return { success: false, heroWon: false, rounds: 0, scrapEarned: 0, error: `Exceção: ${String(err)}` };
  }
}

// ====================================================================
// CENÁRIO: TESTE DE ENGENHARIA COM RECARGA DE KIT
// ====================================================================

function simulateEngineeringCraftCycle(): { success: boolean; error: string | null } {
  try {
    const salvageInv: ISalvageInventory = { scrapCount: 100 };
    const kit: IEngineeringKit = {
      charges: { FIRE: 0, ICE: 0, LIGHTNING: 0 },
      maxCharges: 10,
    };

    // Fabrica 3 cargas de FIRE (custo 20 cada = 60 sucata)
    const craft1 = SalvageManager.craftCharge(salvageInv, kit, 'FIRE', 20);
    const craft2 = SalvageManager.craftCharge(salvageInv, kit, 'FIRE', 20);
    const craft3 = SalvageManager.craftCharge(salvageInv, kit, 'FIRE', 20);

    if (!craft1 || !craft2 || !craft3) {
      return { success: false, error: 'Falha ao fabricar cargas de FIRE' };
    }

    if (kit.charges.FIRE !== 3) {
      return { success: false, error: `Esperado 3 cargas de FIRE, obtido ${kit.charges.FIRE}` };
    }

    if (salvageInv.scrapCount !== 40) {
      return { success: false, error: `Esperado 40 sucata restante, obtido ${salvageInv.scrapCount}` };
    }

    // Testa recarga via EngineeringManager
    EngineeringManager.reloadKit(kit, 'ICE', 5);
    const iceAfterReload: number = kit.charges.ICE;
    if (iceAfterReload !== 5) {
      return { success: false, error: `Esperado 5 cargas de ICE, obtido ${iceAfterReload}` };
    }

    // Testa teto de maxCharges
    EngineeringManager.reloadKit(kit, 'ICE', 10);
    const iceAfterOverReload: number = kit.charges.ICE;
    if (iceAfterOverReload !== 10) {
      return { success: false, error: `Esperado 10 cargas de ICE (teto), obtido ${iceAfterOverReload}` };
    }

    return { success: true, error: null };
  } catch (err) {
    return { success: false, error: `Exceção: ${String(err)}` };
  }
}

// ====================================================================
// CENÁRIO: TESTE DE PERSISTÊNCIA DE ENGENHARIA (toJSON / fromJSON)
// ====================================================================

function simulateEngineeringPersistence(): { success: boolean; error: string | null } {
  try {
    const stats = createBaseStats();
    const character = new CharacterState(stats, undefined, undefined, undefined, Race.DWARF);
    character.currentLevel = 25;
    character.scrapCount = 150;
    character.engineeringCharges = { FIRE: 3, ICE: 5, LIGHTNING: 2 };

    // Serializa
    const json = character.toJSON();

    // Verifica campos de engenharia no JSON
    if (json.scrapCount !== 150) {
      return { success: false, error: `scrapCount serializado incorreto: ${json.scrapCount}` };
    }

    const charges = json.engineeringCharges as Record<string, number>;
    if (charges.FIRE !== 3 || charges.ICE !== 5 || charges.LIGHTNING !== 2) {
      return { success: false, error: `engineeringCharges serializado incorreto: ${JSON.stringify(charges)}` };
    }

    // Desserializa
    const restored = CharacterState.fromJSON(
      { level: 25, scrapCount: 150, engineeringCharges: { FIRE: 3, ICE: 5, LIGHTNING: 2 } },
      stats,
    );

    if (restored.scrapCount !== 150) {
      return { success: false, error: `scrapCount restaurado incorreto: ${restored.scrapCount}` };
    }

    const restoredCharges = restored.engineeringCharges;
    if (restoredCharges.FIRE !== 3 || restoredCharges.ICE !== 5 || restoredCharges.LIGHTNING !== 2) {
      return { success: false, error: `engineeringCharges restaurado incorreto: ${JSON.stringify(restoredCharges)}` };
    }

    return { success: true, error: null };
  } catch (err) {
    return { success: false, error: `Exceção: ${String(err)}` };
  }
}

// ====================================================================
// EXECUTOR PRINCIPAL — LOOP DE 1.000 SIMULAÇÕES
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  MASS COMBAT STRESS TEST — SPRINT 10`);
  console.log(`#  1.000 simulações completas de combate de ponta a ponta`);
  console.log(`#  Misturando heróis engenheiros, feitiçaria e status tecnológicos`);
  console.log(`#  Data:  ${new Date().toISOString()}`);
  console.log(`${'#'.repeat(72)}\n`);

  const TOTAL_SIMULATIONS = 1000;
  let totalErrors = 0;
  let engineerWins = 0;
  let sorceryWins = 0;
  let faerieWins = 0;
  let totalScrapEarned = 0;
  let totalRounds = 0;

  // ================================================================
  // FASE 1: LOOP DE 1.000 SIMULAÇÕES
  // ================================================================
  printSection('FASE 1 — LOOP DE 1.000 SIMULAÇÕES DE COMBATE');

  for (let i = 0; i < TOTAL_SIMULATIONS; i++) {
    // Alterna entre tipos de herói a cada iteração
    const heroType = i % 3;
    const enemyLevel = 1 + (i % 15); // Níveis 1 a 15
    const isMechanical = i % 4 === 0; // 25% dos inimigos são mecânicos
    const heroLevel = 1 + (i % 10); // Níveis 1 a 10

    let result: { success: boolean; heroWon: boolean; rounds: number; scrapEarned: number; error: string | null };

    switch (heroType) {
      case 0: // Engenheiro (HUMAN)
        result = simulateEngineerCombat(heroLevel, enemyLevel, isMechanical);
        if (result.heroWon) engineerWins++;
        break;
      case 1: // Feiticeiro (ELF)
        result = simulateSorceryCombat(heroLevel, enemyLevel, isMechanical);
        if (result.heroWon) sorceryWins++;
        break;
      case 2: // FAERIE com TECH_CONDUCTIVE
        result = simulateFaerieTechCombat(heroLevel, enemyLevel, isMechanical);
        if (result.heroWon) faerieWins++;
        break;
      default:
        result = { success: false, heroWon: false, rounds: 0, scrapEarned: 0, error: 'Tipo de herói inválido' };
        break;
    }

    if (!result.success) {
      totalErrors++;
      if (totalErrors <= 5) {
        console.log(`  ⚠ Simulação #${i + 1} falhou: ${result.error}`);
      }
    }

    totalScrapEarned += result.scrapEarned;
    totalRounds += result.rounds;
  }

  // ================================================================
  // FASE 2: VALIDAÇÕES DEFENSIVAS
  // ================================================================
  printSection('FASE 2 — VALIDAÇÕES DEFENSIVAS');

  // 2.1 Nenhuma exceção não tratada
  assert(
    totalErrors === 0,
    `Nenhuma exceção não tratada nas ${TOTAL_SIMULATIONS} simulações (erros: ${totalErrors})`,
  );

  // 2.2 Nenhum valor nulo corrompido
  assert(
    Number.isFinite(totalRounds) && totalRounds >= 0,
    `Total de rodadas é um número válido (${totalRounds})`,
  );

  assert(
    Number.isFinite(totalScrapEarned) && totalScrapEarned >= 0,
    `Total de sucata coletada é um número válido (${totalScrapEarned})`,
  );

  // 2.3 Nenhuma falha de estouro de estafa
  assert(
    engineerWins + sorceryWins + faerieWins <= TOTAL_SIMULATIONS,
    `Soma de vitórias (${engineerWins + sorceryWins + faerieWins}) não excede total de simulações (${TOTAL_SIMULATIONS})`,
  );

  // ================================================================
  // FASE 3: TESTES DE ENGENHARIA E PERSISTÊNCIA
  // ================================================================
  printSection('FASE 3 — TESTES DE ENGENHARIA E PERSISTÊNCIA');

  // 3.1 Ciclo de fabricação de cargas
  printSubSection('3.1 — Ciclo de fabricação de cargas (SalvageManager + EngineeringManager)');
  const craftResult = simulateEngineeringCraftCycle();
  assert(craftResult.success, `Ciclo de fabricação de cargas: ${craftResult.error ?? 'OK'}`);

  // 3.2 Persistência de engenharia (toJSON / fromJSON)
  printSubSection('3.2 — Persistência de engenharia (toJSON / fromJSON)');
  const persistResult = simulateEngineeringPersistence();
  assert(persistResult.success, `Persistência de engenharia: ${persistResult.error ?? 'OK'}`);

  // ================================================================
  // FASE 4: TELEMETRIA
  // ================================================================
  printSection('FASE 4 — TELEMETRIA DO SIMULADOR');

  const avgRounds = TOTAL_SIMULATIONS > 0 ? (totalRounds / TOTAL_SIMULATIONS).toFixed(2) : '0';
  const avgScrap = TOTAL_SIMULATIONS > 0 ? (totalScrapEarned / TOTAL_SIMULATIONS).toFixed(2) : '0';
  const successRate = TOTAL_SIMULATIONS > 0 ? (((TOTAL_SIMULATIONS - totalErrors) / TOTAL_SIMULATIONS) * 100).toFixed(2) : '0';

  console.log(`  Total de simulações:        ${TOTAL_SIMULATIONS}`);
  console.log(`  Simulações bem-sucedidas:   ${TOTAL_SIMULATIONS - totalErrors}`);
  console.log(`  Simulações com erro:        ${totalErrors}`);
  console.log(`  Taxa de sucesso:            ${successRate}%`);
  console.log(`  Vitórias (Engenheiro):      ${engineerWins}`);
  console.log(`  Vitórias (Feiticeiro):      ${sorceryWins}`);
  console.log(`  Vitórias (FAERIE Tech):     ${faerieWins}`);
  console.log(`  Total de sucata coletada:   ${totalScrapEarned}`);
  console.log(`  Média de rodadas:           ${avgRounds}`);
  console.log(`  Média de sucata/simulação:  ${avgScrap}`);

  // ================================================================
  // RELATÓRIO FINAL
  // ================================================================
  console.log(`\n${'='.repeat(72)}`);
  console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — SPRINT 10`);
  console.log(`${'='.repeat(72)}`);
  console.log(`  Total de testes:    ${totalTests}`);
  console.log(`  Aprovados (PASS):   ${passedTests}`);
  console.log(`  Reprovados (FAIL):  ${failedTests}`);
  console.log(`  Taxa de sucesso:    ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
  console.log(`${'='.repeat(72)}`);

  if (failedTests > 0 || totalErrors > 0) {
    console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam e ${totalErrors} simulação(ões) com erro. Revisar implementação.\n`);
    process.exit(1);
  } else {
    console.log(`\n  ✅ TODOS OS TESTES PASSARAM — HOMOLOGAÇÃO APROVADA\n`);
    process.exit(0);
  }
}

// Executa
main();