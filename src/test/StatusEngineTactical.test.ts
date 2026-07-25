/**
 * ====================================================================
 * StatusEngineTactical.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Status e Condições Táticas (src/core/StatusEngine).
 *
 * NOTA: distinto de statusEngine.test.ts, que cobre o motor tecnológico
 * TECH_* em src/modules/combat/StatusEngine.ts.
 *
 * Cobre:
 *   A) Aplicação e empilhamento (stacks) de status, com renovação de duração.
 *   B) Dano contínuo (DoT) e decremento de duração a cada turno.
 *   C) Remoção limpa de status expirados (duration <= 0).
 *   D) Penalidade correta nos atributos sob RUST_LOCK e STEAM_BURN
 *      (via CharacterState.getEffective*).
 *
 * Execução: npx tsx src/test/StatusEngineTactical.test.ts
 *
 * Fonte: src/core/StatusEngine.ts
 *        src/core/CharacterState.ts
 * ====================================================================
 */

import {
    StatusEngine,
    ITacticalStatus,
    StatusType,
    MAX_STATUS_STACKS,
} from '../core/StatusEngine';
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

function printSection(title: string): void {
    console.log(`\n${'='.repeat(72)}`);
    console.log(`  ${title}`);
    console.log(`${'='.repeat(72)}`);
}

// --------------------------------------------------------------------
// FÁBRICAS
// --------------------------------------------------------------------
function stats(overrides?: Partial<ICharacterStats>): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 20, defense: 30, resilience: 5, movementSpeed: 10, ...overrides };
}

function makeHero(id = 'hero_status_01'): CharacterState {
    return new CharacterState(stats(), undefined, undefined, undefined, null, id);
}

function makeStatus(
    id: string,
    type: StatusType,
    duration: number,
    stacks: number,
    valuePerTurn: number,
): ITacticalStatus {
    return { id, type, duration, stacks, valuePerTurn, sourceId: 'enemy_01' };
}

// ====================================================================
// A) APLICAÇÃO E EMPILHAMENTO
// ====================================================================
function runApplyStackTest(): void {
    printSection('A — Aplicação e empilhamento de status');

    const hero = makeHero();

    // Aplica veneno inicial: 1 stack, 3 turnos.
    StatusEngine.applyStatus(hero, makeStatus('poison', 'CHEMICAL_POISON', 3, 1, 5));
    assert(hero.activeStatuses.length === 1, 'A.1: primeira aplicação adiciona 1 status');
    assert(hero.activeStatuses[0].stacks === 1, 'A.2: começa com 1 stack');

    // Reaplica veneno: +2 stacks, duração maior (5).
    StatusEngine.applyStatus(hero, makeStatus('poison2', 'CHEMICAL_POISON', 5, 2, 5));
    assert(hero.activeStatuses.length === 1, 'A.3: mesmo tipo não duplica entrada');
    assert(hero.activeStatuses[0].stacks === 3, `A.4: stacks acumulam (1+2=3) (obtido ${hero.activeStatuses[0].stacks})`);
    assert(hero.activeStatuses[0].duration === 5, `A.5: duração renovada para a maior (5) (obtido ${hero.activeStatuses[0].duration})`);

    // Limite de stacks.
    StatusEngine.applyStatus(hero, makeStatus('poison3', 'CHEMICAL_POISON', 2, 10, 5));
    assert(
        hero.activeStatuses[0].stacks === MAX_STATUS_STACKS,
        `A.6: stacks limitados a MAX_STATUS_STACKS (${MAX_STATUS_STACKS}) (obtido ${hero.activeStatuses[0].stacks})`,
    );

    // Tipo diferente cria nova entrada.
    StatusEngine.applyStatus(hero, makeStatus('rust', 'RUST_LOCK', 2, 1, 0));
    assert(hero.activeStatuses.length === 2, 'A.7: tipo diferente adiciona nova entrada');
}

