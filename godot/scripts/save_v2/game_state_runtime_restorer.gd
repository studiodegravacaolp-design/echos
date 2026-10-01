class_name GameStateRuntimeRestorer
extends RefCounted

## Blocos C3/C4/C5 — restauração CONTROLADA GameState -> runtime atual, somente para
## diagnóstico, testes e sandbox. Não é o load operacional.
##
##   MODE 1 — DIAGNOSTIC: diagnose(state)                     -> RestorePlan (nenhuma mutação)
##   MODE 2 — SANDBOX:    apply_to_sandbox(state, alvos sandbox) -> RestoreResult
##
## Núcleo (C3): escreve SOMENTE nas representações que o runtime já possui
## (Player, WorldState, QuestState, NPCController).
## Adapters (C4, RuntimeRestoreAdapterRegistry): refinam o plano e reconstroem
## os campos requires_adapter a partir de estruturas/derivações EXISTENTES.
## Sem registry (padrão) o comportamento é exatamente o do C3.
##
## Não conhece SaveV2Service, SaveService, eventos, UI nem a cena. Recusa alvos
## que não sejam sandbox. Não publica eventos.
##
## Ordem (RestorePlan.STEPS): scenario -> player -> world -> consequences ->
## observations -> quests -> echo -> memory -> npcs -> dialogue -> presentation
## -> progression.

const DEST_SCENARIO := "cena da experiência (cenário único, sem variável de runtime)"
const DEST_ECHO := "estado do Eco derivado de flag/quest (RuntimeStateDerivationContract)"
const DEST_MEMORY := "sem armazenamento no runtime (WorldState.memories guarda consequências; fragmentos nunca são registrados)"
const DEST_OBSERVATION_NODE := "estado funcional da observação (RuntimeStateDerivationContract)"
const DEST_QUEST_PRESENTATION := "apresentação da quest derivada do QuestState (RuntimeStateDerivationContract)"
const DEST_AMBIENT := "estados de ambiente derivados (RuntimeStateDerivationContract)"
const DEST_DIALOGUE := "DialogueRuntimeState (DialogueController.persistent_state) — só pelo DialogueRestoreAdapter"

## Seam de teste: nome de um passo que deve falhar (simula falha parcial).
var fault_injection_step: String = ""
var registry: RuntimeRestoreAdapterRegistry


func _init(adapter_registry: RuntimeRestoreAdapterRegistry = null) -> void:
	registry = adapter_registry if adapter_registry != null else RuntimeRestoreAdapterRegistry.new()


# ---------------------------------------------------------------------------
# MODE 1 — DIAGNOSTIC
# ---------------------------------------------------------------------------

func diagnose(state: GameState) -> RestorePlan:
	var plan := RestorePlan.new()
	if state == null:
		return plan
	_diagnose_core(state, plan)
	for adapter in registry.all():
		adapter.diagnose(state, plan)
	return plan


