/**
 * ====================================================================
 * GameLoop.ts
 * --------------------------------------------------------------------
 * CLI (Command-Line Interface) Game Loop para o Projeto Aetheris.
 * 
 * Implementa um loop de jogo interativo via terminal que conecta
 * todos os sistemas core:
 *   - CampaignManager (progresso narrativo)
 *   - CampaignMapEngine (navegação entre nós do mapa)
 *   - CraftingEngine (manufatura de equipamentos — receitas carregadas
 *     de CanonicalContent.ts, sem hardcode local)
 *   - EquipmentEngine (equipar/desequipar itens — catálogo também de
 *     CanonicalContent.ts)
 *   - QuestManager (missões ativas)
 *   - SaveSystem (persistência em disco com checksum SHA-256)
 *   - CharacterState (estado do herói)
 *
 * Fluxo principal:
 *   1. start() → exibe tela de boas-vindas e menu de boot
 *   2. showBootMenu() → Novo Jogo / Carregar Jogo Salvo / Sair
 *      - Novo Jogo → initializeNewGame() → showMainMenu()
 *      - Carregar  → handleLoadGame() (via SaveSystem.loadGame(),
 *        checksum validado) → showMainMenu()
 *   3. showMainMenu() → loop central com 5 opções
 *   4. Cada handler (handleTravel, handleCrafting, etc.) executa
 *      a lógica do sistema correspondente e retorna ao menu
 *   5. Opção 5 (Salvar e Sair) → handleSaveAndExit() → SaveSystem.saveGame()
 *
 * Versão: 1.1.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import * as readline from 'readline';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { CampaignMapEngine } from '../core/CampaignMapEngine';
import { CraftingEngine } from '../core/CraftingEngine';
import { EquipmentEngine } from '../core/EquipmentEngine';
import { QuestManager, QuestStatus } from '../core/QuestManager';
import { SaveSystem } from '../core/SaveSystem';
import { CANONICAL_EQUIPMENT } from '../database/CanonicalContent';
import { LatentLineageAxis, SlotType } from '../types/aetheris.types';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Slots de equipamento disponíveis no jogo */
const EQUIPMENT_SLOTS: SlotType[] = ['WEAPON', 'ARMOR', 'CORE_MOD'];

// ==================================================================
// CATÁLOGO DE EQUIPAMENTOS CONHECIDOS
// ==================================================================
// Mapeia IDs de equipamentos para suas definições completas (IEquipmentItem).
// Usado pelo fluxo de equipar para reconstruir o objeto a partir do
// IInventoryItem armazenado no inventário global.
//
// CONECTADO: consome diretamente CANONICAL_EQUIPMENT do banco de
// dados canônico (src/database/CanonicalContent.ts) — não há mais
// catálogo hardcoded duplicado aqui.
// ==================================================================

const EQUIPMENT_CATALOG = CANONICAL_EQUIPMENT;

// ==================================================================
// CLASSE PRINCIPAL — CLIGameLoop
// ==================================================================

export class CLIGameLoop {
    private rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    private campaign!: CampaignManager;
    private mapEngine = new CampaignMapEngine();
    private craftingEngine = new CraftingEngine();
    private eqEngine = new EquipmentEngine();
    private questManager = new QuestManager();

    /**
     * Cria uma nova instância do CLIGameLoop.
     *
     * NÃO inicializa o jogo aqui — a escolha entre Novo Jogo e
     * Carregar Jogo Salvo acontece no boot, via start() → showBootMenu().
     */
    constructor() {
        // Intencionalmente vazio — ver showBootMenu().
    }

    // ==============================================================
    // INICIALIZAÇÃO
    // ==============================================================

