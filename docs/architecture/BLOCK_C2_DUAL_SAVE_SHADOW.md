# ECHOES OF THE SOUL — BLOCO C2: DUAL SAVE / DUAL LOAD EM MODO SOMBRA

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [A3](BLOCK_A3_SHADOW_GAME_STATE.md) · [B1](BLOCK_B1_STRUCTURED_EVENTS.md) · [C1](BLOCK_C1_SAVE_V2_SHADOW.md)
> **Código:** `godot/scripts/save_v2/save_v2_shadow_coordinator.gd` · **Testes:** `godot/tests/save_v2/test_save_v2_dual.gd`

---

## 1. Objetivo

Ligar o Save V2 ao fluxo **real** de Ctrl+S / Ctrl+L, em paralelo e em modo sombra. O
`SaveService` antigo continua sendo a **fonte operacional** do save/load; o Save V2 só observa,
grava o GameState sombra e compara.

```
Ctrl+S ─┬─► SaveService.save_game (antigo, operacional)
        └─► depois: SaveV2ShadowCoordinator.after_legacy_save()
                      └─► SaveV2Service.save_game_state(GameState sombra) ─► arquivo V2
                      └─► game_saved (somente se o V2 gravou com sucesso)

Ctrl+L ─┬─► SaveService.load_game (antigo, operacional; bug conhecido preservado)
        └─► depois: SaveV2ShadowCoordinator.after_legacy_load(...)
                      └─► SaveV2Service.load_game_state() ─► GameState carregado (cópia)
                      └─► game_loaded (somente se o V2 carregou com sucesso)
                      └─► comparar: V2 × runtime (pós-load antigo)  e  V2 × GameState sombra
```

## 2. Regra fundamental

- O resultado do jogo não muda: o estado carregado pelo V2 **nunca** restaura Player, WorldState,
  QuestState, DialogueController ou qualquer sistema.
- O GameState sombra **não** é substituído nem ressincronizado pelo load (V2 ou antigo).
- Nenhuma mudança de UI/status: o texto exibido continua sendo o do fluxo antigo.
- Falha do V2 nunca interrompe nem altera o save/load antigo — fica só no relatório, e o
  respectivo evento (`game_saved`/`game_loaded`) não é publicado.

## 3. Onde está ligado

`VardhelmVerticalSlice` (aditivo; total A3+B1+C2 = **+44 / −0** linhas vs `a526cc4`):

| Ponto | Mudança |
|---|---|
| Variável | `shadow_save_v2: SaveV2ShadowCoordinator` |
| `_setup_shadow_game_state()` | cria `SaveV2ShadowCoordinator.new(shadow_state, SaveV2Service.new(), shadow_events)` — caminho `user://echoes_of_the_soul_save_v2_shadow.json` |
| `_unhandled_input` — `save_game` | **depois** da chamada ao `SaveService` (e do status): `if shadow_save_v2 != null: shadow_save_v2.after_legacy_save()` |
| `_unhandled_input` — `load_game` | **depois** do load antigo (e do seu tratamento): `if shadow_save_v2 != null: shadow_save_v2.after_legacy_load(not loaded.is_empty(), world_state, quest_states)` |

Nenhuma linha existente foi removida ou alterada; `save_service.gd`, `project.godot` (InputMap)
e a UI estão intactos. O gancho reutiliza a mesma ação de input (`save_game` / `load_game`), sem
nó extra e sem Autoload, e roda sempre depois do fluxo antigo.

## 4. `SaveV2ShadowCoordinator`

Objeto de runtime (`RefCounted`) — não é Node, Autoload nem singleton; dono:
`VardhelmVerticalSlice.shadow_save_v2`.

- `after_legacy_save()`: amostra a posição do jogador no recorder, grava `recorder.game_state` no
  Save V2 (`slot_id` `shadow`) e publica `game_saved {slot_id}` se `ok`.
