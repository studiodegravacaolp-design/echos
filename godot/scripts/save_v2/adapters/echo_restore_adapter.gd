class_name EchoRestoreAdapter
extends RestoreAdapter

## C4/C5 — Eco. O estado do Eco é DERIVADO no runtime; não existe EchoState e este
## adapter não cria um. Com consequência/quest já restauradas, ele pede a
## derivação ao RuntimeStateDerivationContract (C5) e VERIFICA o resultado:
##   resolvido      -> revealed = true, interação desligada
##   quest ativa    -> revealed = false, interação ligada
##   sem quest      -> revealed = false, interação desligada
## Um Eco resolvido sem consequência/quest que permita derivá-lo continua
## requires_adapter (o runtime não teria como representá-lo).
## A visibilidade da esfera NÃO faz parte do contrato (KNOWN GAMEPLAY BUG, C5).


func adapter_id() -> String:
	return "echo"


func step() -> String:
	return "echo"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for echo_id in state.memory.echoes:
		var path := "memory.echoes.%s" % echo_id
		if has_derivation_basis(state, echo_id):
			promote(plan, path, "RuntimeStateDerivationContract.derive_echo_state (a partir de consequência/quest restauradas)",
				RestorePlan.ACTION_DERIVE, "sem EchoState: o estado é derivado e verificado")
		else:
			plan.update(path, {"note": "Eco resolvido sem consequência/quest que o runtime use para derivá-lo"})


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "memory.echoes.")
	var derivations := derivations_of(targets)
	var echo_ids := derivations.echo_ids()
	if echo_ids.is_empty():
		return result
	if not derivations.derive_echo_state():
		for path in result.supported:
			result.requires_adapter.append(path)
		result.supported.clear()
		result.warnings.append("echo: derivação indisponível no sandbox; estado do Eco não reconstruído")
		return result
	for echo_id in echo_ids:
		var described := derivations.describe_echo(echo_id)
		if described.is_empty():
			result.errors.append("Eco sem descrição no runtime: %s" % echo_id)
			continue
		var definition: Dictionary = GameIdCatalog.ECHOES.get(echo_id, {})
		var quest_status := state.quests.get_status(String(definition.get("quest_id", "")))
		var expected_revealed := state.memory.is_echo_resolved(echo_id)
		if expected_revealed and not has_derivation_basis(state, echo_id):
			# Sem base de derivação: permanece requires_adapter (já no plano), não é verificado.
			result.warnings.append("%s: resolvido no GameState sem consequência/quest; o runtime não consegue derivá-lo" % echo_id)
			continue
		var expected_interaction := quest_status == GameQuestState.STATUS_ACTIVE and not expected_revealed
		var revealed := bool(described.get("revealed", false))
		var interaction := bool(described.get("interaction_enabled", false))
		if revealed != expected_revealed or interaction != expected_interaction:
			result.errors.append("%s: estado derivado (revealed=%s, interação=%s) difere do esperado (revealed=%s, interação=%s)" % [
				echo_id, revealed, interaction, expected_revealed, expected_interaction])
			continue
		result.applied.append("memory.echoes.%s" % echo_id)
	return result


## Um Eco resolvido é derivável se a consequência que o resolve foi aplicada
## ou se sua quest foi concluída (mesma regra do runtime e do projetor).
static func has_derivation_basis(state: GameState, echo_id: String) -> bool:
	var definition: Dictionary = GameIdCatalog.ECHOES.get(echo_id, {})
	if definition.is_empty():
		return false
	return state.world.is_consequence_applied(String(definition["resolving_consequence"])) \
		or state.quests.get_status(String(definition["quest_id"])) == GameQuestState.STATUS_COMPLETED