    /**
     * initializeNewGame()
     * ------------------------------------------------------------------
     * Cria o herói padrão (Luis, O Engenheiro) com 50 de sucata inicial
     * e posiciona a campanha no nó 'brenhold_entrance'.
     *
     * Também serve de base para o fluxo de Carregar Jogo Salvo: o save
     * (CampaignManager.loadGameState) restaura dados casando pelo `id`
     * do personagem, então a party-esqueleto precisa existir primeiro
     * com o mesmo id ('hero_engineer_01').
     *
     * @returns Objeto com o ID do herói criado
     */
    private initializeNewGame(): { heroId: string } {
        const hero = new CharacterState(
            {
                maxHp: 100,
                currentHp: 100,
                damage: 10,
                defense: 5,
                resilience: 5,
                movementSpeed: 10,
            },
            LatentLineageAxis.NEUTRO_ABSOLUTO,
            undefined,
            undefined,
            null,
            'hero_engineer_01',
        );
        hero.scrapCount = 50;
        this.campaign = new CampaignManager([hero]);
        this.campaign.setCurrentNode('brenhold_entrance');
        return { heroId: hero.id };
    }

    // ==============================================================
    // LOOP PRINCIPAL
    // ==============================================================

    /**
     * start()
     * ------------------------------------------------------------------
     * Ponto de entrada do jogo. Limpa o console, exibe o banner de
     * boas-vindas e entra no menu de boot (Novo Jogo / Carregar / Sair).
     */
    public start(): void {
        console.clear();
        console.log("==================================================");
        console.log("🛡️ BEM-VINDO AOS DUTOS DE BRENHOLD — AETHERIS BETA");
        console.log("==================================================");
        this.showBootMenu();
    }

    /**
     * showBootMenu()
     * ------------------------------------------------------------------
     * Menu de entrada exibido antes de qualquer estado de campanha
     * existir. Oferece três caminhos:
     *   1. Iniciar Novo Jogo — chama initializeNewGame() e segue para
     *      o menu principal.
     *   2. Carregar Jogo Salvo — valida a existência do save via
     *      SaveSystem.saveExists() e, se houver, restaura o estado
     *      completo via handleLoadGame().
     *   3. Sair — encerra o processo sem tocar em nenhum estado.
     */
    private showBootMenu(): void {
        console.log("\n1. 🆕 Iniciar Novo Jogo");
        console.log("2. 💾 Carregar Jogo Salvo");
        console.log("3. 🚪 Sair");
        console.log("----------------------------------");

        this.rl.question("Escolha uma opção: ", (answer) => {
            switch (answer.trim()) {
                case '1':
                    this.initializeNewGame();
                    console.log("\n✅ Novo jogo iniciado. Bem-vindo, Engenheiro.");
                    this.showMainMenu();
                    break;
                case '2':
                    this.handleLoadGame();
                    break;
                case '3':
                    console.log("\n🛑 Encerrando... Até a próxima, Engenheiro!");
                    this.rl.close();
                    process.exit(0);
                default:
                    console.log("⚠️ Opção inválida!");
                    this.showBootMenu();
            }
        });
    }

    /**
     * handleLoadGame()
     * ------------------------------------------------------------------
     * Restaura uma campanha salva anteriormente:
     *   1. Verifica se existe um save em disco (SaveSystem.saveExists()).
     *   2. Lê e valida o checksum de integridade SHA-256
     *      (SaveSystem.loadGame()).
     *   3. Recria a party-esqueleto (initializeNewGame()) para que os
     *      IDs de personagem existam antes da restauração.
     *   4. Sobrescreve o estado com os dados salvos
     *      (CampaignManager.loadGameState()).
     *
     * Em qualquer falha (sem save, checksum inválido, JSON corrompido),
     * retorna ao boot menu sem alterar nada.
     */
    private handleLoadGame(): void {
        if (!SaveSystem.saveExists()) {
            console.log("\n❌ Nenhum save encontrado em disco.");
            this.showBootMenu();
            return;
        }

        const result = SaveSystem.loadGame();

        if (!result.success || !result.save) {
            console.log(`\n❌ Falha ao carregar o save: ${result.error ?? 'erro desconhecido'}`);
            this.showBootMenu();
            return;
        }

        // Recria a party-esqueleto (mesmo id) para o loadGameState
        // conseguir casar os dados salvos com o personagem.
        this.initializeNewGame();

        const restored = this.campaign.loadGameState(result.save.playerData);

        if (!restored) {
            console.log("\n❌ Falha ao restaurar o estado da campanha (dados corrompidos).");
            this.showBootMenu();
            return;
        }

        console.log("\n✅ Jogo carregado com sucesso! Bem-vindo de volta, Engenheiro.");
        this.showMainMenu();
    }

