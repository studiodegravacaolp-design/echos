# ECHOES OF THE SOUL — BLOCO B1: EVENTOS ESTRUTURADOS (MODO NÃO INVASIVO)

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [A1](BLOCK_A1_CANONICAL_GAME_STATE.md) (contratos) · [A3](BLOCK_A3_SHADOW_GAME_STATE.md) (GameState em modo sombra)
> **Código:** `godot/scripts/events/` · **Branch:** `integration/godot-vardhelm`

---

## 1. Propósito

Descrever, como **eventos estruturados**, fatos que o gameplay de Vardhelm já produz — sem
controlar gameplay, sem substituir controladores, `WorldState` ou `GameState`.

```
GAMEPLAY ATUAL (sinais existentes)
      ↓
GameplayEventPublisher  ── publica ──►  GameEventBus  ── entrega ──►  GameStateShadowRecorder ──► GameState (sombra)
                                                     └─ entrega ──►  RecordedEvents (diagnóstico/testes)
```

A direção nunca se inverte: nada publicado no bus volta para o gameplay (testado: eventos
sintéticos no bus não alteram `WorldState`, `QuestState`, Eco, NPC nem UI).

### Componentes

| Componente | Arquivo | Responsabilidade | Conhece gameplay? |
|---|---|---|---|
| `GameEvent` | `scripts/events/game_event.gd` | Fato imutável e serializável. | Não |
| `GameEventCatalog` | `scripts/events/event_catalog.gd` | Tipos, schema e validação de payload. | Não |
| `GameEventBus` | `scripts/events/event_bus.gd` | `subscribe` / `unsubscribe` / `publish`; entrega FIFO. | Não |
| `GameplayEventPublisher` | `scripts/events/gameplay_event_publisher.gd` | Adaptador: sinais existentes → eventos com IDs canônicos. | **Sim (somente leitura)** |
| `RecordedEvents` | `scripts/events/recorded_events.gd` | Listener de diagnóstico (quantidade, tipo, ordem, payload). Sem UI. | Não |

**Nomes:** `Event` → `GameEvent`, `EventBus` → `GameEventBus`, `EventCatalog` →
`GameEventCatalog` (prefixo `Game`, mesmo padrão do A2, para evitar nomes globais genéricos).
O publisher é um componente a mais, não previsto na proposta: ele isola o conhecimento de
controladores fora do bus e do recorder.

---

## 2. Event (`GameEvent`)

| Campo | Tipo | Descrição |
|---|---|---|
| `event_id` | String | `evt-NNNNNN`, sequencial por bus (determinístico). |
| `event_type` | String | Tipo genérico do catálogo (ex.: `echo_triggered`). |
| `schema_version` | int | Versão do schema do tipo (hoje `1`). |
| `source` | String | Sistema de origem: `experience`, `dialogue`, `quest`, `narrative`, `echo`, `observation`, `npc`, `world`. |
| `payload` | Dictionary | Somente IDs estáveis e dados semânticos (JSON puro). |
| `tick` | int | Número de sequência do bus = ordem causal de publicação. |

- **Sem timestamp do sistema operacional**: nenhuma lógica depende de relógio.
- `to_dict()` produz JSON puro; sobrevive a `JSON.stringify` → `JSON.parse_string`.
- Payload **não aceita** Node, Resource, referência de cena, `Vector3` ou qualquer tipo não
  JSON; **não aceita** campos fora do schema (ex.: texto de UI).

### Imutabilidade (decisão)

- Campos são **somente leitura** (setters ignoram a escrita com aviso).
- `payload` **sempre devolve uma cópia profunda**; o evento guarda sua própria cópia do
  Dictionary publicado.
- Consequência: um listener pode alterar a cópia que recebeu, mas **nunca** o evento original
  nem o que os demais listeners recebem; alterar o Dictionary de origem depois de publicar
  também não afeta o evento (testado).
