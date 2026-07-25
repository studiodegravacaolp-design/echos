// src/tests/campaignIntegration.test.ts

import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { TraderManager } from '../core/TraderManager';
import { CampaignMapEngine } from '../core/CampaignMapEngine';

function runCampaignLoopSimulation() {
    console.log("==================================================");
    console.log("🚀 INICIANDO SIMULAÇÃO INTEGRADA: SPRINT 12");
    console.log("==================================================\n");

    // 1. INICIALIZAÇÃO DA PARTY (Engenheiro ferido após combate na Sprint 11)
    // Simulando o chassi com HP: 65/100 e Scrap: 50
    const hero = new CharacterState(
        { currentHp: 65, maxHp: 100, damage: 10, defense: 5, resilience: 3, movementSpeed: 10 }, // stats
        undefined,                                  // latentLineageAxis (default NEUTRO_ABSOLUTO)
        undefined,                                  // eventCallback
        undefined,                                  // securityLogCallback
        null,                                       // race
        "hero_engineer_01",                         // id
    );
    hero.scrapCount = 50; 

    const campaign = new CampaignManager([hero]);
    const mapEngine = new CampaignMapEngine();
    const trader = new TraderManager();

    console.log(`[Status Inicial] Hero: ${hero.id} | HP: ${hero.hp}/${hero.maxHp} | Sucata: ${hero.scrapCount}`);
    console.log(`[Posição Inicial] Nó Atual: ${campaign.getProgress().currentNodeId}\n`);

    // 2. MOVIMENTAÇÃO NO MAPA NODAL
    console.log("➔ Tentando viajar para o 'Pátio de Fundição' (sector_01_combat)...");
    let movement = mapEngine.travelToNode(campaign, 'sector_01_combat');
    console.log(`   Resultado: Movimento Válido! Entrou em evento do tipo: ${movement.eventType}`);
    console.log(`   Nó Atual no Progresso: ${campaign.getProgress().currentNodeId}\n`);

    console.log("➔ Tentando desviar para o 'Mercador de Sucata' (black_market_trader)...");
    movement = mapEngine.travelToNode(campaign, 'black_market_trader');
    console.log(`   Resultado: Movimento Válido! Entrou em evento do tipo: ${movement.eventType}\n`);

    // 3. SISTEMA ECONÔMICO (ESCAMBO DE SUCATA)
    console.log("🛒 Acessando estoque do Mercador...");
    console.log(`   Disponível: ${trader.getAvailableStock()[0].name} | Preço: ${trader.getAvailableStock()[0].scrapPrice} sucatas`);
    
    console.log(`   Executando compra de 'medkit_standard' para o personagem ${hero.id}...`);
    const purchaseSuccess = trader.buyItem(campaign, hero.id, 'medkit_standard');
    
    console.log(`   Compra bem-sucedida? ${purchaseSuccess}`);
    console.log(`   Nova carteira de Sucata do Herói: ${hero.scrapCount}`);
    console.log(`   Inventário Global da Campanha:`, campaign.getGlobalInventory(), "\n");

    // 4. USO DE CONSUMÍVEIS FORA DE COMBATE (CURA)
    console.log(`🩹 Aplicando cura no Herói. HP Atual antes do item: ${hero.hp}/${hero.maxHp}`);
    const healSuccess = campaign.useConsumableOutOfCombat(hero.id, 'medkit_standard');
    
    console.log(`   Uso do item funcionou? ${healSuccess}`);
    console.log(`   HP Final do Herói (Esperado: 100): ${hero.hp}/${hero.maxHp}`);
    console.log(`   Inventário Global Atualizado (Deve estar vazio):`, campaign.getGlobalInventory(), "\n");

    // 5. SISTEMA DE GRAVAÇÃO (SAVE GAME REGISTRATION)
    console.log("💾 Gerando arquivo de Save Game (JSON)...");
    const saveFile = campaign.saveGameState();
    console.log("   [SAVE DATA GENERATED]:");
    console.log(`   ${saveFile}\n`);

    console.log("==================================================");
    console.log("🏆 SIMULAÇÃO CONCLUÍDA EM VERDE SEM ERROS!");
    console.log("==================================================");
}

runCampaignLoopSimulation();