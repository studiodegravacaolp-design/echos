# ECHOES OF THE SOUL — BLOCO C5: RUNTIME CONTRACT HARDENING + DIALOGUE RESTORE CONTRACT

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C3](BLOCK_C3_RUNTIME_STATE_RESTORE.md) · [C4](BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_runtime_contracts.gd`, `test_runtime_contracts_vardhelm.gd`

---

## 1. Objetivo

Fechar os dois contratos que ainda impediam uma futura restauração V2 limpa:

```
GameState ─► RestorePlan ─► Restore Adapters ─► Runtime Contract ─► runtime atual
                                                 ├─ DialogueRuntimeState
                                                 └─ RuntimeStateDerivationContract (Vardhelm: VardhelmRuntimeStateProvider)
```

Tudo continua só em diagnóstico e sandbox. O Ctrl+L continua usando o load antigo, o GameState
continua sombra e nenhum gameplay consulta os contratos novos.

## 2. Dialogue Runtime Contract

`godot/scripts/dialogue/dialogue_runtime_state.gd` — `DialogueRuntimeState` (RefCounted).

| Pergunta | Resposta do contrato |
|---|---|
| 1. o diálogo já foi concluído? | `is_completed(dialogue_id)` |
| 2. qual a última escolha deste ponto? | `last_choice(dialogue_id, entry_id)` → `choice_id` ("" = nenhuma) |
| 3. é possível restaurar? | `can_restore_completed(DialogueData)`, `can_restore_choice(DialogueData, entry_id, choice_id)` — só se a entrada e a escolha existem na definição |
| 4. o que é transiente? | `TRANSIENT_FIELDS` (abaixo) — nunca persistido, nunca restaurado |

**Dono:** `DialogueController.persistent_state`. O controlador registra a escolha quando
`select_choice` aceita uma escolha válida, e a conclusão imediatamente antes de cada
`dialogue_finished` — a mesma regra do evento `dialogue_completed` do B1, inclusive para
`end_dialogue`. São 7 linhas aditivas no controlador. Nada lê esse estado durante o gameplay:
o comportamento do diálogo é idêntico.

**Identidade:** `dialogue_id` + `entry_id` + `choice_id`. O runtime usa os IDs do `DialogueData`
(`vardhelm_intro`); o GameState usa o ID canônico (`dialogue.vardhelm.intro`), convertido pelo
`GameIdCatalog`. Texto, falante, rótulo e índice visual da escolha nunca são chave. Isso foi
testado alterando texto, falante e rótulos e invertendo a ordem das escolhas: o estado persistente
ficou idêntico.

**Última escolha:** uma por `dialogue_id + entry_id` (decisão A1). Não há histórico, timestamps
nem estado de UI.

### Persistente × transiente

| PERSISTENTE (GameState + DialogueRuntimeState) | TRANSIENTE (nunca persistido/restaurado) |
|---|---|
| `dialogue.completed` | sessão atual (`DialogueController.current_session`) |
| `dialogue.choices` (última escolha por entry) | entrada atual, escolha da sessão aberta |
| | escolhas visíveis, falante exibido, texto, animação |
| | visibilidade da `DialogueBox` |

Testado: com uma sessão aberta, nada disso aparece no GameState nem no `DialogueRuntimeState`. A
conversa em andamento não conta como concluída. A restauração não toca na sessão aberta, e no
sandbox a conversa não é reaberta e a caixa continua oculta.

### DialogueRestoreAdapter

- Diagnóstico: um diálogo com alias no catálogo vira **adapter-supported**, com destino em
  `DialogueRuntimeState`. Sem alias, vira **unsupported**.
- Aplicação: substitui o estado persistente do sandbox (ausência = padrão) e verifica
  `is_completed` e `last_choice`.
- Limites explícitos, sem mascarar:
  - sandbox sem destino (`dialogue_state = null`) → **requires_adapter** com motivo;
  - sem definição do diálogo → **requires_adapter**;
  - `entry_id`/`choice_id` inexistente na definição → **unsupported** (não é inventado).

## 3. Runtime Derivation Contract

`godot/scripts/save_v2/runtime_state_derivation_contract.gd` — `RuntimeStateDerivationContract`.
Tem só os métodos que os adapters usam:

| Área | Métodos |
|---|---|
| observação | `observation_ids()`, `derive_observation_state(id, discovered)`, `describe_observation(id)` → `{revealed, fragment_registered}` |
| Eco | `echo_ids()`, `derive_echo_state()`, `describe_echo(id)` → `{revealed, interaction_enabled}` |
| apresentação da quest | `derive_quest_presentation()`, `describe_quest_presentation(quest_id)` → `{completion_presented}` |
| ambiente | `derive_environment_state()`, `environment_state_ids()` (IDs canônicos) |

- A implementação padrão não deriva nada: devolve `false`/vazio, e o adapter reporta
  requires_adapter.
- O contrato não é um GameState: não guarda estado, cópias nem cache. A identidade é sempre o ID
  canônico, nunca NodePath ou referência de nó.
- **Memória e consequência não têm métodos**: derivam de WorldState/QuestState pelo
  `GameStateProjector` + `GameIdCatalog`, contratos que já existiam. Com isso se mantêm
  `consequence ≠ memory`, o fragmento continua fragmento e a fonte da consequência continua
  validada pelo catálogo.

**`RuntimeRestoreTargets`** não tem mais nenhum Callable nem referência a nós da experiência.
Foram removidos `echo_state_refresher`, `quest_presentation_refresher`, `environment_refresher`,
`ambient_life`, `observations` e `echoes`. Entraram `derivations`, `dialogue_state` e
`dialogue_definitions`.

## 4. Vardhelm provider

`godot/scripts/vardhelm/vardhelm_runtime_state_provider.gd` — `VardhelmRuntimeStateProvider`
estende o contrato. É o único ponto que conhece nós, caminhos
(`AmbientLife/EnvironmentalObservations`), AmbientLife e apresentação do Vardhelm.
`build_targets()` monta os alvos, mas **não** os declara sandbox: quem chama decide.

- **Derivações pela superfície pública do slice.** O provider chama `derive_echo_state()`,
  `derive_quest_presentation()` e `derive_environment_state()`, três métodos públicos novos do
  `VardhelmVerticalSlice` (+12 linhas aditivas). Eles só delegam às derivações existentes
  (`_apply_loaded_visual_state`, `_refresh_objective_text`, `_refresh_persistent_world_state`), que
  continuam privadas e continuam sendo as mesmas do load antigo, sem lógica duplicada.
- **Dependência circular:** não há. O Save V2 depende do contrato, e o Vardhelm depende do contrato
  e do slice.
- **Prova de ausência de dependência privada.** Um teste varre o código de `scripts/save_v2/` e
  `scripts/state/`, ignorando comentários, e falha se encontrar:
  - `VardhelmVerticalSlice`, `VardhelmAmbientLife`, `AmbientLife/`;
  - `EnvironmentalObservation`, `EchoMemoryInteractable`, `get_node`, `Callable(`;
  - os métodos privados de derivação.

  Também falha se o provider acessar `_slice._*`. O próprio detector é testado contra o padrão do
  C4 e o reprova.

## 5. Adapters (estado C5)

| Adapter | Passa por |
|---|---|
| Consequence | WorldState + `GameIdCatalog` (sem mudança) |
| Observation | `derive_observation_state` / `describe_observation` |
| Echo | `derive_echo_state` / `describe_echo` |
| Memory | `GameStateProjector` (sem mudança) |
| Dialogue | `DialogueRuntimeState` (**novo**) |
| QuestPresentation | `derive_quest_presentation` / `describe_quest_presentation` (verifica conclusão apresentada) |
| EnvironmentPresentation | `derive_environment_state` / `environment_state_ids` |

- O registry não mudou: continua objeto comum, sem Autoload/singleton, com os mesmos 7 adapters na
  mesma ordem.
- `GameStateProjector.project(..., dialogue_state = null)`: com o parâmetro opcional, projeta
  também o diálogo; sem ele, o comportamento é o anterior. O coordenador C2 não passa diálogo, então
  suas comparações não mudam.

## 6. Resultados (fluxo real)

- **Plano:** 13 supported · **10 adapter-supported** · **0 requires_adapter** · 0 unsupported ·
  1 not_implemented. No C4 era 13 · 8 · 2 · 0 · 1.
- **Jogo principal:** o `DialogueController` registrou `vardhelm_intro` concluído e `start → learn`.
  A projeção desse destino é igual ao DialogueState do GameState sombra.
- **Sandbox** (GameState → RestorePlan → Adapter → Provider → Sandbox):
  - diálogo restaurado (concluído + última escolha);
  - conversa não reaberta;
  - Eco, observação, apresentação da quest, `echo_awakened`, memórias e consequências derivados.
- **Comparações:**
  - sandbox × GameState V2: **0 diferenças, 0 ausentes em ambos os lados, 0 IDs inesperados**, com
    o diálogo incluído;
  - GameState original (sombra) × GameState restaurado: **iguais**;
  - sandbox × jogo principal: estado funcional + diálogo idênticos, exceto o bug conhecido (§7).
- **Não mutação:** o runtime principal teve zero diferenças (incluindo diálogo, sessão e caixa de
  diálogo); nenhum evento novo; GameState sombra não substituído.

## 7. KNOWN GAMEPLAY BUG — esfera do Eco

`EchoMemoryInteractable` guarda `_visual`/`_light` no próprio `_ready`, antes de o slice criar os
nós `Visual`/`Light`. Consequência: ao vivo, o Eco resolvido **continua com a esfera visível**. A
derivação existente usada na restauração oculta a esfera.

- É um defeito de gameplay, separado da arquitetura de Save V2, e **não foi corrigido** no C5.
- `describe_echo` expõe só o estado funcional (`revealed`, `interaction_enabled`); a visibilidade da
  esfera fica fora do contrato.
- O teste registra a divergência explicitamente.

## 8. Por que o Ctrl+L ainda não foi alterado

1. O C5 é um bloco de contratos: nenhum bloco até aqui autorizou restauração no jogo principal.
2. O `SaveService` antigo não salva nem carrega o diálogo. Depois de um Ctrl+L antigo, o
   `DialogueRuntimeState` do jogo continua com o que a sessão registrou. Um load V2 operacional
   precisa decidir como conviver com isso.
3. O bug da esfera faria o estado carregado divergir do estado ao vivo. Isso precisa de decisão de
   gameplay antes.
4. Restaurar no jogo principal exige política de falha (sem rollback hoje; `partial_failure` só
   manda descartar o sandbox).

## 9. Limitações

- O `DialogueRuntimeState` não é salvo pelo `SaveService` antigo; só o GameState / Save V2 o
  preserva.
- `describe_quest_presentation` verifica apenas "conclusão apresentada". O texto do objetivo não
  entra no contrato, por ser UI.
- As derivações públicas do slice continuam específicas do Vardhelm, sem abstração por cenário além
  do provider.
- A ordem de `WorldState.memories` não é preservada (herdado do C3).
- Progression continua not_implemented.
