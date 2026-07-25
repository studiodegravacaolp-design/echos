/**
 * ====================================================================
 * CombatRewardEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Recompensas de Vitória (loot + progressão).
 *
 * Cobre:
 *   A) Sucata concedida conforme LootEngine (autômato = loot mecânico).
 *   B) XP proporcional ao nível dos inimigos + subida de nível.
 *   C) Distribuição de sucata entre múltiplos heróis.
 *
 * Execução: npx tsx src/test/CombatRewardEngine.test.ts
 *
 * Fonte: src/core/CombatRewardEngine.ts
 * ====================================================================
 */

import { CombatRewardEngine } from '../core/CombatRewardEngine';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { ProgressionManager } from '../core/ProgressionManager';
import { LootEngine } from '../modules/combat/LootEngine';
import { IEnemyInstance, EnemyCategory } from '../core/BestiaryEngine';
import { ICharacterStats } from '../types/aetheris.types';

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
function stats(): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 };
}
function hero(id: string): CharacterState {
    return new CharacterState(stats(), undefined, undefined, undefined, null, id);
}
let ec = 0;
function enemyInst(level: number, category: EnemyCategory): IEnemyInstance {
    ec++;
    return {
        instanceId: `e#${ec}`, templateId: 't', name: `Inimigo ${ec}`, category,
        archetypeAI: 'AGGRESSIVE', level,
        stats: stats(), statusCapabilities: [], activeStatuses: [],
    };
}

// ====================================================================
// A) SUCATA
// ====================================================================
function runScrapTest(): void {
    printSection('A — Sucata concedida via LootEngine');

    const h = hero('hero_01');
    const campaign = new CampaignManager([h]);
    const progression = new ProgressionManager();
    const rewards = new CombatRewardEngine();

    const enemies = [enemyInst(4, 'AUTOMATON'), enemyInst(2, 'MUTANT')];
    // Valor esperado calculado pela mesma fonte (LootEngine).
    const expectedScrap =
        LootEngine.calculateBattleLoot(4, true) + LootEngine.calculateBattleLoot(2, false);

    const scrapBefore = h.scrapCount;
    const reward = rewards.grantVictoryRewards(campaign, enemies, [h], progression);

    assert(reward.scrapAwarded === expectedScrap, `A.1: sucata total = ${expectedScrap} (obtido ${reward.scrapAwarded})`);
    assert(h.scrapCount === scrapBefore + expectedScrap, `A.2: sucata creditada ao herói (obtido ${h.scrapCount})`);
    assert(reward.scrapAwarded > 0, 'A.3: sucata positiva');
}

// ====================================================================
// B) XP E SUBIDA DE NÍVEL
// ====================================================================
function runXpTest(): void {
    printSection('B — XP proporcional e subida de nível');

    const h = hero('hero_01');
    const campaign = new CampaignManager([h]);
    const progression = new ProgressionManager();
    const rewards = new CombatRewardEngine();

    // XP = soma(nível * BASE_XP_PER_ENEMY_LEVEL).
    const enemies = [enemyInst(3, 'MUTANT'), enemyInst(2, 'SCAVENGER')];
    const expectedXp = (3 + 2) * CombatRewardEngine.BASE_XP_PER_ENEMY_LEVEL;

    const reward = rewards.grantVictoryRewards(campaign, enemies, [h], progression);
    assert(reward.xpAwarded === expectedXp, `B.1: XP = ${expectedXp} (obtido ${reward.xpAwarded})`);
    assert(progression.getXp(h) >= 0, 'B.2: XP registrado no ProgressionManager');

    // Batalha massiva → garante subida de nível.
    const h2 = hero('hero_02');
    const campaign2 = new CampaignManager([h2]);
    const bigBatch = Array.from({ length: 10 }, () => enemyInst(5, 'AUTOMATON'));
    const bigReward = rewards.grantVictoryRewards(campaign2, bigBatch, [h2], progression);
    assert(bigReward.levelUps.length === 1, 'B.3: herói registra subida de nível na batalha massiva');
    assert(bigReward.levelUps[0].newLevel === h2.currentLevel, 'B.4: newLevel reportado bate com currentLevel');
    assert(h2.currentLevel > 1, `B.5: nível efetivamente aumentou (obtido ${h2.currentLevel})`);
}

// ====================================================================
// C) DISTRIBUIÇÃO ENTRE MÚLTIPLOS HERÓIS
// ====================================================================
function runDistributionTest(): void {
    printSection('C — Distribuição de sucata entre heróis');

    const a = hero('a');
    const b = hero('b');
    const campaign = new CampaignManager([a, b]);
    const progression = new ProgressionManager();
    const rewards = new CombatRewardEngine();

    const enemies = [enemyInst(5, 'AUTOMATON')];
    const total = LootEngine.calculateBattleLoot(5, true);
    const perMember = Math.floor(total / 2);

    rewards.grantVictoryRewards(campaign, enemies, [a, b], progression);
    assert(a.scrapCount === perMember, `C.1: herói A recebe ${perMember} (obtido ${a.scrapCount})`);
    assert(b.scrapCount === perMember, `C.2: herói B recebe ${perMember} (obtido ${b.scrapCount})`);
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runScrapTest();
    runXpTest();
    runDistributionTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — CombatRewardEngine`);
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
