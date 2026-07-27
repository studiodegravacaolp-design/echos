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
import { QuestManager, QuestStatus, IQuestReward } from '../core/QuestManager';
import { CANONICAL_QUEST_FACTORIES } from '../core/QuestContent';
import { DialogueEngine } from '../core/DialogueEngine';
import { SaveSlotEngine, SaveSlotId, ISaveSlotSummary } from '../core/SaveSlotEngine';
import { CombatAIEngine, ICommandResolution } from '../core/CombatAIEngine';
import { BestiaryEngine, IEnemyInstance, ENEMY_TO_COMBAT_ARCHETYPE } from '../core/BestiaryEngine';
import { CombatLoopEngine, ICombatResult } from '../core/CombatLoopEngine';
import { InteractiveCombatSession } from '../core/InteractiveCombatSession';
import { CombatRewardEngine } from '../core/CombatRewardEngine';
import { ProgressionManager } from '../core/ProgressionManager';
import { SkillTreeEngine } from '../core/SkillTreeEngine';
import { TraderManager } from '../core/TraderManager';
import { CampingEngine } from '../core/CampingEngine';
import { EstafaActionType } from '../mechanics/EstafaCalculator';
import { CANONICAL_EQUIPMENT } from '../database/CanonicalContent';
import { LatentLineageAxis, SlotType, ICharacterStats } from '../types/aetheris.types';

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
    private dialogueEngine = new DialogueEngine();
    private bestiary = new BestiaryEngine();
    private combatLoop = new CombatLoopEngine();
    private progression = new ProgressionManager();
    private rewards = new CombatRewardEngine();
    private skillTree = new SkillTreeEngine();
    private trader = new TraderManager();
    private camping = new CampingEngine();
    private readonly saveSlots: SaveSlotEngine;

    /** Cursor de impressão do log de combate interativo. */
    private combatLogCursor = 0;

    /** Id do diálogo ancorado em andamento (para o gatilho TALK_NPC). */
    private activeDialogueId?: string;

    /** Marca de início da sessão para cálculo de playTime nos metadados. */
    private sessionStart = Date.now();

    /** Atributos-base (nível 1) por herói, para reaplicar a escala por nível. */
    private heroBaseStats = new Map<string, ICharacterStats>();

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
        const baseStats: ICharacterStats = { maxHp: 100, currentHp: 100, damage: 10, defense: 5, resilience: 5, movementSpeed: 10 };
        const hero = new CharacterState(
            { ...baseStats },
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

        // Registra os atributos-base para a escala de progressão por nível.
        this.heroBaseStats.clear();
        this.heroBaseStats.set(hero.id, { ...baseStats });

        // Inicializa a árvore de talentos e concede o kit inicial de habilidades.
        this.skillTree.initializeTreeForCharacter(hero.id);
        this.skillTree.grantStarterAbilities(hero);

        // Registra e ativa as missões canônicas.
        this.registerCanonicalQuests();

        return this.campaign;
    }

    /** Registra (do zero) e inicia as missões canônicas do catálogo. */
    private registerCanonicalQuests(): void {
        this.questManager.clear();
        for (const factory of CANONICAL_QUEST_FACTORIES) {
            const quest = factory();
            this.questManager.registerQuest(quest);
            this.questManager.startQuest(quest.id);
        }
    }

    /** Acesso ao gerenciador de missões (para triggers/testes). */
    public getQuestManager(): QuestManager {
        return this.questManager;
    }

    /**
     * grantQuestReward(reward)
     * ------------------------------------------------------------------
     * Aplica a recompensa de uma missão ao grupo: Sucata + itens
     * (consolidateLoot), Mantimentos (addSupplies) e XP (por sobrevivente).
     */
    private grantQuestReward(reward: IQuestReward): void {
        const items = reward.items.map((ri) => ({
            id: ri.item.id,
            name: ri.item.name,
            type: 'MATERIAL' as const,
            quantity: ri.quantity,
        }));
        if (reward.scrap > 0 || items.length > 0) {
            this.campaign.consolidateLoot(reward.scrap, items);
        }
        if (reward.supplies && reward.supplies > 0) {
            this.campaign.addSupplies(reward.supplies);
        }
        if (reward.xp && reward.xp > 0) {
            this.campaign.getPartyState().filter((c) => c.hp > 0).forEach((c) => this.progression.addExperience(c, reward.xp!));
        }
    }

    /**
     * processQuestCompletions(questIds)
     * ------------------------------------------------------------------
     * Reivindica a recompensa de cada missão recém-concluída e a concede
     * ao grupo, imprimindo o desfecho. Retorna os IDs efetivamente pagos.
     */
    public processQuestCompletions(questIds: string[]): string[] {
        const paid: string[] = [];
        for (const id of questIds) {
            const reward = this.questManager.claimQuestReward(id);
            if (!reward) continue;
            this.grantQuestReward(reward);
            const quest = this.questManager.getQuest(id);
            console.log(`\n📜 Missão concluída: ${quest?.name ?? id}! Recompensa: +${reward.scrap}💰 +${reward.xp ?? 0} XP +${reward.supplies ?? 0}🍞`);
            paid.push(id);
        }
        return paid;
    }

    /**
     * applyLevelScaling(character)
     * ------------------------------------------------------------------
     * Recalcula os atributos de combate do personagem a partir de seus
     * atributos-base e do nível atual (DRF do ProgressionManager) e os
     * aplica. Idempotente — sempre escala a partir da base registrada.
     */
    public applyLevelScaling(character: CharacterState): void {
        const base = this.heroBaseStats.get(character.id);
        if (!base) return;
        const scaled = this.progression.scaleStatsWithDiminishingReturns(base, character.currentLevel);
        character.applyScaledCombatStats(scaled);
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
            `🎯 Missão: ${this.getMainQuestHUD()}`,
        ];
        return lines.join('\n');
    }

    /** Linha de HUD da Missão Principal ativa (nome + etapa atual). */
    public getMainQuestHUD(): string {
        const main = this.questManager.getActiveMainQuest();
        if (!main) return '(nenhuma missão principal ativa)';
        const goal = this.questManager.getCurrentGoal(main.id);
        const step = goal ? `${goal.description} (${goal.current}/${goal.required})` : 'todas as etapas cumpridas';
        return `${main.name} — ${step}`;
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
    ): { result: ITraversalResult; autoSaved: boolean; encounter?: IGeneratedEncounter; dialogueId?: string } {
        const result = this.mapEngine.traverseToNode(this.campaign, targetNodeId);
        if (!result.success) {
            return { result, autoSaved: false };
        }

        const node = this.mapEngine.getNodeDetails(targetNodeId);

        // Nós hostis disparam um encontro escalado pelo perigo do duto.
        let encounter: IGeneratedEncounter | undefined;
        if (node && COMBAT_NODE_TYPES.has(node.type)) {
            encounter = this.generateEncounterForNode(node);
        }

        // Nós narrativos ancoram um diálogo ramificado por Estafa.
        const dialogueId = node?.dialogueId;

        // Gatilho de missão: visita ao nó (REACH_NODE).
        this.processQuestCompletions(this.questManager.notifyNodeVisited(targetNodeId));

        const autoSaved = this.autoSave();
        return { result, autoSaved, encounter, dialogueId };
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
     * runEncounterCombat(encounter)
     * ------------------------------------------------------------------
     * Resolve o combate de um encontro pela party atual, via
     * CombatLoopEngine (turnos, dano mitigado e condições táticas).
     */
    public runEncounterCombat(encounter: IGeneratedEncounter): ICombatResult {
        return this.combatLoop.runCombat(this.campaign.getPartyState(), encounter.enemies, {
            estafaBalance: this.campaign.getProgress().estafaBalance,
        });
    }

    /**
     * handleCombat(encounter)
     * ------------------------------------------------------------------
     * Inicia o combate INTERATIVO por turnos: o jogador escolhe a ação de
     * cada herói (passando pelos bloqueios da Balança de Estafa), e os
     * turnos de inimigos/DoT são resolvidos automaticamente entre decisões.
     */
    private handleCombat(encounter: IGeneratedEncounter): void {
        const session = new InteractiveCombatSession(
            this.campaign.getPartyState(),
            encounter.enemies,
            { estafaBalance: this.campaign.getProgress().estafaBalance },
        );
        session.start();
        this.combatLogCursor = 0;
        this.flushCombatLog(session);
        this.combatTurnPrompt(session, encounter);
    }

    /**
     * grantVictoryRewards(encounter)
     * ------------------------------------------------------------------
     * Concede sucata e XP/nível ao grupo pela vitória e imprime o resumo.
     */
    private grantVictoryRewards(encounter: IGeneratedEncounter): void {
        const survivors = this.campaign.getPartyState().filter((c) => c.hp > 0);
        const reward = this.rewards.grantVictoryRewards(
            this.campaign,
            encounter.enemies,
            survivors,
            this.progression,
        );
        console.log(`\n🎁 Espólio: +${reward.scrapAwarded} sucata | +${reward.xpAwarded} XP por herói.`);
        if (reward.itemsDropped.length > 0) {
            const summary = reward.itemsDropped.map((it) => `${it.name} x${it.quantity}`).join(', ');
            console.log(`   📦 Itens saqueados: ${summary}`);
        }
        reward.levelUps.forEach((lu) => {
            console.log(`   ⬆️ ${lu.characterId} subiu ${lu.levelsGained} nível(is) → Nv.${lu.newLevel}!`);
        });
        // Aplica o crescimento de atributos aos que subiram de nível.
        if (reward.levelUps.length > 0) {
            survivors.forEach((c) => this.applyLevelScaling(c));
        }
        if (reward.overflowMarks > 0) {
            console.log(`   ✨ +${reward.overflowMarks} Marca(s) de Aço (overflow no teto).`);
        }
    }

    /** Imprime as novas linhas do log de combate desde o último flush. */
    private flushCombatLog(session: InteractiveCombatSession): void {
        const log = session.getFullLog();
        for (let i = this.combatLogCursor; i < log.length; i++) {
            console.log(log[i]);
        }
        this.combatLogCursor = log.length;
    }

    /**
     * combatTurnPrompt(session)
     * ------------------------------------------------------------------
     * Exibe o turno atual (HP, Estafa, ações com bloqueios) e coleta a
     * escolha do jogador; encerra retornando ao menu de campanha.
     */
    private combatTurnPrompt(session: InteractiveCombatSession, encounter: IGeneratedEncounter): void {
        if (session.isOver()) {
            const outcome = session.getOutcome();
            // Feedback loop: as escolhas de combate deixam marca na Estafa do grupo.
            const netShift = session.getNetEstafaShift();
            if (netShift !== 0 && outcome !== 'DEFEAT') {
                this.campaign.modifyEstafaBalance(netShift);
                console.log(`\n⚖️ As escolhas do combate deslocam a Estafa do grupo em ${netShift >= 0 ? '+' : ''}${netShift} (agora ${this.campaign.getProgress().estafaBalance}).`);
            }
            if (outcome === 'VICTORY') {
                console.log('\n🏆 Vitória! Os dutos ficam em silêncio novamente.');
                this.grantVictoryRewards(encounter);
                // Gatilho de missão: inimigos derrotados (DEFEAT_ENEMIES / KILL_BOSS).
                this.processQuestCompletions(
                    this.questManager.notifyEnemiesDefeated(encounter.enemies.map((e) => ({ templateId: e.templateId }))),
                );
                this.autoSave();
                return this.showCampaignMenu();
            }
            if (outcome === 'DEFEAT') {
                return this.showGameOver();
            }
            console.log('\n⏳ O confronto se arrasta sem vencedor claro.');
            return this.showCampaignMenu();
        }

        const turn = session.getCurrentTurn()!;
        console.log(`\n🎯 Turno de ${turn.actorName} | ⚖️ Estafa ${turn.actorEstafa} | ⚡ EP ${turn.ep.current}/${turn.ep.max}`);
        console.log(`   👾 Inimigos: ${turn.enemies.map((e) => `${e.name} ${e.hp}/${e.maxHp}`).join(', ')}`);
        console.log(`   🛠️ Aliados: ${turn.allies.map((a) => `${a.name} ${a.hp}/${a.maxHp}`).join(', ')}`);

        // Opções básicas seguidas das habilidades ativas (numeração contínua).
        turn.actions.forEach((a, i) => {
            const lock = a.locked ? ` 🔒 (${a.lockReason})` : '';
            console.log(`   ${i + 1}. ${a.label}${lock}`);
        });
        const abilityOffset = turn.actions.length;
        turn.abilities.forEach((ab, i) => {
            const lock = ab.locked ? ` 🔒 (${ab.lockReason})` : '';
            console.log(`   ${abilityOffset + i + 1}. ✨ ${ab.name} [${ab.epCost} EP]${lock}`);
        });

        const totalOptions = turn.actions.length + turn.abilities.length;
        this.ask('Escolha a ação: ', (answer) => {
            const idx = parseInt(answer, 10) - 1;
            if (isNaN(idx) || idx < 0 || idx >= totalOptions) {
                console.log('⚠️ Opção inválida!');
                return this.combatTurnPrompt(session, encounter);
            }
            if (idx < abilityOffset) {
                // Ação básica travada é permitida — dispara Insubordinação Tática.
                session.submitPlayerAction(turn.actions[idx].action);
            } else {
                const ability = turn.abilities[idx - abilityOffset];
                const res = session.submitAbility(ability.id);
                // Habilidade bloqueada (EP/recarga/Estafa) não consome o turno.
                if (res.log.some((l) => l.includes('⛔'))) {
                    this.flushCombatLog(session);
                    console.log(res.log.join('\n'));
                    return this.combatTurnPrompt(session, encounter);
                }
            }
            this.flushCombatLog(session);
            this.combatTurnPrompt(session, encounter);
        });
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
            progression: this.progression,
            skillTree: this.skillTree,
            questManager: this.questManager,
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
            progression: this.progression,
            skillTree: this.skillTree,
            questManager: this.questManager,
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
        this.startNewGame(); // esqueleto: registra quests, árvore e habilidades base
        this.progression.clear(); // limpa o XP da sessão antes de restaurar
        // Habilidades, nós de talento e estado das missões são restaurados do save.
        const result = this.saveSlots.loadFromSlot(slotId, this.campaign, this.progression, this.skillTree, this.questManager);
        if (result.success) {
            // Reaplica a escala por nível ao estado restaurado.
            this.campaign.getPartyState().forEach((c) => this.applyLevelScaling(c));
        }
        return result.success;
    }

    /** Lista o resumo dos slots de save. */
    public listSlots(): ISaveSlotSummary[] {
        return this.saveSlots.listSaveSlots();
    }

    /**
     * isPartyWiped()
     * ------------------------------------------------------------------
     * true se todos os membros da party estão caídos (HP <= 0) — condição
     * de Game Over.
     */
    public isPartyWiped(): boolean {
        const party = this.campaign.getPartyState();
        return party.length > 0 && party.every((c) => c.hp <= 0);
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

    /**
     * showGameOver()
     * ------------------------------------------------------------------
     * Tela de Game Over após a party tombar: permite recomeçar carregando
     * um save, iniciando novo jogo ou saindo. NÃO retorna à campanha (a
     * party está morta).
     */
    private showGameOver(): void {
        console.log('\n' + '═'.repeat(46));
        console.log('   ☠️  GAME OVER — o grupo tombou nos dutos de Brenhold');
        console.log('═'.repeat(46));
        console.log('1. 📂 Carregar Jogo');
        console.log('2. 🆕 Novo Jogo');
        console.log('3. 🚪 Sair');
        console.log('----------------------------------------------');

        this.ask('Escolha uma opção: ', (answer) => {
            switch (answer) {
                case '1':
                    this.showLoadMenu();
                    break;
                case '2':
                    this.startNewGame();
                    console.log('\n✅ Novo jogo iniciado. Bem-vindo, Engenheiro.');
                    this.showCampaignMenu();
                    break;
                case '3':
                    this.exit();
                    break;
                default:
                    console.log('⚠️ Opção inválida!');
                    this.showGameOver();
            }
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
        console.log('4. 📜 Ver Diário de Missões');
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

                const { result, autoSaved, encounter, dialogueId } = this.performTraversal(targetNodeId);
                if (!result.success) {
                    console.log(`\n❌ ${result.message ?? 'Não foi possível atravessar.'}`);
                    return this.showCampaignMenu();
                }

                console.log(`\n✅ ${result.message}`);
                console.log(`   🍞 -${result.suppliesConsumed} mantimentos${result.suppliesRestocked > 0 ? ` (+${result.suppliesRestocked} reabastecido)` : ''} (restam ${result.suppliesRemaining}) | ⚖️ ${result.estafaShift >= 0 ? '+' : ''}${result.estafaShift} | 🛠️ ${result.equipmentDegraded} item(ns) desgastado(s)`);
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
                    // Combate interativo por turnos (retorna ao menu ao terminar).
                    return this.handleCombat(encounter);
                }
                if (dialogueId) {
                    // Encontro narrativo ancorado ao nó (retorna ao menu ao terminar).
                    return this.handleDialogue(dialogueId);
                }
                const arrived = this.mapEngine.getNodeDetails(targetNodeId);
                if (arrived && arrived.type === 'REST_SITE') {
                    return this.handleCamp();
                }
                if (arrived && arrived.type === 'SCRAP_TRADER') {
                    return this.handleTrader();
                }
                this.showCampaignMenu();
            });
        });
    }

    // --------------------------------------------------------------
    // DIÁLOGO RAMIFICADO ANCORADO A NÓS
    // --------------------------------------------------------------

    /**
     * handleDialogue(dialogueId)
     * ------------------------------------------------------------------
     * Inicia um diálogo ramificado (Estafa) ancorado a um nó do mapa.
     */
    private handleDialogue(dialogueId: string): void {
        const node = this.dialogueEngine.startDialogue(dialogueId);
        if (!node) {
            return this.showCampaignMenu();
        }
        this.activeDialogueId = dialogueId;
        this.dialoguePrompt();
    }

    /** Encerra o diálogo: dispara o gatilho TALK_NPC, salva e volta ao menu. */
    private endDialogue(): void {
        if (this.activeDialogueId) {
            // Gatilho de missão: conversa concluída (TALK_NPC).
            this.processQuestCompletions(this.questManager.notifyNpcTalked(this.activeDialogueId));
            this.activeDialogueId = undefined;
        }
        this.autoSave();
        this.showCampaignMenu();
    }

    /**
     * dialoguePrompt()
     * ------------------------------------------------------------------
     * Exibe o nó ativo, lista as opções ricas com bloqueios por Estafa e
     * aplica a escolha (deslocando a Estafa do grupo). Nós terminais
     * (apenas texto/continuação) encerram o diálogo.
     */
    private dialoguePrompt(): void {
        const node = this.dialogueEngine.getActiveDialogue();
        if (!node) {
            return this.endDialogue();
        }

        console.log(`\n💬 [${node.speaker}]: "${node.text}"`);
        const estafa = this.campaign.getProgress().estafaBalance;
        const options = this.dialogueEngine.getAvailableOptions(estafa);

        // Nó terminal/continuação (sem opções ricas).
        if (options.length === 0) {
            return this.ask('   (Enter para continuar) ', () => this.endDialogue());
        }

        options.forEach((o, i) => {
            const lock = o.locked ? ` 🔒 (${o.lockReason})` : '';
            console.log(`   ${i + 1}. ${o.text}${lock}`);
        });

        this.ask('Escolha: ', (answer) => {
            const idx = parseInt(answer, 10) - 1;
            if (isNaN(idx) || idx < 0 || idx >= options.length) {
                console.log('⚠️ Opção inválida!');
                return this.dialoguePrompt();
            }
            const chosen = options[idx];
            const res = this.dialogueEngine.selectOption(chosen.id, estafa, this.campaign);
            if (res.locked) {
                // A psique do líder recusa esta resposta — reoferece as opções.
                console.log(`   🧠 ${res.lockReason}`);
                return this.dialoguePrompt();
            }
            console.log(`   ⚖️ Estafa do grupo agora: ${this.campaign.getProgress().estafaBalance}`);
            this.dialoguePrompt();
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
    // ACAMPAMENTO (REST_SITE) — GESTÃO DE GRUPO
    // --------------------------------------------------------------

    /**
     * handleCamp()
     * ------------------------------------------------------------------
     * Tela de acampamento em nós REST_SITE: descansar/alimentar, reparo de
     * campo, ajuste de formação e conversa de acampamento. Ao levantar
     * acampamento, dispara o AutoSave e retorna ao menu de campanha.
     */
    private handleCamp(): void {
        const progress = this.campaign.getProgress();
        console.log('\n🏕️  ACAMPAMENTO');
        console.log(`   💰 Sucata: ${this.getHero().scrapCount} | 🍞 Mantimentos: ${this.campaign.getSupplies()} | ⚖️ Estafa: ${progress.estafaBalance}`);
        console.log('   1. 🔥 Descansar e Alimentar (−2 mantimentos → +40% HP / +50% EP)');
        console.log('   2. 🛠️  Reparo de Campo');
        console.log('   3. 🎖️  Ajustar Formação');
        console.log('   4. 💬 Conversa de Acampamento');
        console.log('   0. 🥾 Levantar Acampamento & Marchar');

        this.ask('Escolha: ', (answer) => {
            switch (answer) {
                case '1': this.handleCampRest(); break;
                case '2': this.handleCampRepair(); break;
                case '3': this.handleCampFormation(); break;
                case '4': this.handleCampConversation(); break;
                case '0':
                    console.log('\n🥾 Levantando acampamento e marchando...');
                    this.autoSave(); // persiste o estado pós-acampamento
                    this.showCampaignMenu();
                    break;
                default:
                    console.log('⚠️ Opção inválida!');
                    this.handleCamp();
            }
        });
    }

    private handleCampRest(): void {
        const res = this.camping.restAndFeed(this.campaign);
        if (res.fed) {
            console.log(`\n🔥 Descanso completo: −${res.suppliesConsumed} mantimentos → +${res.hpRestoredTotal} HP e +${res.epRestoredTotal} EP no grupo.`);
        } else {
            console.log(`\n⚠️ Sem mantimentos! Descanso parcial: apenas +${res.epRestoredTotal} EP.`);
            console.log('   ☠️ Risco de ESCASSEZ DE MANTIMENTOS (SURVIVAL_CRISIS) na próxima travessia perigosa.');
        }
        this.handleCamp();
    }

    private handleCampRepair(): void {
        const hero = this.getHero();
        const durable = hero.durableEquipment.filter((e) => e.durability.current < e.durability.max);
        if (durable.length === 0) {
            console.log('\n✅ Nenhum equipamento precisa de reparo.');
            return this.handleCamp();
        }
        console.log('\n🛠️ Reparo de Campo (💰 ' + hero.scrapCount + ' sucata):');
        durable.forEach((e, i) => {
            const rusted = EquipmentEngine.isRusted(e) ? ' 🟠OXIDADO' : '';
            console.log(`   ${i + 1}. ${e.name} ${e.durability.current}/${e.durability.max}${rusted}`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('Reparar qual? ', (answer) => {
            const idx = parseInt(answer, 10) - 1;
            if (isNaN(idx) || idx < 0 || idx >= durable.length) {
                return this.handleCamp();
            }
            const res = this.camping.fieldRepair(this.campaign, hero.id, durable[idx].id);
            if (res.success) {
                console.log(`\n✅ +${res.durabilityRestored} durabilidade por ${res.scrapSpent} sucata.${res.rustCleared ? ' 🟢 Oxidação removida!' : ''}`);
            } else {
                console.log('\n❌ Reparo falhou (sucata insuficiente ou item já íntegro).');
            }
            this.handleCampRepair();
        });
    }

    private handleCampFormation(): void {
        const party = this.campaign.getPartyState();
        console.log('\n🎖️ Formação atual (Vanguarda → Retaguarda):');
        party.forEach((c, i) => {
            const role = i === 0 ? 'Vanguarda' : i === party.length - 1 ? 'Retaguarda' : 'Centro';
            console.log(`   ${i + 1}. ${c.id} [${role}] HP ${c.hp}/${c.maxHp}`);
        });
        if (party.length < 2) {
            console.log('   (Grupo com um único herói — sem reordenação possível.)');
            return this.handleCamp();
        }
        console.log('   Informe duas posições para trocar (ex.: "1 2"), ou 0 para voltar.');

        this.ask('Trocar: ', (answer) => {
            if (answer.trim() === '0') return this.handleCamp();
            const parts = answer.trim().split(/\s+/).map((n) => parseInt(n, 10) - 1);
            if (parts.length !== 2 || parts.some((n) => isNaN(n))) {
                console.log('⚠️ Entrada inválida!');
                return this.handleCampFormation();
            }
            const ok = this.campaign.swapFormationPositions(parts[0], parts[1]);
            console.log(ok ? '✅ Formação ajustada.' : '❌ Posições inválidas.');
            this.handleCampFormation();
        });
    }

    private handleCampConversation(): void {
        console.log('\n💬 Conversa de Acampamento:');
        console.log('   1. 🔩 "Sem espaço para fraqueza aqui." (endurece — +10 Paterno)');
        console.log('   2. 💧 "Descansem; cuidamos uns dos outros." (abranda — −10 Materno)');
        console.log('   0. 🔙 Voltar');

        this.ask('Escolha: ', (answer) => {
            if (answer === '1') {
                const e = this.camping.campConversation(this.campaign, 'PATERNO');
                console.log(`\n⚖️ O grupo se enrijece. Estafa agora: ${e} (Paterno).`);
            } else if (answer === '2') {
                const e = this.camping.campConversation(this.campaign, 'MATERNO');
                console.log(`\n⚖️ O grupo respira fundo. Estafa agora: ${e} (Materno).`);
            } else if (answer === '0') {
                return this.handleCamp();
            } else {
                console.log('⚠️ Opção inválida!');
            }
            this.handleCamp();
        });
    }

    // --------------------------------------------------------------
    // MERCADOR (ECONOMIA DE SUCATA)
    // --------------------------------------------------------------

    /**
     * handleTrader()
     * ------------------------------------------------------------------
     * Interface de mercador em nós SCRAP_TRADER: comprar mantimentos,
     * reparar equipamentos duráveis e comprar itens/upgrades — tudo
     * gastando sucata. Ao sair, salva no AUTOSAVE (persistência).
     */
    private handleTrader(): void {
        const hero = this.getHero();
        console.log('\n🏪 Mercado de Sucata');
        console.log(`   💰 Sucata: ${hero.scrapCount} | 🍞 Mantimentos: ${this.campaign.getSupplies()}`);
        console.log('   1. 🍞 Comprar Mantimentos');
        console.log('   2. 🛠️  Reparar Equipamento');
        console.log('   3. 📦 Comprar Itens');
        console.log('   0. 🚪 Sair do mercado');

        this.ask('Escolha: ', (answer) => {
            switch (answer) {
                case '1': this.handleBuySupplies(); break;
                case '2': this.handleRepair(); break;
                case '3': this.handleBuyItems(); break;
                case '0':
                    this.autoSave(); // persiste a economia atualizada
                    this.showCampaignMenu();
                    break;
                default:
                    console.log('⚠️ Opção inválida!');
                    this.handleTrader();
            }
        });
    }

    private handleBuySupplies(): void {
        const hero = this.getHero();
        console.log(`\n🍞 Comprar Mantimentos (💰 ${hero.scrapCount} sucata disponível, taxa 1:1)`);
        this.ask('Quantos mantimentos comprar? (0 cancela) ', (answer) => {
            const amount = parseInt(answer, 10);
            if (isNaN(amount) || amount <= 0) {
                return this.handleTrader();
            }
            const res = this.trader.buySupplies(this.campaign, hero.id, amount);
            console.log(res.success
                ? `✅ +${res.suppliesBought} mantimentos por ${res.scrapSpent} sucata (agora ${this.campaign.getSupplies()}).`
                : '❌ Sucata insuficiente.');
            this.handleTrader();
        });
    }

    private handleRepair(): void {
        const hero = this.getHero();
        const durable = hero.durableEquipment.filter((e) => e.durability.current < e.durability.max);
        if (durable.length === 0) {
            console.log('\n✅ Nenhum equipamento precisa de reparo.');
            return this.handleTrader();
        }
        console.log('\n🛠️ Equipamentos desgastados:');
        durable.forEach((e, i) => {
            const rusted = EquipmentEngine.isRusted(e) ? ' 🟠OXIDADO' : '';
            console.log(`   ${i + 1}. ${e.name} ${e.durability.current}/${e.durability.max}${rusted} — custo ~${this.trader.estimateRepairCost(e)} sucata`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('Reparar qual? ', (answer) => {
            const idx = parseInt(answer, 10) - 1;
            if (isNaN(idx) || idx < 0 || idx >= durable.length) {
                return this.handleTrader();
            }
            const res = this.trader.repairEquipment(this.campaign, hero.id, durable[idx].id);
            console.log(res.success
                ? `✅ +${res.durabilityRestored} durabilidade por ${res.scrapSpent} sucata.`
                : '❌ Reparo falhou (sucata insuficiente ou já íntegro).');
            this.handleTrader();
        });
    }

    private handleBuyItems(): void {
        const hero = this.getHero();
        const stock = this.trader.getAvailableStock();
        console.log('\n📦 Itens à venda:');
        stock.forEach((s, i) => {
            console.log(`   ${i + 1}. ${s.name} [${s.type}] — 💰 ${s.scrapPrice} (estoque ${s.stock})`);
        });
        console.log('   0. 🔙 Voltar');

        this.ask('Comprar qual? ', (answer) => {
            const idx = parseInt(answer, 10) - 1;
            if (isNaN(idx) || idx < 0 || idx >= stock.length) {
                return this.handleTrader();
            }
            const ok = this.trader.buyItem(this.campaign, hero.id, stock[idx].itemId);
            console.log(ok ? `✅ ${stock[idx].name} comprado.` : '❌ Compra falhou (sucata ou estoque).');
            this.handleTrader();
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
        const active = this.questManager.getQuestsByStatus(QuestStatus.ACTIVE);
        const completed = this.questManager.getQuestsByStatus(QuestStatus.COMPLETED);
        const main = active.filter((q) => q.type === 'MAIN');
        const side = active.filter((q) => q.type !== 'MAIN');

        console.log('\n📜 Diário de Missões');

        const renderQuest = (quest: { name: string; description: string; goals: { description: string; current: number; required: number }[]; reward: { scrap: number; xp?: number; supplies?: number } }) => {
            console.log(`\n📌 ${quest.name}\n   ${quest.description}`);
            quest.goals.forEach((goal) => {
                const bar = this.makeProgressBar(goal.current, goal.required, 20);
                console.log(`   🎯 ${goal.description}: ${bar} ${goal.current}/${goal.required}`);
            });
            console.log(`   🏆 Recompensa: ${quest.reward.scrap}💰 +${quest.reward.xp ?? 0} XP +${quest.reward.supplies ?? 0}🍞`);
        };

        console.log('\n── PRINCIPAL ──');
        if (main.length === 0) console.log('(nenhuma)');
        else main.forEach(renderQuest);

        console.log('\n── SECUNDÁRIAS ──');
        if (side.length === 0) console.log('(nenhuma)');
        else side.forEach(renderQuest);

        console.log('\n── CONCLUÍDAS ──');
        if (completed.length === 0) console.log('(nenhuma)');
        else completed.forEach((q) => console.log(`   ✅ ${q.name}`));

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
