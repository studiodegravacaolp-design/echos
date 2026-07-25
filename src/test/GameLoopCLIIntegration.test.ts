/**
 * ====================================================================
 * GameLoopCLIIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO do fluxo CLI — exercita os métodos "core" do
 * CLIGameLoop (sem readline/process.exit) para validar o ciclo:
 *
 *   Novo Jogo → Travessia (traverseToNode) → AutoSave → Carregar Save
 *
 * Também cobre HUD de status, preview de custo/perigo, save manual e
 * isolação AutoSave × slot manual.
 *
 * Hermético: SaveSlotEngine injetado com diretório temporário isolado.
 * Execução: npx tsx src/test/GameLoopCLIIntegration.test.ts
 *
 * Fonte: src/cli/GameLoop.ts
 *        src/core/SaveSlotEngine.ts, CampaignMapEngine.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { CLIGameLoop } from '../cli/GameLoop';
import { SaveSlotEngine } from '../core/SaveSlotEngine';

// --------------------------------------------------------------------
// HARNESS
// --------------------------------------------------------------------
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function assert(condition: boolean, description: string): void {
    totalTests++;
    if (condition) {
        passedTests++;
        console.log(`  ✓ PASS: ${description}`);
    } else {
        failedTests++;
        console.log(`  ✗ FAIL: ${description}`);
    }
}

function printSection(title: string): void {
    console.log(`\n${'='.repeat(72)}`);
    console.log(`  ${title}`);
    console.log(`${'='.repeat(72)}`);
}

// Diretório temporário isolado.
const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-cli-'));
function cleanup(): void {
    try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ }
}
function newLoop(): CLIGameLoop {
    // SaveSlotEngine com dir isolado; readline NÃO é criado (start() não é chamado).
    return new CLIGameLoop(new SaveSlotEngine(TMP_DIR));
}

// ====================================================================
// A) CICLO PONTA-A-PONTA: NOVO JOGO → TRAVESSIA → AUTOSAVE → CARREGAR
// ====================================================================
function runEndToEndTest(): void {
    printSection('A — Novo Jogo → Travessia → AutoSave → Carregar');

    const loop = newLoop();

    // 1) Novo jogo.
    const campaign = loop.startNewGame();
    assert(campaign.getProgress().currentNodeId === 'brenhold_entrance', 'A.1: novo jogo inicia na entrada');
    assert(campaign.getSupplies() === 100, 'A.2: mantimentos iniciais = 100');
    assert(campaign.getProgress().estafaBalance === 0, 'A.3: estafa inicial = 0');

    // 2) Preview antes de atravessar (custo/perigo).
    const preview = loop.previewTraversal('sector_01_combat');
    assert(preview?.hazardLevel === 2, `A.4: preview perigo=2 (obtido ${preview?.hazardLevel})`);
    assert(preview?.supplyCost === 15, `A.5: preview custo=15 (obtido ${preview?.supplyCost})`);

    // 3) Travessia + AutoSave.
    const { result, autoSaved } = loop.performTraversal('sector_01_combat');
    assert(result.success === true, 'A.6: travessia bem-sucedida');
    assert(autoSaved === true, 'A.7: AutoSave disparado após travessia');
    assert(campaign.getSupplies() === 85, `A.8: mantimentos 100→85 (obtido ${campaign.getSupplies()})`);
    assert(campaign.getProgress().estafaBalance === 8, `A.9: estafa 0→+8 (obtido ${campaign.getProgress().estafaBalance})`);
    assert(campaign.getProgress().currentNodeId === 'sector_01_combat', 'A.10: nó atual avançou');

    // 4) AutoSave aparece na listagem.
    const autosaveSummary = loop.listSlots().find((s) => s.slotId === 'AUTOSAVE');
    assert(autosaveSummary?.empty === false, 'A.11: slot AUTOSAVE ocupado');
    assert(autosaveSummary?.metadata?.supplies === 85, 'A.12: metadata do AutoSave reflete supplies=85');

    // 5) Nova sessão carrega o AutoSave e recupera o estado.
    const loop2 = newLoop();
    const loaded = loop2.loadSlot('AUTOSAVE');
    assert(loaded === true, 'A.13: carregamento do AutoSave bem-sucedido');
    const restored = loop2.getCampaign();
    assert(restored.getSupplies() === 85, `A.14: supplies restaurados = 85 (obtido ${restored.getSupplies()})`);
    assert(restored.getProgress().estafaBalance === 8, `A.15: estafa restaurada = +8 (obtido ${restored.getProgress().estafaBalance})`);
    assert(restored.getProgress().currentNodeId === 'sector_01_combat', 'A.16: posição restaurada');
}

// ====================================================================
// B) HUD DE STATUS
// ====================================================================
function runHudTest(): void {
    printSection('B — HUD de status do grupo');

    const loop = newLoop();
    loop.startNewGame();
    const hud = loop.getPartyStatusHUD();

    assert(hud.includes('Mantimentos: 100'), 'B.1: HUD mostra mantimentos');
    assert(hud.includes('Estafa: 0'), 'B.2: HUD mostra estafa');
    assert(hud.includes('Equilíbrio'), 'B.3: HUD rotula o polo da estafa');
    assert(loop.getEquipmentSummary() === '(nenhum)', 'B.4: sem equipamento durável inicialmente');
}

// ====================================================================
// C) SAVE MANUAL E ISOLAÇÃO COM AUTOSAVE
// ====================================================================
function runManualSaveTest(): void {
    printSection('C — Save manual e isolação com AutoSave');

    const loop = newLoop();
    loop.startNewGame();

    // Avança e autosava (AUTOSAVE = sector_01_combat, estafa +8).
    loop.performTraversal('sector_01_combat');

    // Salva manualmente em SLOT_1 no estado atual.
    const okManual = loop.saveToManualSlot('SLOT_1');
    assert(okManual === true, 'C.1: save manual em SLOT_1 bem-sucedido');

    // Avança de novo (AUTOSAVE muda para sector_02_combat, estafa +20).
    loop.performTraversal('sector_02_combat');

    // SLOT_1 continua no estado anterior (estafa +8); AUTOSAVE avançou (+20).
    const slots = loop.listSlots();
    const slot1 = slots.find((s) => s.slotId === 'SLOT_1');
    const autosave = slots.find((s) => s.slotId === 'AUTOSAVE');
    assert(slot1?.metadata?.estafaBalance === 8, `C.2: SLOT_1 preserva estafa +8 (obtido ${slot1?.metadata?.estafaBalance})`);
    assert(autosave?.metadata?.estafaBalance === 20, `C.3: AUTOSAVE avançou para +20 (obtido ${autosave?.metadata?.estafaBalance})`);

    // Carrega SLOT_1 e confirma o estado antigo.
    const loop2 = newLoop();
    loop2.loadSlot('SLOT_1');
    assert(loop2.getCampaign().getProgress().currentNodeId === 'sector_01_combat', 'C.4: SLOT_1 restaura posição intermediária');
}

// ====================================================================
// D) MENU DE SLOTS — VAZIOS vs OCUPADOS
// ====================================================================
function runSlotListingTest(): void {
    printSection('D — Listagem de slots');

    const loop = newLoop();
    loop.startNewGame();
    loop.saveToManualSlot('SLOT_2');

    const slots = loop.listSlots();
    assert(slots.length === 4, `D.1: quatro slots listados (obtido ${slots.length})`);
    assert(slots.find((s) => s.slotId === 'SLOT_2')?.empty === false, 'D.2: SLOT_2 ocupado');
    assert(slots.find((s) => s.slotId === 'SLOT_3')?.empty === true, 'D.3: SLOT_3 vazio');
}

// ====================================================================
// E) GERAÇÃO DE ENCONTRO AO ENTRAR EM NÓ HOSTIL
// ====================================================================
function runEncounterTest(): void {
    printSection('E — Encontro de combate ao atravessar nó hostil');

    const loop = newLoop();
    loop.startNewGame();

    // entrance → sector_01_combat (COMBAT_ARENA, hazard 2) → encontro de tamanho 2.
    const combat = loop.performTraversal('sector_01_combat');
    assert(combat.result.success === true, 'E.1: travessia bem-sucedida');
    assert(combat.encounter !== undefined, 'E.2: nó de combate gera encontro');
    assert(combat.encounter!.enemies.length === 2, `E.3: hazard 2 → 2 inimigos (obtido ${combat.encounter!.enemies.length})`);
    assert(combat.encounter!.ais.length === combat.encounter!.enemies.length, 'E.4: uma IA de combate por inimigo');

    // Arquétipos mapeados para o AIArchetype de combate legado.
    const archetypes = combat.encounter!.ais.map((ai) => ai.archetype);
    const validArchetypes = archetypes.every((a) => ['ASSASSINO', 'PROTETOR', 'DRENADOR_ESTAFA'].includes(a));
    assert(validArchetypes, 'E.5: IAs usam AIArchetype de combate válido (via ENEMY_TO_COMBAT_ARCHETYPE)');

    // Inimigos escalados têm HP/dano positivos.
    const scaledOk = combat.encounter!.enemies.every((e) => e.stats.maxHp > 0 && e.stats.damage > 0 && e.level >= 1);
    assert(scaledOk, 'E.6: inimigos possuem atributos escalados válidos');

    // Nó não-hostil (SCRAP_TRADER) NÃO gera encontro.
    const trade = loop.performTraversal('black_market_trader');
    assert(trade.result.success === true, 'E.7: travessia ao mercador bem-sucedida');
    assert(trade.encounter === undefined, 'E.8: nó de comércio não gera encontro');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    try {
        runEndToEndTest();
        runHudTest();
        runManualSaveTest();
        runSlotListingTest();
        runEncounterTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE INTEGRAÇÃO — Fluxo CLI / GameLoop`);
    console.log(`${'='.repeat(72)}`);
    console.log(`  Total de testes:    ${totalTests}`);
    console.log(`  Aprovados (PASS):   ${passedTests}`);
    console.log(`  Reprovados (FAIL):  ${failedTests}`);
    console.log(
        `  Taxa de sucesso:    ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`,
    );
    console.log(`${'='.repeat(72)}`);

    if (failedTests > 0) {
        console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam.\n`);
        process.exit(1);
    } else {
        console.log(`\n  ✅ TODOS OS TESTES DE INTEGRAÇÃO PASSARAM\n`);
        process.exit(0);
    }
}

main();
