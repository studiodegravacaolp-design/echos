# 📜 AETHERIS — LOG DE EVOLUÇÃO E ARQUITETURA DO PROJETO

> **Regra de Manutenção:** Este arquivo DEVE ser atualizado a cada nova sprint, funcionalidade, refatoração ou consolidação de código realizada no projeto.

---

## 📊 Resumo do Estado do Sistema
- **Balança de Estafa:** Integrated (Combat, Dialogue, Campaign) — mecânica-core em [`src/mechanics/EstafaCalculator.ts`](src/mechanics/EstafaCalculator.ts)
- **Sistema de Diálogos:** Integrated (Locks Diegéticos + ramificação por Estafa)
- **Equipamentos e Sucata:** Integrated (Durabilidade, Rusted, Repair)
- **Navegação de Campanha:** Integrated (Recursos, Hazard, Crise, Reabastecimento)
- **Status Engine Tático:** Integrated (Poison, Burn, Rust Lock, Spark)
- **Gerenciador de Saves:** Integrated (4 Slots, Checksum SHA-256, AutoSave, XP + Habilidades + Árvore persistidos)
- **Bestiário e Inimigos:** Integrated (Encontros por Hazard, IA Tática, Drop Tables)
- **Combat Loop Engine:** Integrated (Turn-Based, Status, Speed Order)
- **Combate Interativo:** Integrated (Ações gated pela Estafa + feedback loop)
- **Progressão & Recompensas:** Integrated (Sucata, Drops, XP, Level-Up, Stat Scaling DRF)
- **Habilidades de Combate:** Integrated (EP, Cooldown, Status, Gating por Estafa)
- **Mercadores & Economia:** Integrated (Comprar Mantimentos, Reparo, Itens por Sucata)
- **Sistema de Missões:** Integrated (Main/Side, Gatilhos de Nó/Combate/Diálogo, Recompensas, Persistência)
- **Acampamento & Grupo:** Integrated (Descanso HP/EP, Reparo de Campo, Formação, Conversa de Estafa)
- **Interface CLI:** GameLoop v2.0 (Menu, HUD+Missão, Combate, Habilidades, Diálogo, Mercador, Acampamento, Diário, Game Over)
- **Conteúdo:** Ato 2 (Profundezas de Brenhold) + 9 templates de inimigos
- **Assets & Visuais:** Git LFS (.gitattributes, Portraits, Spritesheets)

**Stack:** TypeScript (strict) · execução de testes via `tsx` (harness nativo por suite) · `tsc --noEmit` como build/type-check.

---

## 🗓️ Histórico de Entregas & Modificações

### [2026-07-25] — Acampamento & Gestão de Grupo (REST_SITE) (HEAD)
- **CampingEngine.ts (novo):** `restAndFeed` (−2 mantimentos → +40% HP / +50% EP; descanso parcial só-EP com alerta de SURVIVAL_CRISIS), `fieldRepair` (reparo com sucata, remove *Rusted* acima de 25%), `adjustFormation` e `campConversation` (±10 Estafa Paterno/Materno).
- **EP persistente:** `CharacterState` ganhou `currentEp`/`maxEp` (MAX_EP=100); a `InteractiveCombatSession` passa a semear e sincronizar o EP a partir do `CharacterState` (descanso restaura o EP entre combates).
- **CampaignManager:** `reorderParty` e `swapFormationPositions` (Vanguarda/Retaguarda).
- **Mapa & GameLoop:** novo tipo de nó `REST_SITE` (Bivaque Selado); ao chegar, abre a tela de Acampamento; "Levantar Acampamento & Marchar" dispara o AutoSave.
- **Testes:** `CampingIntegration` 25/25 (descanso HP/EP, parcial, reparo de oxidado, formação, conversa, persistência pós-acampamento). Type-check limpo; regressão verde.

