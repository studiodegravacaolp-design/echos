class_name EnvironmentPresentationRestoreAdapter
extends RestoreAdapter

## C4/C5 — Estados de ambiente. São DERIVADOS de flags e da compatibilidade de
## consequências em WorldState.memories, que o núcleo já restaurou. O adapter
## pede a derivação ao RuntimeStateDerivationContract e reporta os estados
## reconstruídos (IDs canônicos). Efeitos temporários (tween, pulse, modulate,
## label) NÃO são persistidos nem reproduzidos. Nenhum EnvironmentVisualState é
## criado.


func adapter_id() -> String:
	return "environment_presentation"


func step() -> String:
	return "presentation"


func diagnose(_state: GameState, plan: RestorePlan) -> void:
	promote(plan, "(derivado) environment_states",
		"RuntimeStateDerivationContract.derive_environment_state",
		RestorePlan.ACTION_DERIVE, "a partir de flags/WorldState.memories restaurados; efeitos temporários não são reproduzidos")


func apply(_state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "(derivado) environment_states")
	var derivations := derivations_of(targets)
	if not derivations.derive_environment_state():
		result.requires_adapter.append_array(result.supported)
		result.supported.clear()
		result.warnings.append("environment_presentation: derivação indisponível no sandbox")
		return result
	result.applied.append_array(result.supported)
	var states := derivations.environment_state_ids()
	states.sort()
	result.warnings.append("environment_presentation: estados reconstruídos %s" % str(states))
	return result
