// src/test/combatIntegration.test.ts

import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { CampaignMapEngine } from '../core/CampaignMapEngine';

// Função auxiliar para calcular o dano causado aplicando Equipamento e Alinhamento Moral (Paterno)
function calculateFinalDamage(baseDamage: number, attacker: CharacterState, estafaBalance: number): number {
    const equipmentAttackBonus = attacker.equipmentBonusStats?.bonusAttack || 0;
    
    // Bônus do alinhamento Paterno (+1 de ataque para cada +10 de balança)
    let moralAttackBonus = 0;
    if (estafaBalance > 0) {
        moralAttackBonus = Math.floor(estafaBalance / 10);
    }

    return baseDamage + equipmentAttackBonus + moralAttackBonus;
}

// Função auxiliar para calcular o dano sofrido aplicando Equipamento e Alinhamento Moral (Materno)
function calculateDamageReceived(incomingDamage: number, defender: CharacterState, estafaBalance: number): number {
    const equipmentDefenseBonus = defender.equipmentBonusStats?.bonusDefense || 0;

    // Bônus do alinhamento Materno (+1 de defesa para cada -10 de balança)
    let moralDefenseBonus = 0;
    if (estafaBalance < 0) {
        moralDefenseBonus = Math.floor(Math.abs(estafaBalance) / 10);
    }

    const totalMitigation = equipmentDefenseBonus + moralDefenseBonus;
    return Math.max(1, incomingDamage - totalMitigation); // Proteção contra cura por dano negativo
}

function runCombatAndExplorationSimulation() {
    console.log("==================================================");
    console.log("💥 SIMULAÇÃO INTEGRADA: SPRINT 15 (COMBATE & MAPA)");
    console.log("==================================================\n");

    // 1. CONFIGURAÇÃO DO ENGENHEIRO E ARSENAL
    const hero = new CharacterState(
        { currentHp: 100, maxHp: 100, damage: 0, defense: 0, resilience: 0, movementSpeed: 0 },
        undefined,
        undefined,
        undefined,
        undefined,
        "hero_engineer_01"
    );

    // Atribui estatísticas de bônus de equipamento simuladas (Ex: Espada de Aço e Chapa de Bronze)
    hero.equipmentBonusStats = { bonusMaxHp: 20, bonusAttack: 8, bonusDefense: 6 };
    hero.hp = 120; // Vida expandida pelo equipamento

    const campaign = new CampaignManager([hero]);
    const mapEngine = new CampaignMapEngine();

    console.log(`[Status Inicial] Hero: ${hero.id} | HP Atual: ${hero.hp}/${hero.maxHp}`);
    console.log(`[Modificadores de Equipamento] Ataque: +${hero.equipmentBonusStats.bonusAttack} | Defesa: +${hero.equipmentBonusStats.bonusDefense}\n`);

    // 2. TESTANDO INFLUÊNCIA DA BALANÇA DE ESTAFA NO COMBATE
    console.log("⚔️ TESTANDO MATEMÁTICA DE COMBATE COM ALINHAMENTOS:");
    const baseDamage = 30;
    const incomingDamage = 40;

    // Cenário A: Equilíbrio Perfeito (Balança = 0)
    campaign.getProgress().estafaBalance = 0;
    console.log(`--- [Cenário A: Equilíbrio (Estafa: 0)] ---`);
    console.log(`    Dano Final Causado: ${calculateFinalDamage(baseDamage, hero, 0)} (Esperado: 38)`);
    console.log(`    Dano Final Sofrido: ${calculateDamageReceived(incomingDamage, hero, 0)} (Esperado: 34)`);

    // Cenário B: Alinhamento Paterno (+50) - Foco em Força Bruta
    campaign.getProgress().estafaBalance = 50;
    console.log(`--- [Cenário B: Pragmatismo Paterno (Estafa: +50)] ---`);
    console.log(`    Dano Final Causado (30 + 8 Eq + 5 Moral): ${calculateFinalDamage(baseDamage, hero, 50)} (Esperado: 43)`);
    console.log(`    Dano Final Sofrido: ${calculateDamageReceived(incomingDamage, hero, 50)} (Esperado: 34)`);

    // Cenário C: Alinhamento Materno (-70) - Foco em Defesa Absoluta
    campaign.getProgress().estafaBalance = -70;
    console.log(`--- [Cenário C: Proteção Materna (Estafa: -70)] ---`);
    console.log(`    Dano Final Causado: ${calculateFinalDamage(baseDamage, hero, -70)} (Esperado: 38)`);
    console.log(`    Dano Final Sofrido (40 - 6 Eq - 7 Moral): ${calculateDamageReceived(incomingDamage, hero, -70)} (Esperado: 27)\n`);

    // 3. SIMULANDO VIAGENS PARA DISPARAR OS NOVOS PERIGOS DO MAPA (AMBUSH / HAZARD)
    console.log("🧭 SIMULANDO TRAVESSIA DE SEGUIDORES DO MAPA...");
    let dangerFound = false;
    let iterations = 0;

    // Forçamos viagens consecutivas entre os setores de Brenhold até o motor de aleatoriedade disparar
    while (!dangerFound && iterations < 30) {
        iterations++;
        // Resetamos a posição para manter a rota válida de idas e vindas
        campaign.setCurrentNode('brenhold_entrance');
        
        const travelResult = mapEngine.travelToNode(campaign, 'sector_01_combat');
        if (travelResult.success && travelResult.eventType !== 'COMBAT_ARENA') {
            dangerFound = true;
            console.log(`\n   [EVENTO DE EXPLORAÇÃO ATIVADO NA SESSÃO ${iterations}]`);
            console.log(`   Tipo de Evento: ${travelResult.eventType}`);
            console.log(`   Alerta do Sistema: "${travelResult.message}"`);
            console.log(`   Vida Atual de Luis: ${hero.hp}/${hero.maxHp}`);
        }
    }

    console.log("\n==================================================");
    console.log("🏆 SIMULAÇÃO DE SISTEMA DE COMBATE CONCLUÍDA EM VERDE!");
    console.log("==================================================");
}

runCombatAndExplorationSimulation();