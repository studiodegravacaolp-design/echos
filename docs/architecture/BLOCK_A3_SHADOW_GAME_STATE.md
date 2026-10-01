# ECHOES OF THE SOUL — BLOCO A3: GAMESTATE EM MODO SOMBRA

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [A1 — Canonização do Estado](BLOCK_A1_CANONICAL_GAME_STATE.md) (contratos do A2 em `godot/scripts/state/`)
> **Branch:** `integration/godot-vardhelm`

O GameState passa a **existir durante a execução** de Vardhelm, mas **não é fonte de
verdade**. O sistema atual continua decidindo tudo; o GameState apenas acompanha.

> **Atualização (Bloco B1):** o recorder não ouve mais sinais diretamente. Os sinais da §2
> agora são observados pelo `GameplayEventPublisher`, que publica eventos estruturados no
> `GameEventBus`; o `GameStateShadowRecorder` consome esses eventos e continua sendo o único
> que escreve no GameState, com as mesmas regras de registro. Ver
> [BLOCK_B1_STRUCTURED_EVENTS.md](BLOCK_B1_STRUCTURED_EVENTS.md).

```
Sistema atual  ->  comportamento atual  ->  atualização paralela  ->  GameState (sombra)
```

O fluxo nunca é invertido: nada do GameState é lido pelo gameplay, pela UI, pelo áudio ou
pelo Save/Load.

---

## 1. Onde o GameState nasce e quem possui a referência

| Item | Implementação |
|---|---|
| Dono | `GameStateShadowRecorder` (`godot/scripts/state/game_state_shadow_recorder.gd`) — objeto de runtime `RefCounted`. **Não é Autoload nem singleton.** |
| Onde nasce | `VardhelmVerticalSlice._setup_shadow_game_state()`, chamado em `_ready()` logo antes de `_connect_systems()`. |
| Referência | `VardhelmVerticalSlice.shadow_state` (variável da experiência). O GameState em si fica em `shadow_state.game_state`. |
| Ciclo de vida | criação da experiência → `GameStateShadowRecorder.new()` → Vardhelm → a experiência é liberada → a referência é liberada junto (as conexões de sinal ao recorder são desfeitas pelo engine). |
| Inicialização | `state_version = 1`, `player.location.scenario_id = scenario.vardhelm`; demais seções vazias. Determinístico (testado com dois boots). |
| Acesso | Somente por referência explícita: o slice passa ao recorder `player`, `dialogue_controller`, `dialogue_box`, `quest_controller`, `narrative_controller`, `echo`, `npc` e cada `EnvironmentalObservation`. Um único `get_node_or_null` (a raiz das observações, a mesma que o slice já usa). |

### Integração no VardhelmVerticalSlice (aditiva, não estrutural)

`git diff`: **22 inserções, 0 remoções** — 1 variável (`shadow_state`), 1 chamada em
`_ready()` e a função `_setup_shadow_game_state()`, que só cria o recorder e passa
referências. Nenhuma linha existente foi alterada ou movida; nenhuma lógica existente
foi transferida para o GameState.

A chamada fica **antes** de `_connect_systems()` por um único motivo: o runtime só aceita
escolhas de diálogo pela `DialogueBox.choice_requested`, e o slice avança a sessão no mesmo
instante. Conectado antes, o recorder lê a entrada em que a escolha foi feita. Os demais
observadores não dependem de ordem.

---

## 2. Quais sistemas atualizam o GameState e o que é registrado

Todos os gatilhos são **sinais que já existiam** no runtime. Nenhum controlador foi alterado.