    /**
     * getHero()
     * ------------------------------------------------------------------
     * Atalho para obter o primeiro (e único) personagem da party.
     *
     * @returns CharacterState do herói principal
     */
    private getHero(): CharacterState {
        return this.campaign.getPartyState()[0];
    }

    /**
     * showMainMenu()
     * ------------------------------------------------------------------
     * Exibe o menu principal com o status atual do herói e 5 opções
     * de navegação. Aguarda a escolha do usuário via readline.
     */
    private showMainMenu(): void {
        const hero = this.getHero();
        const progress = this.campaign.getProgress();
        const currentNode = this.mapEngine.getNodeDetails(progress.currentNodeId);
        const nodeName = currentNode ? currentNode.name : progress.currentNodeId;

        console.log(`\n👤 [Status] ID: ${hero.id} | HP: ${hero.hp}/${hero.maxHp} | Sucata: ${hero.scrapCount}💰`);
        console.log(`📍 Posição Atual: ${nodeName}`);
        console.log("----------------------------------");
        console.log("1. 🧭 Viajar (Exploração do Mapa)");
        console.log("2. 🔨 Forja de Equipamentos (Manufatura)");
        console.log("3. 🎒 Gerenciar Arsenal e Equipamentos");
        console.log("4. 📜 Diário de Missões Ativas");
        console.log("5. 💾 Salvar e Sair do Jogo");
        console.log("----------------------------------");

        this.rl.question("Escolha uma opção: ", (answer) => {
            switch (answer.trim()) {
                case '1': this.handleTravel(); break;
                case '2': this.handleCrafting(); break;
                case '3': this.handleArsenal(); break;
                case '4': this.handleQuests(); break;
                case '5': this.handleSaveAndExit(); break;
                default:
                    console.log("⚠️ Opção inválida!");
                    this.showMainMenu();
            }
        });
    }

    // ==============================================================
    // HANDLER 1 — VIAJAR (MAPA)
    // ==============================================================

    /**
     * handleTravel()
     * ------------------------------------------------------------------
     * Exibe o nó atual e lista os destinos conectados disponíveis
     * para travessia. O usuário escolhe um destino, e o
     * CampaignMapEngine.travelToNode() processa a viagem (incluindo
     * eventos aleatórios como emboscadas ou perigos ambientais).
     */
    private handleTravel(): void {
        const progress = this.campaign.getProgress();
        const currentNode = this.mapEngine.getNodeDetails(progress.currentNodeId);

        if (!currentNode) {
            console.log("\n❌ Erro: Nó atual não encontrado no mapa.");
            this.showMainMenu();
            return;
        }

        console.log(`\n📍 Você está em: ${currentNode.name} (${currentNode.id})`);
        console.log("🧭 Destinos Disponíveis para Travessia:");

        if (currentNode.connectedTo.length === 0) {
            console.log("   (Nenhum destino disponível — caminho bloqueado.)");
            this.showMainMenu();
            return;
        }

        currentNode.connectedTo.forEach((nodeId, index) => {
            const node = this.mapEngine.getNodeDetails(nodeId);
            if (node) {
                const typeIcon = this.getNodeTypeIcon(node.type);
                console.log(`   ${index + 1}. ${typeIcon} ${node.name} [${node.type}]`);
            }
        });
        console.log("   0. 🔙 Voltar ao Menu Principal");

        this.rl.question("\nEscolha um destino: ", (answer) => {
            const choice = parseInt(answer.trim(), 10);
            if (choice === 0) {
                this.showMainMenu();
                return;
            }
            if (isNaN(choice) || choice < 1 || choice > currentNode.connectedTo.length) {
                console.log("⚠️ Opção inválida!");
                this.handleTravel();
                return;
            }

            const targetNodeId = currentNode.connectedTo[choice - 1];
            const result = this.mapEngine.travelToNode(this.campaign, targetNodeId);

            if (!result.success) {
                console.log("\n❌ Não foi possível viajar para este destino.");
                this.showMainMenu();
                return;
            }

            const targetNode = this.mapEngine.getNodeDetails(targetNodeId);
            console.log(`\n✅ Viagem concluída para: ${targetNode?.name ?? targetNodeId}`);
            if (result.message) {
                console.log(result.message);
            }
            this.showMainMenu();
        });
    }

