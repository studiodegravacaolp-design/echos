/**
 * ====================================================================
 * TraderIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Mercador e Economia de Sucata.
 *
 * Cobre:
 *   A) Compra de mantimentos com sucata (total e parcial).
 *   B) Reparo de equipamento durável oxidado consumindo sucata.
 *   C) Compra de itens do estoque (consumível/equipamento).
 *   D) Falhas por sucata insuficiente.
 *
 * Execução: npx tsx src/test/TraderIntegration.test.ts
 *
 * Fonte: src/core/TraderManager.ts
 * ====================================================================
 */

import { TraderManager, SCRAP_PER_SUPPLY } from '../core/TraderManager';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
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

// --------------------------------------------------------------------
function stats(): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 };
}
function makeCampaign(scrap: number): { campaign: CampaignManager; hero: CharacterState } {
    const hero = new CharacterState(stats(), undefined, undefined, undefined, null, 'hero_01');
    hero.scrapCount = scrap;
    return { campaign: new CampaignManager([hero]), hero };
}
function rustedArmor(): IDurableEquipment {
    return {
        id: 'worn_plate', name: 'Placa Desgastada', type: 'ARMOR', material: 'SCRAP_IRON',
        durability: { current: 20, max: 100 }, baseStats: { ...stats(), defense: 8 },
    };
}

// ====================================================================
function runBuySuppliesTest(): void {
    printSection('A — Compra de mantimentos');

    const { campaign, hero } = makeCampaign(100);
    const trader = new TraderManager();
    const before = campaign.getSupplies();

    const res = trader.buySupplies(campaign, hero.id, 30);
    assert(res.success === true, 'A.1: compra bem-sucedida');
    assert(res.suppliesBought === 30 && res.scrapSpent === 30 * SCRAP_PER_SUPPLY, 'A.2: 30 mantimentos por 30 sucata');
    assert(hero.scrapCount === 70, `A.3: sucata do herói 100 → 70 (obtido ${hero.scrapCount})`);
    assert(campaign.getSupplies() === before + 30, `A.4: mantimentos +30 (obtido ${campaign.getSupplies()})`);

    // Compra parcial limitada pela sucata.
    const poor = makeCampaign(10);
    const partial = new TraderManager().buySupplies(poor.campaign, poor.hero.id, 50);
    assert(partial.suppliesBought === 10 && poor.hero.scrapCount === 0, 'A.5: compra parcial limitada pela sucata');
}

function runRepairTest(): void {
    printSection('B — Reparo de equipamento oxidado');

    const { campaign, hero } = makeCampaign(100);
    const armor = rustedArmor();
    hero.equipDurable(armor);
    const trader = new TraderManager();

    // Faltam 80 de durabilidade; 5 por sucata → 16 sucata para encher.
    const est = trader.estimateRepairCost(armor);
    assert(est === 16, `B.1: custo estimado de reparo = 16 (obtido ${est})`);

    const res = trader.repairEquipment(campaign, hero.id, 'worn_plate');
    assert(res.success === true, 'B.2: reparo bem-sucedido');
    assert(res.durabilityRestored === 80, `B.3: +80 durabilidade (obtido ${res.durabilityRestored})`);
    assert(armor.durability.current === 100, 'B.4: item restaurado ao máximo');
    assert(hero.scrapCount === 84, `B.5: sucata 100 → 84 (16 gastas) (obtido ${hero.scrapCount})`);

    // Reparo limitado pela sucata.
    const poor = makeCampaign(3);
    const armor2 = rustedArmor();
    poor.hero.equipDurable(armor2);
    const partial = new TraderManager().repairEquipment(poor.campaign, poor.hero.id, 'worn_plate');
    assert(partial.scrapSpent === 3 && armor2.durability.current === 20 + 3 * 5, 'B.6: reparo parcial (3 sucata → +15 durabilidade)');
}

function runBuyItemTest(): void {
    printSection('C — Compra de itens do estoque');

    const { campaign, hero } = makeCampaign(100);
    const trader = new TraderManager();

    const ok = trader.buyItem(campaign, hero.id, 'medkit_standard'); // 25 sucata
    assert(ok === true, 'C.1: medkit comprado');
    assert(hero.scrapCount === 75, `C.2: sucata 100 → 75 (obtido ${hero.scrapCount})`);
    assert(campaign.getGlobalInventory().some((i) => i.id === 'medkit_standard'), 'C.3: item no inventário global');

    // Equipamento no estoque.
    const okEq = trader.buyItem(campaign, hero.id, 'eq_scrap_shield'); // 60 sucata
    assert(okEq === true && hero.scrapCount === 15, `C.4: escudo comprado, sucata 75 → 15 (obtido ${hero.scrapCount})`);
}

function runInsufficientTest(): void {
    printSection('D — Falhas por sucata insuficiente');

    const { campaign, hero } = makeCampaign(5);
    const trader = new TraderManager();

    assert(trader.buyItem(campaign, hero.id, 'medkit_standard') === false, 'D.1: compra falha sem sucata (25 > 5)');
    assert(hero.scrapCount === 5, 'D.2: sucata intacta após falha');

    const noScrap = makeCampaign(0);
    const rep = new TraderManager().repairEquipment(noScrap.campaign, noScrap.hero.id, 'worn_plate');
    assert(rep.success === false, 'D.3: reparo falha sem item/sucata');
}

// ====================================================================
function main(): void {
    runBuySuppliesTest();
    runRepairTest();
    runBuyItemTest();
    runInsufficientTest();

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Mercador & Economia de Sucata\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
