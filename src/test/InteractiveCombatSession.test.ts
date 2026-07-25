/**
 * ====================================================================
 * InteractiveCombatSession.test.ts
 * --------------------------------------------------------------------
 * Suite de homologação — Combate Interativo por Turnos.
 *
 * Cobre:
 *   A) Turno do jogador: ataque padrão reduz o HP do inimigo e vence.
 *   B) Insubordinação Tática: no Paterno extremo a Cura Compassiva é
 *      bloqueada e vira ação autônoma (ataque).
 *   C) Insubordinação Tática: no Materno extremo a Execução Fria é
 *      bloqueada; ações STANDARD nunca são bloqueadas.
 *   D) Cura Compassiva (permitida) restaura HP de aliado ferido.
 *   E) Derrota quando a party tomba.
 *
 * Execução: npx tsx src/test/InteractiveCombatSession.test.ts
 *
 * Fonte: src/core/InteractiveCombatSession.ts
 * ====================================================================
 */

import { InteractiveCombatSession, CombatActionType } from '../core/InteractiveCombatSession';
import { CharacterState } from '../core/CharacterState';
import { IEnemyInstance } from '../core/BestiaryEngine';
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
    return { maxHp: 200, currentHp: 200, damage: 40, defense: 20, resilience: 5, movementSpeed: 20, ...o };
}
function hero(id: string, o?: Partial<ICharacterStats>): CharacterState {
    return new CharacterState(stats(o), undefined, undefined, undefined, null, id);
}
let ec = 0;
function enemy(name: string, o?: Partial<ICharacterStats>): IEnemyInstance {
    ec++;
    const s = stats({ maxHp: 30, currentHp: 30, damage: 3, defense: 2, movementSpeed: 1, ...o });
    return {
        instanceId: `enemy#${ec}`, templateId: 't', name, category: 'MUTANT',
        archetypeAI: 'AGGRESSIVE', level: 1, stats: s, statusCapabilities: [], activeStatuses: [], dropTable: [],
    };
}

function findAction(session: InteractiveCombatSession, action: CombatActionType) {
    return session.getCurrentTurn()!.actions.find((a) => a.action === action)!;
}

// ====================================================================
// A) ATAQUE PADRÃO → VITÓRIA
// ====================================================================
function runAttackTest(): void {
    printSection('A — Turno do jogador: ataque padrão e vitória');

    const session = new InteractiveCombatSession([hero('hero_01')], [enemy('Rato', { maxHp: 10, currentHp: 10 })]);
    session.start();

    const turn = session.getCurrentTurn();
    assert(turn !== null, 'A.1: há um turno de herói para decidir');
    assert(turn!.actorId === 'hero_01', 'A.2: o herói veloz age primeiro');
    assert(turn!.enemies[0].hp === 10, 'A.3: inimigo começa com HP cheio');

    const res = session.submitPlayerAction('ATTACK');
    assert(res.executedAction === 'ATTACK', 'A.4: ataque executado');
    assert(res.over === true && res.outcome === 'VICTORY', `A.5: inimigo fraco é derrotado (VICTORY) (obtido ${res.outcome})`);
    assert(session.getCurrentTurn() === null, 'A.6: sem turno após o fim do combate');
}

// ====================================================================
// B) INSUBORDINAÇÃO — PATERNO BLOQUEIA CURA COMPASSIVA
// ====================================================================
function runPaternoBlockTest(): void {
    printSection('B — Insubordinação: Paterno extremo bloqueia Cura Compassiva');

    const session = new InteractiveCombatSession(
        [hero('hero_01')],
        [enemy('Autômato', { maxHp: 400, currentHp: 400, defense: 30 })],
        { estafaBalance: 100 }, // Paterno extremo
    );
    session.start();

    const heal = findAction(session, 'MERCY_HEAL');
    assert(heal.locked === true, 'B.1: Cura Compassiva aparece BLOQUEADA no Paterno');
    assert(!!heal.lockReason, 'B.2: motivo diegético do bloqueio presente');
    assert(findAction(session, 'ATTACK').locked === false, 'B.3: Atacar (STANDARD) nunca bloqueado');
    assert(findAction(session, 'EXECUTE').locked === false, 'B.4: Execução Fria liberada no Paterno');

    // Forçar a cura → insubordinação → ação autônoma (ataque).
    const res = session.submitPlayerAction('MERCY_HEAL');
    assert(res.insubordination === true, 'B.5: comando de cura gera insubordinação');
    assert(res.executedAction === 'ATTACK', 'B.6: ação autônoma resolve como ataque');
    assert(res.log.some((l) => l.includes('ataca')), 'B.7: log mostra o ataque autônomo');
}

// ====================================================================
// C) INSUBORDINAÇÃO — MATERNO BLOQUEIA EXECUÇÃO FRIA
// ====================================================================
function runMaternoBlockTest(): void {
    printSection('C — Insubordinação: Materno extremo bloqueia Execução Fria');

    const session = new InteractiveCombatSession(
        [hero('hero_01')],
        [enemy('Autômato', { maxHp: 400, currentHp: 400, defense: 30 })],
        { estafaBalance: -100 }, // Materno extremo
    );
    session.start();

    assert(findAction(session, 'EXECUTE').locked === true, 'C.1: Execução Fria BLOQUEADA no Materno');
    assert(findAction(session, 'MERCY_HEAL').locked === false, 'C.2: Cura Compassiva liberada no Materno');
    assert(findAction(session, 'ATTACK').locked === false, 'C.3: Atacar sempre liberado');

    const res = session.submitPlayerAction('EXECUTE');
    assert(res.insubordination === true, 'C.4: execução fria gera insubordinação no Materno');
    assert(res.executedAction === 'ATTACK', 'C.5: vira ataque padrão (não-letal autônomo)');
}

