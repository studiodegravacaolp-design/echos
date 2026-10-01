class_name DialogueRestoreAdapter
extends RestoreAdapter

## C4/C5 — Diálogo. Destino (C5): DialogueRuntimeState
## (DialogueController.persistent_state), passado em targets.dialogue_state.
##
## Só a parte PERSISTENTE é restaurada: diálogos concluídos e a última escolha
## por dialogue_id + entry_id. Identidade = IDs (dialogue_id canônico ->
## runtime pelo GameIdCatalog; entry_id/choice_id do DialogueData). Nada de
## texto, falante ou índice visual. A sessão em andamento e a UI (conversa
## aberta, entrada atual, escolhas visíveis, texto) NUNCA são restauradas — o
## adapter nem as conhece.
##
## Sem destino no sandbox (dialogue_state = null) ou sem definição do diálogo:
## requires_adapter, informação preservada no GameState. entry_id/choice_id que
## não existem na definição: unsupported (não é inventado).


const REASON_NO_DESTINATION := "sem destino de diálogo no sandbox; informação preservada no GameState"
const REASON_UNKNOWN_ID := "dialogue_id sem alias no GameIdCatalog"


func adapter_id() -> String:
	return "dialogue"


func step() -> String:
	return "dialogue"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for dialogue_id in state.dialogue.completed:
		var path := "dialogue.completed.%s" % dialogue_id
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id)
		if legacy.is_empty():
			plan.update(path, {"status": RestorePlan.STATUS_UNSUPPORTED, "note": REASON_UNKNOWN_ID})
			continue
		promote(plan, path, "DialogueRuntimeState.completed[%s] (DialogueController.persistent_state)" % legacy,
			RestorePlan.ACTION_RESTORE, "parte persistente; sessão/UI transitórias não são restauradas")
	for dialogue_id in state.dialogue.choices:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id)
		for entry_id in state.dialogue.choices[dialogue_id]:
			var path := "dialogue.choices.%s.%s" % [dialogue_id, entry_id]
			if legacy.is_empty():
				plan.update(path, {"status": RestorePlan.STATUS_UNSUPPORTED, "note": REASON_UNKNOWN_ID})
				continue
			promote(plan, path, "DialogueRuntimeState.choices[%s][%s] (última escolha)" % [legacy, entry_id],
				RestorePlan.ACTION_RESTORE, "identidade dialogue_id + entry_id + choice_id; sem histórico")


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "dialogue.")
	if targets.dialogue_state == null:
		result.requires_adapter.append_array(result.supported)
		result.supported.clear()
		var retained := state.dialogue.completed.size() + state.dialogue.choices.size()
		if retained > 0:
			result.warnings.append("dialogue: %d registro(s) mantidos no GameState; %s" % [retained, REASON_NO_DESTINATION])
		return result

	var completed_ids: Array = []
	var restored_choices := {}
	for dialogue_id in state.dialogue.completed:
		var path := "dialogue.completed.%s" % dialogue_id
		if not result.supported.has(path):
			continue
		if not DialogueRuntimeState.can_restore_completed(targets.dialogue_definitions.get(dialogue_id) as DialogueData):
			_demote(result, path, result.requires_adapter, "%s: sem definição do diálogo no sandbox" % dialogue_id)
			continue
		completed_ids.append(GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id))
	for dialogue_id in state.dialogue.choices:
		var definition := targets.dialogue_definitions.get(dialogue_id) as DialogueData
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id)
		for entry_id in state.dialogue.choices[dialogue_id]:
			var path := "dialogue.choices.%s.%s" % [dialogue_id, entry_id]
			if not result.supported.has(path):
				continue
			var choice_id := state.dialogue.get_choice(dialogue_id, entry_id)
			if definition == null:
				_demote(result, path, result.requires_adapter, "%s: sem definição do diálogo no sandbox" % dialogue_id)
			elif not DialogueRuntimeState.can_restore_choice(definition, entry_id, choice_id):
				_demote(result, path, result.unsupported, "%s.%s: escolha '%s' não existe na definição do diálogo (não inventada)" % [dialogue_id, entry_id, choice_id])
			else:
				if not restored_choices.has(legacy):
					restored_choices[legacy] = {}
				restored_choices[legacy][entry_id] = choice_id

	# Substitui o estado persistente do sandbox (ausência = padrão). A sessão
	# transitória do DialogueController não é tocada.
	targets.dialogue_state.restore(completed_ids, restored_choices)

	for path in result.supported:
		var parts := path.split(".", false)
		if path.begins_with("dialogue.completed."):
			var dialogue_id := path.trim_prefix("dialogue.completed.")
			if not targets.dialogue_state.is_completed(GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id)):
				result.errors.append("%s: conclusão não reconhecida pelo runtime" % dialogue_id)
				continue
		else:
			var entry_id := parts[parts.size() - 1]
			var dialogue_id := path.trim_prefix("dialogue.choices.").trim_suffix("." + entry_id)
			var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_DIALOGUE, dialogue_id)
			if targets.dialogue_state.last_choice(legacy, entry_id) != state.dialogue.get_choice(dialogue_id, entry_id):
				result.errors.append("%s.%s: última escolha não reconhecida pelo runtime" % [dialogue_id, entry_id])
				continue
		result.applied.append(path)
	return result


func _demote(result: RestoreAdapterResult, path: String, bucket: Array[String], warning: String) -> void:
	result.supported.erase(path)
	bucket.append(path)
	result.warnings.append(warning)