- `after_legacy_load(legacy_loaded, world_state, quest_state)`: carrega o Save V2; se `ok`, publica
  `game_loaded {slot_id}` e compara o estado carregado com:
  - **runtime** — projeção (`GameStateProjector`, somente leitura) do runtime **depois** do load antigo;
  - **sombra** — o GameState sombra atual.
- Relatórios JSON-safe em `last_save_report`, `last_load_report` e `reports` (últimos 20):
  resultado do V2 (`ok`, `code`, `message`), resultado do load antigo (`legacy_loaded`) e, no load,
  as duas comparações (diferenças, ausências de cada lado, IDs inesperados, resumo).

`GameStateShadowRecorder` ganhou só o getter somente leitura `tracked_player()`.

## 5. Eventos

`game_saved` e `game_loaded` deixaram de ser reservados no `GameEventCatalog`. São publicados
**somente** pelo coordenador e **somente** após sucesso real do V2 (arquivo gravado e verificado /
estado reconstruído e conferido), com payload `{slot_id}` e `source` `save_v2`. O recorder não
altera o GameState com eles. O `SaveService` antigo continua sem eventos.

## 6. Resultados observados

### Fluxo testado (input real: InputEventKey pela viewport)

Durn → escolha → diálogo → Primeiro Eco → **Ctrl+S** → observação (depois do save) → **Ctrl+L**.

| Verificação | Resultado |
|---|---|
| Runtime, UI e transform do jogador após Ctrl+S e após Ctrl+L | **idênticos** a um controle sem Save V2 |
| Save antigo gravado | sim (operacional) |
| Arquivo V2 | = GameState sombra do instante do Ctrl+S |
| Eventos | Ctrl+S → 1 `game_saved`; Ctrl+L → 1 `game_loaded` |
| Load antigo | retorna vazio (bug conhecido `save_service.gd:44`, preservado) — registrado como `legacy_loaded: false` |
| V2 × runtime pós-load antigo | 0 diferenças; só o DialogueState falta no runtime (invisível ao projetor) |
| V2 × sombra | detecta a observação feita **depois** do save (flag, `world.observations`, fragmento) — a sombra não é ressincronizada |

### Com frames reais (`Input.parse_input_event`)

Mesmo resultado, mais **uma** diferença esperada: `player.location.position.y` (0,094 → ≈0) —
o jogador ainda assentava por gravidade entre o Ctrl+S e o Ctrl+L; o load antigo aborta antes de
restaurar a posição e o V2, por desenho, não restaura nada.

### Falhas do V2

| Situação | Relatório | Evento | Fluxo antigo |
|---|---|---|---|
| Diretório do V2 impossível de criar | `IO_ERROR` | sem `game_saved` | "Jogo salvo." normalmente |
| Load sem arquivo V2 | `FILE_NOT_FOUND` | sem `game_loaded` | inalterado |
| Arquivo V2 corrompido | `CORRUPTED_DATA` | sem `game_loaded` | inalterado |

## 7. Testes

`godot/tests/save_v2/test_save_v2_dual.gd` (33 checks), no runner
`godot/tests/state/state_test_runner.gd` (total 700/700). O input é entregue pela viewport a
todas as experiências vivas na árvore; por isso cada cenário isola a sua instância, e o runner
passa a esperar um frame entre suítes (para liberar cenas de integração anteriores). O arquivo
real do SaveService, gravado pelo Ctrl+S, é salvo antes e restaurado depois; o V2 usa caminho
isolado.

## 8. Limitações e o que NÃO foi migrado

- O `SaveService` antigo continua operacional e com o bug de load; nada foi corrigido.
- O estado V2 carregado não é aplicado; o GameState sombra continua sombra.
- Relatórios ficam só em memória (sem UI, sem log em disco).
- O resultado do save antigo não é lido pelo gancho (evita alterar a linha existente); o
  relatório de save contém só o resultado do V2.
- Um slot (`shadow`); sem autosave; sem migração de saves antigos.
