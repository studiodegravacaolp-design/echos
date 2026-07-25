/**
 * ====================================================================
 * CampaignNavigationIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Navegação de Campanha × Recursos × Durabilidade
 * × Balança de Estafa.
 *
 * Cobre:
 *   A) Consumo de mantimentos e degradação de equipamentos ao atravessar.
 *   B) Alteração da Estafa de grupo conforme o risco do duto.
 *   C) Acionamento de SURVIVAL_CRISIS por falta de recursos (+ penalidade).
 *
 * Execução: npx tsx src/test/CampaignNavigationIntegration.test.ts
 *
 * Fonte: src/core/CampaignMapEngine.ts
 *        src/core/CampaignManager.ts
 *        src/core/EquipmentEngine.ts
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { CampaignMapEngine } from '../core/CampaignMapEngine';
import { IDurableEquipment } from '../core/EquipmentEngine';
import { ICharacterStats } from '../types/aetheris.types';

// --------------------------------------------------------------------
// HARNESS (padrão do projeto — sem framework externo)
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
function stats(overrides?: Partial<ICharacterStats>): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10, ...overrides };
}

function makeArmor(id: string, current: number, max: number): IDurableEquipment {
    return {
        id,
        name: id,
        type: 'ARMOR',
        material: 'SCRAP_IRON',
        durability: { current, max },
        baseStats: stats({ defense: 8 }),
    };
}

function makeHeroWithGear(): { hero: CharacterState; armor: IDurableEquipment } {
    const hero = new CharacterState(stats(), undefined, undefined, undefined, null, 'hero_engineer_01');
    const armor = makeArmor('scrap_plate', 100, 100);
    hero.equipDurable(armor);
    return { hero, armor };
}

// ====================================================================
// A) CONSUMO DE RECURSOS + DEGRADAÇÃO DE EQUIPAMENTO
// ====================================================================
function runResourceDecayTest(): void {
    printSection('A — Consumo de mantimentos e degradação de equipamento');

    const { hero, armor } = makeHeroWithGear();
    const campaign = new CampaignManager([hero]);
    const map = new CampaignMapEngine();

    assert(campaign.getSupplies() === 100, `A.0: mantimentos iniciais = 100 (obtido ${campaign.getSupplies()})`);

    // entrance → sector_01_combat: hazard 2 → custo 5+2*5=15; desgaste 2+2*3=8.
    const res = map.traverseToNode(campaign, 'sector_01_combat');

    assert(res.success === true, 'A.1: travessia bem-sucedida');
    assert(res.suppliesConsumed === 15, `A.2: consumo de 15 mantimentos (obtido ${res.suppliesConsumed})`);
    assert(campaign.getSupplies() === 85, `A.3: mantimentos restantes = 85 (obtido ${campaign.getSupplies()})`);
    assert(res.equipmentDegraded === 1, `A.4: um item degradado (obtido ${res.equipmentDegraded})`);
    assert(armor.durability.current === 92, `A.5: durabilidade 100 → 92 (desgaste 8) (obtido ${armor.durability.current})`);
    assert(campaign.getProgress().currentNodeId === 'sector_01_combat', 'A.6: nó atual atualizado');
    assert(res.survivalCrisis === false, 'A.7: sem crise com mantimentos suficientes');
}

// ====================================================================
// B) ALTERAÇÃO DE ESTAFA POR RISCO DO DUTO
// ====================================================================
function runEstafaRiskTest(): void {
    printSection('B — Alteração da Estafa de grupo pelo risco do duto');

    const { hero } = makeHeroWithGear();
    const campaign = new CampaignManager([hero]);
    const map = new CampaignMapEngine();

    assert(campaign.getProgress().estafaBalance === 0, 'B.0: estafa inicial = 0');

    // sector_01_combat: estafaImpact +8 (Paterno).
    const res1 = map.traverseToNode(campaign, 'sector_01_combat');
    assert(res1.estafaShift === 8, `B.1: shift do nó = +8 (obtido ${res1.estafaShift})`);
    assert(campaign.getProgress().estafaBalance === 8, `B.2: estafa do grupo = +8 (obtido ${campaign.getProgress().estafaBalance})`);

    // sector_02_combat: estafaImpact +12 (duto mais perigoso).
    const res2 = map.traverseToNode(campaign, 'sector_02_combat');
    assert(res2.estafaShift === 12, `B.3: shift do nó profundo = +12 (obtido ${res2.estafaShift})`);
    assert(campaign.getProgress().estafaBalance === 20, `B.4: estafa acumulada = +20 (obtido ${campaign.getProgress().estafaBalance})`);
}

// ====================================================================
// C) SURVIVAL_CRISIS POR FALTA DE RECURSOS
// ====================================================================
function runSurvivalCrisisTest(): void {
    printSection('C — SURVIVAL_CRISIS por escassez de mantimentos');

    const { hero } = makeHeroWithGear();
    const campaign = new CampaignManager([hero]);
    const map = new CampaignMapEngine();

    // Esvazia os mantimentos para 5 (abaixo do custo 15 do próximo nó).
    campaign.consumeSupplies(95);
    assert(campaign.getSupplies() === 5, `C.0: mantimentos reduzidos a 5 (obtido ${campaign.getSupplies()})`);

    // sector_01_combat: custo 15 > 5 disponíveis → crise.
    const res = map.traverseToNode(campaign, 'sector_01_combat');

    assert(res.survivalCrisis === true, 'C.1: SURVIVAL_CRISIS disparada');
    assert(campaign.isSurvivalCrisis() === true, 'C.2: flag de crise persistida na campanha');
    assert(res.suppliesConsumed === 5, `C.3: consome só o disponível (5) (obtido ${res.suppliesConsumed})`);
    assert(campaign.getSupplies() === 0, `C.4: mantimentos zerados (obtido ${campaign.getSupplies()})`);

    // estafa = +8 (nó) + (-15) (penalidade de crise) = -7.
    assert(res.estafaShift === -7, `C.5: shift com penalidade de crise = -7 (obtido ${res.estafaShift})`);
    assert(campaign.getProgress().estafaBalance === -7, `C.6: estafa do grupo = -7 (obtido ${campaign.getProgress().estafaBalance})`);

    // Travessia seguinte para zona sem perigo (registrada) sai da crise.
    map.registerNode({
        id: 'safe_refuge',
        name: 'Refúgio Selado',
        type: 'SAFE_ZONE',
        connectedTo: [],
        hazardLevel: 0,
        estafaImpact: 0,
        traversalSupplyCost: 0,
    });
    // Conecta o nó atual ao refúgio para permitir a travessia.
    map.registerNode({
        id: 'sector_01_combat',
        name: 'Pátio de Fundição',
        type: 'COMBAT_ARENA',
        connectedTo: ['safe_refuge'],
        hazardLevel: 2,
        estafaImpact: 8,
    });
    campaign.addSupplies(10); // reabastece
    const res2 = map.traverseToNode(campaign, 'safe_refuge');
    assert(res2.survivalCrisis === false, 'C.7: travessia a zona segura (custo 0) sai da crise');
    assert(campaign.isSurvivalCrisis() === false, 'C.8: flag de crise limpa');
}

// ====================================================================
// D) VALIDAÇÃO DE TRAVESSIA INVÁLIDA
// ====================================================================
function runInvalidTraversalTest(): void {
    printSection('D — Travessia inválida (nós não conectados)');

    const { hero } = makeHeroWithGear();
    const campaign = new CampaignManager([hero]);
    const map = new CampaignMapEngine();

    // entrance NÃO conecta diretamente a sector_02_combat.
    const res = map.traverseToNode(campaign, 'sector_02_combat');
    assert(res.success === false, 'D.1: travessia não conectada falha');
    assert(campaign.getSupplies() === 100, 'D.2: mantimentos intactos após falha');
    assert(campaign.getProgress().currentNodeId === 'brenhold_entrance', 'D.3: grupo permanece no nó de origem');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runResourceDecayTest();
    runEstafaRiskTest();
    runSurvivalCrisisTest();
    runInvalidTraversalTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE INTEGRAÇÃO — Navegação × Recursos × Estafa`);
    console.log(`${'='.repeat(72)}`);
    console.log(`  Total de testes:    ${totalTests}`);
    console.log(`  Aprovados (PASS):   ${passedTests}`);
    console.log(`  Reprovados (FAIL):  ${failedTests}`);
    console.log(
        `  Taxa de sucesso:    ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`,
    );
    console.log(`${'='.repeat(72)}`);

    if (failedTests > 0) {
        console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar integração.\n`);
        process.exit(1);
    } else {
        console.log(`\n  ✅ TODOS OS TESTES DE INTEGRAÇÃO PASSARAM\n`);
        process.exit(0);
    }
}

main();
