class_name QuestPresentationRestoreAdapter
extends RestoreAdapter

## C4/C5 — Apresentação da quest. É apresentação DERIVADA: nada disso vai para o
## GameState (sem texto, posição de marcador, visibilidade ou layout). O adapter
## pede a derivação ao RuntimeStateDerivationContract a partir do QuestState
## restaurado e verifica só o necessário: quest concluída -> conclusão
## apresentada.


func adapter_id() -> String:
	return "quest_presentation"


func step() -> String:
	return "presentation"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for quest_id in state.quests.quests:
		promote(plan, "quests.%s.presentation" % quest_id,
			"RuntimeStateDerivationContract.derive_quest_presentation (a partir do QuestState restaurado)",
			RestorePlan.ACTION_DERIVE, "apresentação derivada; nada persistido")


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "quests.")
	var derivations := derivations_of(targets)
	if result.supported.is_empty():
		# C7: sem quest no GameState a apresentação ainda precisa ser derivada
		# (ex.: Load V2 de um save inicial sobre um runtime que já tinha quest).
		derivations.derive_quest_presentation()
		return result
	if not derivations.derive_quest_presentation():
		result.requires_adapter.append_array(result.supported)
		result.supported.clear()
		result.warnings.append("quest_presentation: derivação indisponível no sandbox")
		return result
	for path: String in result.supported.duplicate():
		var quest_id := path.trim_prefix("quests.").trim_suffix(".presentation")
		var described := derivations.describe_quest_presentation(quest_id)
		if described.is_empty():
			result.supported.erase(path)
			result.requires_adapter.append(path)
			result.warnings.append("%s: sem apresentação neste runtime" % quest_id)
			continue
		if state.quests.get_status(quest_id) == GameQuestState.STATUS_COMPLETED and not bool(described.get("completion_presented", false)):
			result.errors.append("%s: quest concluída sem conclusão apresentada" % quest_id)
			continue
		result.applied.append(path)
	return result
