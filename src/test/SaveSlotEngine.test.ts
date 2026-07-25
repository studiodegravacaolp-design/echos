/**
 * ====================================================================
 * SaveSlotEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Gerenciamento de Saves Multi-Slot.
 *
 * Cobre:
 *   A) Persistência e carregamento sem perdas (round-trip completo).
 *   B) Isolação entre slots (alterar SLOT_1 não afeta SLOT_2).
 *   C) AutoSave: carregamento e sobrescrita correta.
 *   D) Migração de saves antigos com campos faltantes.
 *
 * Hermético: usa um diretório temporário isolado (limpo ao final).
 * Execução: npx tsx src/test/SaveSlotEngine.test.ts
 *
 * Fonte: src/core/SaveSlotEngine.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { SaveSlotEngine } from '../core/SaveSlotEngine';
import { StatusEngine } from '../core/StatusEngine';
import { IDurableEquipment } from '../core/EquipmentEngine';
import { ICharacterStats, LatentLineageAxis } from '../types/aetheris.types';

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

// --------------------------------------------------------------------
// FÁBRICAS
// --------------------------------------------------------------------
function baseStats(): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 };
}

function makeCampaign(): { campaign: CampaignManager; hero: CharacterState } {
    const hero = new CharacterState(baseStats(), undefined, undefined, undefined, null, 'hero_engineer_01');
    const campaign = new CampaignManager([hero]);
    return { campaign, hero };
}

function makeArmor(id: string, current: number, max: number): IDurableEquipment {
    return { id, name: id, type: 'ARMOR', material: 'SCRAP_IRON', durability: { current, max }, baseStats: { ...baseStats(), defense: 8 } };
}

// Diretório temporário isolado.
const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-saveslot-'));
function cleanup(): void {
    try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ }
}

// ====================================================================
// A) ROUND-TRIP SEM PERDAS
// ====================================================================
function runRoundTripTest(): void {
    printSection('A — Persistência e carregamento sem perdas');

    const engine = new SaveSlotEngine(TMP_DIR);
    const { campaign, hero } = makeCampaign();

    // Monta um estado rico.
    hero.currentLevel = 12;
    hero.scrapCount = 77;
    hero.hp = 60;
    hero.latentLineageAxis = LatentLineageAxis.PATERNO_EMBER;
    hero.equipDurable(makeArmor('scrap_plate', 55, 100));
    StatusEngine.applyStatus(hero, { id: 'poison', type: 'CHEMICAL_POISON', duration: 3, stacks: 2, valuePerTurn: 5, sourceId: 'enemy_01' });
    campaign.modifyEstafaBalance(30);
    campaign.consumeSupplies(40); // 100 → 60
    campaign.setCurrentNode('sector_01_combat');

    const saved = engine.saveToSlot('SLOT_1', campaign, { playTimeSeconds: 1234, currentAreaName: 'Pátio de Fundição' });
    assert(saved === true, 'A.1: saveToSlot retorna sucesso');

    // Campanha nova (esqueleto com mesmo id e stats-base).
    const { campaign: fresh, hero: freshHero } = makeCampaign();
    const load = engine.loadFromSlot('SLOT_1', fresh);

    assert(load.success === true, 'A.2: loadFromSlot bem-sucedido');
    assert(load.metadata?.playTimeSeconds === 1234, 'A.3: metadata playTime preservado');
    assert(load.metadata?.currentAreaName === 'Pátio de Fundição', 'A.4: metadata área preservada');
    assert(fresh.getProgress().estafaBalance === 30, `A.5: estafa restaurada = 30 (obtido ${fresh.getProgress().estafaBalance})`);
    assert(fresh.getSupplies() === 60, `A.6: supplies restaurados = 60 (obtido ${fresh.getSupplies()})`);
    assert(fresh.getProgress().currentNodeId === 'sector_01_combat', 'A.7: nó do mapa restaurado');
    assert(freshHero.hp === 60, `A.8: HP restaurado = 60 (obtido ${freshHero.hp})`);
    assert(freshHero.scrapCount === 77, `A.9: sucata restaurada = 77 (obtido ${freshHero.scrapCount})`);
    assert(freshHero.currentLevel === 12, `A.10: nível restaurado = 12 (obtido ${freshHero.currentLevel})`);
    assert(freshHero.durableEquipment.length === 1, 'A.11: equipamento durável restaurado');
    assert(freshHero.durableEquipment[0].durability.current === 55, `A.12: durabilidade preservada = 55 (obtido ${freshHero.durableEquipment[0].durability.current})`);
    assert(freshHero.activeStatuses.length === 1, 'A.13: status tático restaurado');
    assert(freshHero.activeStatuses[0].stacks === 2, `A.14: stacks do status preservados = 2 (obtido ${freshHero.activeStatuses[0].stacks})`);
    // latentLineageAxis real (nível 12 < 36 → getter mascara, mas o valor stored deve ser PATERNO_EMBER).
    const rawLineage = (freshHero.toJSON() as { latentLineageAxis?: LatentLineageAxis }).latentLineageAxis;
    assert(rawLineage === LatentLineageAxis.PATERNO_EMBER, `A.15: linhagem real preservada (obtido ${rawLineage})`);
}

// ====================================================================
// B) ISOLAÇÃO ENTRE SLOTS
// ====================================================================
function runIsolationTest(): void {
    printSection('B — Isolação entre slots');

    const engine = new SaveSlotEngine(TMP_DIR);

    // SLOT_1 = estafa +20, supplies 90.
    const a = makeCampaign();
    a.campaign.modifyEstafaBalance(20);
    a.campaign.consumeSupplies(10);
    engine.saveToSlot('SLOT_1', a.campaign);

    // SLOT_2 = estafa -50, supplies 30.
    const b = makeCampaign();
    b.campaign.modifyEstafaBalance(-50);
    b.campaign.consumeSupplies(70);
    engine.saveToSlot('SLOT_2', b.campaign);

    // Reescreve SLOT_1 com outro estado.
    const a2 = makeCampaign();
    a2.campaign.modifyEstafaBalance(99);
    engine.saveToSlot('SLOT_1', a2.campaign);

    // SLOT_2 deve permanecer intacto.
    const check2 = engine.loadFromSlot('SLOT_2', makeCampaign().campaign);
    assert(check2.payload?.progress.estafaBalance === -50, `B.1: SLOT_2 estafa intacta = -50 (obtido ${check2.payload?.progress.estafaBalance})`);
    assert(check2.payload?.progress.supplies === 30, `B.2: SLOT_2 supplies intactos = 30 (obtido ${check2.payload?.progress.supplies})`);

    // SLOT_1 reflete a reescrita.
    const check1 = engine.loadFromSlot('SLOT_1', makeCampaign().campaign);
    assert(check1.payload?.progress.estafaBalance === 99, `B.3: SLOT_1 reescrito = 99 (obtido ${check1.payload?.progress.estafaBalance})`);

    // listSaveSlots reporta os slots ocupados e livres.
    const slots = engine.listSaveSlots();
    const s1 = slots.find((s) => s.slotId === 'SLOT_1')!;
    const s3 = slots.find((s) => s.slotId === 'SLOT_3')!;
    assert(s1.empty === false, 'B.4: SLOT_1 listado como ocupado');
    assert(s3.empty === true, 'B.5: SLOT_3 listado como vazio');
}

// ====================================================================
// C) AUTOSAVE — LOAD E SOBRESCRITA
// ====================================================================
function runAutoSaveTest(): void {
    printSection('C — AutoSave: carregamento e sobrescrita');

    const engine = new SaveSlotEngine(TMP_DIR);

    // Primeiro autosave.
    const s1 = makeCampaign();
    s1.campaign.modifyEstafaBalance(15);
    engine.saveToSlot('AUTOSAVE', s1.campaign);

    const first = engine.loadFromSlot('AUTOSAVE', makeCampaign().campaign);
    assert(first.payload?.progress.estafaBalance === 15, `C.1: autosave inicial = 15 (obtido ${first.payload?.progress.estafaBalance})`);

    // Sobrescreve o autosave.
    const s2 = makeCampaign();
    s2.campaign.modifyEstafaBalance(-40);
    engine.saveToSlot('AUTOSAVE', s2.campaign);

    const second = engine.loadFromSlot('AUTOSAVE', makeCampaign().campaign);
    assert(second.payload?.progress.estafaBalance === -40, `C.2: autosave sobrescrito = -40 (obtido ${second.payload?.progress.estafaBalance})`);

    // deleteSlot limpa o autosave.
    assert(engine.deleteSlot('AUTOSAVE') === true, 'C.3: deleteSlot retorna sucesso');
    const afterDelete = engine.loadFromSlot('AUTOSAVE', makeCampaign().campaign);
    assert(afterDelete.success === false, 'C.4: slot deletado não carrega');
}

// ====================================================================
// D) MIGRAÇÃO DE SAVE ANTIGO COM CAMPOS FALTANTES
// ====================================================================
function runMigrationTest(): void {
    printSection('D — Migração de save antigo com campos faltantes');

    const engine = new SaveSlotEngine(TMP_DIR);

    // Save legado: sem checksum, sem supplies/survivalCrisis, party sem
    // durableEquipment/activeStatuses/level/lineage, sem mapState.
    const legacy = {
        slotId: 'SLOT_3',
        metadata: { timestamp: 111, currentAreaName: 'Entrada', partyLeaderName: 'hero_engineer_01' },
        payload: {
            progress: { currentNodeId: 'brenhold_entrance', estafaBalance: 5 },
            party: [{ id: 'hero_engineer_01', hp: 80, scrapCount: 10 }],
        },
    };
    fs.writeFileSync(path.join(TMP_DIR, 'slot_3.json'), JSON.stringify(legacy), 'utf-8');

    const load = engine.loadFromSlot('SLOT_3', makeCampaign().campaign);
    assert(load.success === true, 'D.1: save legado carrega com sucesso');
    assert(load.migrated === true, 'D.2: marcado como migrado');
    assert(load.payload?.progress.supplies === CampaignManager.STARTING_SUPPLIES, `D.3: supplies preenchido com default (obtido ${load.payload?.progress.supplies})`);
    assert(load.payload?.progress.survivalCrisis === false, 'D.4: survivalCrisis default = false');
    assert(Array.isArray(load.payload?.party[0].durableEquipment) && load.payload!.party[0].durableEquipment.length === 0, 'D.5: durableEquipment default = []');
    assert(Array.isArray(load.payload?.party[0].activeStatuses) && load.payload!.party[0].activeStatuses.length === 0, 'D.6: activeStatuses default = []');
    assert(load.payload?.party[0].level === 1, 'D.7: level default = 1');
    assert(load.payload?.party[0].latentLineageAxis === LatentLineageAxis.NEUTRO_ABSOLUTO, 'D.8: linhagem default = NEUTRO_ABSOLUTO');
    assert(load.payload?.progress.estafaBalance === 5, 'D.9: campo existente (estafa=5) preservado na migração');

    // Checksum inválido é rejeitado.
    const tampered = { slotId: 'SLOT_2', metadata: {}, payload: { progress: { currentNodeId: 'x' }, party: [] }, checksum: 'deadbeef' };
    fs.writeFileSync(path.join(TMP_DIR, 'slot_2.json'), JSON.stringify(tampered), 'utf-8');
    const bad = engine.loadFromSlot('SLOT_2', makeCampaign().campaign);
    assert(bad.success === false, 'D.10: checksum inválido é rejeitado');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    try {
        runRoundTripTest();
        runIsolationTest();
        runAutoSaveTest();
        runMigrationTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — SaveSlotEngine`);
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
        console.log(`\n  ✅ TODOS OS TESTES PASSARAM — HOMOLOGAÇÃO APROVADA\n`);
        process.exit(0);
    }
}

main();
