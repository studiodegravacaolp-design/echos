/**
 * ====================================================================
 * progressionPersistence.test.ts
 * --------------------------------------------------------------------
 * Suite de validação cruzada — Sprint 3 (Tarefa 3.3 — Integrity & Persistence Test).
 * Testa a integração entre ProgressionManager e CampaignStateManager,
 * simulando ciclos completos de evolução e corrupção de savegames.
 *
 * Cenário A: Ciclo completo de progresso e salvamento
 *   - Instancia CharacterState level 1
 *   - Adiciona XP suficiente para cascatear múltiplos níveis (ultrapassando level 36)
 *   - Serializa, monta ICampaignSave, gera checksum via CampaignStateManager
 *   - Valida com validateAndLoadSave — prova integridade e recuperação
 *
 * Cenário B: Detecção de adulteração e quebra de hash
 *   - Modifica um caractere do playerData no JSON válido
 *   - Submete ao validateAndLoadSave
 *   - Assevera que o motor bloqueia com PERSIST-ERR-008
 *
 * Fonte: docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md
 *        docs/04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO (Sprint 3)
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { ProgressionManager } from '../core/ProgressionManager';
import { CampaignStateManager, ICampaignSave } from '../core/CampaignStateManager';
import { ICharacterStats, WorldState } from '../types/aetheris.types';

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

function assertStrictEqual(
  actual: unknown,
  expected: unknown,
  description: string,
): void {
  assert(actual === expected, `${description} (esperado="${expected}", atual="${actual}")`);
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
 * Calcula o XP total necessário para ir do nível 1 até (mas não incluindo)
 * o nível alvo, acumulando os requisitos de cada nível intermediário.
 *
 * Fonte: ProgressionManager.calculateRequiredXp()
 */
function calculateTotalXpToLevel(targetLevel: number): number {
  let totalXp = 0;
  const pm = new ProgressionManager();
  for (let level = 1; level < targetLevel; level++) {
    totalXp += pm.calculateRequiredXp(level);
  }
  return totalXp;
}

// ====================================================================
// CENÁRIO A: CICLO COMPLETO DE PROGRESSO E SALVAMENTO
// ====================================================================

