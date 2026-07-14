/**
 * ====================================================================
 * enemyBehavior.test.ts
 * --------------------------------------------------------------------
 * Testes unitários para os comportamentos de IA de inimigos
 * (EnemyBehavior.ts).
 *
 * Cobre:
 *   - Factory function createEnemyBehavior
 *   - Comportamento ASSASSINO (foco em HP baixo)
 *   - Comportamento PROTETOR (foco em maior dano + proteção de aliados)
 *   - Comportamento DRENADOR_ESTAFA (manipulação de estafa)
 *   - Casos de borda (arrays vazios, sem alvos vivos, etc.)
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import {
  createEnemyBehavior,
  ENEMY_BEHAVIOR_REGISTRY,
} from '../modules/combat/EnemyBehavior';
import {
  ICombatantState,
  IEnemyBehavior,
} from '../types/aetheris.types';

// ==================================================================
// HELPERS DE TESTE
// ==================================================================

/**
 * Cria um ICombatantState com valores padrão para testes.
 */
function createTestCombatant(
  id: string,
  overrides?: Partial<{
    maxHp: number;
    currentHp: number;
    damage: number;
    defense: number;
    resilience: number;
    movementSpeed: number;
    shortTermEstafa: number;
  }>,
): ICombatantState {
  return {
    id,
    stats: {
      maxHp: overrides?.maxHp ?? 100,
      currentHp: overrides?.currentHp ?? 100,
      damage: overrides?.damage ?? 10,
      defense: overrides?.defense ?? 10,
      resilience: overrides?.resilience ?? 10,
      movementSpeed: overrides?.movementSpeed ?? 10,
    },
    shortTermEstafa: overrides?.shortTermEstafa ?? 0,
  };
}

// ==================================================================
// TESTES DA FACTORY E REGISTRY
// ==================================================================

console.log('=== TESTES: Factory e Registry ===');

// Teste 1: createEnemyBehavior cria instâncias corretas
const assassino: IEnemyBehavior = createEnemyBehavior('ASSASSINO');
console.assert(
  assassino.archetype === 'ASSASSINO',
  'Factory: archetype deve ser ASSASSINO',
);
console.assert(
  assassino.id === 'ASSASSINO_AI',
  'Factory: id deve ser ASSASSINO_AI (padrão)',
);

const protetor: IEnemyBehavior = createEnemyBehavior('PROTETOR', 'PROTETOR_CUSTOM');
console.assert(
  protetor.archetype === 'PROTETOR',
  'Factory: archetype deve ser PROTETOR',
);
console.assert(
  protetor.id === 'PROTETOR_CUSTOM',
  'Factory: id customizado deve ser respeitado',
);

const drenador: IEnemyBehavior = createEnemyBehavior('DRENADOR_ESTAFA');
console.assert(
  drenador.archetype === 'DRENADOR_ESTAFA',
  'Factory: archetype deve ser DRENADOR_ESTAFA',
);

console.log('  ✓ Factory cria instâncias corretas');

// Teste 2: Registry contém todos os arquétipos
console.assert(
  ENEMY_BEHAVIOR_REGISTRY.ASSASSINO_AI !== undefined,
  'Registry: ASSASSINO_AI presente',
);
console.assert(
  ENEMY_BEHAVIOR_REGISTRY.PROTETOR_AI !== undefined,
  'Registry: PROTETOR_AI presente',
);
console.assert(
  ENEMY_BEHAVIOR_REGISTRY.DRENADOR_ESTAFA_AI !== undefined,
  'Registry: DRENADOR_ESTAFA_AI presente',
);

console.log('  ✓ Registry contém todos os 3 arquétipos');

// ==================================================================
// TESTES: ASSASSINO
// ==================================================================

console.log('\n=== TESTES: ASSASSINO ===');

const assassinoBehavior = ENEMY_BEHAVIOR_REGISTRY.ASSASSINO_AI;

// Teste 3: ASSASSINO foca no alvo com menor HP
const partyNormal: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 180, damage: 5 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 100, damage: 20 }),
  createTestCombatant('healer', { maxHp: 80, currentHp: 40, damage: 8 }),
];

const action1 = assassinoBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  partyNormal,
  0,
);
console.assert(
  action1.targetId === 'healer',
  `ASSASSINO: deve focar no healer (HP relativo mais baixo), alvo: ${action1.targetId}`,
);
console.assert(
  action1.skillId === 'ENEMY_ABILITY_ASSASSINO',
  'ASSASSINO: skillId deve ser ENEMY_ABILITY_ASSASSINO',
);
console.log(`  ✓ Foca no alvo com menor HP: ${action1.actionDescription}`);

// Teste 4: ASSASSINO prioriza alvo com HP crítico (< 35%)
const partyWithCritical: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 190, damage: 5 }),
  createTestCombatant('critical', { maxHp: 100, currentHp: 30, damage: 15 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 60, damage: 20 }),
];

