# ECHOES OF THE SOUL — MATRIZ DE RESTAURAÇÃO GameState → RUNTIME

> Fonte: `GameStateRuntimeRestorer.diagnose()` com `RuntimeRestoreAdapterRegistry.create_default()` (Blocos C3 + C4 + C5).
> Runtime = Vardhelm atual (Godot 4.7.1). Sem registry, o restaurador mantém a classificação do C3
> (as linhas "adapter-supported" voltam a ser "requires_adapter").
> Desde o C5 os adapters só usam contratos formais: `DialogueRuntimeState` e
> `RuntimeStateDerivationContract` (Vardhelm: `VardhelmRuntimeStateProvider`) — nenhum método privado do slice.
>
> Status: **supported** (núcleo restaura/verifica no runtime existente) · **adapter-supported** (um adapter
> reconstrói por um contrato formal) · **requires_adapter** (o runtime ainda não consegue consumir; a
> informação segue no GameState) · **unsupported** (sem destino) · **not_implemented** (reservado).

| Passo | GameState | Runtime | Status | Observação |
|---|---|---|---|---|
| scenario | `state_version` | contrato GameState (v1) | supported (verify) | só verificação |
| scenario | `player.location.scenario_id` | cena da experiência | supported (verify) | cenário único; não há troca de cenário no runtime |
| player | `player.location.position` | `Player.global_position` | supported | exata |
| player | `player.location.rotation` | `Player.global_rotation` | supported | equivalente (`is_equal_approx`) |
| world | `world.flags.<id>` | `WorldState.flags[<id>]` | supported | nomes atuais preservados |
| world | `world.values.<key>` | `WorldState.values[<key>]` | supported | |
| consequences | `world.consequences.<id>` | `WorldState.flags[<legacy>]` + `WorldState.memories[<legacy>]` | supported | representação existente do `NarrativeController.apply_consequence`; `ConsequenceRestoreAdapter` verifica que é reconhecida **uma única vez**; consequence ≠ memory; ordem de `memories` não preservada |
| consequences | `world.consequences.<id>.source_*` | `GameIdCatalog.CONSEQUENCE_SOURCES` | **adapter-supported** (verify) | runtime não guarda a fonte; derivável se == catálogo. Fonte divergente → **requires_adapter** |
| observations | `world.observations.<id>` | `WorldState.flags[observation_<legacy>_seen]` + `WorldState.values[observation.<legacy>.seen]` | supported | sem flag espelho no GameState a flag é reconstruída e aparece como diferença explícita |
| observations | `world.observations.<id>` (estado funcional) | `RuntimeStateDerivationContract.derive_observation_state` | **adapter-supported** | identidade = ID canônico (sem NodePath); mesmo estado que a interação deixa. Observação ausente no runtime → requires_adapter |
| quests | `quests.<id>.status` | `QuestState.active` / `QuestState.completed` | supported | ID legado via `GameIdCatalog` |
| quests | `quests.<id>.objectives.<obj>` | `QuestState.objective_progress[<legacy>][<obj>]` | supported | sem reward, sem histórico |
| echo | `memory.echoes.<id>` | `RuntimeStateDerivationContract.derive_echo_state` | **adapter-supported** (derive) | derivado + verificado (`revealed`/`interaction_enabled`); sem EchoState; esfera fora do contrato (KNOWN GAMEPLAY BUG). Sem consequência/quest → requires_adapter |
| memory | `memory.memories.<id>` (echo) | Eco resolvido (derivado de consequência/quest) | **adapter-supported** (derive) | sem armazenamento próprio; verificado pelo projetor; nunca em `WorldState.memories` |
| memory | `memory.memories.<id>` (observation / fragmento) | observação de origem | **adapter-supported** (derive) | fragmento continua fragmento, sem composição. Sem a observação → requires_adapter |
| npcs | `npcs.<id>.interaction_enabled` | `NPCController.set_interaction_enabled` | supported | núcleo C3 |
| npcs | `npcs` (sem registro) | `NPCController.set_interaction_enabled(true)` | supported | ausência = padrão |
| dialogue | `dialogue.completed.<id>` | `DialogueRuntimeState.completed[<legacy>]` (`DialogueController.persistent_state`) | **adapter-supported** (C5) | sem definição/destino no sandbox → requires_adapter; ID sem alias → unsupported |
| dialogue | `dialogue.choices.<d>.<entry>` | `DialogueRuntimeState.choices[<legacy>][<entry>]` (última escolha) | **adapter-supported** (C5) | identidade dialogue_id + entry_id + choice_id; entry/choice inexistente na definição → unsupported |
| — | *(transiente)* sessão, entrada atual, escolhas visíveis, falante, texto, animação, `DialogueBox` | — | fora do GameState | nunca persistido nem restaurado (`DialogueRuntimeState.TRANSIENT_FIELDS`) |
| presentation | `quests.<id>` (apresentação) | `RuntimeStateDerivationContract.derive_quest_presentation` | **adapter-supported** (derive) | verifica conclusão apresentada; texto/marcador/layout não persistidos |
| presentation | *(derivado)* `environment_states` | `RuntimeStateDerivationContract.derive_environment_state` | **adapter-supported** (derive) | IDs canônicos `envstate.*`; efeitos temporários não reproduzidos |
| progression | `progression` | — | not_implemented | reservado (A1/A2) |
| — | qualquer ID sem alias no `GameIdCatalog` (quest, consequência, observação, NPC, diálogo) | — | unsupported | não aplicado; adapters não promovem |