// ====================================================================
// D) CURA COMPASSIVA PERMITIDA RESTAURA HP
// ====================================================================
function runHealTest(): void {
    printSection('D — Cura Compassiva permitida restaura HP');

    // Dois heróis; um ferido. Estafa neutra (nada bloqueado).
    const wounded = hero('ferido_01', { maxHp: 200, currentHp: 50, movementSpeed: 5 });
    const medic = hero('medico_01', { maxHp: 200, currentHp: 200, damage: 30, movementSpeed: 25 });
    const session = new InteractiveCombatSession(
        [medic, wounded],
        [enemy('Alvo', { maxHp: 500, currentHp: 500, damage: 1, defense: 10, movementSpeed: 1 })],
        { estafaBalance: 0, maxRounds: 3 },
    );
    session.start();

    // O médico (mais veloz) age primeiro → cura o aliado ferido.
    assert(session.getCurrentTurn()!.actorId === 'medico_01', 'D.1: médico veloz age primeiro');
    const res = session.submitPlayerAction('MERCY_HEAL');
    assert(res.insubordination === false, 'D.2: cura permitida na Estafa neutra');
    assert(wounded.hp > 50, `D.3: HP do aliado ferido subiu (50 → ${wounded.hp})`);
}

// ====================================================================
// E) DERROTA
// ====================================================================
function runDefeatTest(): void {
    printSection('E — Derrota quando a party tomba');

    const frail = hero('fraco_01', { maxHp: 10, currentHp: 10, damage: 1, defense: 0, movementSpeed: 1 });
    const boss = enemy('Titã', { maxHp: 999, currentHp: 999, damage: 200, defense: 50, movementSpeed: 30 });
    const session = new InteractiveCombatSession([frail], [boss], { maxRounds: 10 });
    session.start();

    // Se o chefe (mais veloz) já matou o herói antes da 1ª decisão, não há turno.
    let guard = 0;
    while (session.getCurrentTurn() !== null && guard < 20) {
        session.submitPlayerAction('ATTACK');
        guard++;
    }
    assert(session.isOver() === true, 'E.1: combate termina');
    assert(session.getOutcome() === 'DEFEAT', `E.2: desfecho = DEFEAT (obtido ${session.getOutcome()})`);
}

// ====================================================================
// F) FEEDBACK LOOP — AÇÕES DESLOCAM A ESTAFA E RE-BLOQUEIAM
// ====================================================================
function runEstafaFeedbackTest(): void {
    printSection('F — Ações de combate deslocam a Estafa (feedback loop)');

    // Começa em +50 (Paterno, ainda não extremo). Uma Execução Fria (+10)
    // leva a +60 → a Cura Compassiva passa a ser bloqueada no turno seguinte.
    const striker = hero('striker_01', { damage: 40, movementSpeed: 30 });
    const session = new InteractiveCombatSession(
        [striker],
        [enemy('Saco de Pancada', { maxHp: 9999, currentHp: 9999, damage: 0, defense: 5, movementSpeed: 1 })],
        { estafaBalance: 50, maxRounds: 20 },
    );
    session.start();

    // Antes: no +50, cura ainda liberada.
    assert(findAction(session, 'MERCY_HEAL').locked === false, 'F.1: em +50 a Cura ainda está liberada');

    const res = session.submitPlayerAction('EXECUTE');
    assert(res.insubordination === false, 'F.2: Execução Fria permitida em +50');
    assert(res.estafaShift === 10, `F.3: Execução Fria desloca +10 (obtido ${res.estafaShift})`);
    assert(striker.shortTermEstafa === 60, `F.4: Estafa do herói vai a +60 (obtido ${striker.shortTermEstafa})`);

    // Depois: agora em +60 (Paterno extremo) → Cura Compassiva bloqueada.
    assert(findAction(session, 'MERCY_HEAL').locked === true, 'F.5: em +60 a Cura passa a ser BLOQUEADA');
    assert(session.getNetEstafaShift() === 10, 'F.6: deslocamento líquido acumulado = +10');

    // Ação bloqueada (autônoma) NÃO desloca a Estafa.
    const blocked = session.submitPlayerAction('MERCY_HEAL');
    assert(blocked.insubordination === true, 'F.7: cura bloqueada no Paterno vira ação autônoma');
    assert(blocked.estafaShift === 0, 'F.8: ação autônoma não desloca a Estafa');
    assert(session.getNetEstafaShift() === 10, 'F.9: líquido permanece +10 após ação bloqueada');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runAttackTest();
    runPaternoBlockTest();
    runMaternoBlockTest();
    runHealTest();
    runDefeatTest();
    runEstafaFeedbackTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE HOMOLOGAÇÃO — InteractiveCombatSession`);
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
