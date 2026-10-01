class_name ObservationRestoreAdapter
extends RestoreAdapter

## C4/C5 — Estado das observações no runtime. O núcleo restaura a representação
## no WorldState (flag + value). Este adapter reconstrói o estado funcional de
## cada observação pelo RuntimeStateDerivationContract (C5), identificando-a só
## pelo ID canônico — nunca por NodePath ou referência de nó:
##   descoberta  -> mesmo estado que a interação original deixa (revelada; o
##                  fragmento não é emitido de novo)
##   ausente     -> padrão (não revelada)
## Nenhum banco de observações novo é criado e nenhuma observação é inventada.


func adapter_id() -> String:
	return "observation"


func step() -> String:
	return "observations"


func diagnose(state: GameState, plan: RestorePlan) -> void:
	for observation_id in state.world.observations:
		if GameIdCatalog.legacy_id(GameIdCatalog.KIND_OBSERVATION, observation_id).is_empty():
			continue
		promote(plan, "world.observations.%s.node" % observation_id,
			"RuntimeStateDerivationContract.derive_observation_state (estado funcional da observação)",
			RestorePlan.ACTION_RESTORE, "mesmo estado que a interação original deixa; identidade pelo ID canônico")


func apply(state: GameState, plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	var result := new_result()
	collect_plan_items(plan, result, "world.observations.")
	var derivations := derivations_of(targets)
	var known := derivations.observation_ids()
	for observation_id in known:
		var discovered := state.world.is_observation_discovered(observation_id)
		if not derivations.derive_observation_state(observation_id, discovered):
			result.errors.append("%s: derivação de observação recusada pelo runtime" % observation_id)
			return result
		var described := derivations.describe_observation(observation_id)
		if described.is_empty() or bool(described.get("revealed", false)) != discovered:
			result.errors.append("%s: estado derivado (%s) difere do esperado (revealed=%s)" % [observation_id, str(described), discovered])
			return result
		if discovered:
			result.applied.append("world.observations.%s.node" % observation_id)
	for observation_id in state.world.observations:
		var path := "world.observations.%s.node" % observation_id
		if not known.has(observation_id) and result.supported.has(path):
			result.supported.erase(path)
			result.requires_adapter.append(path)
			result.warnings.append("%s: observação ausente no runtime do sandbox; estado não reconstruído" % observation_id)
	return result
