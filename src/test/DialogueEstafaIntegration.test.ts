/**
 * ====================================================================
 * DialogueEstafaIntegration.test.ts
 * --------------------------------------------------------------------
 * Teste de INTEGRAÇÃO — Balança de Estafa × Sistema de Diálogos.
 *
 * Cobre:
 *   A) Deslocamento correto da Estafa ao escolher respostas Materno/Paterno.
 *   B) Bloqueio de respostas insensíveis (PATERNAL_CALCULATION) quando
 *      a Estafa está no extremo Materno (<= -60).
 *   C) Bloqueio de respostas empáticas (MATERNAL_EMPATHY) quando a Estafa
 *      está no extremo Paterno (>= +60).
 *   D) Disponibilidade total das opções na zona NEUTRAL.
 *   E) Persistência do shift no grupo via CampaignManager.
 *
 * Execução: npx tsx src/test/DialogueEstafaIntegration.test.ts
 *
 * Fonte: src/core/DialogueEngine.ts
 *        src/core/CampaignManager.ts
 *        src/mechanics/EstafaCalculator.ts
 * ====================================================================
 */

import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { DialogueEngine, IDialogueNode } from '../core/DialogueEngine';

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
// NÓ DE DIÁLOGO DE TESTE — respostas de todas as categorias
// --------------------------------------------------------------------
const TEST_NODE_ID = 'test_estafa_dialogue';

function buildTestNode(): IDialogueNode {
    return {
        id: TEST_NODE_ID,
        speaker: 'Testador',
        text: 'Como o líder responde?',
        choices: [], // modelo legado não usado neste teste
        options: [
            {
                id: 'empathy',
                text: 'Resposta empática',
                estafaShift: -10,
                actionCategory: 'MATERNAL_EMPATHY',
                // undefined nextDialogueId → mantém o nó ativo (permite reavaliar)
            },
            {
                id: 'cold',
                text: 'Resposta fria/insensível',
                estafaShift: 15,
                actionCategory: 'PATERNAL_CALCULATION',
            },
            {
                id: 'neutral',
                text: 'Resposta neutra',
                estafaShift: 5,
                actionCategory: 'STANDARD',
            },
        ],
    };
}

function freshEngine(): DialogueEngine {
    const engine = new DialogueEngine();
    engine.registerDialogueNode(buildTestNode());
    engine.startDialogue(TEST_NODE_ID);
    return engine;
}

function findOption(list: { id: string; locked: boolean; lockReason?: string }[], id: string) {
    return list.find((o) => o.id === id)!;
}

// ====================================================================
// A) DESLOCAMENTO DE ESTAFA (Materno / Paterno)
// ====================================================================
function runShiftTest(): void {
    printSection('A — Deslocamento de Estafa (Materno / Paterno)');

    // Materno: resposta empática desloca -10 a partir de 0.
    let engine = freshEngine();
    let res = engine.selectOption('empathy', 0);
    assert(res.locked === false, 'A.1: resposta empática permitida na zona neutra');
    assert(res.newEstafa === -10, `A.2: shift Materno 0 → -10 (obtido ${res.newEstafa})`);

    // Paterno: resposta fria desloca +15 a partir de 0.
    engine = freshEngine();
    res = engine.selectOption('cold', 0);
    assert(res.locked === false, 'A.3: resposta fria permitida na zona neutra');
    assert(res.newEstafa === 15, `A.4: shift Paterno 0 → +15 (obtido ${res.newEstafa})`);

    // Clamp: shift não ultrapassa +100.
    engine = freshEngine();
    res = engine.selectOption('cold', 95);
    assert(res.newEstafa === 100, `A.5: clamp superior 95 +15 → 100 (obtido ${res.newEstafa})`);
}