func _diagnose_core(state: GameState, plan: RestorePlan) -> void:
	plan.add("scenario", "state_version", "contrato GameState (state_version %d)" % GameState.STATE_VERSION,
		RestorePlan.ACTION_VERIFY, RestorePlan.STATUS_SUPPORTED if state.state_version == GameState.STATE_VERSION else RestorePlan.STATUS_UNSUPPORTED)
	plan.add("scenario", "player.location.scenario_id", DEST_SCENARIO, RestorePlan.ACTION_VERIFY,
		RestorePlan.STATUS_SUPPORTED if GameIdCatalog.is_known(GameIdCatalog.KIND_SCENARIO, state.player.scenario_id) else RestorePlan.STATUS_UNSUPPORTED,
		"só verificação: não há troca de cenário no runtime")
	plan.add("player", "player.location.position", "Player.global_position", RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)
	plan.add("player", "player.location.rotation", "Player.global_rotation", RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)

	for flag_id in state.world.flags:
		plan.add("world", "world.flags.%s" % flag_id, "WorldState.flags[%s]" % flag_id, RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)
	for key in state.world.values:
		plan.add("world", "world.values.%s" % key, "WorldState.values[%s]" % key, RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)

	for consequence_id in state.world.consequences:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_CONSEQUENCE, consequence_id)
		if legacy.is_empty():
			plan.add("consequences", "world.consequences.%s" % consequence_id, "—", RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_UNSUPPORTED, "consequência sem ID de runtime no GameIdCatalog")
			continue
		plan.add("consequences", "world.consequences.%s" % consequence_id, "WorldState.flags[%s] + WorldState.memories[%s]" % [legacy, legacy],
			RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED, "representação existente do NarrativeController.apply_consequence (flag + entrada em memories)")
		if state.world.consequences[consequence_id].has("source_type"):
			plan.add("consequences", "world.consequences.%s.source" % consequence_id, "sem destino no runtime", RestorePlan.ACTION_NOT_APPLIED,
				RestorePlan.STATUS_REQUIRES_ADAPTER, "o runtime não guarda a fonte; o projetor a reconstrói pelo catálogo")

	for observation_id in state.world.observations:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_OBSERVATION, observation_id)
		if legacy.is_empty():
			plan.add("observations", "world.observations.%s" % observation_id, "—", RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_UNSUPPORTED, "observação sem ID de runtime no GameIdCatalog")
			continue
		plan.add("observations", "world.observations.%s" % observation_id,
			"WorldState.flags[%s] + WorldState.values[%s]" % [observation_flag(legacy), observation_value(legacy)],
			RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED, "representação existente do runtime da experiência (flag + value de observação)")
		plan.add("observations", "world.observations.%s.node" % observation_id, DEST_OBSERVATION_NODE, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER)

	for quest_id in state.quests.quests:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id)
		if legacy.is_empty():
			plan.add("quests", "quests.%s" % quest_id, "—", RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_UNSUPPORTED, "quest sem ID de runtime no GameIdCatalog")
			continue
		plan.add("quests", "quests.%s.status" % quest_id, "QuestState.active/completed[%s]" % legacy, RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)
		var objectives: Dictionary = state.quests.quests[quest_id]["objectives"]
		for objective_id in objectives:
			plan.add("quests", "quests.%s.objectives.%s" % [quest_id, objective_id], "QuestState.objective_progress[%s][%s]" % [legacy, objective_id], RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)

	for echo_id in state.memory.echoes:
		plan.add("echo", "memory.echoes.%s" % echo_id, DEST_ECHO, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER,
			"estado do Eco é derivado da consequência/quest restauradas")
	for memory_id in state.memory.memories:
		plan.add("memory", "memory.memories.%s" % memory_id, DEST_MEMORY, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER,
			"origem %s; o projetor a deriva de consequência/observação — sem composição de fragmentos" % state.memory.get_memory_source_type(memory_id))

	for npc_id in state.npcs.npcs:
		plan.add("npcs", "npcs.%s.interaction_enabled" % npc_id, "NPCController.set_interaction_enabled", RestorePlan.ACTION_RESTORE,
			RestorePlan.STATUS_SUPPORTED if GameIdCatalog.is_known(GameIdCatalog.KIND_NPC, npc_id) else RestorePlan.STATUS_UNSUPPORTED)
	plan.add("npcs", "npcs (sem registro)", "NPCController.set_interaction_enabled(true) — ausência = padrão", RestorePlan.ACTION_RESTORE, RestorePlan.STATUS_SUPPORTED)

	for dialogue_id in state.dialogue.completed:
		plan.add("dialogue", "dialogue.completed.%s" % dialogue_id, DEST_DIALOGUE, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER)
	for dialogue_id in state.dialogue.choices:
		for entry_id in state.dialogue.choices[dialogue_id]:
			plan.add("dialogue", "dialogue.choices.%s.%s" % [dialogue_id, entry_id], DEST_DIALOGUE, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER)

	for quest_id in state.quests.quests:
		if not GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id).is_empty():
			plan.add("presentation", "quests.%s.presentation" % quest_id, DEST_QUEST_PRESENTATION, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER)
	plan.add("presentation", "(derivado) environment_states", DEST_AMBIENT, RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_REQUIRES_ADAPTER,
		"derivado de flags/consequências; exige derivação do runtime")

	plan.add("progression", "progression", "—", RestorePlan.ACTION_NOT_APPLIED, RestorePlan.STATUS_NOT_IMPLEMENTED, "seção reservada (A1/A2)")


# ---------------------------------------------------------------------------
# MODE 2 — SANDBOX
# ---------------------------------------------------------------------------

func apply_to_sandbox(state: GameState, targets: RuntimeRestoreTargets) -> RestoreResult:
	return _apply(state, targets, false)


# ---------------------------------------------------------------------------
# MODE 3 — OPERACIONAL (C7)
# ---------------------------------------------------------------------------

## Aplica no runtime PRINCIPAL. Só aceita alvos NÃO sandbox com
## `operational_load_authorized` — concedido exclusivamente pelo
## SaveV2RuntimeLoadCoordinator depois de rehearsal em sandbox + snapshot.
## Mesmo núcleo e mesmos adapters do sandbox; nenhum segundo sistema.
func apply_to_runtime(state: GameState, targets: RuntimeRestoreTargets) -> RestoreResult:
	return _apply(state, targets, true)