function runScenarioA(): void {
  printSection('CENÁRIO A — CICLO COMPLETO DE PROGRESSO E SALVAMENTO');

  // ----------------------------------------------------------------
  // A.1: Instancia CharacterState no nível 1
  // ----------------------------------------------------------------
  printSubSection('A.1 — Instanciação do personagem nível 1');

  const stats = createBaseStats();
  const character = new CharacterState(stats);
  const progressionManager = new ProgressionManager();

  assertStrictEqual(
    character.currentLevel,
    1,
    `Nível inicial do personagem é 1 (atual: ${character.currentLevel})`,
  );

  // ----------------------------------------------------------------
  // A.2: Adiciona XP suficiente para cascatear múltiplos níveis
  //      ultrapassando a barreira do nível 36
  // ----------------------------------------------------------------
  printSubSection('A.2 — Injeção de XP para cascata além do nível 36');

  // Calcula XP necessário para ir do nível 1 ao 40 (ultrapassa 36)
  const xpToLevel40 = calculateTotalXpToLevel(40);

  // Adiciona um excedente de 500 XP para garantir que passa do nível 40
  const xpToInject = xpToLevel40 + 500;

  console.log(`  XP necessário para nível 40: ${xpToLevel40}`);
  console.log(`  XP a injetar (com folga):    ${xpToInject}`);

  const result = progressionManager.addExperience(character, xpToInject);

  console.log(`  Níveis ganhos:              ${result.levelsGained}`);
  console.log(`  Marcas de Aço (overflow):   ${result.overflowMarks}`);
  console.log(`  Nível final do personagem:  ${character.currentLevel}`);

  // Verifica que o personagem subiu de nível (deve estar >= 36)
  assert(
    character.currentLevel >= 36,
    `Personagem ultrapassou o nível 36 (atual: ${character.currentLevel})`,
  );

  // Verifica que o nível é válido (<= 50)
  assert(
    character.currentLevel <= 50,
    `Personagem não excedeu o teto de nível 50 (atual: ${character.currentLevel})`,
  );

  // Verifica que pelo menos 1 nível foi ganho
  assert(
    result.levelsGained > 0,
    `Pelo menos 1 nível foi ganho (ganhos: ${result.levelsGained})`,
  );

  // ----------------------------------------------------------------
  // A.3: Serialização do CharacterState para JSON string
  // ----------------------------------------------------------------
  printSubSection('A.3 — Serialização do estado do personagem');

  const serializedData = character.toJSON();
  const playerDataJson = JSON.stringify(serializedData);

  console.log(`  Dados serializados: ${playerDataJson}`);

  assert(
    typeof playerDataJson === 'string' && playerDataJson.length > 0,
    'playerData é uma string JSON não vazia',
  );

  // Verifica que o nível serializado corresponde ao nível atual
  const parsedSerialized = JSON.parse(playerDataJson);
  assertStrictEqual(
    parsedSerialized.level,
    character.currentLevel,
    `Nível serializado (${parsedSerialized.level}) === nível atual (${character.currentLevel})`,
  );

  // ----------------------------------------------------------------
  // A.4: Montagem da estrutura ICampaignSave com checksum
  // ----------------------------------------------------------------
  printSubSection('A.4 — Montagem do ICampaignSave e geração de checksum');

  const csm = CampaignStateManager.getInstance();
  csm.reset(); // Garante estado limpo para o teste

  // Monta o save (sem checksum ainda)
  const saveData: Omit<ICampaignSave, 'checksum'> = {
    playerData: playerDataJson,
    worldState: WorldState.ERA_DO_ACO,
    completedMilestones: ['EVT_INICIO_JORNADA'],
  };

  // Gera o checksum
  const checksum = csm.generateChecksum(saveData);
  console.log(`  Checksum gerado: ${checksum}`);

  assert(
    typeof checksum === 'string' && checksum.length > 0,
    'Checksum foi gerado como string não vazia',
  );

  // Monta o save completo
  const completeSave: ICampaignSave = {
    ...saveData,
    checksum,
  };

  const saveJsonString = JSON.stringify(completeSave);
  console.log(`  JSON do save (playerData truncado): ${saveJsonString.substring(0, 120)}...`);

  // ----------------------------------------------------------------
  // A.5: Validação e carregamento via validateAndLoadSave
  // ----------------------------------------------------------------
  printSubSection('A.5 — Validação e carregamento do save legítimo');

  const validResult = csm.validateAndLoadSave(saveJsonString);

  assert(
    validResult.success === true,
    `validateAndLoadSave retornou success=true (error: ${validResult.error ?? 'nenhum'})`,
  );

  assert(
    validResult.save !== undefined,
    'O save validado foi retornado (save !== undefined)',
  );

  if (validResult.save) {
    // Verifica que os dados do jogador foram preservados integralmente
    assertStrictEqual(
      validResult.save.playerData,
      playerDataJson,
      'playerData preservado integralmente após validação',
    );

    // Verifica que o worldState foi preservado
    assertStrictEqual(
      validResult.save.worldState,
      WorldState.ERA_DO_ACO,
      'worldState preservado como ERA_DO_ACO',
    );

    // Verifica que os milestones foram preservados
    assertStrictEqual(
      validResult.save.completedMilestones.length,
      1,
      'completedMilestones contém 1 milestone',
    );

    assertStrictEqual(
      validResult.save.completedMilestones[0],
      'EVT_INICIO_JORNADA',
      'Milestone EVT_INICIO_JORNADA preservado',
    );

    // Verifica que o checksum foi preservado
    assertStrictEqual(
      validResult.save.checksum,
      checksum,
      'Checksum preservado após validação',
    );

    // Recupera o nível do personagem a partir do playerData salvo
    const recoveredPlayerData = JSON.parse(validResult.save.playerData);
    assertStrictEqual(
      recoveredPlayerData.level,
      character.currentLevel,
      `Nível recuperado do save (${recoveredPlayerData.level}) === nível atual (${character.currentLevel})`,
    );
  }

  console.log(`\n  ✅ Save game legítimo validado e carregado com sucesso.`);
}

// ====================================================================
// CENÁRIO B: DETECÇÃO DE ADULTERAÇÃO E QUEBRA DE HASH
// ====================================================================

