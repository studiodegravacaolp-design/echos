// src/test/dialogueIntegration.test.ts

import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { DialogueEngine } from '../core/DialogueEngine';

function runDialogueSimulation() {
    console.log("==================================================");
    console.log("📜 INICIANDO SIMULAÇÃO NARRATIVA: SPRINT 13");
    console.log("==================================================\n");

    // 1. INICIALIZAÇÃO DO CENÁRIO ( Engenheiro iniciando a jornada )
    const hero = new CharacterState(
        { currentHp: 100, maxHp: 100, damage: 0, defense: 0, resilience: 0, movementSpeed: 0 },
        undefined,
        undefined,
        undefined,
        null,
        "hero_engineer_01"
    );
    
    // Teste 1: Iniciando com zero de sucata para testar a trava de segurança do suborno
    hero.scrapCount = 0; 
    let campaign = new CampaignManager([hero]);
    const dialogueEngine = new DialogueEngine();

    console.log(`[Estado Inicial] Alinhamento da Balança de Estafa: ${campaign.getProgress().estafaBalance ?? 0} (Equilíbrio)`);
    console.log(`[Inventário] Carteira de Sucata: ${hero.scrapCount}\n`);

    // 2. DISPARANDO O ENCONTRO COM O CATADOR SOMBRIO
    console.log("➔ Disparando evento: 'brenhold_scavenger_encounter'...");
    const introDialogue = dialogueEngine.startDialogue('brenhold_scavenger_encounter');
    if (introDialogue) {
        console.log(`   NPC: [${introDialogue.speaker}] diz: "${introDialogue.text}"`);
        console.log(`   Opções Disponíveis:`);
        introDialogue.choices.forEach((c, idx) => console.log(`     [${idx}] ${c.text}`));
    }
    console.log("");

    // 3. TESTANDO TRAVA DE SEGURANÇA (Escolha de suborno sem dinheiro)
    console.log("➔ Jogador tenta selecionar Opção [1] (Suborno) sem sucata suficiente...");
    let result = dialogueEngine.selectChoice(campaign, 1);
    console.log(`   Resultado do Motor: ${result.message}`);
    console.log(`   Alinhamento da Balança (Deve continuar 0): ${campaign.getProgress().estafaBalance}\n`);

    // 4. TESTANDO CAMINHO MATERNO (Reparo de Engenharia)
    console.log("➔ Jogador decide usar sua perícia técnica e seleciona Opção [0] (Reparar Gerador)...");
    result = dialogueEngine.selectChoice(campaign, 0);
    console.log(`   Resultado do Motor: ${result.message}`);
    console.log(`   Próximo Texto Narrativo: [${dialogueEngine.getActiveDialogue()?.speaker}] -> "${dialogueEngine.getActiveDialogue()?.text}"`);
    console.log(`   ⚖️ NOVO STATUS DA BALANÇA (Esperado: -15 Materno): ${campaign.getProgress().estafaBalance}\n`);

    // Avança o diálogo de agradecimento para encerrar a conversa e mudar o nó do mapa
    console.log("➔ Jogador clica em 'Continuar jornada...' para encerrar o diálogo...");
    dialogueEngine.selectChoice(campaign, 0);
    console.log(`   Diálogo encerrado? ${dialogueEngine.getActiveDialogue() === null ? "Sim (Limpo)" : "Não"}`);
    console.log(`   🧭 Posição Geográfica Atualizada no Mapa: ${campaign.getProgress().currentNodeId}\n`);

    // 5. TESTANDO CAMINHO PATERNO (Suborno Pragmático com Recursos)
    console.log("🔄 Resetando cenário para testar a rota Pragmática (Paterna)...");
    hero.scrapCount = 50; // Agora o engenheiro tem dinheiro
    campaign = new CampaignManager([hero]); // Nova campanha limpa
    dialogueEngine.startDialogue('brenhold_scavenger_encounter');

    console.log(`➔ Jogador agora com ${hero.scrapCount} sucatas escolhe Opção [1] (Suborno)...`);
    result = dialogueEngine.selectChoice(campaign, 1);
    console.log(`   Resultado do Motor: ${result.message}`);
    console.log(`   Nova carteira de Sucata do Engenheiro: ${hero.scrapCount}`);
    console.log(`   ⚖️ NOVO STATUS DA BALANÇA (Esperado: +10 Paterno): ${campaign.getProgress().estafaBalance}\n`);

    console.log("==================================================");
    console.log("🏆 SIMULAÇÃO NARRATIVA CONCLUÍDA COM SUCESSO!");
    console.log("==================================================");
}

runDialogueSimulation();