### [2026-07-25] — Integração de Missões: GameLoop, Gatilhos & Persistência
- **QuestManager estendido:** tipos `MAIN`/`SIDE`, metas tipadas (`REACH_NODE`/`DEFEAT_ENEMIES`/`KILL_BOSS`/`TALK_NPC`), gatilhos `notifyNodeVisited`/`notifyEnemiesDefeated`/`notifyNpcTalked`, `getActiveMainQuest`/`getCurrentGoal`, `claimQuestReward` (XP/Sucata/Mantimentos) e `serializeState`/`restoreState`. Catálogo em `QuestContent.ts` (missão principal + secundária).
- **GameLoop:** registra/ativa quests no novo jogo; HUD mostra a **Missão Principal** e a etapa atual; "Ver Diário de Missões" lista principal/secundárias/concluídas; gatilhos disparam na travessia (nó), na vitória de combate (inimigos) e no fim de diálogo (NPC); recompensas concedidas ao grupo automaticamente.
- **Persistência:** `SaveSlotEngine` serializa/reidrata o estado das quests (`quests` no payload), com auto-migração para saves legados (checksum SHA-256 preservado).
- **Testes:** `QuestIntegration` 22/22 (gatilhos → conclusão → recompensa → salvar/carregar). Type-check limpo; regressão verde.

### [2026-07-25] — Persistência de Habilidades & Árvore de Talentos no SaveSlotEngine
- **Schema de save expandido:** `ISavedCharacter` ganha `learnedAbilityIds` (habilidades ativas aprendidas) e `unlockedSkillNodes` (nós passivos da árvore). `saveToSlot` captura ambos via `ProgressionManager`/`SkillTreeEngine` (opções); checksum SHA-256 preservado.
- **Reidratação na carga:** `applyPayloadToCampaign` reconstrói as habilidades do catálogo canônico (`CANONICAL_ABILITIES`) e reaplica os bônus passivos via `SkillTreeEngine.restoreUnlockedNodes` (novo). `GameLoop.loadSlot` passa o `skillTree`; `startNewGame` inicializa a árvore.
- **Auto-migração:** saves legados recebem o **starter kit** de habilidades e árvore vazia, mantendo a integridade do checksum (validação antes da migração em memória).
- **Testes:** `SkillTreeSaveIntegration` 19/19 (ciclo aprender→salvar→carregar→validar + migração legada). Type-check limpo; regressão verde.

### [2026-07-25] — Sprint Dupla: Habilidades no Combate & Economia de Mercador
- **Opção 1 — Habilidades ativas no combate:** `CombatAbilities.ts` (kit canônico: Golpe de Forja, Descarga de Ferrugem, Solda de Sobrevivência); `CharacterState` aprende habilidades; `SkillTreeEngine.grantStarterAbilities` faz a ponte. `InteractiveCombatSession` ganha **pool de EP** (regen modulado pelo bônus Materno), **cooldowns**, opções de habilidade e `submitAbility` — com **gating pela Estafa** (agressivas travadas no Materno; suporte no Paterno), custo de EP efetivo (encarecido no Paterno), aplicação de status via `StatusEngine` e feedback loop de Estafa.
- **Opção 2 — Mercador & economia de sucata:** `TraderManager` ganha `buySupplies` (sucata → mantimentos), `repairEquipment` (reparo via `EquipmentEngine`) e estoque de equipamento; `GameLoop` abre a interface de mercador ao chegar em nós `SCRAP_TRADER`, persistindo no AutoSave.
- **Testes:** `CombatSkillsIntegration` 19/19 e `TraderIntegration` 18/18. Type-check limpo; regressão verde.

### [2026-07-25] — Diretriz de Documentação Contínua
- **Implementado:** `CLAUDE.md` na raiz formaliza a regra de **commit atômico** (código + `PROJECT_CHANGELOG.md` sempre no mesmo commit). A partir daqui, toda entrega atualiza este changelog junto do código.

