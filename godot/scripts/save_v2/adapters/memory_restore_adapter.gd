class_name MemoryRestoreAdapter
extends RestoreAdapter

## C4 — Memórias. O runtime NÃO tem armazenamento de memórias recuperadas, e
## este adapter não cria um (nem grava memórias em WorldState.memories, que
## misturaria memória com consequência). Cada memória é reconstruível somente
## pela sua representação existente:
##   origem echo        -> Eco resolvido derivável (consequência/quest)
##   origem observation -> observação de origem restaurada (flag/value + nó);
##                         o fragmento continua fragmento, sem composição
## O adapter só VERIFICA, pelo GameStateProjector, que o runtime restaurado
## reproduz cada memória com a mesma origem. Memórias sem representação
## continuam requires_adapter.


func adapter_id() -> String:
	return "memory"


func step() -> String:
	return "memory"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for memory_id in state.memory.memories:
		var path := "memory.memories.%s" % memory_id
		var record: Dictionary = state.memory.memories[memory_id]
		var source_type := String(record["source_type"])
		var source_id := String(record["source_id"])
		if source_type == GameMemoryState.SOURCE_ECHO and state.memory.is_echo_resolved(source_id) and EchoRestoreAdapter.has_derivation_basis(state, source_id) \
				and GameIdCatalog.memory_source(memory_id).get("source_id") == source_id:
			promote(plan, path, "representação existente: Eco %s resolvido (derivado de consequência/quest)" % source_id,
				RestorePlan.ACTION_DERIVE, "sem armazenamento próprio; memória continua memória")
		elif source_type == GameMemoryState.SOURCE_OBSERVATION and state.world.is_observation_discovered(source_id) \
				and GameIdCatalog.OBSERVATION_FRAGMENTS.get(source_id, "") == memory_id:
			promote(plan, path, "representação existente: observação %s (flag/value + estado da observação)" % source_id,
				RestorePlan.ACTION_DERIVE, "fragmento continua fragmento; sem composição")
		else:
			plan.update(path, {"note": "memória sem representação no runtime (origem %s/%s não restaurável)" % [source_type, source_id]})


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "memory.memories.")
	for memory_id in state.memory.memories:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_MEMORY, memory_id)
		if (not legacy.is_empty() and targets.world_state.memories.has(legacy)) or targets.world_state.memories.has(memory_id):
			result.errors.append("%s: memória gravada em WorldState.memories (misturaria memória e consequência)" % memory_id)
	if not result.errors.is_empty() or result.supported.is_empty():
		return result
	var player: Node3D = targets.player if targets.player != null and targets.player.is_inside_tree() else null
	var projected := GameStateProjector.project(targets.world_state, targets.quest_state, player).state
	for path in result.supported:
		var memory_id := path.substr("memory.memories.".length())
		var expected: Dictionary = state.memory.memories.get(memory_id, {})
		var reproduced: Dictionary = projected.memory.memories.get(memory_id, {})
		if reproduced.is_empty() or reproduced.get("source_type") != expected.get("source_type") or reproduced.get("source_id") != expected.get("source_id"):
			result.errors.append("%s: runtime restaurado não reproduz a memória com a mesma origem" % memory_id)
			continue
		result.applied.append(path)
	return result
