class_name GameStateProjector
extends RefCounted

## Projetor SOMENTE LEITURA: runtime atual (WorldState, QuestState, Player)
## -> GameState canônico.
##
##   Current Runtime -> snapshot (cópias profundas) -> GameStateMigrator -> GameState
##
## Nunca altera os objetos de origem: lê cópias e delega a classificação
## (consequência × memória, observações, Primeiro Eco, quarentena) ao
## GameStateMigrator, para que projeção e migração sigam a mesma regra.
## Não está ligado ao jogo, ao SaveService nem ao VardhelmVerticalSlice.


## Projeta a partir do runtime. `player` é opcional; quando presente, lê
## global_position/global_rotation (os mesmos campos usados pelo SaveService).
## `dialogue_state` (C5) é opcional: quando presente, a parte persistente de
## diálogo (DialogueRuntimeState) também é projetada; ausente = seção vazia,
## exatamente como antes.
static func project(world_state: WorldState, quest_state: QuestState, player: Node3D = null, dialogue_state: DialogueRuntimeState = null) -> GameStateMigrationResult:
	var result: GameStateMigrationResult
	if player == null:
		result = project_values(world_state, quest_state, Vector3.ZERO, Vector3.ZERO, false)
	else:
		result = project_values(world_state, quest_state, player.global_position, player.global_rotation, true)
	if dialogue_state != null:
		project_dialogue(dialogue_state, result)
	return result


## DialogueRuntimeState (IDs de runtime) -> GameState.dialogue (IDs canônicos).
## Somente leitura; diálogos sem alias no catálogo vão para a quarentena.
static func project_dialogue(dialogue_state: DialogueRuntimeState, result: GameStateMigrationResult) -> void:
	var data := dialogue_state.to_dict()
	for runtime_id in data["completed"]:
		var dialogue_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_DIALOGUE, String(runtime_id))
		if dialogue_id.is_empty():
			result.quarantine("dialogue.completed.%s" % runtime_id, true, "diálogo sem ID canônico")
			continue
		result.state.dialogue.mark_completed(dialogue_id)
	for runtime_id in data["choices"]:
		var dialogue_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_DIALOGUE, String(runtime_id))
		if dialogue_id.is_empty():
			result.quarantine("dialogue.choices.%s" % runtime_id, data["choices"][runtime_id], "diálogo sem ID canônico")
			continue
		var points: Dictionary = data["choices"][runtime_id]
		for entry_id in points:
			result.state.dialogue.record_choice(dialogue_id, String(entry_id), String(points[entry_id]))


## Variante sem nós: permite projetar e testar sem cena.
static func project_values(
	world_state: WorldState,
	quest_state: QuestState,
	player_position: Vector3,
	player_rotation: Vector3,
	include_player: bool = true,
) -> GameStateMigrationResult:
	var snapshot := build_runtime_snapshot(world_state, quest_state, player_position, player_rotation, include_player)
	return GameStateMigrator.migrate_legacy_payload(snapshot)


## Snapshot no mesmo formato do payload atual do SaveService, feito só com
## cópias (os objetos de runtime não são tocados).
static func build_runtime_snapshot(
	world_state: WorldState,
	quest_state: QuestState,
	player_position: Vector3,
	player_rotation: Vector3,
	include_player: bool = true,
) -> Dictionary:
	var snapshot := {}
	if world_state != null:
		var memories: Array = []
		for memory_id in world_state.memories:
			memories.append(memory_id)
		snapshot["world"] = {
			"flags": world_state.flags.duplicate(true),
			"values": world_state.values.duplicate(true),
			"memories": memories,
		}
	if quest_state != null:
		snapshot["quests"] = {
			"active": quest_state.active.duplicate(true),
			"completed": quest_state.completed.duplicate(true),
			"objective_progress": quest_state.objective_progress.duplicate(true),
		}
	if include_player:
		snapshot["player"] = {
			"position": GameStateSerde.vector3_to_array(player_position),
			"rotation": GameStateSerde.vector3_to_array(player_rotation),
		}
	return snapshot
