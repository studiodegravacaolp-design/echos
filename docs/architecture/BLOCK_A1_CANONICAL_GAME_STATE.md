# ECHOES OF THE SOUL — BLOCO A1: CANONIZAÇÃO DO ESTADO

> **Jogo:** ECHOES OF THE SOUL · **Mundo/universo:** AETHERIS · **Primeiro cenário:** Vardhelm
> **Runtime:** Godot 4.7.1 (`godot/`) · **Referência/especificação:** núcleo TypeScript (`src/`)
> **Status:** A1 aprovado — decisões humanas registradas na §7. Contrato em código entregue no Bloco A2 (§9).
> **Base factual:** Inventário A0 da branch `integration/godot-vardhelm` @ `a526cc4`.

Este documento especifica o **estado canônico** que deve existir no runtime Godot antes de
qualquer mudança no Save/Load. Ele não implementa sistemas de gameplay novos e não substitui
os sistemas já validados de Vardhelm.

---

## 1. Diagnóstico (estado real encontrado no A0)

| # | Fato (A0) | Consequência para o contrato |
|---|---|---|
| D1 | Não existe dono único do estado: `WorldState` vive no `NarrativeController`, `QuestState` no `QuestController`, a posição no nó `Player` — todos filhos do slice, sem autoload. | O contrato precisa de uma raiz (`GameState`) e separar **dado** de **dono em runtime**. |
| D2 | `WorldState.memories` recebe **IDs de consequência** (`vardhelm_heard_echo`, `vardhelm_first_echo_complete`) via `NarrativeController.apply_consequence`. | Memória e consequência precisam de coleções distintas. |
| D3 | O Eco tem `memory_id = vardhelm_first_echo_memory`, nunca persistido; o Eco não tem ID próprio (só o nó `FirstEcho`); `revealed` vive só no nó. | O Eco precisa de identidade e estado próprios, separados da memória que produz. |
| D4 | Observações emitem `memory_fragment_discovered` sem nenhuma conexão; `vardhelm_memory_*` nunca são registradas. | O contrato precisa prever o registro de fragmentos sem inventar regra de composição. |
| D5 | Observação vista é gravada duas vezes (flag `observation_<id>_seen` + value `observation.<id>.seen`); `seen_flag` do JSON é carregado e não usado. | Observações precisam de seção própria; a flag vira espelho de compatibilidade. |
| D6 | `environment_states` (em `VardhelmAmbientLife`) é **calculado** de flags + `narrative_consequences` e não é salvo. `_refresh_persistent_world_state` percorre `memories` achando que ali estão consequências. | Estado de ambiente é **derivado**; separar memória/consequência afeta esse código. |
| D7 | Quest: `active`/`completed` são dicionários separados; objetivos booleanos; `completion_consequence` e recompensa não são usados. | Um registro por quest com status único; recompensa só como contrato futuro. |
| D8 | Diálogo: só a sessão em runtime; sem histórico nem registro de conclusão. Ctrl+S funciona durante o diálogo. | Separar sessão (transitória) de histórico (persistente). |
| D9 | Player: só `position` e `rotation` (Vector3 globais). O `language` é salvo junto do estado. | PlayerState mínimo = localização; idioma não é estado de jogo. |
| D10 | O Load quebra ao atribuir o `Array` do JSON a `Array[String]` (`save_service.gd:44`). | Regra R2: a forma serializada usa só tipos JSON e é convertida explicitamente. |
| D11 | Durn tem três identificadores: `vardhelm.durn` (entidade), `Durn` (nó), `npc.vardhelm.elder.name` (chave de texto). | Três namespaces legítimos; faltava regra que os relacionasse (resolvido na decisão #7). |

---

## 2. Estrutura canônica

Avaliação da proposta inicial:

| Componente | Existe? | Motivo |
|---|---|---|
| GameState | **Sim** | Raiz única, versionada e serializável (D1). |
| PlayerState | **Sim** | Já existe dado real (posição/rotação). |
| WorldState | **Sim, reestruturado** | Hoje mistura flags, consequências, memórias e observações. |
| QuestState | **Sim** | Já funciona; muda só a forma canônica. |
| DialogueState | **Sim (só persistente)** | Conclusão e escolhas; a sessão não é persistida. |
| MemoryState | **Sim** | Separa Eco/memória de consequência (D2–D4). |
| NPCState | **Sim, contrato sem registros obrigatórios** | Nenhum estado de NPC muda hoje; o modelo fica pronto sem inventar comportamento. |
| ProgressionState | **Não — nome reservado** | Não há progressão no Godot e o design está pendente; compatibilidade futura vem de versão de schema + migração, não de uma seção vazia. |

```
GameState                      state_version: int = 1
├── player: PlayerState
│   └── location { scenario_id, position, rotation }
├── world: WorldState
│   ├── flags
│   ├── values
│   ├── consequences
│   └── observations
│   (environment_states: DERIVADO — nunca persistido)
├── quests: QuestState         quest_id -> { status, objectives }
├── dialogue: DialogueState    { completed, choices }  (sessão é runtime)
├── memory: MemoryState        { echoes, memories }
└── npcs: NPCState             npc_id -> { interaction_enabled }  (só diferenças do padrão)
[reservado] progression — sem campos até decisão de design
```

### Regras globais

- **R1 — Três classes de dado.** *Persistente* (no GameState); *derivado* (recalculado do
  persistente + dados de conteúdo; nunca salvo); *transitório* (UI, timers, tweens, sessão de
  diálogo, candidato de interação, áudio, posição de trabalhadores ambientais; nunca salvo).
- **R2 — Forma serializada.** Somente `Dictionary`, `Array`, `String`, `bool` e número.
  `Vector3` ↔ `[x, y, z]`. Números voltam do JSON como float e são convertidos explicitamente
  (`state_version` → int; `world.values` normalizados para float na entrada). **Nenhum dado de
  JSON é atribuído diretamente a coleção tipada** (`Array[String]`, `Dictionary[String, bool]`).
- **R3 — IDs, nunca texto.** Título, texto, categoria e rótulos ficam nos dados de conteúdo e
  na localização.
- **R4 — Ausência = padrão.** Só se grava o que difere do estado inicial.
- **R5 — Sem dados de usuário.** Idioma, volume e controles são configuração da
  instalação/sessão ou do envelope do save (Bloco C).
- **R6 — Versões independentes.** `state_version` do GameState (=1) não é a `"version"` do
  arquivo de save atual (que se declara 2).

---

## 3. Especificação por estado

### 3.1 GameState

| Item | Especificação |
|---|---|
| Responsabilidade | Raiz única e versionada de todo o estado persistente da partida. |
| Campos mínimos | `state_version: int` (=1), `player`, `world`, `quests`, `dialogue`, `memory`, `npcs`. |
| Origem atual | Não existe; estado espalhado em `NarrativeController.world_state`, `QuestController.states` e no nó `Player`. |
| Destino futuro | Serializado pelo envelope do Save V2 (Bloco C); lido pelos sistemas narrativos. |
| Fora dele | Metadados de save (slot, data, checksum, versão do arquivo), idioma, áudio, câmera, input, timers, tweens, sessão de diálogo, UI. |
| Dependências | Todos os sub-estados. |
| Riscos | Dono em runtime (autoload × objeto do slice) ainda não decidido (§8, técnica). |

### 3.2 PlayerState

| Item | Especificação |
|---|---|
| Responsabilidade | Onde o jogador está. |
| Campos mínimos | `location.scenario_id: String` · `location.position: Vector3` · `location.rotation: Vector3`. |
| Serializado | `{ "location": { "scenario_id": "scenario.vardhelm", "position": [x,y,z], "rotation": [x,y,z] } }` |
| Origem atual | `save_service.gd`: `player.position`/`player.rotation` (`global_*`). `scenario_id` não existe hoje e é implícito (cena principal única). |
| Fora agora (explícito) | HP, EP, XP, nível, atributos, equipamento, inventário, party, skills, `area_id`, `spawn_id`/`checkpoint_id`. |
| Migração | `player.position` → `location.position`; `player.rotation` → `location.rotation`; `scenario_id` ← `scenario.vardhelm` (inferido). |
| Não pertence | `language` (R5), câmera, velocidade, estado de input, candidato de interação. |
| Riscos | Restaurar posição livre em nível alterado pode posicionar o jogador em lugar inválido (hash do LevelBuilder dessincronizado no A0). Decisão #5: posição e rotação exatas; sem checkpoint agora. |

### 3.3 WorldState — quatro subseções, nunca uma lista única

| Subseção | Responsabilidade | Serializado | Origem atual | Migração | Fora dele |
|---|---|---|---|---|---|
| `flags` | Fatos narrativos booleanos globais (ex.: condição do texto pós-Eco). | `{ flag_id: bool }` | `WorldState.flags` | Mantidas **com os nomes atuais**. Flags de consequência e de observação seguem como **espelho de compatibilidade** enquanto `ambient_life.json (world_flag)` e `environmental_observation.gd` as consultarem. | Contadores e valores não booleanos. |
| `values` | Escalares genéricos não booleanos. | `{ key: bool\|number\|String }` | `WorldState.values` | Hoje só contém `observation.<id>.seen` (duplicata) → representado em `observations`; `values` fica disponível para uso futuro. | Dados de observação ou qualquer coisa com seção própria. |
| `consequences` | Consequências aplicadas (idempotente) e sua fonte narrativa. | `{ consequence_id: { "applied": true, "source_type"?: String, "source_id"?: String } }` | **Não existe** — hoje inferido de `flags`/`memories`. | IDs de consequência conhecidos em `flags`/`memories` → `consequences`, com fonte do catálogo. | O efeito (flags, estado de ambiente); memórias. |
| `observations` | Observações ambientais descobertas. | `{ observation_id: { "discovered": true } }` | flag `observation_<id>_seen` + value `observation.<id>.seen` | Qualquer uma → `discovered: true`. | Título/texto/raio/posição/chaves pré e pós-Eco (conteúdo); `revealed` do nó (derivado). |
| *(environment_states)* | Estado visual do ambiente (`echo_awakened`, `*_remembered`). | **DERIVADO — não persistido** | `VardhelmAmbientLife.environment_states` | Recalculado de `flags`/`consequences` + `narrative_consequences`. | Tudo (R1). |

- Consequência aplicada é **idempotente**: a primeira aplicação (e sua fonte) prevalece.
- Futuro: `scenarios` (progresso/conclusão de cenário — hoje o "encerramento" é o banner da quest).
- Dependências: `ambient_life.json` (`narrative_consequences`, `observations`), `NarrativeController`,
  `EnvironmentalObservation` (lê flag pelo pai do ator).
- Riscos: `_refresh_persistent_world_state` percorre `memories` para reaplicar o ambiente; os IDs
  de `narrative_consequences` são simultaneamente IDs de consequência e de memória (`vardhelm_memory_*`).

### 3.4 QuestState

| Item | Especificação |
|---|---|
| Responsabilidade | Status e progresso de cada quest. |
| Campos mínimos | `{ quest_id: { "status": "active"\|"completed", "objectives": { objective_id: bool } } }`; `not_started` = ausente (R4). |
| Origem atual | `QuestState.active` / `completed` / `objective_progress`. |
| Migração | `active[id]` → `active`; `completed[id]` → `completed` (se nos dois, vale `completed`); `objective_progress[id]` → `objectives`; só progresso sem status → `active` (mesma regra de `_apply_loaded_visual_state`). |
| Preservação | API de runtime (`start_quest`, `set_objective_complete`, `complete_quest`, `is_completed`) **inalterada**; mapeamento só na serialização. |
| Futuro (só contrato) | **Recompensa:** definida nos dados (`QuestData.rewards`); no estado, `reward_granted: bool` **só quando existir lógica de recompensa** (não criado agora — sem justificativa técnica atual). **Consequência de conclusão:** `completion_consequence` permanece como dado de conteúdo e **não** gera segunda aplicação (decisão #4). **`failed`:** não existe. |
| Não pertence | Título, chaves de objetivo, texto exibido; habilitação do Eco (derivada). |
| Riscos | Fonte dupla da consequência final — resolvido pela decisão #4 (fonte = Eco). |

### 3.5 DialogueState

| Item | Especificação |
|---|---|
| Responsabilidade | O que o jogador concluiu e escolheu em diálogos. |
| Campos mínimos | `completed: { dialogue_id: true }` · `choices: { dialogue_id: { entry_id: choice_id } }` |
| Origem atual | Não existe. `DialogueSession.current_entry_id`/`selected_choice_id` são transitórios. |
| Análise | **Diálogo/entrada atuais**: transitórios, fora (R1). **Escolha**: no máximo uma por ponto de decisão (`dialogue_id` + `entry_id`) — a **última** realizada (decisão #6). **Histórico completo**: não agora. **Concluído**: `dialogue_finished` → `completed[id]`. |
| Futuro | Contagem de vezes, log ordenado, condições de disponibilidade. |
| Não pertence | Texto, falante, chaves, estado da caixa de diálogo, consequências (→ `world.consequences`). |
| Riscos | `dialogue_finished` também dispara em `end_dialogue()` e ao reiniciar sessão — "concluído" pode ser registrado sem chegar ao fim; o avanço linear após `learn` passa pela entrada `end`. |

### 3.6 MemoryState

Conceitos separados pelo que o código mostra:

| Conceito | No código | Natureza |
|---|---|---|
| **Eco** | Fenômeno interagível (`EchoMemoryInteractable`, nó `FirstEcho`): disponível com a quest ativa; `revealed` ao ser observado. | Entidade do mundo com estado. |
| **Memória** | Registro do jogador. Origens previstas: Eco (`memory_id` exportado) e observações (`memory_fragment_discovered`). | Registro do jogador. |
| **Fragmento** | Memória cuja origem é uma observação (decisão #1). Pode futuramente compor uma memória maior — **composição não implementada**. | Memória com `source_type = observation`. |
| **Consequência** | Mudança narrativa aplicada ao mundo (`apply_consequence`). | `world.consequences` — **não é memória**. |

**Relação memória ↔ consequência:** hoje o `NarrativeController` transforma toda consequência
em "memória" — conveniência de implementação, sem regra de design. O contrato separa as duas.
Registrar uma memória **não** aplica consequência nem dispara reação (decisão #3); reações
ambientais continuam dependendo de consequências/regras narrativas explícitas.

| Item | Especificação |
|---|---|
| Campos mínimos | `echoes: { echo_id: { "status": "resolved" } }` · `memories: { memory_id: { "source_type": "echo"\|"observation", "source_id": String } }` |
| Eco | Só `resolved` é persistido; `dormant`/`available` são derivados (quest ativa). |
| Primeiro Eco | `echo.vardhelm.first` resolvido registra `memory.vardhelm.first_echo` (`source_type: echo`) — decisão #2. |
| Fragmentos | `memory.vardhelm.maintenance_board`, `.sealed_panel`, `.tool_rack` (`source_type: observation`). |
| Origem atual | `echo.revealed` (nó), `echo.memory_id` (não salvo), `WorldState.memories` (contém consequências). |
| Migração | Consequência conhecida em `world.memories` → `world.consequences`; memória conhecida → `memory.memories`; **desconhecido → quarentena** (nunca descartado). Eco resolvido ← consequência do Eco **ou** quest concluída (regra atual do slice). Observação descoberta → seu fragmento (decisão #1). |
| Fora agora | Composição de fragmentos, diário, categorias funcionais, ordenação temporal. |
| Não pertence | Título/texto/categoria (conteúdo + localização), painéis e timers, consequências. |
| Riscos | Ligar esse registro ao runtime ativaria `react_to_memory`/`narrative_consequences` de observação, hoje inertes — por isso a decisão #3 exige que reação dependa de consequência explícita. |

### 3.7 NPCState

| Item | Especificação |
|---|---|
| Responsabilidade | Estado persistente por NPC que difere do padrão. |
| Contrato | `{ npc_id: { "interaction_enabled": bool } }` — espelha `NPCController.set_interaction_enabled`. |
| Mínimo agora | **Nenhum registro obrigatório.** Durn (`npc.vardhelm.durn`) só ganha registro se algo mudar seu padrão — hoje nada muda. |
| Futuro | `state_id`, flags por NPC, posição persistente — só quando um sistema os alterar. |
| Não pertence | `display_name`, material, placa de nome, IA, relacionamento, afinidade, máquina de estados, histórico de diálogo (→ DialogueState), NPCs ambientais. |

### 3.8 ProgressionState

Não existe nesta versão. O nome `progression` é **reservado**: `GameState.validate_dict`
rejeita a seção enquanto `state_version = 1`. XP, nível, skills e atributos dependem de
design; o TypeScript (`ProgressionManager`, `SkillTreeEngine`) segue como referência. A
entrada futura é feita incrementando `state_version` com migração.

---

## 4. Catálogo de IDs

**Regra de entidades:** `kind.scope.name` — minúsculas, `snake_case` por segmento, separados
por ponto. `kind` ∈ {`scenario`, `npc`, `dialogue`, `quest`, `echo`, `memory`, `consequence`,
`observation`, `envstate`, `area`, `flag`}. `scope` = cenário (`vardhelm`) ou `global`
(não se usa `aetheris` como escopo, para não confundir mundo, título e `WorldState`).

**Sub-IDs locais** ao pai, sem prefixo: entrada (`start`, `memory`, `end`), escolha
(`learn`, `leave`), objetivo (`observe`).

**Localização:** `<entity_id>.<campo>` (ex.: `npc.vardhelm.durn.name`). **Nome de nó** é
apresentação e nunca é ID.

| Tipo | Atual (A0) | Canônico | Observação |
|---|---|---|---|
| Scenario | *(implícito)* | `scenario.vardhelm` | — |
| NPC | `vardhelm.durn` / nó `Durn` / `npc.vardhelm.elder.name` | `npc.vardhelm.durn`; nome `npc.vardhelm.durn.name` | Decisão #7: a chave `elder` não é identidade. |
| Dialogue | `vardhelm_intro` | `dialogue.vardhelm.intro` | — |
| Quest | `vardhelm_first_echo` | `quest.vardhelm.first_echo` | Hoje repetido em 3 lugares. |
| Echo | *(sem ID; nó `FirstEcho`)* | `echo.vardhelm.first` | Novo. |
| Memory | `vardhelm_first_echo_memory`, `vardhelm_memory_{maintenance_board,sealed_panel,tool_rack}` | `memory.vardhelm.first_echo`, `memory.vardhelm.{maintenance_board,sealed_panel,tool_rack}` | — |
| Consequence | `vardhelm_heard_echo`, `vardhelm_first_echo_complete` | `consequence.vardhelm.heard_echo`, `consequence.vardhelm.first_echo_complete` | `first_echo_complete` aparece em 5 lugares. |
| Observation | `maintenance_board`, `sealed_panel`, `tool_rack` | `observation.vardhelm.{…}` | Colide com IDs de `story_props`. |
| Env. state | `echo_awakened`, `*_remembered` | `envstate.vardhelm.{…}` | Derivado. |
| Flag | IDs de consequência e `observation_<id>_seen` | `flag.vardhelm.{…}` (futuro) | Mantidas com nomes atuais. |
| Area | *(nenhuma formal)* | `area.vardhelm.forge_01` (quando existir) | Reservado. |

**Transição:** tabela de aliases (atual → canônico) como dado, permitindo ler conteúdo e saves
antigos sem renomear. Renomeação física é passo separado, com migração.

---

## 5. Riscos

| Risco | Nível | Evidência |
|---|---|---|
| Separar memória de consequência quebra a restauração do ambiente e o painel de status | **ALTO** | `_refresh_persistent_world_state` percorre `memories`; `_on_consequence_applied` exibe "Memória registrada: <consequence_id>". |
| Registrar memórias ativaria reações hoje inertes | **MÉDIO** | 0 conexões em `memory_fragment_discovered`; mitigado pela decisão #3. |
| Posição livre restaurada em nível alterado | **MÉDIO** | Hash do LevelBuilder dessincronizado (A0). |
| Tipagem JSON repetindo o bug do Load | **ALTO** se ignorado | `save_service.gd:44`; regra R2. |
| Flags de compatibilidade viram fonte dupla de verdade | **MÉDIO** | Observações e consequências espelhadas em flags. |
| Renomear IDs sem aliases quebra JSON, localização, testes e saves | **ALTO** | IDs espalhados (A0). |
| "Diálogo concluído" registrado indevidamente | **BAIXO** | `dialogue_finished` em `end_dialogue()`/reinício. |
| Testes antigos codificam o modelo antigo e parte não roda | **MÉDIO** | A0: 3/9 passam; 3 não executáveis. |

---

## 6. Classes de dado (resumo R1)

| Persistente (GameState) | Derivado (nunca salvo) | Transitório (nunca salvo) |
|---|---|---|
| localização do jogador; flags; values; consequências; observações; quests; diálogos concluídos e última escolha; Ecos resolvidos; memórias; diferenças de NPC | `environment_states`; Eco disponível/dormente; `revealed` do Eco e das observações; texto pós-Eco; texto de objetivo; banner de conclusão | sessão/entrada de diálogo; candidato de interação; painéis, timers, tweens; áudio; trabalhadores ambientais; câmera; input |

---

## 7. Decisões humanas aprovadas (canonizadas para o A2)

1. **Fragmento × memória.** Observações ambientais produzem **fragmentos de memória**
   (`source_type = observation`). Fragmentos podem futuramente compor uma memória maior;
   **composição não implementada** — o contrato só permite identificar a origem.
2. **Primeiro Eco.** Gera/registra uma memória real: `vardhelm_first_echo_memory`
   (canônico `memory.vardhelm.first_echo`). **Não ligado ao Save/Load nesta etapa** — só
   contrato, projeção e migração.
3. **Reações de memória.** Registrar memória **não** ativa reação do mundo. Reações ambientais
   continuam dependendo de consequências/regras narrativas explícitas. Memória registrada não
   vira consequência.
4. **Consequência `first_echo_complete`.** A fonte narrativa de `vardhelm_first_echo_complete`
   é o **Eco**. A Quest registra progresso/conclusão, mas não duplica a aplicação;
   `completion_consequence` permanece como contrato de conteúdo sem segunda aplicação.
5. **Posição do jogador.** O Save futuro preserva **posição e rotação exatas**. Sem
   checkpoint/spawn. `scenario_id` existe no contrato; sem áreas formais.
6. **Escolhas de diálogo.** Por ponto de decisão (`dialogue_id + entry_id`), no máximo uma
   escolha persistida — a **última** realizada. Sem histórico completo.
7. **Durn.** Identidade canônica `npc.vardhelm.durn`; nome exibido é dado/localização
   `npc.vardhelm.durn.name`. `npc.vardhelm.elder.name` **não** é identidade. Sem renomear
   conteúdo agora; aliases tratados separadamente.
8. **Idioma.** Não pertence ao GameState; é configuração da instalação/sessão, tratada no
   envelope/configuração do Save em etapa posterior.

---

## 8. Pendências

**Técnicas (engenharia, sem mudar a experiência):**
- Dono do GameState em runtime (autoload × objeto do slice).
- Prazo de remoção dos espelhos de flag (observação/consequência).
- Momento da renomeação física com aliases.
- Local definitivo do catálogo de IDs (hoje `godot/scripts/state/id_catalog.gd`).

**Ainda dependentes de design (fora do escopo A1/A2):** progressão, combate, inventário,
economia, party, raça mecânica, equipamento, exploração global, semântica da Estafa,
composição de fragmentos, diário de memórias.

---

## 9. Implementação do contrato (Bloco A2)

Contratos GDScript puros em `godot/scripts/state/`, **não ligados** ao `SaveService`, ao
`VardhelmVerticalSlice` nem a qualquer controlador existente.

> **Nomes de classe:** `WorldState` e `QuestState` já são `class_name` globais do runtime
> (`scripts/narrative/world_state.gd`, `scripts/quest/quest_state.gd`). Para não colidir, os
> contratos usam o prefixo `Game`.

| Conceito A1 | Classe | Arquivo |
|---|---|---|
| GameState | `GameState` | `godot/scripts/state/game_state.gd` |
| PlayerState | `GamePlayerState` | `godot/scripts/state/game_player_state.gd` |
| WorldState | `GameWorldState` | `godot/scripts/state/game_world_state.gd` |
| QuestState | `GameQuestState` | `godot/scripts/state/game_quest_state.gd` |
| DialogueState | `GameDialogueState` | `godot/scripts/state/game_dialogue_state.gd` |
| MemoryState | `GameMemoryState` | `godot/scripts/state/game_memory_state.gd` |
| NPCState | `GameNPCState` | `godot/scripts/state/game_npc_state.gd` |
| Serialização R2 | `GameStateSerde` | `godot/scripts/state/game_state_serde.gd` |
| Catálogo/aliases | `GameIdCatalog` | `godot/scripts/state/id_catalog.gd` |
| Projetor (somente leitura) | `GameStateProjector` | `godot/scripts/state/game_state_projector.gd` |
| Migração preparatória | `GameStateMigrator` | `godot/scripts/state/game_state_migrator.gd` |
| Resultado da migração | `GameStateMigrationResult` | `godot/scripts/state/game_state_migration_result.gd` |

Cada estado oferece propriedades com valores padrão, `to_dict()`, `from_dict()` (conversão
explícita, tolerante a entradas malformadas) e `validate()`/`validate_dict()` (validação
estrutural estrita, sem erro de script diante de tipos inesperados).

**Testes:** `godot/tests/state/` com runner próprio (não altera os testes antigos):

```
godot --headless --path godot --script res://tests/state/state_test_runner.gd
```
