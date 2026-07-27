/**
 * ====================================================================
 * HazardEventIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Anomalias de Duto (eventos de travessia).
 *
 * Arquitetura nativa do projeto: harness `tsx` + `assert`, motor em
 * src/core/HazardEventEngine.ts, modelos reais (CampaignManager /
 * CharacterState / StatusEngine / Estafa / EP).
 *
 * Cobre:
 *   A) Sorteio de anomalia por hazardLevel (RNG injetável).
 *   B) Vazamento de Gás Químico: filtro (recurso) / correr (status) / severo (estafa+dano).
 *   C) Sobrecarga de Vapor: desviar (sucata→EP) / forçar (STEAM_BURN).
 *   D) Surtos Elétricos: descarregar (durabilidade) / contornar (mantimento).
 *   E) Disparo via GameLoop.performTraversal (determinístico) + resolução.
 *
 * Execução: npx tsx src/test/HazardEventIntegration.test.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { HazardEventEngine } from '../core/HazardEventEngine';
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
function hero(id = 'hero_01', o?: Partial<ICharacterStats>): CharacterState {
    return new CharacterState(stats(o), undefined, undefined, undefined, null, id);
}
function armor(current: number, max: number): IDurableEquipment {
    return { id: 'plate', name: 'Placa', type: 'ARMOR', material: 'SCRAP_IRON', durability: { current, max }, baseStats: stats({ defense: 8 }) };
}

const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-hazard-'));
function cleanup(): void { try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ } }

// ====================================================================
function runRollTest(): void {
    printSection('A — Sorteio de anomalia por perigo');
    const engine = new HazardEventEngine();

    assert(engine.rollEvent(0, () => 0) === null, 'A.1: nó seguro (hazard 0) nunca dispara');
    assert(engine.rollEvent(3, () => 0.99) === null, 'A.2: sorteio alto não dispara');
    const ev = engine.rollEvent(3, () => 0);
    assert(ev !== null, 'A.3: sorteio baixo dispara em nó perigoso');
    assert(ev?.type === 'CHEMICAL_GAS_LEAK', 'A.4: índice 0 → Vazamento de Gás Químico');
    assert((ev?.options.length ?? 0) === 3, 'A.5: gás químico oferece 3 opções de mitigação');
}

function runChemicalTest(): void {
    printSection('B — Vazamento de Gás Químico');
    const engine = new HazardEventEngine();

    // Filtro com mantimentos.
    let campaign = new CampaignManager([hero()]);
    const before = campaign.getSupplies();
    let res = engine.resolveEvent(campaign, 'CHEMICAL_GAS_LEAK', 'filter');
    assert(res.success && res.suppliesSpent === 1, 'B.1: filtro consome 1 mantimento');
    assert(campaign.getSupplies() === before - 1, 'B.2: mantimentos debitados');

    // Filtro sem mantimentos → falha.
    campaign = new CampaignManager([hero()]);
    campaign.consumeSupplies(campaign.getSupplies());
    res = engine.resolveEvent(campaign, 'CHEMICAL_GAS_LEAK', 'filter');
    assert(res.success === false, 'B.3: filtro falha sem mantimentos');

    // Correr → veneno no grupo por 2 turnos.
    campaign = new CampaignManager([hero()]);
    res = engine.resolveEvent(campaign, 'CHEMICAL_GAS_LEAK', 'run');
    const poisoned = campaign.getPartyState()[0].activeStatuses.some((s) => s.type === 'CHEMICAL_POISON' && s.duration === 2);
    assert(res.statusApplied === 'CHEMICAL_POISON' && poisoned, 'B.4: correr aplica CHEMICAL_POISON (2 turnos)');

    // Severo → estafa +10 (Paterno) e dano direto ao líder.
    campaign = new CampaignManager([hero()]);
    res = engine.resolveEvent(campaign, 'CHEMICAL_GAS_LEAK', 'severe');
    assert(res.estafaShift === 10 && campaign.getProgress().estafaBalance === 10, 'B.5: decisão severa desloca +10 Paterno');
    assert(res.hpDamage === 15 && campaign.getPartyState()[0].hp === 85, `B.6: líder sofre 15 de dano (obtido ${campaign.getPartyState()[0].hp})`);
}

function runSteamTest(): void {
    printSection('C — Sobrecarga de Conduto de Vapor');
    const engine = new HazardEventEngine();

    // Desviar com sucata → evita e +5 EP.
    const h = hero(); h.scrapCount = 10; h.currentEp = 50;
    let campaign = new CampaignManager([h]);
    let res = engine.resolveEvent(campaign, 'STEAM_CONDUIT_OVERLOAD', 'divert');
    assert(res.success && res.scrapSpent === 1, 'C.1: desviar consome 1 sucata');
    assert(h.scrapCount === 9 && h.currentEp === 55, `C.2: +5 EP ao grupo (obtido ${h.currentEp})`);

    // Desviar sem sucata → falha.
    const h2 = hero(); h2.scrapCount = 0;
    campaign = new CampaignManager([h2]);
    res = engine.resolveEvent(campaign, 'STEAM_CONDUIT_OVERLOAD', 'divert');
    assert(res.success === false, 'C.3: desviar falha sem sucata');

    // Forçar → STEAM_BURN no grupo.
    campaign = new CampaignManager([hero()]);
    res = engine.resolveEvent(campaign, 'STEAM_CONDUIT_OVERLOAD', 'force');
    const burned = campaign.getPartyState()[0].activeStatuses.some((s) => s.type === 'STEAM_BURN');
    assert(res.statusApplied === 'STEAM_BURN' && burned, 'C.4: forçar aplica STEAM_BURN');
}

function runStaticTest(): void {
    printSection('D — Surtos Elétricos Estáticos');
    const engine = new HazardEventEngine();

    // Descarregar → −5% durabilidade.
    const h = hero(); const eq = armor(100, 100); h.equipDurable(eq);
    let campaign = new CampaignManager([h]);
    let res = engine.resolveEvent(campaign, 'STATIC_ELECTRIC_SURGE', 'discharge');
    assert(res.durabilityReducedPct === 5 && eq.durability.current === 95, `D.1: durabilidade 100 → 95 (obtido ${eq.durability.current})`);

    // Contornar → −1 mantimento (passo extra).
    campaign = new CampaignManager([hero()]);
    const before = campaign.getSupplies();
    res = engine.resolveEvent(campaign, 'STATIC_ELECTRIC_SURGE', 'detour');
    assert(res.success && res.suppliesSpent === 1 && campaign.getSupplies() === before - 1, 'D.2: contornar consome 1 mantimento');
}

function runGameLoopTest(): void {
    printSection('E — Disparo via GameLoop + resolução');
    const loop = new CLIGameLoop(new SaveSlotEngine(TMP_DIR));
    const campaign = loop.startNewGame();
    loop.setHazardRng(() => 0); // força o disparo determinístico

    // Travessia a nó perigoso (sector_01_combat, hazard 2) dispara a anomalia.
    const res = loop.performTraversal('sector_01_combat');
    assert(res.hazardEvent?.type === 'CHEMICAL_GAS_LEAK', 'E.1: performTraversal a nó perigoso dispara anomalia');

    // Resolve "correr" → grupo envenenado.
    loop.resolveHazardEvent('CHEMICAL_GAS_LEAK', 'run');
    assert(campaign.getPartyState()[0].activeStatuses.some((s) => s.type === 'CHEMICAL_POISON'), 'E.2: resolução aplica status ao grupo');

    // Nó seguro (hazard 0) não dispara mesmo com RNG mínimo.
    campaign.setCurrentNode('deep_refuge');
    const safe = loop.performTraversal('sealed_bivouac');
    assert(safe.hazardEvent === undefined, 'E.3: nó seguro (hazard 0) não dispara anomalia');
}

// ====================================================================
function main(): void {
    try {
        runRollTest();
        runChemicalTest();
        runSteamTest();
        runStaticTest();
        runGameLoopTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Anomalias de Duto\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