    /**
     * getNodeTypeIcon(type)
     * ------------------------------------------------------------------
     * Retorna um ícone representativo para o tipo de nó do mapa.
     *
     * @param type - Tipo do nó (COMBAT_ARENA, SAFE_ZONE, etc.)
     * @returns String com o ícone correspondente
     */
    private getNodeTypeIcon(type: string): string {
        switch (type) {
            case 'COMBAT_ARENA': return '⚔️';
            case 'SAFE_ZONE': return '🏠';
            case 'SCRAP_TRADER': return '🏪';
            case 'AMBUSH': return '⚠️';
            case 'HAZARD': return '☠️';
            default: return '❓';
        }
    }

    // ==============================================================
    // HANDLER 2 — FORJA (MANUFATURA)
    // ==============================================================

    /**
     * handleCrafting()
     * ------------------------------------------------------------------
     * Lista todas as receitas de manufatura disponíveis no
     * CraftingEngine, exibindo o custo em sucata e materiais
     * necessários. O usuário escolhe uma receita para forjar.
     */
    private handleCrafting(): void {
        const recipes = this.craftingEngine.getAvailableRecipes();
        const hero = this.getHero();

        console.log("\n🔨 Forja de Equipamentos");
        console.log(`💰 Sucata disponível: ${hero.scrapCount}`);
        console.log("----------------------------------");

        if (recipes.length === 0) {
            console.log("(Nenhuma receita disponível no momento.)");
            this.showMainMenu();
            return;
        }

        recipes.forEach((recipe, index) => {
            const materials = recipe.requiredMaterials
                .map(m => `${m.materialId} x${m.quantity}`)
                .join(", ");
            console.log(`   ${index + 1}. ${recipe.resultItem.name}`);
            console.log(`      💰 Custo: ${recipe.requiredScrap} sucata | Materiais: ${materials}`);
        });
        console.log("   0. 🔙 Voltar ao Menu Principal");

        this.rl.question("\nEscolha uma receita para forjar: ", (answer) => {
            const choice = parseInt(answer.trim(), 10);
            if (choice === 0) {
                this.showMainMenu();
                return;
            }
            if (isNaN(choice) || choice < 1 || choice > recipes.length) {
                console.log("⚠️ Opção inválida!");
                this.handleCrafting();
                return;
            }

            const recipe = recipes[choice - 1];
            const success = this.craftingEngine.craftItem(this.campaign, hero.id, recipe.recipeId);

            if (success) {
                console.log(`\n✅ ${recipe.resultItem.name} forjado com sucesso e adicionado ao inventário!`);
            } else {
                console.log("\n❌ Falha ao forjar: recursos insuficientes (sucata ou materiais).");
            }
            this.showMainMenu();
        });
    }

    // ==============================================================
    // HANDLER 3 — ARSENAL (EQUIPAR/DESEQUIPAR)
    // ==============================================================

