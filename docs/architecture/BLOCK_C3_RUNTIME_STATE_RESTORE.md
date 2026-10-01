# ECHOES OF THE SOUL — BLOCO C3: RUNTIME STATE RESTORE / LOAD DIAGNOSTIC

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C1](BLOCK_C1_SAVE_V2_SHADOW.md) · [C2](BLOCK_C2_DUAL_SAVE_SHADOW.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Código:** `godot/scripts/save_v2/game_state_runtime_restorer.gd`, `restore_plan.gd`, `restore_result.gd`, `runtime_restore_targets.gd`

---

> **Atualização C4** ([BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md](BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md)):
> - `GameStateRuntimeRestorer.new(registry)` aceita um `RuntimeRestoreAdapterRegistry`; **sem registry
>   o comportamento é exatamente o descrito aqui** (as classificações `requires_adapter` do C3 valem).
> - Novo status `adapter-supported` no `RestorePlan`; com `create_default()` o fluxo real passa de
>   13 supported · 10 requires_adapter · 0 · 1 para **13 supported · 8 adapter-supported · 2 requires_adapter (só diálogo)** · 0 · 1.
> - Ordem de passos refinada: `scenario → player → world → consequences → observations → quests →
>   echo → memory → npcs → dialogue → presentation → progression` (o passo `world` agora cobre só
>   flags/values; consequências e observações ganharam passos próprios). A §16 abaixo descreve a
>   ordem original do C3.

## 1. Objetivo

Responder, com evidência:

1. Com um GameState válido vindo do Save V2, **quais dados do runtime atual conseguimos reconstruir?**
2. **Quais dados ainda não têm destino claro?**

A restauração existe só para **diagnóstico, testes e sandbox**. Não é o load operacional: Ctrl+L
continua sendo o load antigo, o `SaveService` não foi alterado e o GameState continua sombra.

```
GameState ─► GameStateRuntimeRestorer ─┬─► MODE 1 DIAGNOSTIC: RestorePlan (nenhuma mutação)
                                       └─► MODE 2 SANDBOX:    aplica em alvos sandbox ─► RestoreResult
                                                               └─► runtime → Projector → comparação
```

O restaurador **não** está acoplado ao `SaveV2Service` (recebe um GameState qualquer), não conhece
a cena, UI, eventos nem o SaveService, e não publica eventos (`restore_*` não existem neste bloco).

## 2. RestorePlan

Um item por campo do GameState: `step`, `source_path`, `destination`, `action` (`restore` /
`verify` / `not_applied`), `status` (`supported` / `requires_adapter` / `unsupported` /
`not_implemented`) e `note`. Nenhum campo é omitido; itens estruturais sempre presentes:
`state_version`, cenário, posição, rotação, `environment_states` derivado, NPCs sem registro,
`progression`.

## 3. RestoreResult

`success`, `partial_failure`, `completed_steps`, `applied`, `requires_adapter`, `unsupported`,
`not_implemented`, `warnings`, `errors` e `differences` (comparação runtime restaurado × GameState).
JSON-safe; nunca apenas um bool.

## 4. Matriz de campos

Ver [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md). Regra: o
restaurador escreve **somente nas representações que o runtime já possui**; não cria
armazenamento paralelo nem inventa destino.

## 5–11. Por seção

- **Player (supported):** `scenario_id` é verificado (cena única, sem troca de cenário no
  runtime); posição e rotação vão para `Player.global_position`/`global_rotation`. Nenhum atributo
  novo. No sandbox o Player é congelado (`set_physics_process(false)`) para não haver gravidade na
  comparação.
- **World (supported):** flags → `WorldState.flags`; values → `WorldState.values`; consequências →
  flag legada + entrada legada em `WorldState.memories` (é exatamente o que o
  `NarrativeController.apply_consequence` faz); observações → flag `observation_<id>_seen` + value
  `observation.<id>.seen` (o que o slice faz). `WorldState.memories` é preenchido item a item — nunca
  por atribuição direta de Array (o bug do load antigo). A fonte da consequência e o estado de nó
  das observações são `requires_adapter`.
- **Quests (supported):** status → `QuestState.active`/`completed`; objetivos →
  `QuestState.objective_progress`. Sem reward, sem histórico. A apresentação dependente (Eco
  interativo, marcador, painel de objetivo) é `requires_adapter`.
- **Dialogue (requires_adapter):** `dialogue.completed` e `dialogue.choices` não têm persistência
  equivalente no runtime; nada é forçado.
- **Memory (requires_adapter):** o runtime não armazena memórias recuperadas nem fragmentos, e o
  estado do Eco é derivado. O restaurador não injeta memórias no `WorldState` (isso misturaria memória
  e consequência). Com flags/quests restauradas, o **projetor** reproduz Eco, memória do Primeiro Eco
  e fragmentos com a origem correta — sem composição.
- **NPC (supported):** `NPCController.set_interaction_enabled`; ausência de registro = padrão
  (`true`). Sem IA, sem posição persistente.
- **Progression (not_implemented):** reservado.

## 12–14. Classificação no fluxo real de Vardhelm

| Status | Itens (GameState do fluxo real) |
|---|---|
| **supported (13)** | state_version, scenario_id, position, rotation, 3 flags, 2 consequências, 1 observação, status e objetivo da quest, NPCs sem registro |
| **requires_adapter (10)** | fonte das 2 consequências, estado de nó da observação, `environment_states`, apresentação da quest, Eco, memória do Primeiro Eco, fragmento `maintenance_board`, `dialogue.completed`, `dialogue.choices` |
| **unsupported (0)** | nenhum no fluxo real (testado com IDs sem alias: quest, consequência, observação e NPC) |
| **not_implemented (1)** | `progression` |

## 15. Diagnóstico

`diagnose(state)` não recebe alvos e não muta nada (GameState e runtime verificados intactos).

## 16. Sandbox

`apply_to_sandbox(state, targets)`:

- recusa alvos que não estejam marcados `is_sandbox` (o jogo principal nunca é tocado — testado);
- pré-checagem (GameState válido, Player/WorldState/QuestState presentes, Player na árvore) antes
  de qualquer mutação;
- aplica na ordem `scenario → player → world → quests → memory → npcs → dialogue → progression`
  (memory/dialogue/progression não aplicam nada; cenário primeiro porque um GameState de outro
  cenário é recusado antes de qualquer escrita);
- falha no meio → `partial_failure = true`, passos concluídos listados e aviso para **descartar o
  sandbox** (sem rollback no runtime principal). Testado com uma falha injetada
  (`fault_injection_step`, seam de teste).

No teste real, o sandbox é uma **segunda instância da cena de Vardhelm**, isolada do jogo principal.

## 17. Comparação

`Runtime restaurado → GameStateProjector → GameStateProjected` × `Save V2 → GameStateLoaded`
(`GameStateComparator`). Resultado no fluxo real:

- **0 diferenças de valor, 0 IDs inesperados**, nada extra no runtime;
- ausentes no runtime: somente `dialogue.completed` e `dialogue.choices` (requires_adapter);
- o que o V2 restaurou no sandbox coincide com o que o load antigo deixou no jogo principal em
  flags e quests; `WorldState.memories` tem os mesmos itens, em outra ordem (§18);
- a apresentação do sandbox **não** é reaplicada (Eco segue oculto, painel de objetivo inicial) —
  evidência concreta do `requires_adapter` de apresentação;
- a restauração não publica eventos e o GameState carregado não é alterado.

Achado de teste: um GameState **sem** a flag espelho de uma observação faz o restaurador escrever
a representação completa do runtime; a comparação **reporta** a flag extra em vez de escondê-la.

## 18. Limitações

- Ordem de `WorldState.memories` não é preservada: o GameState não guarda ordem de consequências e
  o arquivo canônico do V2 ordena chaves. O comportamento atual não depende dessa ordem (o
  AmbientLife reaplica cada item de forma independente).
- Apresentação (Eco, objetivo, marcador, estados de ambiente, nós de observação) não é reaplicada.
- O projetor não lê NPCs; o estado de NPC é verificado diretamente no alvo.
- A fonte das consequências não tem destino no runtime (reconstruída pelo catálogo).
- `fault_injection_step` é um seam de teste.

## 19. O que ainda não é operacional

- Ctrl+L continua sendo o load antigo (com o bug de `save_service.gd:44`); o restaurador não está
  ligado a ele nem ao `SaveV2ShadowCoordinator`.
- Nenhuma restauração é aplicada ao jogo principal; GameState continua sombra.
- Sem adapters de diálogo, memória, Eco e apresentação; sem eventos `restore_*`.