func _apply(state: GameState, targets: RuntimeRestoreTargets, operational: bool) -> RestoreResult:
	var result := RestoreResult.new()
	if state == null:
		result.errors.append("GameState nulo")
		return result
	var plan := diagnose(state)
	result.plan = plan
	result.adapter_supported = plan.by_status(RestorePlan.STATUS_ADAPTER_SUPPORTED)
	result.requires_adapter = plan.by_status(RestorePlan.STATUS_REQUIRES_ADAPTER)
	result.unsupported = plan.by_status(RestorePlan.STATUS_UNSUPPORTED)
	result.not_implemented = plan.by_status(RestorePlan.STATUS_NOT_IMPLEMENTED)

	# Pré-checagem: nada é mutado se algo estiver errado antes de começar.
	if operational:
		if targets == null or targets.is_sandbox or not targets.operational_load_authorized:
			result.errors.append("aplicação operacional recusada: alvo principal sem autorização do SaveV2RuntimeLoadCoordinator")
			return result
	elif targets == null or not targets.is_sandbox:
		result.errors.append("restauração recusada: alvo não é sandbox (nunca aplicar ao jogo principal)")
		return result
	var state_errors := state.validate()
	if not state_errors.is_empty():
		result.errors.append("GameState inválido: %s" % "; ".join(state_errors))
		return result
	for requirement in [["player", targets.player], ["world_state", targets.world_state], ["quest_state", targets.quest_state]]:
		if requirement[1] == null:
			result.errors.append("alvo ausente: %s" % requirement[0])
	if targets.player != null and not targets.player.is_inside_tree():
		result.errors.append("alvo inválido: player fora da árvore")
	if not result.errors.is_empty():
		return result

	var original_snapshot := JSON.stringify(state.to_dict(), "", true)
	for step in RestorePlan.STEPS:
		if fault_injection_step == step:
			result.errors.append("falha no passo '%s' (injetada)" % step)
			break
		var ok: bool = call("_apply_%s" % step, state, targets, result)
		if ok:
			for adapter in registry.adapters_for(step):
				var adapter_result := adapter.apply(state, plan, targets)
				result.adapter_results.append(adapter_result.to_dict())
				result.warnings.append_array(adapter_result.warnings)
				if not adapter_result.errors.is_empty():
					for error in adapter_result.errors:
						result.errors.append("%s: %s" % [adapter_result.adapter, error])
					ok = false
					break
		if not ok:
			break
		result.completed_steps.append(step)

	result.success = result.errors.is_empty()
	var mutated := not result.applied.is_empty() or not result.adapter_results.is_empty()
	result.partial_failure = not result.success and mutated
	if result.partial_failure:
		result.warnings.append("restauração parcial: descartar o sandbox; o estado não é válido")
	if JSON.stringify(state.to_dict(), "", true) != original_snapshot:
		result.errors.append("GameState de origem foi alterado (não deveria)")
		result.success = false
	result.differences = compare_with_runtime(state, targets)
	return result


## Projeta o runtime dos alvos (GameStateProjector) e compara com o GameState.
## Resumo JSON-safe (sem a lista de caminhos iguais). Ausências são reportadas.
func compare_with_runtime(state: GameState, targets: RuntimeRestoreTargets) -> Dictionary:
	if targets == null or targets.world_state == null or targets.quest_state == null:
		return {}
	var player: Node3D = targets.player if targets.player != null and targets.player.is_inside_tree() else null
	var projection := GameStateProjector.project(targets.world_state, targets.quest_state, player, targets.dialogue_state)
	var comparison := GameStateComparator.compare(state, projection.state, "game_state", "runtime")
	var data := comparison.to_dict()
	data.erase("matching")
	data["matching_count"] = comparison.matching.size()
	data["summary"] = comparison.summary()
	return data


# ---------------------------------------------------------------------------
# Passos do núcleo (cada um devolve false em erro)
# ---------------------------------------------------------------------------