    /**
     * handleArsenal()
     * ------------------------------------------------------------------
     * Exibe o inventário global da campanha e os equipamentos
     * ativos do herói. Oferece opções para equipar um item do
     * inventário ou remover um equipamento de um slot.
     */
    private handleArsenal(): void {
        const hero = this.getHero();
        const inventory = this.campaign.getGlobalInventory();

        console.log("\n🎒 Arsenal e Equipamentos");
        console.log("----------------------------------");
        console.log("📦 Inventário Global:");

        if (inventory.length === 0) {
            console.log("   (Vazio)");
        } else {
            inventory.forEach((item, index) => {
                const typeIcon = item.type === 'EQUIPMENT' ? '🔧' : item.type === 'CONSUMABLE' ? '🧪' : '📦';
                console.log(`   ${index + 1}. ${typeIcon} ${item.name} (${item.id}) x${item.quantity} [${item.type}]`);
            });
        }

        console.log("\n⚔️ Equipamentos Ativos:");
        EQUIPMENT_SLOTS.forEach(slot => {
            const item = hero.equippedItems[slot];
            if (item) {
                const mods = item.statsModifiers;
                const bonusStr = [
                    mods.bonusMaxHp ? `HP+${mods.bonusMaxHp}` : '',
                    mods.bonusAttack ? `ATK+${mods.bonusAttack}` : '',
                    mods.bonusDefense ? `DEF+${mods.bonusDefense}` : '',
                ].filter(Boolean).join(' ');
                console.log(`   ${slot}: ${item.name} (${bonusStr})`);
            } else {
                console.log(`   ${slot}: (vazio)`);
            }
        });

        console.log("\nOpções:");
        console.log("   1. 🔧 Equipar item do inventário");
        console.log("   2. 🔄 Remover equipamento de um slot");
        console.log("   0. 🔙 Voltar ao Menu Principal");

        this.rl.question("\nEscolha uma opção: ", (answer) => {
            const choice = answer.trim();
            if (choice === '0') {
                this.showMainMenu();
            } else if (choice === '1') {
                this.handleEquipItem();
            } else if (choice === '2') {
                this.handleUnequipItem();
            } else {
                console.log("⚠️ Opção inválida!");
                this.handleArsenal();
            }
        });
    }

    /**
     * handleEquipItem()
     * ------------------------------------------------------------------
     * Lista os equipamentos disponíveis no inventário global e
     * permite que o usuário escolha um para equipar no herói.
     * Consulta o EQUIPMENT_CATALOG para obter a definição completa
     * do item (slot, statsModifiers) antes de chamar o EquipmentEngine.
     */
    private handleEquipItem(): void {
        const hero = this.getHero();
        const inventory = this.campaign.getGlobalInventory();
        const equipmentItems = inventory.filter(
            item => item.type === 'EQUIPMENT' && item.quantity > 0,
        );

        if (equipmentItems.length === 0) {
            console.log("\n❌ Nenhum equipamento disponível no inventário.");
            this.showMainMenu();
            return;
        }

        console.log("\n🔧 Itens disponíveis para equipar:");
        equipmentItems.forEach((item, index) => {
            const catalogEntry = EQUIPMENT_CATALOG[item.id];
            const slotInfo = catalogEntry ? `[${catalogEntry.slot}]` : '[slot desconhecido]';
            console.log(`   ${index + 1}. ${item.name} ${slotInfo} x${item.quantity}`);
        });
        console.log("   0. 🔙 Voltar");

        this.rl.question("\nEscolha um item para equipar: ", (answer) => {
            const choice = parseInt(answer.trim(), 10);
            if (choice === 0) {
                this.handleArsenal();
                return;
            }
            if (isNaN(choice) || choice < 1 || choice > equipmentItems.length) {
                console.log("⚠️ Opção inválida!");
                this.handleEquipItem();
                return;
            }

            const selectedItem = equipmentItems[choice - 1];
            const equipmentDef = EQUIPMENT_CATALOG[selectedItem.id];

            if (!equipmentDef) {
                console.log(`\n❌ Definição do equipamento '${selectedItem.id}' não encontrada no catálogo.`);
                this.showMainMenu();
                return;
            }

            const success = this.eqEngine.equipItem(this.campaign, hero.id, equipmentDef);

            if (success) {
                console.log(`\n✅ ${equipmentDef.name} equipado com sucesso no slot ${equipmentDef.slot}!`);
            } else {
                console.log("\n❌ Falha ao equipar item.");
            }
            this.showMainMenu();
        });
    }