// ====================================================================
// B) DANO CONTÍNUO E DECREMENTO DE DURAÇÃO
// ====================================================================
function runDotTurnTest(): void {
    printSection('B — Dano contínuo (DoT) e decremento de duração');

    const hero = makeHero();
    // Veneno: 2 stacks, 5/turno, 3 turnos → 10 de dano/turno.
    StatusEngine.applyStatus(hero, makeStatus('poison', 'CHEMICAL_POISON', 3, 2, 5));

    const hp0 = hero.hp;
    const t1 = StatusEngine.processTurnStart(hero);
    assert(t1.totalDamage === 10, `B.1: dano DoT = valuePerTurn*stacks (5*2=10) (obtido ${t1.totalDamage})`);
    assert(hero.hp === hp0 - 10, `B.2: HP reduzido em 10 (obtido ${hero.hp})`);
    assert(hero.activeStatuses[0].duration === 2, `B.3: duração decrementada 3 → 2 (obtido ${hero.activeStatuses[0].duration})`);

    // Segundo turno.
    StatusEngine.processTurnStart(hero);
    assert(hero.hp === hp0 - 20, `B.4: HP acumulado -20 após 2 turnos (obtido ${hero.hp})`);
    assert(hero.activeStatuses[0].duration === 1, `B.5: duração 2 → 1 (obtido ${hero.activeStatuses[0].duration})`);

    // RUST_LOCK não causa DoT.
    const hero2 = makeHero();
    StatusEngine.applyStatus(hero2, makeStatus('rust', 'RUST_LOCK', 2, 3, 99));
    const r = StatusEngine.processTurnStart(hero2);
    assert(r.totalDamage === 0, 'B.6: RUST_LOCK não aplica DoT');
    assert(hero2.hp === 100, 'B.7: HP intacto sob RUST_LOCK');
}

// ====================================================================
// C) REMOÇÃO LIMPA DE EXPIRADOS
// ====================================================================
function runExpiryTest(): void {
    printSection('C — Remoção limpa de status expirados');

    const hero = makeHero();
    // Burn com 1 turno de duração — expira no primeiro processamento.
    StatusEngine.applyStatus(hero, makeStatus('burn', 'STEAM_BURN', 1, 1, 4));
    // Poison com 3 turnos — persiste.
    StatusEngine.applyStatus(hero, makeStatus('poison', 'CHEMICAL_POISON', 3, 1, 2));

    assert(hero.activeStatuses.length === 2, 'C.1: dois status ativos antes do turno');

    const res = StatusEngine.processTurnStart(hero);
    assert(res.expired.includes('burn'), 'C.2: burn expirado retornado em expired[]');
    assert(hero.activeStatuses.length === 1, `C.3: apenas 1 status restante (obtido ${hero.activeStatuses.length})`);
    assert(hero.activeStatuses[0].type === 'CHEMICAL_POISON', 'C.4: o status remanescente é o veneno');
    // O dano do burn (4) e do veneno (2) ainda são aplicados no turno de expiração.
    assert(res.totalDamage === 6, `C.5: DoT combinado no turno = 4 + 2 = 6 (obtido ${res.totalDamage})`);
}

// ====================================================================
// D) PENALIDADE DE ATRIBUTOS (RUST_LOCK / STEAM_BURN)
// ====================================================================
function runAttributePenaltyTest(): void {
    printSection('D — Penalidade de atributos sob RUST_LOCK / STEAM_BURN');

    // Base: defense=30, movementSpeed=10, damage=20 (estafa neutra).
    const hero = makeHero();
    assert(hero.getEffectivePhysicalDefense() === 30, `D.0: defesa base efetiva = 30 (obtido ${hero.getEffectivePhysicalDefense()})`);

    // RUST_LOCK: 2 stacks → defense -3*2=-6, movement -2*2=-4.
    StatusEngine.applyStatus(hero, makeStatus('rust', 'RUST_LOCK', 5, 2, 0));
    assert(hero.getEffectivePhysicalDefense() === 24, `D.1: RUST_LOCK reduz defesa 30 → 24 (obtido ${hero.getEffectivePhysicalDefense()})`);
    assert(hero.getEffectiveMovementSpeed() === 6, `D.2: RUST_LOCK reduz velocidade 10 → 6 (obtido ${hero.getEffectiveMovementSpeed()})`);

    // STEAM_BURN: 1 stack → defense -2 adicional (total -8 → 22).
    StatusEngine.applyStatus(hero, makeStatus('burn', 'STEAM_BURN', 5, 1, 4));
    assert(hero.getEffectivePhysicalDefense() === 22, `D.3: STEAM_BURN soma penalidade de defesa (→ 22) (obtido ${hero.getEffectivePhysicalDefense()})`);

    // SPARK_OVERCHARGE: +3 de dano por stack (bônus ofensivo).
    const striker = makeHero('striker_01');
    StatusEngine.applyStatus(striker, makeStatus('spark', 'SPARK_OVERCHARGE', 3, 2, 0));
    assert(striker.getEffectiveDamage() === 26, `D.4: SPARK_OVERCHARGE aumenta dano 20 → 26 (+3*2) (obtido ${striker.getEffectiveDamage()})`);
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runApplyStackTest();
    runDotTurnTest();
    runExpiryTest();
    runAttributePenaltyTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — StatusEngine (Condições Táticas)`);
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
