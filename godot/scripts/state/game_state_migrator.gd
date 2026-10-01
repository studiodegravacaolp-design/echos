class_name GameStateMigrator
extends RefCounted

## Migração preparatória PURA: formato atual (payload do SaveService /
## snapshot do runtime) -> GameState canônico. NÃO é usada pelo jogo ainda e
## nunca escreve de volta no save atual; a entrada nunca é modificada.
##
## Formato de entrada reconhecido (SaveService atual, "version": 2):
##   { version, language, world: {flags, values, memories},
##     quests: {active, completed, objective_progress},
##     player: {position: [x,y,z], rotation: [x,y,z]} }
##
## Regras para world.memories (hoje mistura consequências e memórias):
##   1. ID conhecido de consequência -> world.consequences
##   2. ID conhecido de memória       -> memory.memories
##   3. ID desconhecido               -> quarentena
##   4. Nada é descartado em silêncio.

const LEGACY_ROOT_KEYS := ["version", "language", "world", "quests", "player"]
const LEGACY_WORLD_KEYS := ["flags", "values", "memories"]
const LEGACY_QUEST_KEYS := ["active", "completed", "objective_progress"]


static func migrate_legacy_payload(payload: Variant) -> GameStateMigrationResult:
	var result := GameStateMigrationResult.new()
	if typeof(payload) != TYPE_DICTIONARY:
		result.quarantine("payload", payload, "payload não é Dictionary; GameState padrão mantido")
		return result
	var data: Dictionary = (payload as Dictionary).duplicate(true)

	_read_version(data, result)
	_migrate_language(data, result)
	_migrate_player(data, result)
	_migrate_world(data, result)
	_migrate_quests(data, result)
	_derive_resolved_echoes(result)
	result.warn("dialogue: formato atual não registra diálogos concluídos nem escolhas; DialogueState vazio (não inferido)")

	for key in data:
		if not LEGACY_ROOT_KEYS.has(key):
			result.quarantine(str(key), data[key], "campo raiz desconhecido")
	return result


static func _read_version(data: Dictionary, result: GameStateMigrationResult) -> void:
	if not data.has("version"):
		return
	if GameStateSerde.is_whole_number(data["version"]):
		result.source_version = int(data["version"])
	else:
		result.quarantine("version", data["version"], "versão de origem não numérica")


static func _migrate_language(data: Dictionary, result: GameStateMigrationResult) -> void:
	if data.has("language"):
		result.exclude("language", data["language"], "idioma é configuração da instalação/sessão, não GameState (decisão A1 #8)")


static func _migrate_player(data: Dictionary, result: GameStateMigrationResult) -> void:
	var player := result.state.player
	player.scenario_id = GameIdCatalog.SCENARIO_VARDHELM
	if not data.has("player"):
		result.warn("player: ausente na origem; localização padrão (%s, origem)" % GameIdCatalog.SCENARIO_VARDHELM)
		return
	if typeof(data["player"]) != TYPE_DICTIONARY:
		result.quarantine("player", data["player"], "esperado Dictionary")
		return
	var raw: Dictionary = data["player"]
	result.note("player.scenario_id <- %s (inferido: o formato atual não registra cenário)" % GameIdCatalog.SCENARIO_VARDHELM)
	for key in ["position", "rotation"]:
		if not raw.has(key):
			result.warn("player.%s: ausente; Vector3.ZERO" % key)
			continue
		if not GameStateSerde.is_vector3_array(raw[key]):
			result.quarantine("player.%s" % key, raw[key], "esperado [x, y, z] numérico")
			continue
		var vector := GameStateSerde.array_to_vector3(raw[key])
		if key == "position":
			player.position = vector
		else:
			player.rotation = vector
		result.note("player.%s -> player.location.%s" % [key, key])
	for key in raw:
		if key != "position" and key != "rotation":
			result.quarantine("player.%s" % str(key), raw[key], "campo de player desconhecido")


static func _migrate_world(data: Dictionary, result: GameStateMigrationResult) -> void:
	if not data.has("world"):
		result.warn("world: ausente na origem")
		return
	if typeof(data["world"]) != TYPE_DICTIONARY:
		result.quarantine("world", data["world"], "esperado Dictionary")
		return
	var raw: Dictionary = data["world"]
	_migrate_flags(raw.get("flags", {}), result)
	_migrate_values(raw.get("values", {}), result)
	_migrate_memories(raw.get("memories", []), result)
	_derive_observation_fragments(result)
	for key in raw:
		if not LEGACY_WORLD_KEYS.has(key):
			result.quarantine("world.%s" % str(key), raw[key], "campo de world desconhecido")


