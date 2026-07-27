/**
 * ====================================================================
 * CampingIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Acampamento e Gestão de Grupo.
 *
 * Cobre:
 *   A) Descanso: consumo de mantimentos → recuperação de HP + EP.
 *   B) Descanso parcial sem mantimentos (só EP) + risco de escassez.
 *   C) Reparo de campo de item oxidado (Rusted) via sucata.
 *   D) Reordenação de formação (Vanguarda/Retaguarda).
 *   E) Conversa de acampamento desloca a Estafa.
 *   F) Salvamento e carregamento do estado pós-acampamento.
 *
 * Hermético (SaveSlotEngine em diretório temporário).
 * Execução: npx tsx src/test/CampingIntegration.test.ts
 *
 * Fonte: src/core/CampingEngine.ts, CampaignManager.ts, src/cli/GameLoop.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { CampingEngine, REST_SUPPLY_COST } from '../core/CampingEngine';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { SaveSlotEngine } from '../core/SaveSlotEngine';
import { CLIGameLoop } from '../cli/GameLoop';
import { IDurableEquipment } from '../core/EquipmentEngine';
import { ICharacterStats } from '../types/aetheris.types';

// --------------------------------------------------------------------
let totalTests = 0, passedTests = 0, failedTests = 0;
function assert(c: boolean, d: string): void {
    totalTests++;
    if (c) { passedTests++; console.log(`  ✓ PASS: ${d}`); }
    else { failedTests++; console.log(`  ✗ FAIL: ${d}`); }
}
function printSection(t: string): void { console.log(`\n${'='.repeat(72)}\n  ${t}\n${'='.repeat(72)}`); }

function stats(o?: Partial<ICharacterStats>): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10, ...o };
}
function hero(id: string, o?: Partial<ICharacterStats>): CharacterState {
    return new CharacterState(stats(o), undefined, undefined, undefined, null, id);
}
function rustedArmor(): IDurableEquipment {
    return { id: 'worn_plate', name: 'Placa Desgastada', type: 'ARMOR', material: 'SCRAP_IRON', durability: { current: 20, max: 100 }, baseStats: stats({ defense: 8 }) };
}

const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-camp-'));
function cleanup(): void { try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ } }

// ====================================================================
function runRestTest(): void {
    printSection('A — Descanso completo (mantimentos → HP + EP)');
    const camping = new CampingEngine();
    const h = hero('hero_01');
    h.hp = 40; h.currentEp = 20;
    const campaign = new CampaignManager([h]);
    const suppliesBefore = campaign.getSupplies();

    const res = camping.restAndFeed(campaign);
    assert(res.fed === true, 'A.1: descanso completo (havia mantimentos)');
    assert(res.suppliesConsumed === REST_SUPPLY_COST, `A.2: consumiu ${REST_SUPPLY_COST} mantimentos`);
    assert(campaign.getSupplies() === suppliesBefore - REST_SUPPLY_COST, 'A.3: mantimentos debitados');
    assert(h.hp === 80, `A.4: HP 40 → 80 (+40% de 100) (obtido ${h.hp})`);
    assert(h.currentEp === 70, `A.5: EP 20 → 70 (+50% de 100) (obtido ${h.currentEp})`);
    assert(res.survivalRisk === false, 'A.6: sem risco de escassez');
}

function runPartialRestTest(): void {
    printSection('B — Descanso parcial (sem mantimentos → só EP)');
    const camping = new CampingEngine();
    const h = hero('hero_01');
    h.hp = 40; h.currentEp = 20;
    const campaign = new CampaignManager([h]);
    campaign.consumeSupplies(campaign.getSupplies()); // zera mantimentos

    const res = camping.restAndFeed(campaign);
    assert(res.fed === false, 'B.1: descanso parcial (sem mantimentos)');
    assert(res.survivalRisk === true, 'B.2: sinaliza risco de escassez');
    assert(h.hp === 40, `B.3: HP inalterado sem alimento (obtido ${h.hp})`);
    assert(h.currentEp === 70, `B.4: EP restaurado mesmo sem alimento (obtido ${h.currentEp})`);
}

function runRepairTest(): void {
    printSection('C — Reparo de campo de item oxidado');
    const camping = new CampingEngine();
    const h = hero('hero_01');
    h.scrapCount = 100;
    const armor = rustedArmor();
    h.equipDurable(armor);
    const campaign = new CampaignManager([h]);

    const res = camping.fieldRepair(campaign, 'hero_01', 'worn_plate');
    assert(res.success === true, 'C.1: reparo bem-sucedido');
    assert(res.durabilityRestored === 80 && armor.durability.current === 100, 'C.2: durabilidade restaurada ao máximo');
    assert(res.rustCleared === true, 'C.3: estado Rusted removido (>25%)');
    assert(h.scrapCount === 84, `C.4: sucata 100 → 84 (16 gastas) (obtido ${h.scrapCount})`);
}

function runFormationTest(): void {
    printSection('D — Reordenação de formação');
    const a = hero('vanguard_a');
    const b = hero('rear_b');
    const campaign = new CampaignManager([a, b]);
    const camping = new CampingEngine();

    assert(campaign.getPartyState()[0].id === 'vanguard_a', 'D.1: A começa na Vanguarda');
    camping.adjustFormation(campaign, ['rear_b', 'vanguard_a']);
    assert(campaign.getPartyState()[0].id === 'rear_b', 'D.2: B assume a Vanguarda após reordenar');

    campaign.swapFormationPositions(0, 1);
    assert(campaign.getPartyState()[0].id === 'vanguard_a', 'D.3: swap devolve A à Vanguarda');
}

function runConversationTest(): void {
    printSection('E — Conversa de acampamento desloca a Estafa');
    const campaign = new CampaignManager([hero('hero_01')]);
    const camping = new CampingEngine();

    assert(campaign.getProgress().estafaBalance === 0, 'E.1: estafa inicial 0');
    assert(camping.campConversation(campaign, 'PATERNO') === 10, 'E.2: conversa Paterno → +10');
    assert(camping.campConversation(campaign, 'MATERNO') === 0, 'E.3: conversa Materno → −10 (volta a 0)');
}

function runSavePostCampTest(): void {
    printSection('F — Salvamento do estado pós-acampamento');
    const loop = new CLIGameLoop(new SaveSlotEngine(TMP_DIR));
    const campaign = loop.startNewGame();
    const h = campaign.getPartyState()[0];
    h.hp = 40;
    const camping = new CampingEngine();

    // Acampa: consome mantimentos e restaura HP.
    camping.restAndFeed(campaign);
    const suppliesAfter = campaign.getSupplies();
    const hpAfter = h.hp;
    assert(hpAfter === 80, `F.1: HP pós-descanso = 80 (obtido ${hpAfter})`);

    const saved = loop.saveToManualSlot('SLOT_1');
    assert(saved === true, 'F.2: save pós-acampamento bem-sucedido');

    // Nova sessão carrega e valida a persistência.
    const loop2 = new CLIGameLoop(new SaveSlotEngine(TMP_DIR));
    const ok = loop2.loadSlot('SLOT_1');
    assert(ok === true, 'F.3: carregamento bem-sucedido');
    const restored = loop2.getCampaign();
    assert(restored.getSupplies() === suppliesAfter, `F.4: mantimentos pós-acampamento persistidos (obtido ${restored.getSupplies()})`);
    assert(restored.getPartyState()[0].hp === hpAfter, `F.5: HP pós-descanso persistido (obtido ${restored.getPartyState()[0].hp})`);
}

// ====================================================================
function main(): void {
    try {
        runRestTest();
        runPartialRestTest();
        runRepairTest();
        runFormationTest();
        runConversationTest();
        runSavePostCampTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Acampamento & Gestão de Grupo\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