| Evento do runtime | Sinal observado | Registro no GameState |
|---|---|---|
| Entrada no cenário | (boot do slice) | `player.location.scenario_id = scenario.vardhelm` |
| Diálogo iniciado | — | Nada persistente (sessão é transitória, A1 R1). O recorder só lê a sessão ativa no momento da escolha. |
| Escolha de diálogo | `DialogueBox.choice_requested` | `dialogue.choices[dialogue.vardhelm.intro][entry_id] = choice_id` — última escolha, sem histórico. Só registra escolhas que existem na entrada atual (mesma condição de `DialogueController.select_choice`). |
| Diálogo concluído | `DialogueController.dialogue_finished` | `dialogue.completed[dialogue.vardhelm.intro] = true` |
| Quest iniciada | `QuestController.quest_started` | `quests[quest.vardhelm.first_echo].status = active` |
| Objetivo concluído | `QuestController.objective_completed` | `quests[...].objectives[observe] = true` |
| Quest concluída | `QuestController.quest_completed` | `quests[...].status = completed`. **Não** aplica consequência (decisões #4/#5). |
| Consequência aplicada | `NarrativeController.consequence_applied` | `world.consequences[consequence.vardhelm.*] = {applied, source_type, source_id}` (fonte pelo catálogo) + espelho da flag legada de mesmo nome. **Nunca** em `memory.memories`. |
| Eco resolvido | `EchoMemoryInteractable.memory_revealed` | `memory.echoes[echo.vardhelm.first] = resolved` + `memory.memories[memory.vardhelm.first_echo] = {echo, echo.vardhelm.first}` (decisão #2). |
| Observação descoberta | `EnvironmentalObservation.observation_revealed` | `world.observations[observation.vardhelm.<id>] = {discovered}` + espelho da flag `observation_<id>_seen`. |
| Fragmento de memória | `EnvironmentalObservation.memory_fragment_discovered` (sinal que o runtime não conecta) | `memory.memories[memory.vardhelm.<id>] = {observation, observation.vardhelm.<id>}` — **sem consequência e sem reação** (decisões #1, #3, #12). |
| Localização do jogador | — (sem sinal) | **Amostrada** em `sync_sampled_state()`/`snapshot()`: `global_position`/`global_rotation`, os mesmos campos do SaveService. |
| Estado de NPC (Durn) | — (sem sinal) | **Amostrado**: `npcs[npc.vardhelm.durn]` só existe se a interação diferir do padrão. No fluxo atual, Durn nunca difere → nenhum registro. |

IDs do runtime são convertidos pelo `GameIdCatalog` (ex.: `vardhelm_intro` →
`dialogue.vardhelm.intro`, `vardhelm.durn` → `npc.vardhelm.durn`). ID fora do catálogo **não
entra** nas seções canônicas; vai para `shadow_state.diagnostics`. No fluxo real de Vardhelm,
`diagnostics` fica vazio.

### Flags como compatibilidade

As flags atuais do runtime permanecem intactas. No GameState sombra, `world.flags` espelha as
mesmas flags (consequência e observação) para que a comparação com o projetor seja fiel.
O espelho **não** foi removido neste bloco.

---

## 3. O que continua sendo fonte de verdade

| Dado | Fonte de verdade (inalterada) |
|---|---|
| Flags, values, memórias atuais | `NarrativeController.world_state` (`WorldState`) |
| Quests | `QuestController.states` (`QuestState`) |
| Diálogo | `DialogueController` / `DialogueSession` |
| Eco, observações, reações, UI, áudio | nós e controladores existentes do slice |
| Save/Load | `SaveService` (inalterado, **com o bug de load conhecido**) |

O GameState sombra não é lido por nenhum desses sistemas.

---

## 4. Projetor e detecção de divergências

- `shadow_state.compare_with_runtime(world_state, quest_state)` amostra a localização,
  projeta o runtime atual com `GameStateProjector` (somente leitura) e compara com
  `GameStateComparator.compare(sombra, projeção)`.
- `GameStateComparison` informa: **iguais** (`matching`), **diferenças** (`differences`,
  mesmo caminho com valores distintos), **campos ausentes** em cada lado
  (`missing_in_left`/`missing_in_right`) e **IDs inesperados** (`unexpected_ids` — qualquer ID
  fora do catálogo canônico, inclusive alias legado dentro do estado canônico).
- A comparação **não corrige, não mescla e não sobrescreve** nenhum dos lados.

### Resultado no fluxo real (Durn → escolha → diálogo → quest → Primeiro Eco → observação → save/load)

| Etapa | Iguais | Diferenças | Ausentes na sombra | Ausentes na projeção | IDs inesperados |
|---|---|---|---|---|---|
| boot | 14 | 0 | 0 | 0 | 0 |
| escolha `learn` | 15 | 0 | 0 | 1 (`dialogue.choices…`) | 0 |
| diálogo concluído | 15 | 0 | 0 | 2 (`dialogue.*`) | 0 |
| Primeiro Eco | 20 | 0 | 0 | 2 (`dialogue.*`) | 0 |
| observação | 23 | 0 | 0 | 2 (`dialogue.*`) | 0 |
| após save/load | 23 | 0 | 0 | 2 (`dialogue.*`) | 0 |

**Divergência esperada e única:** `dialogue.completed` e `dialogue.choices` existem só na
sombra, porque o runtime atual não guarda diálogo e o projetor não tem de onde lê-los.

---

## 5. Regressão (A0 × A3)

- A sonda de fluxo do A0, executada **sem alteração** contra o projeto com o A3, produz saída
  idêntica em 36 de 37 linhas. A única diferença é `obs.memory_signal_connections: 0 → 1`:
  é o próprio registro paralelo (o recorder escuta `memory_fragment_discovered` para
  alimentar só o GameState). Nenhum texto de UI, flag, memória, quest, reação ou resultado de
  Save/Load mudou.
- O `WorldState.memories` do runtime continua `["vardhelm_heard_echo",
  "vardhelm_first_echo_complete"]` — exatamente como no A0.
- Cena principal: 240 frames headless sem erro de script.

---

## 6. O que NÃO foi migrado ainda

- GameState **não** é fonte de verdade; nenhum sistema lê dele.
- **Save/Load não observado:** o GameState sombra não é salvo, não é carregado e não é
  ressincronizado após Ctrl+L. O bug de load (`save_service.gd:44`) permanece.
- Sem Save V2, SaveEnvelope, checksum ou cadeia de migração em produção.
- `WorldState`, `QuestState`, flags, memórias antigas e consequências antigas continuam onde
  estavam; o espelho de flags permanece.
- Sem diário, composição de fragmentos, categorias ou ordenação de memórias; sem UI nova.
- Sem Autoload; sem progressão, inventário, combate ou economia.
- Mudança de estado de NPC só é vista por amostragem (o `NPCController` não emite sinal).
- Escolhas de diálogo feitas fora da `DialogueBox` não seriam observadas — hoje não existe
  outro caminho no runtime.

---

## 7. Testes

Runner: `godot --headless --path godot --script res://tests/state/state_test_runner.gd`

| Suíte | Escopo |
|---|---|
| `test_shadow_recorder.gd` | Recorder e comparador isolados, com controladores reais fora da árvore. |
| `test_shadow_vardhelm.gd` | Cena real de Vardhelm, fluxo pelos caminhos do jogo (Interactable e botões da DialogueBox), sem Save/Load. |

Cobre os 20 itens do Bloco A3 (boot, cenário, última escolha, diálogo concluído, quest
ativa/concluída, Eco e memória, consequência fora de memórias, observação e fragmento,
memória sem consequência, Durn, independência de SaveService/SceneTree, projetor somente
leitura, detecção de divergências, determinismo e serialização).
