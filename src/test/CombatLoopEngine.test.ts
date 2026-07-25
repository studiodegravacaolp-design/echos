/**
 * ====================================================================
 * CombatLoopEngine.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Loop de Combate por Turnos.
 *
 * Cobre:
 *   A) Vitória da party contra inimigo fraco (dano mitigado + KO).
 *   B) Derrota contra inimigo esmagador.
 *   C) Dano contínuo (StatusEngine) atua no início do turno do inimigo.
 *   D) Ordem de turno respeita a velocidade efetiva (RUST_LOCK desacelera).
 *   E) Integração com BestiaryEngine (encontro real é resolvido).
 *
 * Execução: npx tsx src/test/CombatLoopEngine.test.ts
 *
 * Fonte: src/core/CombatLoopEngine.ts
 * ====================================================================
 */

import { CombatLoopEngine } from '../core/CombatLoopEngine';
import { CharacterState } from '../core/CharacterState';
import { BestiaryEngine, IEnemyInstance } from '../core/BestiaryEngine';
import { StatusType } from '../core/StatusEngine';
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
function stats(o?: Partial<ICharacterStats>): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 20, defense: 10, resilience: 5, movementSpeed: 10, ...o };
}

function hero(id: string, o?: Partial<ICharacterStats>): CharacterState {
    return new CharacterState(stats(o), undefined, undefined, undefined, null, id);
}

let enemyCounter = 0;
function enemy(
    name: string,
    o?: Partial<ICharacterStats>,
    overrides?: Partial<IEnemyInstance>,
): IEnemyInstance {
    enemyCounter++;
    const s = stats(o);
    return {
        instanceId: `enemy#${enemyCounter}`,
        templateId: 'test_enemy',
        name,
        category: 'MUTANT',
        archetypeAI: 'AGGRESSIVE',
        level: 1,
        stats: s,
        statusCapabilities: [] as StatusType[],
        activeStatuses: [],
        ...overrides,
    };
}

// ====================================================================
// A) VITÓRIA
// ====================================================================
function runVictoryTest(): void {
    printSection('A — Vitória da party contra inimigo fraco');

    const engine = new CombatLoopEngine();
    const party = [hero('hero_01', { damage: 40, defense: 20, maxHp: 200, currentHp: 200, movementSpeed: 15 })];
    const weak = enemy('Rato', { damage: 3, defense: 2, maxHp: 20, currentHp: 20, movementSpeed: 5 });

    const result = engine.runCombat(party, [weak]);
    assert(result.outcome === 'VICTORY', `A.1: desfecho = VICTORY (obtido ${result.outcome})`);
    assert(result.survivingParty.includes('hero_01'), 'A.2: herói sobrevive');
    assert(result.defeatedEnemies.length === 1, 'A.3: inimigo derrotado registrado');
    assert(result.rounds >= 1, 'A.4: pelo menos 1 rodada');
    assert(result.log.length > 0, 'A.5: log de combate preenchido');
}

// ====================================================================
// B) DERROTA
// ====================================================================
function runDefeatTest(): void {
    printSection('B — Derrota contra inimigo esmagador');

    const engine = new CombatLoopEngine();
    const party = [hero('hero_01', { damage: 1, defense: 0, maxHp: 20, currentHp: 20, movementSpeed: 5 })];
    const boss = enemy('Guardião', { damage: 60, defense: 40, maxHp: 500, currentHp: 500, movementSpeed: 15 });

    const result = engine.runCombat(party, [boss]);
    assert(result.outcome === 'DEFEAT', `B.1: desfecho = DEFEAT (obtido ${result.outcome})`);
    assert(result.survivingParty.length === 0, 'B.2: party eliminada');
}

// ====================================================================
// C) DANO CONTÍNUO (STATUS)
// ====================================================================
function runDotTest(): void {
    printSection('C — Dano contínuo atua no combate');

    const engine = new CombatLoopEngine();
    // Herói tanque que quase não causa dano direto, mas o inimigo entra
    // envenenado com veneno forte → o DoT o mata ao longo dos turnos.
    const party = [hero('tank_01', { damage: 1, defense: 50, maxHp: 999, currentHp: 999, movementSpeed: 20 })];
    const poisoned = enemy(
        'Alvo Envenenado',
        { damage: 2, defense: 5, maxHp: 40, currentHp: 40, movementSpeed: 5 },
        {
            activeStatuses: [
                { id: 'p1', type: 'CHEMICAL_POISON', duration: 10, stacks: 3, valuePerTurn: 6, sourceId: 'test' },
            ],
        },
    );

    const result = engine.runCombat(party, [poisoned], { maxRounds: 30 });
    assert(result.outcome === 'VICTORY', `C.1: veneno leva à vitória (obtido ${result.outcome})`);
    const dotLine = result.log.some((l) => l.includes('dano contínuo'));
    assert(dotLine, 'C.2: log registra dano contínuo (DoT)');
}

// ====================================================================
// D) ORDEM DE TURNO POR VELOCIDADE
// ====================================================================
function runTurnOrderTest(): void {
    printSection('D — Ordem de turno respeita velocidade efetiva');

    const engine = new CombatLoopEngine();
    const fastHero = hero('veloz_01', { damage: 40, defense: 20, maxHp: 200, currentHp: 200, movementSpeed: 30 });
    const slowEnemy = enemy('Lento', { damage: 5, defense: 2, maxHp: 20, currentHp: 20, movementSpeed: 1 });

    const result = engine.runCombat([fastHero], [slowEnemy]);
    // Na rodada 1, o herói veloz deve agir (atacar) antes do inimigo lento.
    const round1 = result.log.slice(result.log.findIndex((l) => l.includes('Rodada 1')));
    const heroIdx = round1.findIndex((l) => l.includes('veloz_01 ataca'));
    const enemyIdx = round1.findIndex((l) => l.includes('Lento ataca'));
    assert(heroIdx >= 0, 'D.1: herói veloz age na rodada 1');
    assert(enemyIdx === -1 || heroIdx < enemyIdx, 'D.2: herói veloz age antes do inimigo lento');
}

// ====================================================================
// E) INTEGRAÇÃO COM BESTIARYENGINE
// ====================================================================
function runBestiaryIntegrationTest(): void {
    printSection('E — Resolução de um encontro real do BestiaryEngine');

    const bestiary = new BestiaryEngine();
    const engine = new CombatLoopEngine();

    // Encontro de baixo perigo; party forte para garantir desfecho determinístico.
    const enemies = bestiary.generateEncounter(1, 1);
    const party = [hero('hero_01', { damage: 60, defense: 30, maxHp: 300, currentHp: 300, movementSpeed: 20 })];

    const result = engine.runCombat(party, enemies, { estafaBalance: 0 });
    assert(enemies.length === 1, 'E.1: encontro hazard 1 tem 1 inimigo');
    assert(result.outcome === 'VICTORY', `E.2: party forte vence o encontro (obtido ${result.outcome})`);
    assert(result.defeatedEnemies.length === enemies.length, 'E.3: todos os inimigos derrotados');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runVictoryTest();
    runDefeatTest();
    runDotTest();
    runTurnOrderTest();
    runBestiaryIntegrationTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — CombatLoopEngine`);
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