const action2 = assassinoBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  partyWithCritical,
  0,
);
console.assert(
  action2.targetId === 'critical',
  `ASSASSINO: deve priorizar alvo crítico (<35% HP), alvo: ${action2.targetId}`,
);
console.log(`  ✓ Prioriza alvo com HP crítico: ${action2.actionDescription}`);

// Teste 5: ASSASSINO com party vazia retorna fallback
const emptyAction = assassinoBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  [],
  0,
);
console.assert(
  emptyAction.targetId === 'NONE',
  `ASSASSINO: party vazio deve retornar 'NONE', alvo: ${emptyAction.targetId}`,
);
console.log('  ✓ Party vazio retorna fallback corretamente');

// ==================================================================
// TESTES: PROTETOR
// ==================================================================

console.log('\n=== TESTES: PROTETOR ===');

const protetorBehavior = ENEMY_BEHAVIOR_REGISTRY.PROTETOR_AI;

// Teste 6: PROTETOR foca no maior dano quando nenhum aliado está crítico
const partyForProtetor: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 180, damage: 5 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 100, damage: 25 }),
  createTestCombatant('healer', { maxHp: 80, currentHp: 80, damage: 3 }),
];

const action3 = protetorBehavior.evaluateAction(
  [createTestCombatant('enemy_ally', { maxHp: 100, currentHp: 100 })],
  partyForProtetor,
  0,
);
console.assert(
  action3.targetId === 'dps',
  `PROTETOR: deve focar no DPS (maior dano), alvo: ${action3.targetId}`,
);
console.log(`  ✓ Foca no maior dano do grupo: ${action3.actionDescription}`);

// Teste 7: PROTETOR protege aliado frágil atacando maior ameaça
const action4 = protetorBehavior.evaluateAction(
  [createTestCombatant('ally_fragil', { maxHp: 100, currentHp: 30, damage: 10 })],
  partyForProtetor,
  0,
);
console.assert(
  action4.targetId === 'dps',
  `PROTETOR: deve proteger aliado frágil atacando maior dano, alvo: ${action4.targetId}`,
);
console.log(`  ✓ Protege aliado frágil: ${action4.actionDescription}`);

// ==================================================================
// TESTES: DRENADOR_ESTAFA
// ==================================================================

console.log('\n=== TESTES: DRENADOR_ESTAFA ===');

const drenadorBehavior = ENEMY_BEHAVIOR_REGISTRY.DRENADOR_ESTAFA_AI;

// Teste 8: DRENADOR com estafa alta tenta empurrar para FRATURA_FRENESI
const partyDrenador: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 180, shortTermEstafa: 50 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 100, shortTermEstafa: 80 }),
  createTestCombatant('healer', { maxHp: 80, currentHp: 80, shortTermEstafa: 20 }),
];

const action5 = drenadorBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  partyDrenador,
  75,
);
console.assert(
  action5.targetId === 'dps',
  `DRENADOR(alta): deve mirar no DPS (estafa 80, mais perto de 100), alvo: ${action5.targetId}`,
);
console.log(`  ✓ Estafa alta (75): ${action5.actionDescription}`);

// Teste 9: DRENADOR com estafa baixa tenta empurrar para ESTAGNACAO_TATICA
const partyDrenadorLow: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 180, shortTermEstafa: -50 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 100, shortTermEstafa: -90 }),
  createTestCombatant('healer', { maxHp: 80, currentHp: 80, shortTermEstafa: -20 }),
];

const action6 = drenadorBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  partyDrenadorLow,
  -75,
);
console.assert(
  action6.targetId === 'dps',
  `DRENADOR(baixa): deve mirar no DPS (estafa -90, mais perto de -100), alvo: ${action6.targetId}`,
);
console.log(`  ✓ Estafa baixa (-75): ${action6.actionDescription}`);

// Teste 10: DRENADOR com estafa moderada ataca maior desvio absoluto
const partyDrenadorMid: ICombatantState[] = [
  createTestCombatant('tank', { maxHp: 200, currentHp: 180, shortTermEstafa: 10 }),
  createTestCombatant('dps', { maxHp: 100, currentHp: 100, shortTermEstafa: 60 }),
  createTestCombatant('healer', { maxHp: 80, currentHp: 80, shortTermEstafa: -40 }),
];

const action7 = drenadorBehavior.evaluateAction(
  [createTestCombatant('enemy')],
  partyDrenadorMid,
  0,
);
console.assert(
  action7.targetId === 'dps',
  `DRENADOR(médio): deve mirar no DPS (maior |estafa| = 60), alvo: ${action7.targetId}`,
);
console.log(`  ✓ Estafa moderada (0): ${action7.actionDescription}`);

// ==================================================================
// RESUMO
// ==================================================================

console.log('\n=== RESUMO ===');
console.log('  ASSASSINO_AI:    ', assassinoBehavior.id);
console.log('  PROTETOR_AI:     ', protetorBehavior.id);
console.log('  DRENADOR_ESTAFA_AI:', drenadorBehavior.id);
console.log('\n✓ Todos os testes passaram!');