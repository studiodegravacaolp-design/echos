class_name RuntimeRestoreTargets
extends RefCounted

## Alvos explícitos de uma restauração (Blocos C3/C4/C5). Só referências passadas
## por quem monta o sandbox — o restaurador e os adapters não procuram nós nem
## conhecem a cena.
##
## `is_sandbox` precisa ser true: a restauração recusa qualquer alvo que não
## tenha sido declarado sandbox (nunca aplicada ao jogo principal).
##
## C5: sem Callables. Derivações chegam por um RuntimeStateDerivationContract
## (contrato formal) e o diálogo por um DialogueRuntimeState.

var is_sandbox: bool = false
## C7: autorização de aplicação no runtime PRINCIPAL (GameStateRuntimeRestorer.apply_to_runtime).
## Só o SaveV2RuntimeLoadCoordinator a concede, depois de rehearsal + snapshot, e a
## revoga ao terminar. Nunca coexiste com is_sandbox.
var operational_load_authorized: bool = false
## Cenário da experiência que contém os alvos (ex.: scenario.vardhelm).
var scenario_id: String = ""
var player: Node3D = null
var world_state: WorldState = null
var quest_state: QuestState = null
## ID canônico -> NPCController (ex.: "npc.vardhelm.durn").
var npcs: Dictionary = {}

## Destino do DialogueState (DialogueController.persistent_state). null = sem destino.
var dialogue_state: DialogueRuntimeState = null
## ID canônico -> DialogueData: definições usadas só para validar entry_id/choice_id.
var dialogue_definitions: Dictionary = {}

## Derivações de runtime (observação, Eco, apresentação da quest, ambiente).
## null = nenhuma derivação disponível (adapters reportam requires_adapter).
var derivations: RuntimeStateDerivationContract = null