    /**
     * handleUnequipItem()
     * ------------------------------------------------------------------
     * Lista os slots ocupados do herói e permite que o usuário
     * escolha um para remover o equipamento (devolvendo-o ao
     * inventário global).
     */
    private handleUnequipItem(): void {
        const hero = this.getHero();
        const occupiedSlots = EQUIPMENT_SLOTS.filter(
            slot => hero.equippedItems[slot] !== undefined,
        );

        if (occupiedSlots.length === 0) {
            console.log("\n❌ Nenhum equipamento equipado para remover.");
            this.showMainMenu();
            return;
        }

        console.log("\n🔄 Slots ocupados:");
        occupiedSlots.forEach((slot, index) => {
            const item = hero.equippedItems[slot]!;
            console.log(`   ${index + 1}. ${slot}: ${item.name}`);
        });
        console.log("   0. 🔙 Voltar");

        this.rl.question("\nEscolha um slot para remover o equipamento: ", (answer) => {
            const choice = parseInt(answer.trim(), 10);
            if (choice === 0) {
                this.handleArsenal();
                return;
            }
            if (isNaN(choice) || choice < 1 || choice > occupiedSlots.length) {
                console.log("⚠️ Opção inválida!");
                this.handleUnequipItem();
                return;
            }

            const slot = occupiedSlots[choice - 1];
            const success = this.eqEngine.unequipItem(this.campaign, hero.id, slot);

            if (success) {
                console.log(`\n✅ Equipamento removido do slot ${slot} e devolvido ao inventário.`);
            } else {
                console.log("\n❌ Falha ao remover equipamento.");
            }
            this.showMainMenu();
        });
    }

    // ==============================================================
    // HANDLER 4 — MISSÕES
    // ==============================================================

    /**
     * handleQuests()
     * ------------------------------------------------------------------
     * Exibe todas as missões ativas registradas no QuestManager,
     * com barras de progresso para cada meta e detalhes das
     * recompensas.
     */
    private handleQuests(): void {
        const activeQuests = this.questManager.getQuestsByStatus(QuestStatus.ACTIVE);

        console.log("\n📜 Diário de Missões Ativas");
        console.log("----------------------------------");

        if (activeQuests.length === 0) {
            console.log("(Nenhuma missão ativa no momento.)");
        } else {
            activeQuests.forEach(quest => {
                console.log(`\n📌 ${quest.name}`);
                console.log(`   ${quest.description}`);
                quest.goals.forEach(goal => {
                    const bar = this.makeProgressBar(goal.current, goal.required, 20);
                    console.log(`   🎯 ${goal.description}: ${bar} ${goal.current}/${goal.required}`);
                });
                console.log(`   🏆 Recompensa: ${quest.reward.scrap}💰 + ${quest.reward.items.length} itens`);
            });
        }

        console.log("\n   0. 🔙 Voltar ao Menu Principal");
        this.rl.question("Pressione Enter para voltar...", () => {
            this.showMainMenu();
        });
    }

    /**
     * makeProgressBar(current, required, length)
     * ------------------------------------------------------------------
     * Gera uma barra de progresso visual usando caracteres Unicode.
     *
     * @param current  - Valor atual do progresso
     * @param required - Valor necessário para completar
     * @param length   - Comprimento da barra em caracteres
     * @returns String com a barra de progresso (ex: "███████░░░ 7/10")
     */
    private makeProgressBar(current: number, required: number, length: number): string {
        const ratio = required > 0 ? Math.min(1, current / required) : 0;
        const filled = Math.round(ratio * length);
        const empty = length - filled;
        return '█'.repeat(filled) + '░'.repeat(empty);
    }

    // ==============================================================
    // HANDLER 5 — SALVAR E SAIR
    // ==============================================================

    /**
     * handleSaveAndExit()
     * ------------------------------------------------------------------
     * Persiste o estado completo da campanha via
     * SaveSystem.saveGame() — que serializa através de
     * CampaignManager.saveGameState() e grava em disco com checksum
     * de integridade SHA-256 (CampaignStateManager), em vez de
     * fs.writeFileSync bruto sem proteção. Em seguida, encerra o
     * processo.
     */
    private handleSaveAndExit(): void {
        const saved = SaveSystem.saveGame(this.campaign);

        if (saved) {
            console.log(`\n💾 Progresso salvo com integridade verificada em: ${SaveSystem.getSaveFilePath()}`);
        } else {
            console.log("\n❌ Falha ao salvar o progresso — verifique as permissões do diretório 'saves/'.");
        }

        console.log("🛑 Desligando chassi... Até a próxima, Engenheiro!");
        this.rl.close();
        process.exit(0);
    }
}