**Fluxo real de Vardhelm (C5):** 13 supported · 10 adapter-supported · 0 requires_adapter · 0 unsupported · 1 not_implemented.
(C4: 13 · 8 · 2 · 0 · 1 — os 2 requires_adapter eram `dialogue.completed` e `dialogue.choices`.)

## C6 — validação de ponta a ponta (arquivo real → sandbox)

Pipeline `SaveV2DiagnosticCoordinator` (Save V2 diagnóstico → arquivo → Load V2 → checksum → GameState →
RestorePlan → VardhelmDiagnosticSandbox → comparação), ver [BLOCK_C6_V2_DIAGNOSTIC_LOAD.md](BLOCK_C6_V2_DIAGNOSTIC_LOAD.md).
A classificação da matriz acima **não mudou**; o C6 prova cada linha com um arquivo real:

| Área | Antes do Eco | Depois do Eco (3 observações) |
|---|---|---|
| player (posição exata, rotação, scenario_id) | ✓ | ✓ |
| world / consequences (origem do catálogo) | ✓ heard_echo | ✓ heard_echo + first_echo_complete |
| observations (nó, flag, value) | — | ✓ 3 |
| quests | ✓ ativa | ✓ concluída |
| dialogue (completed + última escolha; transiente fora) | ✓ | ✓ |
| memory (Eco = memória; observação = fragmento, sem composição) | — | ✓ 1 + 3 fragmentos |
| echo (derivado) | ✓ oculto/interativo | ✓ resolvido (esfera: KNOWN GAMEPLAY BUG) |
| npcs | ✓ | ✓ |
| presentation (conclusão, marcador, envstate) | ✓ | ✓ echo_awakened |
| plano | — | 17 supported · 14 adapter-supported · 0 requires_adapter · 0 unsupported · 1 not_implemented |

Política do C6: o load diagnóstico **recusa** (RESTORE_REJECTED) qualquer plano com `unsupported` ou
`requires_adapter` antes de criar o sandbox, e trata como PARTIAL_FAILURE (sandbox descartado) qualquer
item que um adapter não consiga aplicar no runtime — nenhum status da matriz é aceito "em best effort".

## C7 — aplicação OPERACIONAL no runtime principal (flag SAVE_V2_OPERATIONAL_LOAD_ENABLED, padrão OFF)

Mesma matriz, mesmo restaurador e mesmos adapters (`GameStateRuntimeRestorer.apply_to_runtime`), agora
também no jogo principal — somente depois de rehearsal em sandbox + snapshot + rehearsal do rollback. Ver
[BLOCK_C7_V2_OPERATIONAL_LOAD.md](BLOCK_C7_V2_OPERATIONAL_LOAD.md).

| Área | Aplicação no runtime principal | Pode voltar a um estado anterior? |
|---|---|---|
| player / world / consequences / observations (flag+value) / quests / npcs | núcleo (supported) | sim |
| observations (estado funcional) | `derive_observation_state` | sim |
| echo | `derive_echo_state` (esfera: KNOWN GAMEPLAY BUG, fora do contrato) | sim |
| memory | derivada (verificada pelo projetor) | sim |
| dialogue | `DialogueRuntimeState.restore` | sim (sessão transitória não tocada) |
| presentation — quest | `derive_quest_presentation` (C7: oculta o banner sem quest concluída; derivada mesmo sem quest no save) | sim |
| presentation — ambiente | `derive_environment_state` (C7: `VardhelmAmbientLife.reset_persistent_state` + re-derivação) | sim |
| progression | not_implemented (reservado; não bloqueia) | — |

