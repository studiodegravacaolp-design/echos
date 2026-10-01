# ECHOES OF THE SOUL — BLOCO C7: V2 OPERATIONAL LOAD CONTROLADO + RUNTIME ROLLBACK

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C2](BLOCK_C2_DUAL_SAVE_SHADOW.md) · [C3](BLOCK_C3_RUNTIME_STATE_RESTORE.md) · [C4](BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md) · [C5](BLOCK_C5_RUNTIME_CONTRACT_HARDENING.md) · [C6](BLOCK_C6_V2_DIAGNOSTIC_LOAD.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_save_v2_operational_load.gd`, `test_save_v2_operational_load_vardhelm.gd`

> **Atualização C8:** o KNOWN GAMEPLAY BUG da esfera (§10) foi corrigido em `EchoMemoryInteractable`; ver [BLOCK_C8](BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md) §7.

---

## 1. Objetivo

O Load V2 deixa de ser só diagnóstico e passa a ser um **caminho operacional controlado**, com opt-in
explícito, rehearsal, snapshot e rollback. O Ctrl+L antigo continua existindo e continua sendo o
padrão.

```
Ctrl+L ─┬─ flag OFF (padrão) ─► load antigo (SaveService) — exatamente como antes
        └─ flag ON ─► SaveV2RuntimeLoadCoordinator (SEM fallback para o load antigo)
             arquivo ─► envelope ─► checksum ─► GameState ─► RestorePlan
             ─► REHEARSAL em sandbox (pipeline C6)            falha: nada tocado
             ─► SNAPSHOT transitório do runtime principal
             ─► REHEARSAL DO ROLLBACK (snapshot em sandbox)    falha: nada tocado
             ─► APPLY no runtime principal
             ─► VALIDAÇÃO pós-restore (persistente + funcional)
             ─► SUCCESS  |  ROLLBACK (snapshot ─► RestorePlan ─► adapters) + verificação
```

## 2. Feature flag

- `SaveV2OperationalConfig.enabled` corresponde a **SAVE_V2_OPERATIONAL_LOAD_ENABLED**, com padrão
  **false**.
- É um objeto local (`VardhelmVerticalSlice.save_v2_operational_config`). Não é Autoload, não lê
  `ProjectSettings` nem ambiente, e `project.godot` não foi alterado.
- **Arquivo lido:** o Save V2 que o **Ctrl+S já grava** em paralelo desde o C2
  (`user://echoes_of_the_soul_save_v2_shadow.json`). O save antigo nunca é lido, convertido,
  sobrescrito ou apagado pelo V2.
- **Flag OFF:** o Ctrl+L executa o load antigo, byte a byte igual ao código anterior (a linha
  original ficou intacta). O V2 não é chamado e nenhum sandbox é criado (testado).
- **Flag ON:** o Ctrl+L executa **somente** o V2 e marca o input como tratado. Se o V2 falhar, o
  runtime é preservado, a falha aparece no `status_label` e é registrada com `push_warning`. **Não há
  fallback para o load antigo**, para não mascarar corrupção.

## 3. SaveV2RuntimeLoadCoordinator

`godot/scripts/save_v2/save_v2_runtime_load_coordinator.gd`. É um objeto comum, criado a cada Ctrl+L.
Não conhece `SaveService`, a cena nem o EventBus, e não publica eventos.

| Etapa | Garantia |
|---|---|
| `flag` | OFF → DISABLED, nada executado |
| alvos | o runtime principal não pode ser sandbox e precisa ter Player (na árvore), WorldState e QuestState |
| `rehearsal` | `SaveV2DiagnosticCoordinator` (C6) inteiro em um sandbox novo: arquivo, envelope, checksum sobre o texto literal, GameState, plano sem `unsupported`/`requires_adapter`, adapters, verificação e comparação. **O jogo principal não é tocado** |
| `snapshot` | tirado **só depois** do rehearsal (§4) |
| `rollback_rehearsal` | o snapshot é restaurado em outro sandbox e precisa reproduzir o runtime atual com 0 diferenças; se não reproduzir, o load é recusado antes de qualquer escrita |
| `apply` | `GameStateRuntimeRestorer.apply_to_runtime` — **mesmo núcleo e mesmos adapters** do C3–C5, na ordem `scenario → player → world → consequences → observations → quests → echo → memory → npcs → dialogue → presentation → progression`. `progression` = not_implemented (reservado), não bloqueia |
| `post_restore` | persistente: projeção do runtime == GameState carregado (0 diferenças / ausentes / IDs inesperados). Funcional: estados derivados do runtime principal == rehearsal |

**Guarda no restaurador:**

- `apply_to_runtime` só aceita alvos que **não** são sandbox e têm `operational_load_authorized`.
  Essa autorização é concedida só pelo coordenador, depois dos dois rehearsals, e revogada ao
  terminar (sucesso ou rollback).
- `apply_to_sandbox` continua recusando o jogo principal.

**Depois de SUCCESS:** a experiência passa ao GameState sombra uma **cópia** do estado carregado.
Sem isso, o próximo Ctrl+S gravaria no V2 o progresso anterior ao load. Continua sendo sombra:
nenhum gameplay lê o GameState.

## 4. Snapshot (transitório)

`SaveV2RuntimeSnapshot` existe só durante a operação. Não é gravado (o código não usa arquivo nem
`user://`, e isso é testado), não é save do jogador e não substitui o GameState.

| Parte | Conteúdo |
|---|---|
| `state` | GameState projetado do runtime + NPCs + `scenario_id`. É o que o rollback restaura |
| `raw` | cópia exata de flags, values, memories (como conjunto), quests (active/completed/objective_progress), diálogo persistente e NPCs |
| player | posição e rotação |
| `functional` | observações, Ecos, apresentação da quest e estados de ambiente, lidos pelo `RuntimeStateDerivationContract` |

Não captura câmera, UI transitória, áudio, timers, animações, input, mouse nem efeitos.

**Runtime não representável → load recusado sem tocar em nada** (`RESTORE_REJECTED /
SNAPSHOT_NOT_REVERSIBLE`). Isso vale para dois casos, ambos testados:

- a projeção põe algo em quarentena (ex.: uma memória desconhecida em `WorldState.memories`);
- o rehearsal do rollback não reproduz o runtime. Exemplo: um estado derivado que não corresponde ao
  persistente, como uma observação marcada como vista cujo nó está "não revelado".

## 5. Rollback

```
falha no apply ou na validação ─► snapshot.state ─► RestorePlan ─► mesmos adapters (apply_to_runtime)
                               ─► snapshot.differences(runtime) == [] ─► ROLLBACK_SUCCESS
```

Não existe um segundo sistema de restauração. O rollback é verificado contra `raw`, player e
`functional` e exige 0 diferenças.

**Rollback failure:** o status passa a ser **ROLLBACK_FAILURE**. Ficam registradas a falha original
(`original_failure`) e a do rollback (`rollback_details`). Não há falso sucesso, o load antigo não é
chamado e o processo não é encerrado. O jogo mostra o status e registra o aviso. Nesse caso o estado
do runtime principal **não é confirmado**, e o relatório diz isso explicitamente.

## 6. Estados do resultado

| Status | Quando |
|---|---|
| DISABLED | flag OFF |
| SUCCESS | aplicado e validado |
| LOAD_FAILURE | arquivo inexistente ou E/S |
| VALIDATION_FAILURE | checksum, JSON, envelope, schema ou GameState inválido |
| RESTORE_REJECTED | recusado antes de tocar no jogo: ID desconhecido, plano incompleto, falha de adapter ou derivação no rehearsal, snapshot não reversível, alvo inválido |
| APPLY_FAILURE | falha durante o apply → rollback (`rollback_status = ROLLBACK_SUCCESS`) |
| POST_RESTORE_MISMATCH | aplicado, mas diferente do GameState ou do rehearsal → rollback |
| ROLLBACK_SUCCESS | registrado em `rollback_status` junto de APPLY_FAILURE ou POST_RESTORE_MISMATCH |
| ROLLBACK_FAILURE | o rollback falhou (vira o status; a falha original fica preservada) |

## 7. Derivações que precisam voltar atrás

Aplicar um save **anterior** ao estado atual (ex.: antes do Eco) exige que a apresentação derivada
também volte. As derivações existentes eram só aditivas. Com aprovação explícita, foi adicionado o
mínimo necessário, sempre aditivo e nunca chamado pelo gameplay:

- `VardhelmAmbientLife.reset_persistent_state()`: limpa `environment_states` e devolve ao padrão os
  rótulos que a marcação persistente altera. É a única exceção à regra "não alterar AmbientLife";
  efeitos temporários não são tocados.
- `VardhelmVerticalSlice.derive_environment_state()`: faz o reset e depois a derivação existente.
- `VardhelmVerticalSlice.derive_quest_presentation()`: sem quest concluída, oculta o banner de
  conclusão (como em `_start_intro_state`) antes da derivação existente.
- `QuestPresentationRestoreAdapter` agora deriva a apresentação mesmo quando o GameState não tem
  quest (caso "estado inicial"); antes retornava cedo.

## 8. Resultados com o Vardhelm real (Ctrl+L de verdade)

| Teste | Resultado |
|---|---|
| OP1 estado inicial → diálogo, quest, Eco, observação, posição → Ctrl+L | volta ao inicial (Eco, banner, ambiente, observações, diálogo, objetivo, posição); 0 diferenças |
| OP2 antes do Eco → Eco + 3 observações + mover → Ctrl+L | **exatamente** o estado antes do Eco, inclusive a esfera; quest ativa, sem memória do Eco nem fragmentos, só `heard_echo`, observações não descobertas, posição e rotação |
| OP3 depois do Eco → alterações deliberadas → Ctrl+L | estado do save (exceto a esfera, §10); diálogo (`learn`), NPC, quest, alteração desfeita, consequências sem duplicação, memory ≠ consequence |
| OP4 posição/rotação não padrão | restauradas |
| OP5 diálogo | `DialogueRuntimeState` restaurado; diálogo não aberto |
| OP6 runtime recriado | observações + fragmentos restaurados em uma instância nova |
| OP7 consequências | corretas, uma vez cada |
| OP8 checksum corrompido | VALIDATION_FAILURE/INVALID_CHECKSUM; runtime **exatamente igual**; sem fallback; falha mostrada |
| OP9 falha injetada no apply | APPLY_FAILURE + ROLLBACK_SUCCESS; runtime == snapshot |
| OP10 falha injetada no rollback | ROLLBACK_FAILURE com falha original registrada; sem falso sucesso; sem load antigo |
| OP11 flag OFF | V2 não chamado; o Ctrl+L de sempre roda (load antigo + comparação sombra do C2) |
| OP12 flag ON | V2 executado; o load antigo **não** executa |
| Isolamento | V2 em uma instância e Old Load em outra, sem mistura |
| Idempotência | Ctrl+L repetido dá o mesmo estado |
| Eventos | o Load V2 não publica nenhum evento; `restore_*` continuam fora do catálogo |

## 9. Old Save/Load = LEGACY COMPATIBILITY PATH

O `SaveService` e o Ctrl+L antigo continuam disponíveis, são o **padrão** e não foram alterados.
O bug de `save_service.gd:44` (atribuir `Array` a `WorldState.memories`) continua: o load antigo
aborta antes de quests e Player. Está registrado e **não foi corrigido**.

**Política de saves antigos:** não há migração nem conversão automática, e nenhum save antigo é
apagado ou sobrescrito. A política fica para um bloco posterior.

## 10. KNOWN GAMEPLAY BUG — esfera do Eco

Ao vivo, o Eco resolvido mantém a esfera visível. O Load V2 (e o rollback) aplicam a derivação
documentada, que oculta a esfera. Não há workaround para mascarar o bug. Consequências:

- depois do Eco, o estado carregado difere do estado ao vivo só na esfera;
- um rollback de um runtime com o bug não reproduz o estado "com bug", reproduz o estado funcional
  documentado.

## 11. Limitações

- Diálogo aberto no momento do Ctrl+L: a sessão transitória não é fechada nem restaurada.
- `describe_quest_presentation` verifica só "conclusão apresentada"; o texto do objetivo é UI.
- O contador "Memórias registradas" (UI) não é recalculado pelo Load V2.
- A ordem de `WorldState.memories` não é preservada (C3); a comparação usa conjunto.
- O custo do rehearsal (duas instâncias sandbox da cena por Ctrl+L) não foi medido em jogo.
- Um runtime internamente inconsistente não pode ser recarregado (recusa segura, §4).

## 12. Por que o V2 ainda não é o único caminho

1. A flag está OFF por padrão: o V2 é opt-in e o caminho legado continua sendo a referência do
   jogador.
2. Os saves antigos não têm política de migração; trocar o padrão os deixaria órfãos.
3. O Ctrl+S ainda grava o V2 a partir da sombra (C2); o V2 Save operacional não foi adotado.
4. O bug da esfera e o bug de `save_service.gd:44` precisam de decisão de gameplay antes de o V2 virar
   o padrão.

## 13. Estratégia de regressão (corrigida no C7)

Todos os entrypoints automatizados rodam **headless**, e só são executados scripts que o Godot aceita
como entrypoint (`extends SceneTree`/`MainLoop`). Nenhum código de gameplay nem teste legado foi
alterado para isso.

| Entrypoint | Como |
|---|---|
| suítes A2–C7 | `--headless --script res://tests/state/state_test_runner.gd` (SceneTree) |
| sonda A0 | `--headless --script` (SceneTree, cópia temporária) |
| cena principal | `--headless --quit-after 300` |
| legados `extends SceneTree` (6) | `--headless --script`, comparados com a linha de base: `environmental_interaction`, `interaction_foundation`, `npc_foundation` terminam; `dialogue_controller_foundation`, `dialogue_foundation`, `full_narrative_systems` falham em asserts/bug antigo e não chamam `quit()` (timeout), igual à linha de base |
| legados `extends Node` (3): `memory_echoes_test`, `narrative_consequence_test`, `world_response_test` | **não executáveis diretamente por esse método** — passados a `--script`, o Godot abre um alerta nativo ("doesn't inherit from SceneTree or MainLoop"), mesmo headless, e fica preso até o timeout. Não há runner para eles no projeto: **limitação conhecida** (desde o A0). Eles não foram convertidos nem alterados |

A oscilação "trava × recusa o script" registrada no C6 era esse alerta: o processo ficava bloqueado
nele até o timeout.