### [2026-07-25] — Ganchos de Nó: Diálogos Ancorados & Reabastecimento
- **Commit:** `708506c`
- **Commit:** `708506c`
- **Implementado:** nós do mapa ganham `dialogueId` e `supplyRestock`. `traverseToNode` reabastece mantimentos (limpando crise) e o CLI dispara o diálogo ancorado ao chegar (Condutos de Vapor → Autômato Preso; Refúgio → Engenheira Ferida).
- **Testes:** +4 em `CampaignNavigationIntegration`, +7 na seção H de `GameLoopCLIIntegration`.

### [2026-07-25] — Expansão de Conteúdo (Bestiário, Mapa Ato 2, Diálogos)
- **Commit:** `a60aba9`
- **Implementado:** 5 novos templates de inimigo (tiers 2–5, incl. chefe **Colosso de Ferrugem** t5); ramificação do mapa para o Ato 2 (Refúgio, Condutos de Vapor, Fundição, Santuário Enferrujado, Mercado das Profundezas, Reator Central); 2 diálogos ramificados por Estafa.

### [2026-07-25] — Progressão, Recompensas & Game Over
- **Commits:** `0e27fbd`, `aeae4cc`, `c932b40`, `f45c36b`, `8dc7e9e`
- **Implementado:**
  - `CombatRewardEngine.ts` — sucata (LootEngine) + XP/level-up (ProgressionManager) na vitória.
  - Persistência de XP por personagem no `SaveSlotEngine` (migração de saves antigos).
  - Fluxo de **Game Over** no defeat (Carregar/Novo Jogo/Sair) + `isPartyWiped()`.
  - **Drops de itens** por template de inimigo (materiais/consumíveis/equipamento).
  - **Escala de atributos por nível** (DRF) reaplicada em level-up e no load.
- **Testes:** `CombatRewardEngine` 10/10; seções de Game Over, drops e level-scaling verdes.

### [2026-07-25] — Combate Interativo & Feedback Loop da Estafa
- **Commits:** `ecd27e8`, `6047dea`, `89f897c`
- **Implementado:**
  - `CombatLoopEngine.ts` — combate headless por turnos (ordem por velocidade, DoT, mitigação hiperbólica, IA de alvo).
  - `InteractiveCombatSession.ts` — o jogador escolhe a ação de cada herói (Atacar / Execução Fria / Cura Compassiva), gated pela Balança de Estafa (Insubordinação Tática → ação autônoma).
  - **Feedback loop:** ações de combate deslocam a Estafa (Execução → +Paterno, Cura → −Materno), re-gating dinâmico e persistência no grupo.
- **Testes:** `CombatLoopEngine` 14/14; `InteractiveCombatSession` 32/32.

### [2026-07-25] — Bestiário & Geração de Encontros
- **Commits:** `f131fa5`, `ae04ce1`
- **Implementado:** `BestiaryEngine.ts` (templates: Rato Químico, Batedor Catador, Autômato Oxidado, Guardião de Vapor; `generateEncounter` escalado por hazard/nível; RUST_LOCK ambiental; `ENEMY_TO_COMBAT_ARCHETYPE`). Integrado ao `GameLoop` — nós de combate/emboscada geram encontros na travessia.
- **Testes:** `BestiaryEngine` 25/25.

### [2026-07-25] — Multi-Slot Save Engine & GameLoop CLI v2.0
- **Commits:** `8f34e7d`, `5398a79`
- **Implementado:** `SaveSlotEngine.ts` (4 slots, checksum SHA-256, migração de schema, AutoSave) e `GameLoop.ts` refatorado (Menu Principal, HUD de grupo, preview de duto, travessia + AutoSave).
- **Testes:** `SaveSlotEngine` 34/34; `GameLoopCLIIntegration` (base) verdes.

### [2026-07-25] — Assets via Git LFS
- **Commit:** `0b71943`
- **Implementado:** Git LFS (`.gitattributes` para `assets/**/*.png`), padronização de extensão PNG (correção de `.png.png`) e inclusão de 11 artes (6 portraits + 5 spritesheets, ~26 MB fora do histórico).

