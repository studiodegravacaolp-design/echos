/**
 * ====================================================================
 * SkillTreeSaveIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Persistência de Habilidades e Árvore de Talentos.
 *
 * Ciclo coberto:
 *   Aprender Habilidade + Desbloquear Nó → Salvar em Slot →
 *   Modificar Estado (novo grupo) → Carregar Slot →
 *   Validar Habilidades e Bônus Passivos Restaurados.
 *
 * Também cobre a auto-migração de saves legados (sem os campos novos).
 *
 * Hermético: SaveSlotEngine com diretório temporário isolado.
 * Execução: npx tsx src/test/SkillTreeSaveIntegration.test.ts
 *
 * Fonte: src/core/SaveSlotEngine.ts, SkillTreeEngine.ts, CombatAbilities.ts
 * ====================================================================
 */

import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { SaveSlotEngine } from '../core/SaveSlotEngine';
import { SkillTreeEngine } from '../core/SkillTreeEngine';
import { ProgressionManager } from '../core/ProgressionManager';
import { CANONICAL_ABILITIES, STARTER_ABILITY_IDS } from '../core/CombatAbilities';
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
const HERO_ID = 'hero_engineer_01';
function stats(): ICharacterStats {
    return { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 };
}
function makeParty(): { campaign: CampaignManager; hero: CharacterState } {
    const hero = new CharacterState(stats(), undefined, undefined, undefined, null, HERO_ID);
    return { campaign: new CampaignManager([hero]), hero };
}

const TMP_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aetheris-skillsave-'));
function cleanup(): void { try { fs.rmSync(TMP_DIR, { recursive: true, force: true }); } catch { /* noop */ } }

// ====================================================================
// A) CICLO COMPLETO: APRENDER → SALVAR → CARREGAR → VALIDAR
// ====================================================================
function runRoundTripTest(): void {
    printSection('A — Persistência de habilidades e nós de talento');

    const engine = new SaveSlotEngine(TMP_DIR);

    // --- Estado de origem ---
    const src = makeParty();
    const srcSkills = new SkillTreeEngine();
    const srcProg = new ProgressionManager();
    srcSkills.initializeTreeForCharacter(src.hero.id);
    srcSkills.grantStarterAbilities(src.hero); // 3 habilidades do kit inicial

    // Aprende uma habilidade AVANÇADA (fora do kit inicial).
    src.hero.learnCombatAbility({ ...CANONICAL_ABILITIES['pneumatic_burst'] });
    assert(src.hero.getCombatAbilities().length === 4, 'A.1: herói conhece 4 habilidades (3 kit + 1 avançada)');

    // Desbloqueia um nó passivo da árvore (+5 defesa).
    const unlock = srcSkills.unlockSkill(src.hero, 'skill_reinforced_plating');
    assert(unlock.success === true, 'A.2: nó passivo desbloqueado');
    assert(src.hero.equipmentBonusStats.bonusDefense === 5, 'A.3: bônus passivo aplicado (+5 defesa)');

    // --- Salva ---
    const saved = engine.saveToSlot('SLOT_1', src.campaign, { progression: srcProg, skillTree: srcSkills });
    assert(saved === true, 'A.4: save bem-sucedido');

    // --- Novo grupo/engines (estado modificado, "sessão nova") ---
    const dst = makeParty();
    const dstSkills = new SkillTreeEngine();
    const dstProg = new ProgressionManager();
    assert(dst.hero.getCombatAbilities().length === 0, 'A.5: herói novo começa sem habilidades');

    const load = engine.loadFromSlot('SLOT_1', dst.campaign, dstProg, dstSkills);
    assert(load.success === true, 'A.6: carregamento bem-sucedido');

    // --- Validação da restauração ---
    assert(dst.hero.getCombatAbilities().length === 4, `A.7: 4 habilidades restauradas (obtido ${dst.hero.getCombatAbilities().length})`);
    assert(dst.hero.hasCombatAbility('pneumatic_burst'), 'A.8: habilidade avançada restaurada');
    assert(STARTER_ABILITY_IDS.every((id) => dst.hero.hasCombatAbility(id)), 'A.9: kit inicial restaurado');
    assert(dstSkills.getUnlockedNodeIds(HERO_ID).includes('skill_reinforced_plating'), 'A.10: nó passivo restaurado na árvore');
    assert(dst.hero.equipmentBonusStats.bonusDefense === 5, `A.11: bônus passivo reaplicado (+5 defesa) (obtido ${dst.hero.equipmentBonusStats.bonusDefense})`);

    // Metadados de payload expõem os campos novos.
    assert(Array.isArray(load.payload?.party[0].learnedAbilityIds), 'A.12: payload inclui learnedAbilityIds');
    assert(load.payload?.party[0].unlockedSkillNodes.includes('skill_reinforced_plating') === true, 'A.13: payload inclui unlockedSkillNodes');
}

// ====================================================================
// B) MIGRAÇÃO DE SAVE LEGADO (SEM OS CAMPOS NOVOS)
// ====================================================================
function runMigrationTest(): void {
    printSection('B — Migração de save legado (sem habilidades/árvore)');

    const engine = new SaveSlotEngine(TMP_DIR);

    // Save legado: personagem sem learnedAbilityIds/unlockedSkillNodes, sem checksum.
    const legacy = {
        slotId: 'SLOT_2',
        metadata: { timestamp: 1, currentAreaName: 'Legado', partyLeaderName: HERO_ID },
        payload: {
            progress: { currentNodeId: 'brenhold_entrance', estafaBalance: 0 },
            party: [{ id: HERO_ID, hp: 100, scrapCount: 10, level: 1 }],
        },
    };
    fs.writeFileSync(path.join(TMP_DIR, 'slot_2.json'), JSON.stringify(legacy), 'utf-8');

    const dst = makeParty();
    const dstSkills = new SkillTreeEngine();
    const load = engine.loadFromSlot('SLOT_2', dst.campaign, new ProgressionManager(), dstSkills);

    assert(load.success === true, 'B.1: save legado carrega');
    assert(load.migrated === true, 'B.2: marcado como migrado');
    // Save legado recebe o starter kit de habilidades.
    assert(STARTER_ABILITY_IDS.every((id) => dst.hero.hasCombatAbility(id)), 'B.3: starter kit concedido na migração');
    assert(dst.hero.getCombatAbilities().length === STARTER_ABILITY_IDS.length, 'B.4: exatamente o starter kit');
    // Árvore vazia por padrão.
    assert(dstSkills.getUnlockedNodeIds(HERO_ID).length === 0, 'B.5: nenhum nó passivo (árvore vazia por migração)');
    assert((load.payload?.party[0].unlockedSkillNodes.length ?? -1) === 0, 'B.6: unlockedSkillNodes migrado para []');
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    try {
        runRoundTripTest();
        runMigrationTest();
    } finally {
        cleanup();
    }

    console.log(`\n${'='.repeat(72)}\n  RELATÓRIO — Persistência de Habilidades & Árvore\n${'='.repeat(72)}`);
    console.log(`  Total: ${totalTests} | PASS: ${passedTests} | FAIL: ${failedTests} | ${totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'}%`);
    console.log('='.repeat(72));
    if (failedTests > 0) { console.log(`\n  ⚠  ${failedTests} teste(s) falharam.\n`); process.exit(1); }
    console.log('\n  ✅ TODOS OS TESTES PASSARAM\n'); process.exit(0);
}
main();