// ====================================================================
// B) BLOQUEIO DE RESPOSTA INSENSÍVEL NO EXTREMO MATERNO (<= -60)
// ====================================================================
function runMaternoLockTest(): void {
    printSection('B — Bloqueio de resposta insensível (Estafa <= -60)');

    const engine = freshEngine();
    const options = engine.getAvailableOptions(-80);

    const cold = findOption(options, 'cold');
    assert(cold.locked === true, 'B.1: resposta fria travada no extremo Materno');
    assert(!!cold.lockReason, 'B.2: lockReason diegético presente para resposta fria');

    // A empática e a neutra continuam disponíveis.
    assert(findOption(options, 'empathy').locked === false, 'B.3: empática disponível no Materno');
    assert(findOption(options, 'neutral').locked === false, 'B.4: neutra disponível no Materno');

    // selectOption em opção travada não aplica shift nem altera a estafa.
    const res = engine.selectOption('cold', -80);
    assert(res.locked === true, 'B.5: selectOption reporta bloqueio');
    assert(res.newEstafa === -80, `B.6: estafa inalterada ao tentar opção travada (obtido ${res.newEstafa})`);
}

// ====================================================================
// C) BLOQUEIO DE RESPOSTA EMPÁTICA NO EXTREMO PATERNO (>= +60)
// ====================================================================
function runPaternoLockTest(): void {
    printSection('C — Bloqueio de resposta empática (Estafa >= +60)');

    const engine = freshEngine();
    const options = engine.getAvailableOptions(80);

    const empathy = findOption(options, 'empathy');
    assert(empathy.locked === true, 'C.1: resposta empática travada no extremo Paterno');
    assert(!!empathy.lockReason, 'C.2: lockReason diegético presente para resposta empática');

    // A fria e a neutra continuam disponíveis.
    assert(findOption(options, 'cold').locked === false, 'C.3: fria disponível no Paterno');
    assert(findOption(options, 'neutral').locked === false, 'C.4: neutra disponível no Paterno');

    const res = engine.selectOption('empathy', 80);
    assert(res.locked === true, 'C.5: selectOption reporta bloqueio da empática');
    assert(res.newEstafa === 80, `C.6: estafa inalterada ao tentar empática travada (obtido ${res.newEstafa})`);
}

// ====================================================================
// D) ZONA NEUTRAL — DISPONIBILIDADE TOTAL
// ====================================================================
function runNeutralTest(): void {
    printSection('D — Zona NEUTRAL: disponibilidade total');

    const engine = freshEngine();
    const options = engine.getAvailableOptions(0);

    assert(options.length === 3, `D.1: três opções avaliadas (obtido ${options.length})`);
    assert(
        options.every((o) => o.locked === false),
        'D.2: nenhuma opção travada na zona neutra',
    );
    // Limites da zona neutra (±59 ainda liberam tudo).
    assert(
        engine.getAvailableOptions(-59).every((o) => !o.locked),
        'D.3: -59 (limiar) ainda libera todas as opções',
    );
    assert(
        engine.getAvailableOptions(59).every((o) => !o.locked),
        'D.4: +59 (limiar) ainda libera todas as opções',
    );
}

// ====================================================================
// E) PERSISTÊNCIA NO GRUPO VIA CAMPAIGNMANAGER
// ====================================================================
function runCampaignPersistenceTest(): void {
    printSection('E — Persistência do shift no grupo (CampaignManager)');

    const hero = new CharacterState(
        { currentHp: 100, maxHp: 100, damage: 0, defense: 0, resilience: 0, movementSpeed: 0 },
        undefined,
        undefined,
        undefined,
        null,
        'hero_engineer_01',
    );
    const campaign = new CampaignManager([hero]);

    const engine = new DialogueEngine();
    engine.startDialogue('brenhold_scavenger_encounter');

    const startEstafa = campaign.getProgress().estafaBalance;
    assert(startEstafa === 0, `E.1: estafa inicial do grupo = 0 (obtido ${startEstafa})`);

    // Escolhe reparar (Materno, -15) e persiste no grupo.
    const res = engine.selectOption('opt_repair', startEstafa, campaign);
    assert(res.locked === false, 'E.2: opção de reparo permitida');
    assert(res.newEstafa === -15, `E.3: novo valor retornado = -15 (obtido ${res.newEstafa})`);
    assert(
        campaign.getProgress().estafaBalance === -15,
        `E.4: estafa do grupo persistida em -15 (obtido ${campaign.getProgress().estafaBalance})`,
    );
    assert(
        campaign.getProgress().currentNodeId === 'sector_01_combat',
        'E.5: nó do mapa redirecionado pela opção',
    );
}