### [2026-07-24] — Consolidação de Engines Pré-existentes & Tooling
- **Commit:** `98b5451`
- **Implementado:** versionamento de `QuestManager`, `SkillTreeEngine`, `TraderManager`, `ArenaHazardEngine`, `StatusEffectEngine` e seus testes; scripts `test`/`build` e devDependency `tsx` no `package.json`.

### [2026-07-24] — Status Engine Tático
- **Commit:** `53133de`
- **Implementado:** `src/core/StatusEngine.ts` — condições `CHEMICAL_POISON`, `STEAM_BURN`, `SPARK_OVERCHARGE`, `RUST_LOCK` (empilhamento, DoT, penalidades de atributo refletidas nos getters do `CharacterState`). Distinto do motor TECH_* legado.
- **Testes:** `StatusEngineTactical` 24/24.

### [2026-07-24] — Navegação de Campanha (Recursos, Desgaste, Estafa)
- **Commit:** `afc7d3a`
- **Implementado:** `CampaignMapEngine.traverseToNode` — consumo de `supplies`, degradação de durabilidade dos equipamentos, deslocamento de Estafa por perigo e estado `SURVIVAL_CRISIS` por escassez.

### [2026-07-24] — Durabilidade, Oxidação e Reparo
- **Commit:** `f2fee53`
- **Implementado:** modelo `IDurableEquipment` no `EquipmentEngine` — durabilidade, `isRusted` (≤25% → penalidade de 50%), degradação e reparo via sucata; integração com `CharacterState.getEffectivePhysicalDefense`.

### [2026-07-24] — Diálogos com Locks Diegéticos
- **Commit:** `ac40ea4`
- **Implementado:** `DialogueEngine` integrado ao `EstafaCalculator` — `getAvailableOptions` marca opções incompatíveis como travadas; `selectOption` aplica o `estafaShift` clampado ao grupo.

### [2026-07-24] — Integração da Estafa ao Combate
- **Commit:** `f8c1837`
- **Implementado:** `CharacterState.getEffective*` moduladas pela Estafa; `CombatAIEngine.resolvePlayerCommand` (Insubordinação Tática); seam `resolveCombatCommand` no GameLoop.

### [2026-07-24] — Mecânica-Core: Balança de Estafa
- **Commits:** `6dc2b91`, `e73d1b0`
- **Implementado:** `src/mechanics/EstafaCalculator.ts` — `calculateModifiers`, `getQuadrant`, `validateAction` (clamp [-100,+100]); testes unitários (42/42) e doc formal `docs/mechanics/ESTAFA_SYSTEM.md`.

### [2026-07-24] — Blueprint Mestre & Bíblia de Arte
- **Commits:** `9f7863f`, `ada07c5`, `cf23dfb`, `b8cbde0`, `7be16c5`
- **Implementado:** `AETHERIS_MASTER_INDEX.md` (fonte única da verdade); calibração de prompts HD-2D (Anões, Fadas, Lurídeos); padrão de Portraits "Card de UI com Caixa de Diálogo Integrada"; consolidação/migração de prompts (Tier 1/2, exceção Veredito do Tier 3).

---

## 🧪 Convenção de Testes
- Cada suite é um script executável via `npx tsx src/test/<suite>.test.ts`, com harness próprio (`assert` + relatório).
- Validação padrão de cada entrega: `npx tsc --noEmit` (type-check global) + execução das suites afetadas.

## 📌 Índice de Documentação
- [`AETHERIS_MASTER_INDEX.md`](AETHERIS_MASTER_INDEX.md) — blueprint mestre do produto e regras de sistema.
- [`docs/mechanics/ESTAFA_SYSTEM.md`](docs/mechanics/ESTAFA_SYSTEM.md) — especificação da Balança de Estafa.
- [`doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md`](doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) — direção de arte HD-2D.
- [`doc/art_bible/PROMPTS_MESTRES_ARTE.md`](doc/art_bible/PROMPTS_MESTRES_ARTE.md) — prompts canônicos de geração.