Contagem do plano inalterada: **0 requires_adapter · 0 unsupported · 1 not_implemented** no fluxo real.
Validação pós-apply: projeção == GameState (persistente) e estados derivados == rehearsal (funcional); qualquer
divergência → rollback pelo snapshot (mesmos adapters) com verificação de 0 diferenças.

## C8 — ciclo completo Save V2 → Load V2 → Save V2 (flags SAVE_V2_OPERATIONAL_SAVE/LOAD_ENABLED, padrão OFF)

Ver [BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md](BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md). Classificação
inalterada (**0 requires_adapter · 0 unsupported · 1 not_implemented**). O Save V2 operacional grava a projeção
persistente do runtime (mesmas linhas da matriz, sem nada derivado/transitório); o Load V2 as restaura.

| Área | Save V2 grava | Load V2 restaura | Mudança no C8 |
|---|---|---|---|
| player (posição exata, rotação, cenário) | ✓ | ✓ | — |
| world / consequences / observations | ✓ | ✓ | — |
| quests (status + objetivos) | ✓ | ✓ | núcleo preserva `objective_progress` vazio de quest iniciada (invariante do QuestState) |
| dialogue (completed + última escolha) | ✓ (também com sessão aberta) | ✓ (recusado com sessão aberta: LOAD_REJECTED_TRANSIENT_DIALOGUE) | política de diálogo aberto |
| memory (derivada) / echo | derivada | ✓ | **bug da esfera corrigido**: ao vivo == após load |
| npcs | ✓ | ✓ | — |
| presentation (quest, ambiente) | não gravada (derivada) | ✓ derivada | — |
| sessão de diálogo, UI, câmera, áudio, timers, animações, efeitos | ✗ nunca | ✗ nunca | — |

## C9 — prontidão de adoção (playtest renderizado, flags ON só em teste; defaults OFF)

Ver [BLOCK_C9_ADOPTION_READINESS.md](BLOCK_C9_ADOPTION_READINESS.md). Classificação inalterada
(**0 requires_adapter · 0 unsupported · 1 not_implemented**). Todas as linhas da matriz foram confirmadas com
renderização real (Forward+/D3D12), Ctrl+S/Ctrl+L de verdade e capturas de tela: player, world, consequences,
observations, quests, dialogue (sessão nunca restaurada), memory, echo (esfera/luz), npcs e apresentação derivada.

| Mudança no C9 | Efeito na restauração |
|---|---|
| `GameplayEventPublisher.resync_after_load` | após Load V2 com SUCCESS a deduplicação de eventos acompanha o estado carregado → a sombra registra o gameplay seguinte (antes: divergia até o próximo Save) |
| Tempos por sandbox (`sandbox1_*`, `sandbox2_*`) | custo medido: criação das instâncias ≈ 90% do Load; restore/apply/validação < 3 ms |
| Mensagens localizadas (`SaveV2PlayerMessages`) | nenhuma mudança de estado; só UX e log técnico |
| Não restaurado por desenho (achado visual) | painéis transitórios de observação/memória abertos antes do Load expiram pelos próprios timers (≤ 5 s) |

## C10 — endurecimento da adoção (flags continuam OFF)

Ver [BLOCK_C10_ADOPTION_HARDENING.md](BLOCK_C10_ADOPTION_HARDENING.md). Classificação inalterada
(**0 requires_adapter · 0 unsupported · 1 not_implemented**). Nenhuma linha persistente mudou; só isolamento e apresentação:

| Mudança no C10 | Efeito |
|---|---|
| Sandbox preserva a câmera ativa do jogo | antes: após todo Load V2 a câmera ficava presa na câmera panorâmica do nível (vazamento do sandbox) |
| `player.velocity = 0` após apply (SUCCESS ou rollback) | velocidade física anterior não sobrevive ao teleporte (não persistida) |
| UI transitória descartada após Load SUCCESS | painéis de memória/observação do estado desfeito não ficam na tela; banner/objetivo continuam derivados |
| Falante do diálogo localizado | "Durn" na caixa; ID `npc.vardhelm.durn` e DialogueState inalterados |
| Migração de saves antigos | **OPTION B — OPT-IN**, decidida e não implementada ([SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md)) |