// ====================================================================
// F) NOVOS ENCONTROS RAMIFICADOS (CONTEÚDO)
// ====================================================================
function runBranchingContentTest(): void {
    printSection('F — Encontros ramificados por Estafa (Autômato Preso / Engenheira Ferida)');

    // Autômato Preso: libertar (Materno) vs desmontar (Paterno) vs ignorar.
    let engine = new DialogueEngine();
    engine.startDialogue('trapped_automaton');

    // No extremo Paterno (+80): "libertar" (empatia) é bloqueado.
    let opts = engine.getAvailableOptions(80);
    assert(findOption(opts, 'auto_free').locked === true, 'F.1: no Paterno, libertar (empatia) é bloqueado');
    assert(findOption(opts, 'auto_salvage').locked === false, 'F.2: desmontar (cálculo) liberado no Paterno');
    assert(findOption(opts, 'auto_ignore').locked === false, 'F.3: ignorar (STANDARD) sempre liberado');

    // No extremo Materno (-80): "desmontar" (frieza) é bloqueado.
    opts = engine.getAvailableOptions(-80);
    assert(findOption(opts, 'auto_salvage').locked === true, 'F.4: no Materno, desmontar (frieza) é bloqueado');
    assert(findOption(opts, 'auto_free').locked === false, 'F.5: libertar liberado no Materno');

    // Selecionar "libertar" na zona neutra desloca a Estafa ao Materno e avança.
    engine.startDialogue('trapped_automaton');
    const freed = engine.selectOption('auto_free', 0);
    assert(freed.locked === false, 'F.6: libertar permitido na zona neutra');
    assert(freed.newEstafa === -12, `F.7: libertar desloca a Estafa a -12 (obtido ${freed.newEstafa})`);
    assert(engine.getActiveDialogue()?.id === 'automaton_freed', 'F.8: diálogo avança para o desfecho de libertação');

    // Engenheira Ferida: interrogar friamente desloca ao Paterno.
    engine = new DialogueEngine();
    engine.startDialogue('wounded_engineer');
    const cold = engine.selectOption('eng_interrogate', 0);
    assert(cold.newEstafa === 10, `F.9: interrogatório frio desloca a +10 (obtido ${cold.newEstafa})`);
}

// ====================================================================
// MAIN
// ====================================================================
function main(): void {
    runShiftTest();
    runMaternoLockTest();
    runPaternoLockTest();
    runNeutralTest();
    runCampaignPersistenceTest();
    runBranchingContentTest();

    console.log(`\n${'='.repeat(72)}`);
    console.log(`  RELATÓRIO DE INTEGRAÇÃO — Diálogo × Estafa`);
    console.log(`${'='.repeat(72)}`);
    console.log(`  Total de testes:    ${totalTests}`);
    console.log(`  Aprovados (PASS):   ${passedTests}`);
    console.log(`  Reprovados (FAIL):  ${failedTests}`);
    console.log(
        `  Taxa de sucesso:    ${
            totalTests > 0 ? ((passedTests / totalTests) * 100).toFixed(1) : 'N/A'
        }%`,
    );
    console.log(`${'='.repeat(72)}`);

    if (failedTests > 0) {
        console.log(`\n  ⚠  ATENÇÃO: ${failedTests} teste(s) falharam. Revisar integração.\n`);
        process.exit(1);
    } else {
        console.log(`\n  ✅ TODOS OS TESTES DE INTEGRAÇÃO PASSARAM\n`);
        process.exit(0);
    }
}

main();