static func _migrate_flags(raw_flags: Variant, result: GameStateMigrationResult) -> void:
	if typeof(raw_flags) != TYPE_DICTIONARY:
		result.quarantine("world.flags", raw_flags, "esperado Dictionary")
		return
	var world := result.state.world
	var flags: Dictionary = raw_flags
	for key in flags:
		var flag_id := str(key)
		if typeof(flags[key]) != TYPE_BOOL:
			result.quarantine("world.flags.%s" % flag_id, flags[key], "flag não booleana")
			continue
		# Flags mantêm os nomes atuais (A1): continuam espelho de compatibilidade.
		world.set_flag(flag_id, bool(flags[key]))
		result.note("world.flags.%s -> world.flags.%s" % [flag_id, flag_id])
		if not bool(flags[key]):
			continue
		var consequence_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_CONSEQUENCE, flag_id)
		if not consequence_id.is_empty():
			_apply_known_consequence(consequence_id, "world.flags.%s" % flag_id, result)
		var legacy_observation := GameIdCatalog.legacy_observation_from_flag(flag_id)
		if not legacy_observation.is_empty():
			_discover_legacy_observation(legacy_observation, "world.flags.%s" % flag_id, result)


static func _migrate_values(raw_values: Variant, result: GameStateMigrationResult) -> void:
	if typeof(raw_values) != TYPE_DICTIONARY:
		result.quarantine("world.values", raw_values, "esperado Dictionary")
		return
	var world := result.state.world
	var values: Dictionary = raw_values
	for key in values:
		var value_key := str(key)
		var legacy_observation := GameIdCatalog.legacy_observation_from_value_key(value_key)
		if not legacy_observation.is_empty():
			if not GameIdCatalog.is_known(GameIdCatalog.KIND_OBSERVATION, legacy_observation):
				result.quarantine("world.values.%s" % value_key, values[key], "observação desconhecida")
			elif GameStateSerde.is_true(values[key]):
				# Duplicata da flag observation_<id>_seen: representada em observations.
				_discover_legacy_observation(legacy_observation, "world.values.%s" % value_key, result)
			else:
				result.quarantine("world.values.%s" % value_key, values[key], "valor de observação não verdadeiro")
			continue
		if world.set_value(value_key, values[key]):
			result.note("world.values.%s -> world.values.%s" % [value_key, value_key])
		else:
			result.quarantine("world.values.%s" % value_key, values[key], "valor não escalar JSON")


static func _migrate_memories(raw_memories: Variant, result: GameStateMigrationResult) -> void:
	if typeof(raw_memories) != TYPE_ARRAY:
		result.quarantine("world.memories", raw_memories, "esperado Array")
		return
	for entry in raw_memories:
		if typeof(entry) != TYPE_STRING:
			result.quarantine("world.memories", entry, "entrada não é String")
			continue
		var legacy_id := String(entry)
		var consequence_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_CONSEQUENCE, legacy_id)
		if not consequence_id.is_empty():
			_apply_known_consequence(consequence_id, "world.memories[%s]" % legacy_id, result)
			continue
		var memory_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_MEMORY, legacy_id)
		if not memory_id.is_empty():
			var source := GameIdCatalog.memory_source(memory_id)
			if source.is_empty():
				result.quarantine("world.memories", legacy_id, "memória sem origem conhecida no catálogo")
				continue
			if result.state.memory.register_memory(memory_id, source["source_type"], source["source_id"]):
				result.note("world.memories[%s] -> memory.memories.%s (%s)" % [legacy_id, memory_id, source["source_type"]])
			continue
		result.quarantine("world.memories", legacy_id, "ID desconhecido (nem consequência nem memória no catálogo)")


static func _apply_known_consequence(consequence_id: String, origin: String, result: GameStateMigrationResult) -> void:
	var source: Dictionary = GameIdCatalog.CONSEQUENCE_SOURCES.get(consequence_id, {})
	var applied := result.state.world.apply_consequence(
		consequence_id,
		String(source.get("source_type", "")),
		String(source.get("source_id", "")),
	)
	if applied:
		result.note("%s -> world.consequences.%s" % [origin, consequence_id])


static func _discover_legacy_observation(legacy_id: String, origin: String, result: GameStateMigrationResult) -> void:
	var observation_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, legacy_id)
	if observation_id.is_empty():
		# A flag de origem já foi preservada em world.flags; só registra o aviso.
		result.warn("%s: observação '%s' fora do catálogo; world.observations não atualizado" % [origin, legacy_id])
		return
	if result.state.world.discover_observation(observation_id):
		result.note("%s -> world.observations.%s" % [origin, observation_id])


## Decisão A1 #1: observação descoberta produz seu fragmento de memória.
## Registrar a memória não aplica consequência nem reação (decisão #3).
static func _derive_observation_fragments(result: GameStateMigrationResult) -> void:
	for observation_id in result.state.world.observations:
		var memory_id: String = GameIdCatalog.OBSERVATION_FRAGMENTS.get(observation_id, "")
		if memory_id.is_empty():
			continue
		if result.state.memory.register_memory(memory_id, GameMemoryState.SOURCE_OBSERVATION, observation_id):
			result.note("world.observations.%s -> memory.memories.%s (fragmento, derivado)" % [observation_id, memory_id])