- Todos os listeners recebem **o mesmo objeto** `GameEvent` (identidade preservada para
  rastreio), protegido por essas regras.

---

## 3. EventBus (`GameEventBus`)

- Objeto de runtime (`RefCounted`) criado pela experiência: `VardhelmVerticalSlice.shadow_events`.
  **Não é Autoload nem singleton** — cada experiência cria o seu (projeto sem `[autoload]`).
- `subscribe(listener, tipos = [])` · `unsubscribe(listener)` · `publish(tipo, payload, source) -> GameEvent | null`.
- Um evento → vários listeners; inscrição opcionalmente filtrada por tipo.
- `publish` valida no catálogo; evento inválido é **rejeitado** (retorna `null`, não é numerado
  nem entregue, fica em `rejected`).
- **Entrega FIFO:** um evento publicado por um listener durante a entrega de outro só é entregue
  depois que o atual chega a todos os listeners — a ordem de publicação é a mesma para todos.
- Não conhece `DialogueController`, `QuestController`, `NarrativeController`, `SaveService`,
  UI, `AmbientLife`, `WorldState` nem `GameState` (verificado por varredura de código nos testes).

---

## 4. EventCatalog (`GameEventCatalog`)

Tipos são **genéricos**; IDs de entidades são **dados**. Não existe tipo por entidade
(`echo.vardhelm.first_triggered` é rejeitado).

| Tipo | Payload obrigatório | Opcional | Estado |
|---|---|---|---|
| `scenario_entered` | `scenario_id` | — | em uso |
| `dialogue_started` | `dialogue_id` | — | em uso |
| `dialogue_choice_selected` | `dialogue_id`, `entry_id`, `choice_id` | — | em uso |
| `dialogue_completed` | `dialogue_id` | — | em uso |
| `quest_started` | `quest_id` | — | em uso |
| `quest_progressed` | `quest_id`, `objective_id` | — | em uso |
| `quest_completed` | `quest_id` | — | em uso |
| `echo_triggered` | `echo_id` | — | em uso |
| `memory_recovered` | `memory_id`, `source_type`, `source_id` | — | em uso |
| `consequence_applied` | `consequence_id` | `source_type`, `source_id` | em uso |
| `observation_discovered` | `observation_id` | `memory_id` | em uso |
| `npc_state_changed` | `npc_id` | `interaction_enabled` | em uso (só em mudança real) |
| `world_state_changed` | `state_id` | — | em uso (só em mudança real) |
| `scenario_completed` | `scenario_id` | — | **preparado** — sem encerramento real no gameplay |
| `game_saved` | — | `slot_id` | em uso desde o C2 — publicado só pelo Save V2 sombra após sucesso |
| `game_loaded` | — | `slot_id` | em uso desde o C2 — publicado só pelo Save V2 sombra após sucesso |

Strings obrigatórias não podem ser vazias. `schema_version = 1` para todos os tipos.

---

## 5. Schema (exemplo)

```json
{
  "event_id": "evt-000011",
  "event_type": "echo_triggered",
  "schema_version": 1,
  "source": "echo",
  "tick": 11,
  "payload": { "echo_id": "echo.vardhelm.first" }
}
```

---

## 6. Payloads no Vardhelm (IDs canônicos)

IDs de entidade vêm do `GameIdCatalog` (canônicos, `kind.scope.name`). Sub-IDs locais do
diálogo e da quest (`start`, `learn`, `leave`, `observe`) seguem exatamente como no runtime.

