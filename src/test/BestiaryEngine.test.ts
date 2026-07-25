/**
 * ====================================================================
 * BestiaryEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Bestiário e Gerador de Inimigos.
 *
 * Cobre:
 *   A) Geração de encontros dentro dos limites por hazardLevel.
 *   B) Escalamento de atributos por nível de perigo e do grupo (+ Estafa).
 *   C) Capabilities de status tático nos templates (veneno/vapor/ferrugem)
 *      e semeadura ambiental de RUST_LOCK em autômatos oxidados.
 *
 * Execução: npx tsx src/test/BestiaryEngine.test.ts
 *
 * Fonte: src/core/BestiaryEngine.ts
 * ====================================================================
 */

import { BestiaryEngine, IEnemyInstance } from '../core/BestiaryEngine';

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

// ====================================================================
// A) LIMITES DE ENCONTRO POR HAZARD
// ====================================================================
function runEncounterBoundsTest(): void {
    printSection('A — Geração dentro dos limites por hazardLevel');

    const engine = new BestiaryEngine();

    const e1 = engine.generateEncounter(1, 5);
    const e3 = engine.generateEncounter(3, 5);
    const e5 = engine.generateEncounter(5, 5);

    assert(e1.length === 1, `A.1: hazard 1 gera 1 inimigo (obtido ${e1.length})`);
    assert(e3.length === 3, `A.2: hazard 3 gera 3 inimigos (obtido ${e3.length})`);
    assert(e5.length === 4, `A.3: hazard 5 limita a 4 inimigos (obtido ${e5.length})`);
    assert(e5.length >= e1.length, 'A.4: tamanho do grupo é monotônico com o perigo');

    // Elegibilidade por tier: nenhum inimigo com tier acima do hazard.
    const eligibleOk = engine.generateEncounter(2, 5).every((enemy) => {
        const tmpl = engine.getEnemyTemplate(enemy.templateId);
        return tmpl !== undefined && tmpl.tier <= 2;
    });
    assert(eligibleOk, 'A.5: hazard 2 só spawna templates de tier <= 2');

    // Hazard fora do intervalo é clampado.
    assert(engine.generateEncounter(99, 5).length === 4, 'A.6: hazard > 5 clampa para tamanho máx (4)');
    assert(engine.generateEncounter(0, 5).length === 1, 'A.7: hazard < 1 clampa para 1');
}

// ====================================================================
// B) ESCALAMENTO DE ATRIBUTOS
// ====================================================================
function runScalingTest(): void {
    printSection('B — Escalamento por perigo e nível do grupo');

    const engine = new BestiaryEngine();

    // Mesmo template (Rato Químico, base maxHp 30 / damage 6 / defense 2).
    const weak = engine.instantiateEnemy('rato_quimico', 1, 1);
    const strong = engine.instantiateEnemy('rato_quimico', 3, 5);

    // hazard1/level1 → sem escala.
    assert(weak.level === 1, `B.1: nível efetivo base = 1 (obtido ${weak.level})`);
    assert(weak.stats.maxHp === 30, `B.2: maxHp base = 30 (obtido ${weak.stats.maxHp})`);
    assert(weak.stats.currentHp === weak.stats.maxHp, 'B.3: currentHp inicia cheio');

    // hazard3/level5 → level = 5 + 2 = 7; levelFactor 1.6, hazardFactor 1.3.
    // maxHp = round(30 * 1.6 * 1.3) = 62; damage = round(6 * 2.08) = 12.
    assert(strong.level === 7, `B.4: nível efetivo = partyLevel + hazard-1 = 7 (obtido ${strong.level})`);
    assert(strong.stats.maxHp === 62, `B.5: maxHp escalado = 62 (obtido ${strong.stats.maxHp})`);
    assert(strong.stats.damage === 12, `B.6: dano escalado = 12 (obtido ${strong.stats.damage})`);
    assert(strong.stats.maxHp > weak.stats.maxHp && strong.stats.damage > weak.stats.damage, 'B.7: inimigo mais profundo é mais forte');

    // Estafa extrema do líder endurece o inimigo (dano +10%).
    const neutral = engine.instantiateEnemy('rato_quimico', 3, 5, { estafaBalance: 0 });
    const extreme = engine.instantiateEnemy('rato_quimico', 3, 5, { estafaBalance: 100 });
    assert(extreme.stats.damage > neutral.stats.damage, `B.8: Estafa extrema aumenta o dano (${neutral.stats.damage} → ${extreme.stats.damage})`);
    assert(extreme.stats.maxHp === neutral.stats.maxHp, 'B.9: Estafa não altera o HP (só o dano)');
}

// ====================================================================
// C) CAPABILITIES DE STATUS E SEMEADURA AMBIENTAL
// ====================================================================
function runStatusTest(): void {
    printSection('C — Capabilities de status e RUST_LOCK ambiental');

    const engine = new BestiaryEngine();
    const templates = engine.listTemplates();

    const allCapabilities = new Set(templates.flatMap((t) => t.statusCapabilities));
    assert(allCapabilities.has('CHEMICAL_POISON'), 'C.1: bestiário cobre veneno (CHEMICAL_POISON)');
    assert(allCapabilities.has('STEAM_BURN'), 'C.2: bestiário cobre vapor (STEAM_BURN)');
    assert(allCapabilities.has('RUST_LOCK'), 'C.3: bestiário cobre ferrugem (RUST_LOCK)');

    // Template desconhecido → undefined.
    assert(engine.getEnemyTemplate('inexistente') === undefined, 'C.4: template desconhecido retorna undefined');

    // Autômato oxidado com alta oxidação e RNG "sempre" → aplica RUST_LOCK.
    const auto = engine.instantiateEnemy('automato_oxidado', 2, 3);
    const applied = engine.applyEncounterStatus(auto, { oxidationLevel: 0.9, rng: () => 0 });
    assert(applied === true, 'C.5: autômato oxidado recebe RUST_LOCK inicial');
    assert(auto.activeStatuses.some((s) => s.type === 'RUST_LOCK'), 'C.6: RUST_LOCK presente nos status ativos');

    // RNG "nunca" (>= oxidação) → não aplica.
    const auto2 = engine.instantiateEnemy('automato_oxidado', 2, 3);
    const notApplied = engine.applyEncounterStatus(auto2, { oxidationLevel: 0.9, rng: () => 0.99 });
    assert(notApplied === false && auto2.activeStatuses.length === 0, 'C.7: chance falha → sem RUST_LOCK');

    // Sem oxidação → nunca aplica.
    const auto3 = engine.instantiateEnemy('automato_oxidado', 2, 3);
    assert(engine.applyEncounterStatus(auto3, { oxidationLevel: 0, rng: () => 0 }) === false, 'C.8: oxidação 0 → sem RUST_LOCK');

    // Não-autômato nunca recebe RUST_LOCK ambiental.
    const rat = engine.instantiateEnemy('rato_quimico', 2, 3);
    assert(engine.applyEncounterStatus(rat as IEnemyInstance, { oxidationLevel: 1, rng: () => 0 }) === false, 'C.9: mutante não recebe RUST_LOCK ambiental');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runEncounterBoundsTest();
    runScalingTest();
    runStatusTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — BestiaryEngine`);
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
