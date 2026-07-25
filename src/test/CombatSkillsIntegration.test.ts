/**
 * ====================================================================
 * CombatSkillsIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Habilidades Ativas no Combate Interativo.
 *
 * Cobre:
 *   A) Concessão de habilidades (SkillTreeEngine) e exibição no turno.
 *   B) Uso de habilidade: gasto de EP, status no alvo e shift de Estafa.
 *   C) Gating por Estafa (agressiva no Materno / suporte no Paterno).
 *   D) EP insuficiente bloqueia a habilidade.
 *   E) Recarga (cooldown) bloqueia a habilidade no turno seguinte.
 *
 * Execução: npx tsx src/test/CombatSkillsIntegration.test.ts
 *
 * Fonte: src/core/InteractiveCombatSession.ts, CombatAbilities.ts,
 *        SkillTreeEngine.ts
 * ====================================================================
 */

import { InteractiveCombatSession } from '../core/InteractiveCombatSession';
import { CharacterState } from '../core/CharacterState';
import { SkillTreeEngine } from '../core/SkillTreeEngine';
import { IEnemyInstance } from '../core/BestiaryEngine';
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
function stats(o?: Partial<ICharacterStats>): ICharacterStats {
    return { maxHp: 500, currentHp: 500, damage: 40, defense: 30, resilience: 5, movementSpeed: 30, ...o };
}
function heroWithSkills(id = 'hero_01'): CharacterState {
    const h = new CharacterState(stats(), undefined, undefined, undefined, null, id);
    new SkillTreeEngine().grantStarterAbilities(h); // integração: concede o kit inicial
    return h;
}
let ec = 0;
function tankEnemy(): IEnemyInstance {
    ec++;
    return {
        instanceId: `enemy#${ec}`, templateId: 't', name: 'Saco de Pancada', category: 'MUTANT',
        archetypeAI: 'AGGRESSIVE', level: 1,
        stats: { maxHp: 9999, currentHp: 9999, damage: 1, defense: 10, resilience: 5, movementSpeed: 1 },
        statusCapabilities: [], activeStatuses: [], dropTable: [],
    };
}
function abilityOpt(session: InteractiveCombatSession, id: string) {
    return session.getCurrentTurn()!.abilities.find((a) => a.id === id)!;
}

// ====================================================================
function runAvailabilityTest(): void {
    printSection('A — Habilidades concedidas e exibidas no turno');
    const session = new InteractiveCombatSession([heroWithSkills()], [tankEnemy()]);
    session.start();
    const turn = session.getCurrentTurn()!;
    assert(turn.ep.current === 100 && turn.ep.max === 100, 'A.1: EP inicial 100/100');
    assert(turn.abilities.length === 3, `A.2: 3 habilidades do kit inicial (obtido ${turn.abilities.length})`);
    assert(!!abilityOpt(session, 'forja_strike') && !!abilityOpt(session, 'survival_weld'), 'A.3: Golpe de Forja e Solda de Sobrevivência presentes');
}

function runUsageTest(): void {
    printSection('B — Uso de habilidade: EP, status e Estafa');
    const session = new InteractiveCombatSession([heroWithSkills()], [tankEnemy()]);
    session.start();

    const res = session.submitAbility('forja_strike'); // AGGRESSIVE, epCost 30, STEAM_BURN, +8
    assert(res.log.some((l) => l.includes('Golpe de Forja')), 'B.1: log registra o uso da habilidade');
    assert(res.log.some((l) => l.includes('−30 EP')), 'B.2: custo de 30 EP debitado');
    assert(res.log.some((l) => l.includes('STEAM_BURN')), 'B.3: STEAM_BURN aplicado no alvo');
    assert(res.estafaShift === 8, `B.4: Estafa desloca +8 ao usar (obtido ${res.estafaShift})`);
    // 100 − 30 (custo) + 25 (regen do turno seguinte) = 95.
    assert(session.getEp('hero_01')!.current === 95, `B.5: EP líquido = 95 (obtido ${session.getEp('hero_01')!.current})`);
}

function runGatingTest(): void {
    printSection('C — Gating por Estafa');

    // Materno extremo: habilidade AGRESSIVA travada.
    const materno = new InteractiveCombatSession([heroWithSkills()], [tankEnemy()], { estafaBalance: -100 });
    materno.start();
    assert(abilityOpt(materno, 'forja_strike').locked === true, 'C.1: agressiva travada no Materno');
    assert(!!abilityOpt(materno, 'forja_strike').lockReason, 'C.2: motivo do bloqueio presente');
    assert(abilityOpt(materno, 'survival_weld').locked === false, 'C.3: suporte liberada no Materno');
    const blocked = materno.submitAbility('forja_strike');
    assert(blocked.log.some((l) => l.includes('⛔')), 'C.4: submitAbility recusa a agressiva no Materno');

    // Paterno extremo: habilidade de SUPORTE travada.
    const paterno = new InteractiveCombatSession([heroWithSkills()], [tankEnemy()], { estafaBalance: 100 });
    paterno.start();
    assert(abilityOpt(paterno, 'survival_weld').locked === true, 'C.5: suporte travada no Paterno');
    assert(abilityOpt(paterno, 'forja_strike').locked === false, 'C.6: agressiva liberada no Paterno');
}

function runEpInsufficientTest(): void {
    printSection('D — EP insuficiente bloqueia a habilidade');
    const hero = heroWithSkills();
    hero.learnCombatAbility({
        id: 'ultimate_overload', name: 'Sobrecarga Total', category: 'NEUTRAL',
        epCost: 200, cooldown: 0, damageMultiplier: 3, healMultiplier: 0, estafaShift: 0,
    });
    const session = new InteractiveCombatSession([hero], [tankEnemy()]);
    session.start();
    const opt = abilityOpt(session, 'ultimate_overload');
    assert(opt.locked === true && (opt.lockReason ?? '').includes('EP'), 'D.1: habilidade de 200 EP travada por EP insuficiente');
    const res = session.submitAbility('ultimate_overload');
    assert(res.log.some((l) => l.includes('⛔') && l.includes('EP')), 'D.2: submitAbility recusa por EP insuficiente');
}

function runCooldownTest(): void {
    printSection('E — Recarga (cooldown)');
    const session = new InteractiveCombatSession([heroWithSkills()], [tankEnemy()]);
    session.start();

    // rust_discharge tem cooldown 2.
    assert(abilityOpt(session, 'rust_discharge').cooldownRemaining === 0, 'E.1: pronta antes do uso');
    session.submitAbility('rust_discharge');
    const after = abilityOpt(session, 'rust_discharge');
    assert(after.locked === true && after.cooldownRemaining === 1, `E.2: em recarga no turno seguinte (cd ${after.cooldownRemaining})`);
    assert((after.lockReason ?? '').toLowerCase().includes('recarga'), 'E.3: motivo indica recarga');
}

// ====================================================================
function main(): void {
    runAvailabilityTest();
    runUsageTest();
    runGatingTest();
    runEpInsufficientTest();
    runCooldownTest();

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Habilidades no Combate\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