| Fato do gameplay | Sinal existente observado | Evento e payload |
|---|---|---|
| Entrada no cenário | boot da experiência | `scenario_entered {scenario_id: scenario.vardhelm}` |
| Diálogo iniciado | `DialogueController.dialogue_started` | `dialogue_started {dialogue_id: dialogue.vardhelm.intro}` |
| Escolha | `DialogueBox.choice_requested` | `dialogue_choice_selected {dialogue_id, entry_id: start, choice_id: learn}` |
| Diálogo concluído | `DialogueController.dialogue_finished` | `dialogue_completed {dialogue_id}` |
| Quest iniciada | `QuestController.quest_started` | `quest_started {quest_id: quest.vardhelm.first_echo}` |
| Objetivo | `QuestController.objective_completed` | `quest_progressed {quest_id, objective_id: observe}` |
| Quest concluída | `QuestController.quest_completed` | `quest_completed {quest_id}` |
| Consequência | `NarrativeController.consequence_applied` | `consequence_applied {consequence_id, source_type, source_id}` (fonte pelo catálogo: `heard_echo`→diálogo, `first_echo_complete`→Eco) |
| Eco resolvido | `EchoMemoryInteractable.memory_revealed` | `echo_triggered {echo_id: echo.vardhelm.first}` + `memory_recovered {memory.vardhelm.first_echo, echo, echo.vardhelm.first}` |
| Observação descoberta | `EnvironmentalObservation.observation_revealed` | `observation_discovered {observation_id, memory_id}` |
| Fragmento de memória | `EnvironmentalObservation.memory_fragment_discovered` | `memory_recovered {memory_id, observation, observation_id}` |
| Reação do mundo | estado de `AmbientLife.environment_states` (sem sinal; verificado após a reação) | `world_state_changed {state_id: envstate.vardhelm.echo_awakened}` |
| Estado de NPC | `NPCController.interaction_enabled` (sem sinal; verificado nas fronteiras de evento e em `poll()`) | `npc_state_changed {npc_id: npc.vardhelm.durn, interaction_enabled}` |

**Uma vez por acontecimento:** reaplicar uma consequência já aplicada ou reexaminar uma
observação já descoberta **não** são fatos novos — não geram evento e ficam em
`GameplayEventPublisher.suppressed_repeats`. Escolhas e conclusões de diálogo repetidas **são**
fatos novos e geram evento (a última escolha substitui a anterior no GameState).

**IDs fora do catálogo:** o publisher não publica e registra em `diagnostics`. No fluxo real de
Vardhelm, `diagnostics`, `rejected` e `suppressed_repeats` ficam vazios.

---

## 7. Integração no VardhelmVerticalSlice

Aditiva em relação ao commit `a526cc4` (`+35 / −0` no total A3+B1):

- `_setup_shadow_game_state()` (antes de `_connect_systems()`): cria `GameEventBus`,
  `GameStateShadowRecorder` (inscrito no bus), `GameplayEventPublisher` (observadores dos sinais
  existentes) e publica `scenario_entered`.
- `_setup_shadow_world_observer()` (depois de `_connect_systems()`): observa as reações do mundo
  **após** o AmbientLife reagir à consequência — por isso `world_state_changed` aparece logo
  depois da consequência que o causou.

Nenhum controlador, sinal existente, `SaveService`, UI ou áudio foi alterado.

---

## 8. Ordem causal

### Ordem real do Primeiro Eco (uma interação com o Eco)

```
consequence_applied   (consequence.vardhelm.first_echo_complete, fonte: echo.vardhelm.first)
  ↓
world_state_changed   (envstate.vardhelm.echo_awakened — reação do AmbientLife)
  ↓
quest_progressed      (quest.vardhelm.first_echo / observe)
  ↓
quest_completed       (quest.vardhelm.first_echo)
  ↓
echo_triggered        (echo.vardhelm.first)
  ↓
memory_recovered      (memory.vardhelm.first_echo, fonte: echo)
```

**Diferença em relação à ordem proposta** (`echo_triggered → memory_recovered →
consequence_applied → quest_progressed → quest_completed`): no runtime atual, o slice aplica a
consequência e conclui a quest **dentro** do handler de interação do Eco, e só depois o Eco
emite `memory_revealed`. A ordem real foi registrada **sem forçar** e sem alterar o gameplay.