func _apply_scenario(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	if state.state_version != GameState.STATE_VERSION:
		result.errors.append("state_version %d não suportada" % state.state_version)
		return false
	if state.player.scenario_id != targets.scenario_id:
		result.errors.append("cenário do GameState (%s) difere do cenário do sandbox (%s)" % [state.player.scenario_id, targets.scenario_id])
		return false
	_mark_applied(result, "player.location.scenario_id")
	_mark_applied(result, "state_version")
	return true


func _apply_player(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	targets.player.global_position = state.player.position
	targets.player.global_rotation = state.player.rotation
	_mark_applied(result, "player.location.position")
	_mark_applied(result, "player.location.rotation")
	return true


## flags/values do WorldState. memories é reescrita no passo de consequências.
func _apply_world(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	var flags := {}
	for flag_id in state.world.flags:
		flags[flag_id] = state.world.flags[flag_id]
	var values := {}
	for key in state.world.values:
		values[key] = state.world.values[key]
	targets.world_state.flags = flags
	targets.world_state.values = values
	targets.world_state.memories.clear()
	_mark_step_supported(result, "world")
	return true


## Consequência -> flag legada + entrada legada em WorldState.memories (a
## representação do NarrativeController). Array tipado preenchido item a item.
func _apply_consequences(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	var world := targets.world_state
	for consequence_id in state.world.consequences:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_CONSEQUENCE, consequence_id)
		if legacy.is_empty():
			continue
		world.flags[legacy] = true
		if not world.memories.has(legacy):
			world.memories.append(legacy)
	_mark_step_supported(result, "consequences")
	return true


## Observação -> flag + value (representação do slice). O estado de nó é do adapter.
func _apply_observations(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	var world := targets.world_state
	for observation_id in state.world.observations:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_OBSERVATION, observation_id)
		if legacy.is_empty():
			continue
		world.flags[observation_flag(legacy)] = true
		world.values[observation_value(legacy)] = true
	_mark_step_supported(result, "observations")
	return true


func _apply_quests(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	var active := {}
	var completed := {}
	var progress := {}
	for quest_id in state.quests.quests:
		var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id)
		if legacy.is_empty():
			continue
		var record: Dictionary = state.quests.quests[quest_id]
		if record["status"] == GameQuestState.STATUS_COMPLETED:
			completed[legacy] = true
		else:
			active[legacy] = true
		var objectives := {}
		for objective_id in record["objectives"]:
			objectives[objective_id] = bool(record["objectives"][objective_id])
		# C8: mesma invariante do QuestState.start_quest — toda quest iniciada tem
		# entrada em objective_progress, mesmo sem objetivo concluído.
		progress[legacy] = objectives
	targets.quest_state.active = active
	targets.quest_state.completed = completed
	targets.quest_state.objective_progress = progress
	_mark_step_supported(result, "quests")
	return true


## Passos cujo trabalho é feito só pelos adapters (ou por ninguém).
func _apply_echo(_state: GameState, _targets: RuntimeRestoreTargets, _result: RestoreResult) -> bool:
	return true


func _apply_memory(_state: GameState, _targets: RuntimeRestoreTargets, _result: RestoreResult) -> bool:
	return true


func _apply_npcs(state: GameState, targets: RuntimeRestoreTargets, result: RestoreResult) -> bool:
	for npc_id in targets.npcs:
		var npc := targets.npcs[npc_id] as NPCController
		if npc == null:
			result.errors.append("alvo de NPC inválido: %s" % str(npc_id))
			return false
		npc.set_interaction_enabled(state.npcs.is_interaction_enabled(String(npc_id)))
	for npc_id in state.npcs.npcs:
		if targets.npcs.has(npc_id):
			_mark_applied(result, "npcs.%s.interaction_enabled" % npc_id)
		else:
			result.warnings.append("npcs.%s: sem NPC correspondente no sandbox; não aplicado" % npc_id)
	if not targets.npcs.is_empty():
		_mark_applied(result, "npcs (sem registro)")
	return true


func _apply_dialogue(_state: GameState, _targets: RuntimeRestoreTargets, _result: RestoreResult) -> bool:
	return true


func _apply_presentation(_state: GameState, _targets: RuntimeRestoreTargets, _result: RestoreResult) -> bool:
	return true


## Progression: reservado (not_implemented).
func _apply_progression(_state: GameState, _targets: RuntimeRestoreTargets, _result: RestoreResult) -> bool:
	return true


func _mark_applied(result: RestoreResult, source_path: String) -> void:
	var item := result.plan.find(source_path)
	if not item.is_empty():
		result.applied.append(item)


func _mark_step_supported(result: RestoreResult, step: String) -> void:
	for item in result.plan.by_step(step):
		if item["status"] == RestorePlan.STATUS_SUPPORTED:
			result.applied.append(item)


static func observation_flag(legacy_id: String) -> String:
	return "%s%s%s" % [GameIdCatalog.LEGACY_OBSERVATION_FLAG_PREFIX, legacy_id, GameIdCatalog.LEGACY_OBSERVATION_FLAG_SUFFIX]


static func observation_value(legacy_id: String) -> String:
	return "%s%s%s" % [GameIdCatalog.LEGACY_OBSERVATION_VALUE_PREFIX, legacy_id, GameIdCatalog.LEGACY_OBSERVATION_VALUE_SUFFIX]
