class_name ConsequenceRestoreAdapter
extends RestoreAdapter

## C4 — Consequências. O núcleo já escreve a representação existente (flag +
## compatibilidade histórica em WorldState.memories, como o NarrativeController).
## Este adapter:
## - verifica que o runtime reconhece cada consequência como ocorrida, sem
##   duplicá-la;
## - trata source_type/source_id: o runtime não guarda a fonte, mas ela é
##   determinística pelo GameIdCatalog (CONSEQUENCE_SOURCES). Se a fonte do
##   GameState coincide com o catálogo, é reconstruível (adapter-supported);
##   se diverge, continua requires_adapter — explícito, nunca mascarado.
## consequence ≠ memory: nada é gravado como memória.


func adapter_id() -> String:
	return "consequence"


func step() -> String:
	return "consequences"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for consequence_id in state.world.consequences:
		if not state.world.consequences[consequence_id].has("source_type"):
			continue
		var path := "world.consequences.%s.source" % consequence_id
		if _source_matches_catalog(state, consequence_id):
			promote(plan, path, "GameIdCatalog.CONSEQUENCE_SOURCES (derivação determinística; o runtime não guarda a fonte)",
				RestorePlan.ACTION_VERIFY, "fonte do GameState == fonte canônica; o projetor a reproduz")
		else:
			plan.update(path, {"note": "fonte do GameState difere do catálogo; o runtime não consegue representá-la"})


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "world.consequences.")
	var world := targets.world_state
	for consequence_id in state.world.consequences:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_CONSEQUENCE, consequence_id)
		if legacy.is_empty():
			continue
		if not world.has_flag(legacy) or world.memories.count(legacy) != 1:
			result.errors.append("%s: runtime não reconhece a consequência exatamente uma vez" % consequence_id)
			continue
		result.applied.append("world.consequences.%s" % consequence_id)
		var source_path := "world.consequences.%s.source" % consequence_id
		if plan.find(source_path).get("status") == RestorePlan.STATUS_ADAPTER_SUPPORTED:
			result.applied.append(source_path)
	return result


func _source_matches_catalog(state: GameState, consequence_id: String) -> bool:
	var canonical: Dictionary = GameIdCatalog.CONSEQUENCE_SOURCES.get(consequence_id, {})
	var record: Dictionary = state.world.consequences[consequence_id]
	return not canonical.is_empty() \
		and record.get("source_type") == canonical.get("source_type") \
		and record.get("source_id") == canonical.get("source_id")