### Sequência real completa (Durn → escolha → diálogo → quest → Eco → observação)

```
evt-01 scenario_entered
evt-02 dialogue_started
evt-03 dialogue_choice_selected   (start / learn)
evt-04 consequence_applied        (heard_echo — consequência da escolha)
evt-05 dialogue_completed
evt-06 quest_started
evt-07 consequence_applied        (first_echo_complete)
evt-08 world_state_changed        (echo_awakened)
evt-09 quest_progressed
evt-10 quest_completed
evt-11 echo_triggered
evt-12 memory_recovered           (Primeiro Eco)
evt-13 observation_discovered     (maintenance_board)
evt-14 memory_recovered           (fragmento maintenance_board)
```

A sequência é determinística: duas execuções produzem eventos idênticos (tipos, ordem, IDs,
ticks e payloads). Save/load não gera eventos.

---

## 9. Relação com o GameState

- O `GameStateShadowRecorder` agora **consome eventos** (`attach(bus)` → `consume(event)`) e é o
  **único** que escreve no GameState. O bus não conhece o GameState; o publisher não conhece o
  recorder — **eventos** e **estado** permanecem separados.
- O recorder deixou de ouvir sinais diretamente (os observadores do A3 migraram para o
  publisher); não há caminho paralelo.
- Regras de aplicação preservadas do A3: consequência → `world.consequences` (nunca memórias) +
  espelho da flag legada; Eco → `memory.echoes`; memória → `memory.memories` com origem;
  observação → `world.observations` + espelho `observation_<id>_seen`; última escolha por ponto;
  quest concluída não aplica consequência.
- Tipos sem efeito no GameState: `dialogue_started` (sessão transitória), `world_state_changed`
  (estado de ambiente é derivado), `scenario_completed` (sem seção de cenário ainda),
  `game_saved`/`game_loaded` (Bloco C).
- A localização do jogador continua **amostrada** (não é evento).
- GameState **continua em modo sombra**: não é fonte de verdade.

---

## 10. Relação com o Projector

- O `GameStateProjector` **não publica eventos** e o recorder não recebe nada dele (testado:
  `published_count` e `consumed_event_ids` inalterados após projeção/comparação).
- Sombra (via eventos) × projeção no fluxo real: **0 diferenças, 0 IDs inesperados**; única
  divergência esperada continua sendo o `DialogueState` (invisível ao projetor).

---

## 11. Relação futura com o Save V2 (Bloco C)

- `game_saved` / `game_loaded`: reservados no B1; em uso desde o C2 (ver [BLOCK_C2_DUAL_SAVE_SHADOW.md](BLOCK_C2_DUAL_SAVE_SHADOW.md)).
- O `event_id`/`tick` sequencial permite, no futuro, registrar no envelope do save o último
  evento aplicado ao GameState (ponto de consistência), sem depender de relógio.
- O Save V2 deverá persistir o **estado** (GameState), não o fluxo de eventos (decisão do plano
  V1.1); eventos continuam sendo fatos transitórios da sessão.

---

## 12. O que ainda NÃO foi migrado

- GameState não é fonte de verdade; nenhum sistema lê o bus para decidir gameplay.
- `SaveService` intocado; bug de load (`save_service.gd:44`) permanece; save/load não gera eventos.
- Sem Save V2, SaveEnvelope, checksum ou cadeia de migração em produção.
- `WorldState`, `QuestState`, controladores, flags e memórias antigas continuam como estavam.
- UI, áudio e apresentação continuam ligados aos sinais originais (não ao bus).
- Sem encerramento real de cenário (`scenario_completed` só preparado).
- Estados sem sinal (NPC, ambiente) são detectados por verificação nas fronteiras de evento —
  não há sinal nativo para eles no runtime atual.
- Escolhas feitas fora da `DialogueBox` não seriam observadas (hoje não existe outro caminho).
