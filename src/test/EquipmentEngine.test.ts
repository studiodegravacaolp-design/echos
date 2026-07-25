/**
 * ====================================================================
 * EquipmentEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Durabilidade, Oxidação (Rust) e Reparo.
 *
 * Cobre:
 *   A) Bônus corretos de equipamentos limpos (calculateEquipmentModifiers).
 *   B) Penalidade de 50% quando um item fica Rusted (durabilidade <= 25%),
 *      inclusive refletida em CharacterState.getEffectivePhysicalDefense.
 *   C) Degradação (clamp em 0) e reparo via consumo de sucata.
 *   D) isRusted no limiar exato de 25%.
 *
 * Execução: npx tsx src/test/EquipmentEngine.test.ts
 *
 * Fonte: src/core/EquipmentEngine.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import {
    EquipmentEngine,
    IDurableEquipment,
    REPAIR_DURABILITY_PER_SCRAP,
} from '../core/EquipmentEngine';
import { CharacterState } from '../core/CharacterState';
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

function assertApprox(actual: number, expected: number, tol: number, description: string): void {
    assert(Math.abs(actual - expected) <= tol, `${description} (esperado=${expected}, atual=${actual})`);
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
    return {
        maxHp: 0,
        currentHp: 0,
        damage: 0,
        defense: 0,
        resilience: 0,
        movementSpeed: 0,
        ...overrides,
    };
}

function makeItem(
    id: string,
    type: IDurableEquipment['type'],
    baseStats: ICharacterStats,
    current: number,
    max: number,
    material: IDurableEquipment['material'] = 'SCRAP_IRON',
): IDurableEquipment {
    return { id, name: id, type, material, durability: { current, max }, baseStats };
}

// ====================================================================
// A) BÔNUS DE EQUIPAMENTOS LIMPOS
// ====================================================================
function runCleanBonusTest(): void {
    printSection('A — Bônus de equipamentos limpos');

    const armor = makeItem('armor_plate', 'ARMOR', stats({ defense: 8, maxHp: 20 }), 100, 100);
    const weapon = makeItem('scrap_blade', 'WEAPON', stats({ damage: 15 }), 80, 100, 'REFINED_BRASS');

    assert(EquipmentEngine.isRusted(armor) === false, 'A.1: armadura cheia não está Rusted');
    assert(EquipmentEngine.isRusted(weapon) === false, 'A.2: arma a 80% não está Rusted');

    const mods = EquipmentEngine.calculateEquipmentModifiers([armor, weapon]);
    assertApprox(mods.defense, 8, 0.001, 'A.3: defesa somada integral = 8');
    assertApprox(mods.maxHp, 20, 0.001, 'A.4: maxHp somado integral = 20');
    assertApprox(mods.damage, 15, 0.001, 'A.5: dano somado integral = 15');
}

// ====================================================================
// B) PENALIDADE RUST (50%)
// ====================================================================
function runRustPenaltyTest(): void {
    printSection('B — Penalidade de 50% em item Rusted (durabilidade <= 25%)');

    // Armadura idêntica, mas a 20% de durabilidade → Rusted.
    const rustedArmor = makeItem('armor_plate', 'ARMOR', stats({ defense: 8, maxHp: 20 }), 20, 100, 'HEAVY_LEAD');
    assert(EquipmentEngine.isRusted(rustedArmor) === true, 'B.1: armadura a 20% está Rusted');

    const mods = EquipmentEngine.calculateEquipmentModifiers([rustedArmor]);
    assertApprox(mods.defense, 4, 0.001, 'B.2: defesa reduzida a 50% (8 → 4)');
    assertApprox(mods.maxHp, 10, 0.001, 'B.3: maxHp reduzido a 50% (20 → 10)');

    // Integração com CharacterState.getEffectivePhysicalDefense (estafa neutra).
    const hero = new CharacterState(
        stats({ maxHp: 100, currentHp: 100, defense: 10 }),
        undefined, undefined, undefined, null, 'hero_rust_01',
    );

    const cleanArmor = makeItem('armor_clean', 'ARMOR', stats({ defense: 8 }), 100, 100);
    hero.equipDurable(cleanArmor);
    assertApprox(hero.getEffectivePhysicalDefense(), 18, 0.001, 'B.4: defesa efetiva com armadura limpa (10+8)');

    // Degrada a mesma armadura até ficar Rusted e revalida.
    EquipmentEngine.degradeEquipment(cleanArmor, 80); // 100 → 20 (Rusted)
    assert(EquipmentEngine.isRusted(cleanArmor) === true, 'B.5: armadura degradada agora Rusted');
    assertApprox(hero.getEffectivePhysicalDefense(), 14, 0.001, 'B.6: defesa efetiva cai (10 + 8*0.5 = 14)');
}

// ====================================================================
// C) DEGRADAÇÃO E REPARO
// ====================================================================
function runDegradeRepairTest(): void {
    printSection('C — Degradação (clamp 0) e Reparo via sucata');

    const item = makeItem('worn_gear', 'ACCESSORY', stats({ resilience: 5 }), 40, 100, 'COPPER_CIRCUIT');

    // Degradação normal.
    EquipmentEngine.degradeEquipment(item, 15);
    assert(item.durability.current === 25, `C.1: 40 - 15 = 25 (obtido ${item.durability.current})`);

    // Clamp em 0 (não fica negativo).
    EquipmentEngine.degradeEquipment(item, 999);
    assert(item.durability.current === 0, `C.2: degradação clampa em 0 (obtido ${item.durability.current})`);

    // No-op seguro para amount inválido.
    EquipmentEngine.degradeEquipment(item, -5);
    assert(item.durability.current === 0, 'C.3: amount inválido é no-op');

    // Reparo limitado pela sucata disponível.
    // current=0, max=100, missing=100. Taxa = REPAIR_DURABILITY_PER_SCRAP por sucata.
    const partial = EquipmentEngine.repairEquipment(item, 4); // 4 * taxa
    const expectedRestored = 4 * REPAIR_DURABILITY_PER_SCRAP;
    assert(partial.scrapSpent === 4, `C.4: gasta 4 sucata (obtido ${partial.scrapSpent})`);
    assert(item.durability.current === expectedRestored, `C.5: restaura ${expectedRestored} (obtido ${item.durability.current})`);

    // Reparo total: sucata sobrando não é gasta além do necessário.
    const missingNow = item.durability.max - item.durability.current;
    const scrapNeeded = Math.ceil(missingNow / REPAIR_DURABILITY_PER_SCRAP);
    const full = EquipmentEngine.repairEquipment(item, 9999);
    assert(item.durability.current === item.durability.max, 'C.6: durabilidade restaurada ao máximo');
    assert(full.scrapSpent === scrapNeeded, `C.7: gasta só o necessário (${scrapNeeded}, obtido ${full.scrapSpent})`);

    // Reparo em item cheio é no-op (não gasta sucata).
    const noop = EquipmentEngine.repairEquipment(item, 50);
    assert(noop.scrapSpent === 0, 'C.8: reparo em item cheio não gasta sucata');
}

// ====================================================================
// D) LIMIAR DE OXIDAÇÃO (25%)
// ====================================================================
function runThresholdTest(): void {
    printSection('D — Limiar de oxidação (25%)');

    const atThreshold = makeItem('t', 'ARMOR', stats({ defense: 4 }), 25, 100);
    const justAbove = makeItem('t', 'ARMOR', stats({ defense: 4 }), 26, 100);

    assert(EquipmentEngine.isRusted(atThreshold) === true, 'D.1: exatamente 25% é Rusted (<=)');
    assert(EquipmentEngine.isRusted(justAbove) === false, 'D.2: 26% não é Rusted');

    // Durabilidade máxima inválida → Rusted por segurança.
    const broken = makeItem('b', 'WEAPON', stats(), 0, 0);
    assert(EquipmentEngine.isRusted(broken) === true, 'D.3: max<=0 tratado como Rusted');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runCleanBonusTest();
    runRustPenaltyTest();
    runDegradeRepairTest();
    runThresholdTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — EquipmentEngine (Durabilidade)`);
    console.log(`${'='.repeat(72)}`);
    console.log(`  Total de testes:    ${totalTests}`);
    console.log(`  Aprovados (PASS):   ${passedTests}`);
    console.log(`  Reprovados (FAIL):  ${failedTests}`);
    console.log(
        `  Taxa de sucesso:    ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`,
    );
    console.log(`${'='.repeat(72)}`);

    if (failedTests > 0) {
        console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar implementação.\n`);
        process.exit(1);
    } else {
        console.log(`\n  ✅ TODOS OS TESTES PASSARAM — HOMOLOGAÇÃO APROVADA\n`);
        process.exit(0);
    }
}

main();
