/**
 * ====================================================================
 * GameLoop.ts
 * --------------------------------------------------------------------
 * CLI (Command-Line Interface) Game Loop para o Projeto Aetheris.
 *
 * Conecta os sistemas core ao fluxo de jogo interativo via terminal:
 *   - CampaignManager       (progresso, recursos, party)
 *   - CampaignMapEngine     (navegação/travessia de nós com custo/perigo)
 *   - SaveSlotEngine        (saves multi-slot + AUTOSAVE, checksum SHA-256)
 *   - CraftingEngine / EquipmentEngine / QuestManager
 *   - CombatAIEngine        (Insubordinação Tática)
 *
 * ARQUITETURA TESTÁVEL:
 *   A lógica de fluxo vive em métodos "core" puros de I/O de terminal
 *   (startNewGame, performTraversal, autoSave, saveToManualSlot,
 *   loadSlot, listSlots, HUD). A camada readline apenas os orquestra.
 *   Isso permite testar o ciclo Novo Jogo → Travessia → AutoSave →
 *   Carregar sem depender de stdin/process.exit.
 *
 * Versão: 2.0.0
 * ====================================================================
 */

import * as readline from 'readline';
import { CharacterState } from '../core/CharacterState';
import { CampaignManager } from '../core/CampaignManager';
import { CampaignMapEngine, ITraversalResult, ICampaignNode, NodeType } from '../core/CampaignMapEngine';
import { CraftingEngine } from '../core/CraftingEngine';
import { EquipmentEngine } from '../core/EquipmentEngine';
import { QuestManager, QuestStatus } from '../core/QuestManager';
import { SaveSlotEngine, SaveSlotId, ISaveSlotSummary } from '../core/SaveSlotEngine';
import { CombatAIEngine, ICommandResolution } from '../core/CombatAIEngine';
import { BestiaryEngine, IEnemyInstance, ENEMY_TO_COMBAT_ARCHETYPE } from '../core/BestiaryEngine';
import { EstafaActionType } from '../mechanics/EstafaCalculator';
import { CANONICAL_EQUIPMENT } from '../database/CanonicalContent';
import { LatentLineageAxis, SlotType } from '../types/aetheris.types';

// ==================================================================
// CONSTANTES
// ==================================================================

/** Slots de equipamento disponíveis no jogo (modelo legado slot-based). */
const EQUIPMENT_SLOTS: SlotType[] = ['WEAPON', 'ARMOR', 'CORE_MOD'];

/** Catálogo canônico de equipamentos. */
const EQUIPMENT_CATALOG = CANONICAL_EQUIPMENT;

/** Id fixo do herói inicial. */
const HERO_ID = 'hero_engineer_01';

/** Slots manuais de save disponíveis no menu de descanso. */
const MANUAL_SLOTS: SaveSlotId[] = ['SLOT_1', 'SLOT_2', 'SLOT_3'];

/** Tipos de nó que disparam um encontro de combate ao serem atravessados. */
const COMBAT_NODE_TYPES: ReadonlySet<NodeType> = new Set<NodeType>(['COMBAT_ARENA', 'AMBUSH']);

/** Encontro de combate gerado ao entrar em um nó hostil. */
export interface IGeneratedEncounter {
    nodeId: string;
    nodeType: NodeType;
    enemies: IEnemyInstance[];
    /** IAs de combate instanciadas (uma por inimigo). */
    ais: CombatAIEngine[];
}

// ==================================================================
// CLASSE PRINCIPAL — CLIGameLoop
// ==================================================================

export class CLIGameLoop {
    /** Interface readline — criada preguiçosamente em start() (testes não abrem stdin). */
    private rl!: readline.Interface;
    private campaign!: CampaignManager;
    private mapEngine = new CampaignMapEngine();
    private craftingEngine = new CraftingEngine();
    private eqEngine = new EquipmentEngine();
    private questManager = new QuestManager();
    private bestiary = new BestiaryEngine();
    private readonly saveSlots: SaveSlotEngine;