static func _migrate_quests(data: Dictionary, result: GameStateMigrationResult) -> void:
	if not data.has("quests"):
		result.warn("quests: ausente na origem")
		return
	if typeof(data["quests"]) != TYPE_DICTIONARY:
		result.quarantine("quests", data["quests"], "esperado Dictionary")
		return
	var raw: Dictionary = data["quests"]
	var quest_state := result.state.quests
	var active := _quest_section(raw, "active", result)
	var completed := _quest_section(raw, "completed", result)
	var progress := _quest_section(raw, "objective_progress", result)

	for legacy_id in completed:
		var quest_id := _canonical_quest(str(legacy_id), "quests.completed", completed[legacy_id], result)
		if quest_id.is_empty() or not GameStateSerde.is_true(completed[legacy_id]):
			continue
		quest_state.complete_quest(quest_id)
		result.note("quests.completed.%s -> quests.%s.status = completed" % [legacy_id, quest_id])
		if GameStateSerde.is_true(active.get(legacy_id)):
			result.warn("quests.%s: ativa e concluída ao mesmo tempo na origem; mantido 'completed'" % quest_id)

	for legacy_id in active:
		var quest_id := _canonical_quest(str(legacy_id), "quests.active", active[legacy_id], result)
		if quest_id.is_empty() or not GameStateSerde.is_true(active[legacy_id]):
			continue
		if quest_state.start_quest(quest_id):
			result.note("quests.active.%s -> quests.%s.status = active" % [legacy_id, quest_id])

	for legacy_id in progress:
		var quest_id := _canonical_quest(str(legacy_id), "quests.objective_progress", progress[legacy_id], result)
		if quest_id.is_empty():
			continue
		if typeof(progress[legacy_id]) != TYPE_DICTIONARY:
			result.quarantine("quests.objective_progress.%s" % legacy_id, progress[legacy_id], "esperado Dictionary")
			continue
		if quest_state.get_status(quest_id) == GameQuestState.STATUS_NOT_STARTED:
			# Mesma regra do slice atual (_apply_loaded_visual_state): progresso implica quest ativa.
			quest_state.start_quest(quest_id)
			result.warn("quests.%s: só havia objective_progress; status inferido 'active'" % quest_id)
		var objectives: Dictionary = progress[legacy_id]
		for objective_id in objectives:
			if typeof(objectives[objective_id]) != TYPE_BOOL:
				result.quarantine("quests.objective_progress.%s.%s" % [legacy_id, objective_id], objectives[objective_id], "objetivo não booleano")
				continue
			quest_state.set_objective_complete(quest_id, str(objective_id), bool(objectives[objective_id]))
			result.note("quests.objective_progress.%s.%s -> quests.%s.objectives.%s" % [legacy_id, objective_id, quest_id, objective_id])

	for key in raw:
		if not LEGACY_QUEST_KEYS.has(key):
			result.quarantine("quests.%s" % str(key), raw[key], "campo de quests desconhecido")


static func _quest_section(raw: Dictionary, key: String, result: GameStateMigrationResult) -> Dictionary:
	if not raw.has(key):
		return {}
	if typeof(raw[key]) != TYPE_DICTIONARY:
		result.quarantine("quests.%s" % key, raw[key], "esperado Dictionary")
		return {}
	return raw[key]


static func _canonical_quest(legacy_id: String, path: String, raw_value: Variant, result: GameStateMigrationResult) -> String:
	var quest_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_QUEST, legacy_id)
	if quest_id.is_empty():
		result.quarantine("%s.%s" % [path, legacy_id], raw_value, "quest desconhecida no catálogo")
	return quest_id


## Decisões A1 #2 e #4: um Eco é resolvido quando sua consequência foi aplicada
## (fonte = Eco) ou quando sua quest foi concluída — a mesma regra usada hoje
## por _apply_loaded_visual_state. Eco resolvido registra sua memória real.
## A consequência NÃO é aplicada aqui só porque a quest terminou.
static func _derive_resolved_echoes(result: GameStateMigrationResult) -> void:
	var state := result.state
	for echo_id in GameIdCatalog.ECHOES:
		var definition: Dictionary = GameIdCatalog.ECHOES[echo_id]
		var by_consequence := state.world.is_consequence_applied(String(definition["resolving_consequence"]))
		var by_quest := state.quests.get_status(String(definition["quest_id"])) == GameQuestState.STATUS_COMPLETED
		if not by_consequence and not by_quest:
			continue
		if state.memory.resolve_echo(echo_id):
			result.note("%s -> memory.echoes.%s = resolved (derivado)" % ["consequência" if by_consequence else "quest concluída", echo_id])
		var memory_id := String(definition["memory_id"])
		if state.memory.register_memory(memory_id, GameMemoryState.SOURCE_ECHO, echo_id):
			result.note("memory.echoes.%s -> memory.memories.%s (echo, decisão A1 #2)" % [echo_id, memory_id])
