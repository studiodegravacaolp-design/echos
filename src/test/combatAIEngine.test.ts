/**
 * ====================================================================
 * combatAIEngine.test.ts
 * --------------------------------------------------------------------
 * Testes de integração para o CombatAIEngine com CharacterState.
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { CombatAIEngine } from '../core/CombatAIEngine';
import { LatentLineageAxis } from '../types/aetheris.types';

function createHero(id: string, maxHp: number, currentHp: number, dmg: number, def: number): CharacterState {
  const cs = new CharacterState(
    { maxHp, currentHp, damage: dmg, defense: def, resilience: 10, movementSpeed: 10 },
    LatentLineageAxis.NEUTRO_ABSOLUTO,
    undefined, undefined, undefined, id,
  );
  cs.currentLevel = 10;
  return cs;
}

const hero = createHero('hero_01', 100, 100, 20, 10);
const tank = createHero('tank_01', 200, 180, 5, 25);
const healer = createHero('healer_01', 80, 40, 8, 8);
const enemy = createHero('enemy_01', 150, 150, 15, 12);

const party = [hero, tank, healer];
const enemies = [enemy];

let pass = 0;
let fail = 0;

function assert(cond: boolean, msg: string) {
  if (cond) { pass++; console.log(`  ✓ ${msg}`); }
  else { fail++; console.error(`  ✗ ${msg}`); }
}

console.log('=== CombatAIEngine Integration Tests ===\n');

// === ASSASSINO ===
console.log('--- ASSASSINO ---');
const assassinoAI = new CombatAIEngine('boss_assassino', 'ASSASSINO');
const action1 = assassinoAI.evaluateAction(enemies, party, 0);
assert(action1.targetId === 'healer_01', `Deve mirar no healer (HP mais baixo), alvo: ${action1.targetId}`);
assert(action1.skillId === 'ENEMY_ABILITY_ASSASSINO', `Skill deve ser ENEMY_ABILITY_ASSASSINO: ${action1.skillId}`);
console.log(`  → ${action1.actionDescription}\n`);

// === PROTETOR ===
console.log('--- PROTETOR ---');
const protetorAI = new CombatAIEngine('boss_protetor', 'PROTETOR');
const action2 = protetorAI.evaluateAction(enemies, party, 0);
assert(action2.targetId === 'hero_01', `Deve mirar no hero (maior dano=20), alvo: ${action2.targetId}`);
assert(action2.skillId === 'ENEMY_ABILITY_PROTETOR', `Skill deve ser ENEMY_ABILITY_PROTETOR: ${action2.skillId}`);
console.log(`  → ${action2.actionDescription}\n`);

// === DRENADOR_ESTAFA ===
console.log('--- DRENADOR_ESTAFA ---');
const drenadorAI = new CombatAIEngine('boss_drenador', 'DRENADOR_ESTAFA');
const action3 = drenadorAI.evaluateAction(enemies, party, 75);
assert(action3.skillId === 'ENEMY_ABILITY_DRENADOR', `Skill deve ser ENEMY_ABILITY_DRENADOR: ${action3.skillId}`);
console.log(`  → ${action3.actionDescription}\n`);

// === CASOS DE BORDA ===
console.log('--- Casos de Borda ---');
try {
  assassinoAI.evaluateAction(enemies, [], 0);
  assert(false, 'Deveria lançar erro com party vazia');
} catch (e: any) {
  assert(e.message.includes('alvos'), `Party vazia: ${e.message}`);
}

// === RESUMO ===
console.log(`\n=== Resumo: ${pass} passed, ${fail} failed ===`);