    /** Marca de início da sessão para cálculo de playTime nos metadados. */
    private sessionStart = Date.now();

    /**
     * @param saveSlots - Engine de saves multi-slot (injetável para testes herméticos).
     */
    constructor(saveSlots: SaveSlotEngine = new SaveSlotEngine()) {
        this.saveSlots = saveSlots;
    }

    // ==============================================================
    // NÚCLEO TESTÁVEL — SEM readline / process.exit
    // ==============================================================

    /**
     * startNewGame()
     * ------------------------------------------------------------------
     * Cria a party-esqueleto (herói padrão) e uma nova campanha no nó
     * de entrada. Retorna a campanha criada.
     */
    public startNewGame(): CampaignManager {
        const hero = new CharacterState(
            { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 },
            LatentLineageAxis.NEUTRO_ABSOLUTO,
            undefined,
            undefined,
            null,
            HERO_ID,
        );
        hero.scrapCount = 50;
        this.campaign = new CampaignManager([hero]);
        this.campaign.setCurrentNode('brenhold_entrance');
        this.sessionStart = Date.now();
        return this.campaign;
    }

    /** Retorna a campanha ativa. */
    public getCampaign(): CampaignManager {
        return this.campaign;
    }

    /** Atalho para o herói principal. */
    private getHero(): CharacterState {
        return this.campaign.getPartyState()[0];
    }

    /** Segundos de jogo desde o início da sessão. */
    private playTimeSeconds(): number {
        return Math.floor((Date.now() - this.sessionStart) / 1000);
    }

    /**
     * getPartyStatusHUD()
     * ------------------------------------------------------------------
     * Monta o HUD de status do grupo: Mantimentos, Estafa, posição e o
     * estado dos equipamentos duráveis. Retorna string (testável).
     */
    public getPartyStatusHUD(): string {
        const progress = this.campaign.getProgress();
        const hero = this.getHero();
        const node = this.mapEngine.getNodeDetails(progress.currentNodeId);
        const areaName = node?.name ?? progress.currentNodeId;
        const crisis = this.campaign.isSurvivalCrisis() ? ' ⚠️ ESCASSEZ' : '';

        const lines = [
            `📍 Área: ${areaName}`,
            `🍞 Mantimentos: ${this.campaign.getSupplies()}${crisis}`,
            `⚖️ Estafa: ${progress.estafaBalance} ${this.estafaLabel(progress.estafaBalance)}`,
            `👤 ${hero.id} | HP: ${hero.hp}/${hero.maxHp} | Sucata: ${hero.scrapCount}💰`,
            `🛠️ Equipamentos: ${this.getEquipmentSummary()}`,
        ];
        return lines.join('\n');
    }

    /** Rótulo do polo da Estafa. */
    private estafaLabel(estafa: number): string {
        if (estafa <= -60) return '(Materno Extremo)';
        if (estafa >= 60) return '(Paterno Extremo)';
        if (estafa < 0) return '(Materno)';
        if (estafa > 0) return '(Paterno)';
        return '(Equilíbrio)';
    }

    /**
     * getEquipmentSummary()
     * ------------------------------------------------------------------
     * Resume o estado dos equipamentos duráveis do herói (durabilidade e
     * oxidação). Retorna "(nenhum)" se não houver.
     */
    public getEquipmentSummary(): string {
        const durable = this.getHero().durableEquipment;
        if (durable.length === 0) return '(nenhum)';
        return durable
            .map((item) => {
                const rusted = EquipmentEngine.isRusted(item) ? ' 🟠OXIDADO' : '';
                return `${item.name} ${item.durability.current}/${item.durability.max}${rusted}`;
            })
            .join(', ');
    }

    /**
     * previewTraversal(targetNodeId)
     * ------------------------------------------------------------------
     * Custo/perigo estimado de atravessar até um destino, para confirmação.
     */
    public previewTraversal(targetNodeId: string) {
        return this.mapEngine.getTraversalPreview(targetNodeId);
    }