function runScenarioB(): void {
  printSection('CENÁRIO B — DETECÇÃO DE ADULTERAÇÃO E QUEBRA DE HASH');

  // ----------------------------------------------------------------
  // B.1: Geração de um save legítimo para servir de base
  // ----------------------------------------------------------------
  printSubSection('B.1 — Geração de save legítimo base');

  const stats = createBaseStats();
  const character = new CharacterState(stats);
  const progressionManager = new ProgressionManager();

  // Sobe o personagem para o nível 25 (meio do jogo)
  const xpToLevel25 = calculateTotalXpToLevel(25);
  progressionManager.addExperience(character, xpToLevel25);

  const serializedData = character.toJSON();
  const playerDataJson = JSON.stringify(serializedData);

  const csm = CampaignStateManager.getInstance();
  csm.reset();

  const saveData: Omit<ICampaignSave, 'checksum'> = {
    playerData: playerDataJson,
    worldState: WorldState.ESTASE_RUNICA,
    completedMilestones: [
      'EVT_INICIO_JORNADA',
      'EVT_PRIMEIRO_COMBATE',
      'EVT_CHEGADA_MERIDIANO',
    ],
  };

  const checksum = csm.generateChecksum(saveData);

  const completeSave: ICampaignSave = {
    ...saveData,
    checksum,
  };

  const legitimateJson = JSON.stringify(completeSave);
  console.log(`  Save legítimo gerado (nível ${character.currentLevel}, ${WorldState.ESTASE_RUNICA})`);

  // ----------------------------------------------------------------
  // B.2: Modificação maliciosa de um único caractere no playerData
  // ----------------------------------------------------------------
  printSubSection('B.2 — Modificação maliciosa de um caractere no playerData');

  // Parseia o save legítimo para manipular o playerData diretamente
  const parsedSave = JSON.parse(legitimateJson);
  const originalPlayerData: string = parsedSave.playerData;

  // Modifica o primeiro caractere do playerData (troca '{' por 'A')
  const tamperedPlayerData = 'A' + originalPlayerData.substring(1);
  parsedSave.playerData = tamperedPlayerData;

  const tamperedJson = JSON.stringify(parsedSave);

  console.log(`  Primeiro caractere do playerData original: '${originalPlayerData.charAt(0)}'`);
  console.log(`  Primeiro caractere do playerData adulterado: '${tamperedPlayerData.charAt(0)}'`);

  // Garante que a modificação foi aplicada (o JSON mudou)
  assert(
    tamperedJson !== legitimateJson,
    'O JSON adulterado é diferente do JSON legítimo',
  );

  // ----------------------------------------------------------------
  // B.3: Submissão do JSON adulterado ao validateAndLoadSave
  // ----------------------------------------------------------------
  printSubSection('B.3 — Validação do save adulterado');

  const tamperResult = csm.validateAndLoadSave(tamperedJson);

  // ----------------------------------------------------------------
  // B.4: Asserção de que o motor bloqueia com PERSIST-ERR-008
  // ----------------------------------------------------------------
  printSubSection('B.4 — Verificação do bloqueio de integridade');

  // O resultado deve ser success = false
  assert(
    tamperResult.success === false,
    `validateAndLoadSave retornou success=false para save adulterado`,
  );

  // O resultado deve conter mensagem de erro
  assert(
    tamperResult.error !== undefined && tamperResult.error !== null,
    'Mensagem de erro foi retornada',
  );

  // O erro deve conter PERSIST-ERR-008
  assert(
    tamperResult.error!.includes('PERSIST-ERR-008'),
    `Erro contém código PERSIST-ERR-008 (mensagem: ${tamperResult.error})`,
  );

  // O save NÃO deve ser retornado
  assert(
    tamperResult.save === undefined,
    'save não foi retornado para dados adulterados (save === undefined)',
  );

  // Verifica que o save legítimo AINDA funciona (prova que o motor não quebrou)
  printSubSection('B.5 — Prova de que o motor ainda aceita saves legítimos');

  const postTamperValidResult = csm.validateAndLoadSave(legitimateJson);
  assert(
    postTamperValidResult.success === true,
    'Save legítimo ainda é aceito após tentativa de adulteração',
  );

  console.log(`\n  🔒 Barreira criptográfica PERSIST-ERR-008 interceptou a adulteração com sucesso.`);
}

// ====================================================================
// EXECUTOR PRINCIPAL
// ====================================================================

function main(): void {
  console.log(`\n${'#'.repeat(72)}`);
  console.log(`#  PROGRESSION & PERSISTENCE TEST SUITE — SPRINT 3 (TAREFA 3.3)`);
  console.log(`#  Integração: ProgressionManager + CampaignStateManager`);
  console.log(`#  Data:  ${new Date().toISOString()}`);
  console.log(`${'#'.repeat(72)}\n`);

  // Executa Cenário A
  runScenarioA();

  // Executa Cenário B
  runScenarioB();

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