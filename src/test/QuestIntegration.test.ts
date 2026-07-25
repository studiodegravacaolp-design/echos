/**
 * ====================================================================
 * QuestIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Sistema de Missões.
 *
 * Cobre o ciclo:
 *   Iniciar Quest → Navegar até Nó (REACH_NODE) → Vencer Combate
 *   (DEFEAT_ENEMIES / KILL_BOSS) → Concluir Quest e Receber Recompensa
 *   → Salvar & Carregar Estado das Missões.
 *
 * Hermético (SaveSlotEngine em diretório temporário).
 * Execução: npx tsx src/test/QuestIntegration.test.ts
 *
 * Fonte: src/core/QuestManager.ts, QuestContent.ts, SaveSlotEngine.ts,
 *        src/cli/GameLoop.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { QuestManager, QuestStatus } from '../core/QuestManager';
import { makeMainQuest, makeSideQuestAutomaton } from '../core/QuestContent';
import { SaveSlotEngine } from '../core/SaveSlotEngine';
import { CLIGameLoop } from '../cli/GameLoop';

// --------------------------------------------------------------------
let totalTests = 0, passedTests = 0, failedTests = 0;
function assert(c: boolean, d: string): void {
    totalTests++;
    if (c) { passedTests++; console.log(`  ✓ PASS: ${d}`); }
    else { failedTests++; console.log(`  ✗ FAIL: ${d}`); }
}
function printSection(t: string): void { console.log(`\n${'='.repeat(72)}\n  ${t}\n${'='.repeat(72)}`); }

const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-quest-'));
function cleanup(): void { try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ } }
function newLoop(): CLIGameLoop { return new CLIGameLoop(new SaveSlotEngine(TMP_DIR)); }

const MAIN_ID = 'quest_heart_of_brenhold';

// ====================================================================
// A) GATILHOS DO QUESTMANAGER
// ====================================================================
function runTriggersTest(): void {
    printSection('A — Gatilhos de progresso (nó / combate / diálogo)');

    const qm = new QuestManager();
    qm.registerQuest(makeMainQuest());
    qm.startQuest(MAIN_ID);
    qm.registerQuest(makeSideQuestAutomaton());
    qm.startQuest('quest_echoes_in_ducts');

    assert(qm.getActiveMainQuest()?.id === MAIN_ID, 'A.1: missão principal ativa detectada');
    assert(qm.getCurrentGoal(MAIN_ID)?.id === 'g_reach_foundry', 'A.2: etapa atual = alcançar a fundição');

    // REACH_NODE.
    let done = qm.notifyNodeVisited('sector_01_combat');
    assert(done.length === 0 && qm.getCurrentGoal(MAIN_ID)?.id === 'g_defeat_enemies', 'A.3: nó avança para a etapa de combate');

    // DEFEAT_ENEMIES (3 hostis).
    qm.notifyEnemiesDefeated([{ templateId: 'rato_quimico' }, { templateId: 'batedor_catador' }, { templateId: 'enxame_faisca' }]);
    assert(qm.getCurrentGoal(MAIN_ID)?.id === 'g_kill_colossus', 'A.4: após 3 abates, etapa = matar o chefe');

    // KILL_BOSS — completa a principal.
    done = qm.notifyEnemiesDefeated([{ templateId: 'colosso_ferrugem' }]);
    assert(done.includes(MAIN_ID), 'A.5: derrotar o Colosso conclui a missão principal');

    // TALK_NPC — completa a secundária.
    const doneSide = qm.notifyNpcTalked('trapped_automaton');
    assert(doneSide.includes('quest_echoes_in_ducts'), 'A.6: falar com o autômato conclui a secundária');

    // Reivindicação de recompensa marca COMPLETED e é única.
    const reward = qm.claimQuestReward(MAIN_ID);
    assert(reward?.scrap === 100 && reward?.xp === 200 && reward?.supplies === 50, 'A.7: recompensa da principal (100💰/200XP/50🍞)');
    assert(qm.getQuest(MAIN_ID)?.status === QuestStatus.COMPLETED, 'A.8: missão marcada COMPLETED');
    assert(qm.claimQuestReward(MAIN_ID) === null, 'A.9: recompensa não pode ser reivindicada 2x');
}

// ====================================================================
// B) FLUXO NO GAMELOOP + APLICAÇÃO DE RECOMPENSA
// ====================================================================
function runGameLoopFlowTest(): void {
    printSection('B — GameLoop: navegação, combate e recompensa ao grupo');

    const loop = newLoop();
    const campaign = loop.startNewGame();
    const qm = loop.getQuestManager();

    assert(qm.getActiveMainQuest()?.id === MAIN_ID, 'B.1: novo jogo registra e ativa a missão principal');
    assert(loop.getMainQuestHUD().includes('O Coração de Brenhold'), 'B.2: HUD exibe a missão principal');

    // Navegar até a fundição (dispara REACH_NODE via performTraversal).
    const suppliesBeforeQuest = campaign.getSupplies(); // após custo de travessia
    loop.performTraversal('sector_01_combat');
    assert(qm.getCurrentGoal(MAIN_ID)?.id === 'g_defeat_enemies', 'B.3: travessia avançou a etapa de nó');

    // Simular vitória de combate: abates + conclusão da principal.
    const scrapBefore = campaign.getPartyState()[0].scrapCount;
    const suppliesAfterTraversal = campaign.getSupplies();
    const enemies = [
        { templateId: 'rato_quimico' }, { templateId: 'batedor_catador' },
        { templateId: 'enxame_faisca' }, { templateId: 'colosso_ferrugem' },
    ];
    const completed = qm.notifyEnemiesDefeated(enemies);
    const paid = loop.processQuestCompletions(completed);

    assert(paid.includes(MAIN_ID), 'B.4: missão principal concluída e paga');
    assert(campaign.getPartyState()[0].scrapCount === scrapBefore + 100, `B.5: +100 sucata de recompensa (obtido ${campaign.getPartyState()[0].scrapCount - scrapBefore})`);
    assert(campaign.getSupplies() === suppliesAfterTraversal + 50, `B.6: +50 mantimentos de recompensa (obtido ${campaign.getSupplies() - suppliesAfterTraversal})`);
    assert(qm.getQuest(MAIN_ID)?.status === QuestStatus.COMPLETED, 'B.7: principal marcada COMPLETED no GameLoop');
    void suppliesBeforeQuest;
}

// ====================================================================
// C) PERSISTÊNCIA DO ESTADO DAS MISSÕES
// ====================================================================
function runPersistenceTest(): void {
    printSection('C — Salvar & Carregar estado das missões');

    // Sessão 1: avança a etapa de nó e salva.
    const loop = newLoop();
    loop.startNewGame();
    loop.performTraversal('sector_01_combat'); // g_reach_foundry → 1/1
    // Também conclui a secundária para testar persistência de COMPLETED.
    loop.processQuestCompletions(loop.getQuestManager().notifyNpcTalked('trapped_automaton'));
    assert(loop.getQuestManager().getQuest('quest_echoes_in_ducts')?.status === QuestStatus.COMPLETED, 'C.1: secundária concluída na sessão 1');
    const saved = loop.saveToManualSlot('SLOT_1');
    assert(saved === true, 'C.2: save bem-sucedido');

    // Sessão 2 (nova) carrega o slot.
    const loop2 = newLoop();
    const ok = loop2.loadSlot('SLOT_1');
    assert(ok === true, 'C.3: carregamento bem-sucedido');

    const qm2 = loop2.getQuestManager();
    const reachGoal = qm2.getQuest(MAIN_ID)?.goals.find((g) => g.id === 'g_reach_foundry');
    assert(reachGoal?.current === 1, `C.4: progresso da etapa de nó restaurado (1/1) (obtido ${reachGoal?.current})`);
    assert(qm2.getCurrentGoal(MAIN_ID)?.id === 'g_defeat_enemies', 'C.5: etapa atual restaurada corretamente');
    assert(qm2.getQuest('quest_echoes_in_ducts')?.status === QuestStatus.COMPLETED, 'C.6: secundária COMPLETED persistida');
}

// ====================================================================
function main(): void {
    try {
        runTriggersTest();
        runGameLoopFlowTest();
        runPersistenceTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Integração de Missões\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