    /**
     * performTraversal(targetNodeId)
     * ------------------------------------------------------------------
     * Executa a travessia (recursos + desgaste + estafa) e, em caso de
     * sucesso, dispara o salvamento automático no slot AUTOSAVE.
     */
    public performTraversal(
        targetNodeId: string,
    ): { result: ITraversalResult; autoSaved: boolean; encounter?: IGeneratedEncounter } {
        const result = this.mapEngine.traverseToNode(this.campaign, targetNodeId);
        if (!result.success) {
            return { result, autoSaved: false };
        }

        // Nós hostis disparam um encontro escalado pelo perigo do duto.
        let encounter: IGeneratedEncounter | undefined;
        const node = this.mapEngine.getNodeDetails(targetNodeId);
        if (node && COMBAT_NODE_TYPES.has(node.type)) {
            encounter = this.generateEncounterForNode(node);
        }

        const autoSaved = this.autoSave();
        return { result, autoSaved, encounter };
    }

    /**
     * getPartyAverageLevel()
     * ------------------------------------------------------------------
     * Nível médio (arredondado) da party — usado para escalar encontros.
     */
    public getPartyAverageLevel(): number {
        const party = this.campaign.getPartyState();
        if (party.length === 0) return 1;
        const sum = party.reduce((acc, c) => acc + c.currentLevel, 0);
        return Math.max(1, Math.round(sum / party.length));
    }

    /**
     * generateEncounterForNode(node)
     * ------------------------------------------------------------------
     * Gera um encontro escalado para um nó hostil: instancia os inimigos
     * (BestiaryEngine.generateEncounter), semeia RUST_LOCK ambiental em
     * áreas oxidadas (perigo >= 3) e cria a IA de combate de cada inimigo
     * mapeando o arquétipo do bestiário para o AIArchetype de combate.
     */
    public generateEncounterForNode(node: ICampaignNode): IGeneratedEncounter {
        const hazard = Math.max(1, node.hazardLevel ?? 1);
        const partyLevel = this.getPartyAverageLevel();
        const estafaBalance = this.campaign.getProgress().estafaBalance;

        const enemies = this.bestiary.generateEncounter(hazard, partyLevel, { estafaBalance });

        // Dutos muito oxidados (perigo alto) podem travar autômatos por ferrugem.
        const oxidationLevel = hazard >= 3 ? 0.5 : 0;
        for (const enemy of enemies) {
            this.bestiary.applyEncounterStatus(enemy, { oxidationLevel });
        }

        const ais = enemies.map(
            (e) => new CombatAIEngine(e.instanceId, ENEMY_TO_COMBAT_ARCHETYPE[e.archetypeAI]),
        );

        return { nodeId: node.id, nodeType: node.type, enemies, ais };
    }

    /**
     * autoSave()
     * ------------------------------------------------------------------
     * Salva o estado atual no slot AUTOSAVE.
     */
    public autoSave(): boolean {
        const progress = this.campaign.getProgress();
        const areaName = this.mapEngine.getNodeDetails(progress.currentNodeId)?.name ?? progress.currentNodeId;
        return this.saveSlots.saveToSlot('AUTOSAVE', this.campaign, {
            playTimeSeconds: this.playTimeSeconds(),
            currentAreaName: areaName,
        });
    }

    /**
     * saveToManualSlot(slotId)
     * ------------------------------------------------------------------
     * Salva o estado atual em um slot manual (SLOT_1..SLOT_3).
     */
    public saveToManualSlot(slotId: SaveSlotId): boolean {
        const progress = this.campaign.getProgress();
        const areaName = this.mapEngine.getNodeDetails(progress.currentNodeId)?.name ?? progress.currentNodeId;
        return this.saveSlots.saveToSlot(slotId, this.campaign, {
            playTimeSeconds: this.playTimeSeconds(),
            currentAreaName: areaName,
        });
    }

    /**
     * loadSlot(slotId)
     * ------------------------------------------------------------------
     * Cria uma party-esqueleto e restaura o estado do slot nela.
     *
     * @returns true se carregado com sucesso.
     */
    public loadSlot(slotId: SaveSlotId): boolean {
        this.startNewGame(); // esqueleto com o id de herói correto
        const result = this.saveSlots.loadFromSlot(slotId, this.campaign);
        return result.success;
    }

    /** Lista o resumo dos slots de save. */
    public listSlots(): ISaveSlotSummary[] {
        return this.saveSlots.listSaveSlots();
    }

    // ==============================================================
    // CAMADA INTERATIVA — readline
    // ==============================================================

    /**
     * start()
     * ------------------------------------------------------------------
     * Ponto de entrada interativo. Cria a interface readline e exibe o
     * Menu Principal.
     */
    public start(): void {
        this.rl = readline.createInterface({ input: process.stdin, output: process.stdout });
        console.clear();
        console.log('==================================================');
        console.log('🛡️ BEM-VINDO AOS DUTOS DE BRENHOLD — AETHERIS');
        console.log('==================================================');
        this.showMainMenu();
    }

    /** Pergunta encapsulada (readline). */
    private ask(query: string, cb: (answer: string) => void): void {
        this.rl.question(query, (answer) => cb(answer.trim()));
    }

    // --------------------------------------------------------------
    // MENU PRINCIPAL (BOOT)
    // --------------------------------------------------------------

    /**
     * showMainMenu()
     * ------------------------------------------------------------------
     * Novo Jogo / Carregar Jogo / Gerenciar Slots de Save / Sair.
     */
    private showMainMenu(): void {
        console.log('\n===== MENU PRINCIPAL =====');
        console.log('1. 🆕 Novo Jogo');
        console.log('2. 📂 Carregar Jogo');
        console.log('3. 🗂️  Gerenciar Slots de Save');
        console.log('4. 🚪 Sair');
        console.log('--------------------------');

        this.ask('Escolha uma opção: ', (answer) => {
            switch (answer) {
                case '1':
                    this.startNewGame();
                    console.log('\n✅ Novo jogo iniciado. Bem-vindo, Engenheiro.');
                    this.showCampaignMenu();
                    break;
                case '2':
                    this.showLoadMenu();
                    break;
                case '3':
                    this.showSlotManager();
                    break;
                case '4':
                    this.exit();
                    break;
                default:
                    console.log('⚠️ Opção inválida!');
                    this.showMainMenu();
            }
        });
    }

    /** Renderiza uma linha de resumo de slot. */
    private formatSlotSummary(summary: ISaveSlotSummary): string {
        if (summary.empty || !summary.metadata) {
            return `${summary.slotId}: (vazio)`;
        }
        const m = summary.metadata;
        const mins = Math.floor(m.playTimeSeconds / 60);
        const secs = m.playTimeSeconds % 60;
        return (
            `${summary.slotId}: ${m.currentAreaName} | Líder: ${m.partyLeaderName} | ` +
            `⏱️ ${mins}m${secs}s | 🍞 ${m.supplies} | ⚖️ ${m.estafaBalance}`
        );
    }

    /**
     * showLoadMenu()
     * ------------------------------------------------------------------
     * Lista os slots com seus resumos e permite carregar um deles.
     */
    private showLoadMenu(): void {
        const slots = this.listSlots();
        console.log('\n===== CARREGAR JOGO =====');
        slots.forEach((s, i) => console.log(`${i + 1}. ${this.formatSlotSummary(s)}`));
        console.log('0. 🔙 Voltar');

        this.ask('\nEscolha o slot para carregar: ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.showMainMenu();
            if (isNaN(choice) || choice < 1 || choice > slots.length) {
                console.log('⚠️ Opção inválida!');
                return this.showLoadMenu();
            }
            const target = slots[choice - 1];
            if (target.empty) {
                console.log('❌ Slot vazio — nada a carregar.');
                return this.showLoadMenu();
            }
            const ok = this.loadSlot(target.slotId);
            if (ok) {
                console.log(`\n✅ ${target.slotId} carregado! Bem-vindo de volta, Engenheiro.`);
                this.showCampaignMenu();
            } else {
                console.log('❌ Falha ao carregar o slot (corrompido ou inválido).');
                this.showLoadMenu();
            }
        });
    }

    /**
     * showSlotManager()
     * ------------------------------------------------------------------
     * Lista os slots e permite apagar um deles.
     */
    private showSlotManager(): void {
        const slots = this.listSlots();
        console.log('\n===== GERENCIAR SLOTS DE SAVE =====');
        slots.forEach((s, i) => console.log(`${i + 1}. ${this.formatSlotSummary(s)}`));
        console.log('0. 🔙 Voltar');

        this.ask('\nEscolha um slot para APAGAR (ou 0): ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.showMainMenu();
            if (isNaN(choice) || choice < 1 || choice > slots.length) {
                console.log('⚠️ Opção inválida!');
                return this.showSlotManager();
            }
            const target = slots[choice - 1];
            const ok = this.saveSlots.deleteSlot(target.slotId);
            console.log(ok ? `🗑️ ${target.slotId} apagado.` : '❌ Falha ao apagar.');
            this.showSlotManager();
        });
    }

    // --------------------------------------------------------------
    // LOOP DE EXPLORAÇÃO DE CAMPANHA
    // --------------------------------------------------------------

    /**
     * showCampaignMenu()
     * ------------------------------------------------------------------
     * HUD de status + opções de exploração/gestão e descanso (save manual).
     */
    private showCampaignMenu(): void {
        console.log('\n──────────── HUD DO GRUPO ────────────');
        console.log(this.getPartyStatusHUD());
        console.log('──────────────────────────────────────');
        console.log('1. 🧭 Explorar (Travessia de Nó)');
        console.log('2. 🔨 Forja de Equipamentos');
        console.log('3. 🎒 Arsenal e Equipamentos');
        console.log('4. 📜 Missões Ativas');
        console.log('5. 🏕️  Descansar (Salvar em Slot)');
        console.log('6. 🚪 Voltar ao Menu Principal');
        console.log('--------------------------------------');

        this.ask('Escolha uma opção: ', (answer) => {
            switch (answer) {
                case '1': this.handleTravel(); break;
                case '2': this.handleCrafting(); break;
                case '3': this.handleArsenal(); break;
                case '4': this.handleQuests(); break;
                case '5': this.handleRest(); break;
                case '6': this.showMainMenu(); break;
                default:
                    console.log('⚠️ Opção inválida!');
                    this.showCampaignMenu();
            }
        });
    }

    /**
     * handleTravel()
     * ------------------------------------------------------------------
     * Lista destinos conectados com custo/perigo estimado, confirma a
     * travessia e dispara o AUTOSAVE em caso de sucesso.
     */
    private handleTravel(): void {
        const progress = this.campaign.getProgress();
        const currentNode = this.mapEngine.getNodeDetails(progress.currentNodeId);

        if (!currentNode || currentNode.connectedTo.length === 0) {
            console.log('\n❌ Nenhum destino disponível a partir daqui.');
            return this.showCampaignMenu();
        }

        console.log(`\n📍 Você está em: ${currentNode.name}`);
        console.log('🧭 Destinos (com custo estimado):');
        currentNode.connectedTo.forEach((nodeId, i) => {
            const preview = this.previewTraversal(nodeId);
            if (preview) {
                console.log(
                    `   ${i + 1}. ${this.getNodeTypeIcon(preview.node.type)} ${preview.node.name} ` +
                    `[perigo ${preview.hazardLevel} | 🍞 -${preview.supplyCost} | ⚖️ ${preview.estafaImpact >= 0 ? '+' : ''}${preview.estafaImpact}]`,
                );
            }
        });
        console.log('   0. 🔙 Voltar');

        this.ask('\nEscolha um destino: ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.showCampaignMenu();
            if (isNaN(choice) || choice < 1 || choice > currentNode.connectedTo.length) {
                console.log('⚠️ Opção inválida!');
                return this.handleTravel();
            }

            const targetNodeId = currentNode.connectedTo[choice - 1];
            const preview = this.previewTraversal(targetNodeId);
            const costMsg = preview
                ? `Custo: 🍞 ${preview.supplyCost} mantimentos, perigo ${preview.hazardLevel}. `
                : '';

            this.ask(`${costMsg}Confirmar travessia? (s/n): `, (confirm) => {
                if (confirm.toLowerCase() !== 's') {
                    console.log('↩️ Travessia cancelada.');
                    return this.showCampaignMenu();
                }

                const { result, autoSaved, encounter } = this.performTraversal(targetNodeId);
                if (!result.success) {
                    console.log(`\n❌ ${result.message ?? 'Não foi possível atravessar.'}`);
                    return this.showCampaignMenu();
                }

                console.log(`\n✅ ${result.message}`);
                console.log(`   🍞 -${result.suppliesConsumed} mantimentos (restam ${result.suppliesRemaining}) | ⚖️ ${result.estafaShift >= 0 ? '+' : ''}${result.estafaShift} | 🛠️ ${result.equipmentDegraded} item(ns) desgastado(s)`);
                if (result.survivalCrisis) {
                    console.log('   ⚠️ ESCASSEZ DE MANTIMENTOS — o grupo avança exausto!');
                }
                console.log(autoSaved ? '   💾 AutoSave concluído.' : '   ⚠️ Falha no AutoSave.');

                if (encounter) {
                    console.log(`\n⚔️ ENCONTRO (${encounter.nodeType})! ${encounter.enemies.length} inimigo(s) surgem dos dutos:`);
                    encounter.enemies.forEach((e, i) => {
                        const rusted = e.activeStatuses.some((s) => s.type === 'RUST_LOCK') ? ' 🟠(travado por ferrugem)' : '';
                        console.log(`   ${i + 1}. ${e.name} [Nv.${e.level}] HP ${e.stats.maxHp} | DMG ${e.stats.damage} | DEF ${e.stats.defense} — IA ${e.archetypeAI}${rusted}`);
                    });
                }
                this.showCampaignMenu();
            });
        });
    }

    /** Ícone por tipo de nó. */
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

    /**
     * handleRest()
     * ------------------------------------------------------------------
     * Menu de descanso: salva o jogo em um dos slots manuais (SLOT_1..3).
     */
    private handleRest(): void {
        console.log('\n🏕️ Descanso — Salvar Jogo');
        MANUAL_SLOTS.forEach((slot, i) => {
            const summary = this.listSlots().find((s) => s.slotId === slot);
            console.log(`   ${i + 1}. ${summary ? this.formatSlotSummary(summary) : slot}`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('\nSalvar em qual slot? ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.showCampaignMenu();
            if (isNaN(choice) || choice < 1 || choice > MANUAL_SLOTS.length) {
                console.log('⚠️ Opção inválida!');
                return this.handleRest();
            }
            const slot = MANUAL_SLOTS[choice - 1];
            const ok = this.saveToManualSlot(slot);
            console.log(ok ? `\n💾 Jogo salvo em ${slot}.` : `\n❌ Falha ao salvar em ${slot}.`);
            this.showCampaignMenu();
        });
    }

    // --------------------------------------------------------------
    // FORJA (MANUFATURA)
    // --------------------------------------------------------------

    private handleCrafting(): void {
        const recipes = this.craftingEngine.getAvailableRecipes();
        const hero = this.getHero();

        console.log('\n🔨 Forja de Equipamentos');
        console.log(`💰 Sucata disponível: ${hero.scrapCount}`);

        if (recipes.length === 0) {
            console.log('(Nenhuma receita disponível.)');
            return this.showCampaignMenu();
        }

        recipes.forEach((recipe, index) => {
            const materials = recipe.requiredMaterials.map((m) => `${m.materialId} x${m.quantity}`).join(', ');
            console.log(`   ${index + 1}. ${recipe.resultItem.name} — 💰 ${recipe.requiredScrap} | ${materials}`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('\nEscolha uma receita: ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.showCampaignMenu();
            if (isNaN(choice) || choice < 1 || choice > recipes.length) {
                console.log('⚠️ Opção inválida!');
                return this.handleCrafting();
            }
            const recipe = recipes[choice - 1];
            const success = this.craftingEngine.craftItem(this.campaign, hero.id, recipe.recipeId);
            console.log(success
                ? `\n✅ ${recipe.resultItem.name} forjado e adicionado ao inventário!`
                : '\n❌ Falha ao forjar: recursos insuficientes.');
            this.showCampaignMenu();
        });
    }

    // --------------------------------------------------------------
    // ARSENAL (EQUIPAR/DESEQUIPAR)
    // --------------------------------------------------------------

    private handleArsenal(): void {
        const hero = this.getHero();
        const inventory = this.campaign.getGlobalInventory();

        console.log('\n🎒 Arsenal e Equipamentos');
        console.log('📦 Inventário Global:');
        if (inventory.length === 0) {
            console.log('   (Vazio)');
        } else {
            inventory.forEach((item, index) => {
                const typeIcon = item.type === 'EQUIPMENT' ? '🔧' : item.type === 'CONSUMABLE' ? '🧪' : '📦';
                console.log(`   ${index + 1}. ${typeIcon} ${item.name} (${item.id}) x${item.quantity}`);
            });
        }

        console.log('\n⚔️ Equipamentos Ativos:');
        EQUIPMENT_SLOTS.forEach((slot) => {
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

        console.log('\n   1. 🔧 Equipar item   2. 🔄 Remover   0. 🔙 Voltar');
        this.ask('\nEscolha uma opção: ', (answer) => {
            if (answer === '0') this.showCampaignMenu();
            else if (answer === '1') this.handleEquipItem();
            else if (answer === '2') this.handleUnequipItem();
            else {
                console.log('⚠️ Opção inválida!');
                this.handleArsenal();
            }
        });
    }

    private handleEquipItem(): void {
        const hero = this.getHero();
        const equipmentItems = this.campaign
            .getGlobalInventory()
            .filter((item) => item.type === 'EQUIPMENT' && item.quantity > 0);

        if (equipmentItems.length === 0) {
            console.log('\n❌ Nenhum equipamento disponível no inventário.');
            return this.showCampaignMenu();
        }

        console.log('\n🔧 Itens para equipar:');
        equipmentItems.forEach((item, index) => {
            const catalogEntry = EQUIPMENT_CATALOG[item.id];
            const slotInfo = catalogEntry ? `[${catalogEntry.slot}]` : '[slot desconhecido]';
            console.log(`   ${index + 1}. ${item.name} ${slotInfo} x${item.quantity}`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('\nEscolha um item: ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.handleArsenal();
            if (isNaN(choice) || choice < 1 || choice > equipmentItems.length) {
                console.log('⚠️ Opção inválida!');
                return this.handleEquipItem();
            }
            const equipmentDef = EQUIPMENT_CATALOG[equipmentItems[choice - 1].id];
            if (!equipmentDef) {
                console.log('\n❌ Definição do equipamento não encontrada no catálogo.');
                return this.showCampaignMenu();
            }
            const success = this.eqEngine.equipItem(this.campaign, hero.id, equipmentDef);
            console.log(success
                ? `\n✅ ${equipmentDef.name} equipado no slot ${equipmentDef.slot}!`
                : '\n❌ Falha ao equipar item.');
            this.showCampaignMenu();
        });
    }

    private handleUnequipItem(): void {
        const hero = this.getHero();
        const occupiedSlots = EQUIPMENT_SLOTS.filter((slot) => hero.equippedItems[slot] !== undefined);

        if (occupiedSlots.length === 0) {
            console.log('\n❌ Nenhum equipamento equipado.');
            return this.showCampaignMenu();
        }

        console.log('\n🔄 Slots ocupados:');
        occupiedSlots.forEach((slot, index) => {
            console.log(`   ${index + 1}. ${slot}: ${hero.equippedItems[slot]!.name}`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('\nEscolha um slot: ', (answer) => {
            const choice = parseInt(answer, 10);
            if (choice === 0) return this.handleArsenal();
            if (isNaN(choice) || choice < 1 || choice > occupiedSlots.length) {
                console.log('⚠️ Opção inválida!');
                return this.handleUnequipItem();
            }
            const slot = occupiedSlots[choice - 1];
            const success = this.eqEngine.unequipItem(this.campaign, hero.id, slot);
            console.log(success
                ? `\n✅ Equipamento removido do slot ${slot}.`
                : '\n❌ Falha ao remover equipamento.');
            this.showCampaignMenu();
        });
    }

    // --------------------------------------------------------------
    // MISSÕES
    // --------------------------------------------------------------

    private handleQuests(): void {
        const activeQuests = this.questManager.getQuestsByStatus(QuestStatus.ACTIVE);

        console.log('\n📜 Diário de Missões Ativas');
        if (activeQuests.length === 0) {
            console.log('(Nenhuma missão ativa no momento.)');
        } else {
            activeQuests.forEach((quest) => {
                console.log(`\n📌 ${quest.name}\n   ${quest.description}`);
                quest.goals.forEach((goal) => {
                    const bar = this.makeProgressBar(goal.current, goal.required, 20);
                    console.log(`   🎯 ${goal.description}: ${bar} ${goal.current}/${goal.required}`);
                });
                console.log(`   🏆 Recompensa: ${quest.reward.scrap}💰 + ${quest.reward.items.length} itens`);
            });
        }
        console.log('\n   0. 🔙 Voltar');
        this.ask('Pressione Enter para voltar...', () => this.showCampaignMenu());
    }

    private makeProgressBar(current: number, required: number, length: number): string {
        const ratio = required > 0 ? Math.min(1, current / required) : 0;
        const filled = Math.round(ratio * length);
        return '█'.repeat(filled) + '░'.repeat(length - filled);
    }

    // --------------------------------------------------------------
    // RESOLUÇÃO DE COMANDO DE COMBATE — BALANÇA DE ESTAFA
    // --------------------------------------------------------------

    /**
     * resolveCombatCommand(actor, actionType)
     * ------------------------------------------------------------------
     * Submete um comando de combate à Insubordinação Tática antes de
     * despachá-lo (ver CombatAIEngine.resolvePlayerCommand).
     */
    public resolveCombatCommand(actor: CharacterState, actionType: EstafaActionType): ICommandResolution {
        const resolution = CombatAIEngine.resolvePlayerCommand(
            actor,
            actionType,
            (code, message) => console.log(`⚠️  [${code}] ${message}`),
        );
        if (resolution.insubordination) {
            console.log(`🧠 Insubordinação Tática: ${resolution.reason}`);
            console.log(`➡️  Ação autônoma executada: ${resolution.autonomousAlternative}`);
        }
        return resolution;
    }

    // --------------------------------------------------------------
    // ENCERRAMENTO
    // --------------------------------------------------------------

    private exit(): void {
        console.log('\n🛑 Desligando chassi... Até a próxima, Engenheiro!');
        this.rl.close();
        process.exit(0);
    }
}

// ==================================================================
// PONTO DE ENTRADA
// ==================================================================

if (require.main === module) {
    new CLIGameLoop().start();
}
