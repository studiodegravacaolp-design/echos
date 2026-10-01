extends RefCounted

## Bloco C5 — contratos de runtime (sem a cena de Vardhelm):
##   DialogueRuntimeState (persistente × transiente, identidade por IDs),
##   DialogueRestoreAdapter, RuntimeStateDerivationContract e a ausência de
##   dependência do Save V2 em métodos privados da experiência.
## O fluxo real com o VardhelmRuntimeStateProvider está em test_runtime_contracts_vardhelm.gd.

const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const DIALOGUE_ID := "dialogue.vardhelm.intro"
const RUNTIME_DIALOGUE_ID := "vardhelm_intro"

## Tokens que o Save V2 / GameState não podem usar em código (fora de comentários).
const FORBIDDEN_IN_SAVE_V2 := [
	"VardhelmVerticalSlice", "VardhelmAmbientLife", "AmbientLife/", "EnvironmentalObservation", "EchoMemoryInteractable",
	"_apply_loaded_visual_state", "_refresh_objective_text", "_refresh_persistent_world_state", "Callable(", "get_node",
]
const FORBIDDEN_IN_STATE := ["VardhelmVerticalSlice", "_apply_loaded_visual_state", "_refresh_objective_text", "_refresh_persistent_world_state"]

var _nodes: Array[Node] = []


func run(t) -> void:
	_test_dialogue_contract(t)
	_test_controller_records(t)
	_test_transient_not_persisted(t)
	_test_identity(t)
	_test_dialogue_restore(t)
	_test_dialogue_restore_limits(t)
	_test_no_duplication(t)
	_test_derivation_contract(t)
	_test_no_private_dependency(t)
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()


func _dialogue() -> DialogueData:
	return JSON_LOADER.load_dialogue(DIALOGUE_PATH)


func _controller() -> DialogueController:
	var controller := DialogueController.new()
	_nodes.append(controller)
	return controller


func _targets(t, with_dialogue: bool = true) -> RuntimeRestoreTargets:
	var targets := RuntimeRestoreTargets.new()
	targets.is_sandbox = true
	targets.scenario_id = GameIdCatalog.SCENARIO_VARDHELM
	var player := Node3D.new()
	t.root.add_child(player)
	_nodes.append(player)
	targets.player = player
	targets.world_state = WorldState.new()
	targets.quest_state = QuestState.new()
	if with_dialogue:
		targets.dialogue_state = DialogueRuntimeState.new()
		targets.dialogue_definitions = {DIALOGUE_ID: _dialogue()}
	return targets


func _dialogue_state() -> GameState:
	var state := GameState.new()
	state.dialogue.mark_completed(DIALOGUE_ID)
	state.dialogue.record_choice(DIALOGUE_ID, "start", "learn")
	return state


func _restorer() -> GameStateRuntimeRestorer:
	return GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default())


func _adapter_result(result: RestoreResult, adapter_id: String) -> Dictionary:
	for entry in result.adapter_results:
		if entry["adapter"] == adapter_id:
			return entry
	return {}


# 1–5. contrato do DialogueRuntimeState
func _test_dialogue_contract(t) -> void:
	t.section("C5 — DialogueRuntimeState (contrato)")
	var runtime := DialogueRuntimeState.new()
	t.check(not runtime.is_completed(RUNTIME_DIALOGUE_ID) and runtime.last_choice(RUNTIME_DIALOGUE_ID, "start") == "", "1/2. estado vazio: não concluído, sem escolha")
	runtime.mark_completed(RUNTIME_DIALOGUE_ID)
	t.check(runtime.is_completed(RUNTIME_DIALOGUE_ID), "1. diálogo concluído consultável por dialogue_id")
	runtime.record_choice(RUNTIME_DIALOGUE_ID, "start", "leave")
	runtime.record_choice(RUNTIME_DIALOGUE_ID, "start", "learn")
	t.check(runtime.last_choice(RUNTIME_DIALOGUE_ID, "start") == "learn" and (runtime.choices[RUNTIME_DIALOGUE_ID] as Dictionary).size() == 1, "2. última escolha por dialogue_id + entry_id (substitui; sem histórico)")
	t.check(not runtime.record_choice(RUNTIME_DIALOGUE_ID, "", "learn") and not runtime.record_choice("", "start", "learn") and not runtime.record_choice(RUNTIME_DIALOGUE_ID, "start", ""), "4/5. entry_id e choice_id obrigatórios")
	var data := runtime.to_dict()
	var keys := data.keys()
	keys.sort()
	t.check(keys == ["choices", "completed"] and Array(DialogueRuntimeState.PERSISTENT_FIELDS) == ["completed", "choices"], "persistente = só completed + choices (sem timestamps, sem UI)")
	var transient := Array(DialogueRuntimeState.TRANSIENT_FIELDS)
	var required := ["current_session", "current_entry", "visible_choices", "speaker", "text", "animation", "dialogue_box_visible"]
	t.check(required.all(func(field): return transient.has(field)), "6. transientes declarados: sessão, entrada atual, escolhas visíveis, falante, texto, animação, visibilidade da caixa")
	var dialogue := _dialogue()
	t.check(DialogueRuntimeState.can_restore_choice(dialogue, "start", "learn") and DialogueRuntimeState.can_restore_choice(dialogue, "start", "leave"), "3. escolha existente na definição: restaurável")
	t.check(not DialogueRuntimeState.can_restore_choice(dialogue, "start", "ghost") and not DialogueRuntimeState.can_restore_choice(dialogue, "nowhere", "learn") and not DialogueRuntimeState.can_restore_choice(null, "start", "learn"), "3. escolha/entrada inexistente ou sem definição: não restaurável")
	t.check(DialogueRuntimeState.can_restore_completed(dialogue) and not DialogueRuntimeState.can_restore_completed(null), "3. conclusão restaurável só com definição válida")
	runtime.restore([RUNTIME_DIALOGUE_ID], {})
	t.check(runtime.is_completed(RUNTIME_DIALOGUE_ID) and runtime.choices.is_empty(), "restore substitui o estado inteiro (nada mesclado)")


# DialogueController como dono do destino
func _test_controller_records(t) -> void:
	t.section("C5 — DialogueController.persistent_state")
	var controller := _controller()
	t.check(controller.persistent_state is DialogueRuntimeState, "DialogueController possui o destino persistente")
	controller.start_dialogue(_dialogue(), "start")
	controller.select_choice("learn")
	t.check(controller.persistent_state.last_choice(RUNTIME_DIALOGUE_ID, "start") == "learn", "escolha aceita registrada por dialogue_id + entry_id + choice_id")
	t.check(not controller.persistent_state.is_completed(RUNTIME_DIALOGUE_ID), "sessão em andamento não conta como concluída")
	t.check(not controller.select_choice("ghost") and controller.persistent_state.last_choice(RUNTIME_DIALOGUE_ID, "memory") == "", "escolha inexistente não é registrada")
	controller.advance()
	controller.advance()
	t.check(not controller.is_active() and controller.persistent_state.is_completed(RUNTIME_DIALOGUE_ID), "diálogo terminado: concluído")
	var aborted := _controller()
	aborted.start_dialogue(_dialogue(), "start")
	aborted.end_dialogue()
	t.check(aborted.persistent_state.is_completed(RUNTIME_DIALOGUE_ID) and aborted.persistent_state.choices.is_empty(), "end_dialogue conta como concluído (mesma regra do evento dialogue_completed do B1)")


# 6. transiente fora do GameState — teste crítico
func _test_transient_not_persisted(t) -> void:
	t.section("C5 — estado transitório de diálogo fora do GameState")
	var bus := GameEventBus.new()
	var recorder := GameStateShadowRecorder.new()
	recorder.attach(bus)
	var publisher := GameplayEventPublisher.new(bus)
	var controller := _controller()
	publisher.observe_dialogue(controller)
	var dialogue := _dialogue()
	controller.start_dialogue(dialogue, "start")
	publisher.handle_choice_submitted("learn")
	controller.select_choice("learn")
	# Sessão transitória aberta: entrada atual, escolhas visíveis e texto.
	var current := controller.get_current_entry()
	t.check(controller.is_active() and current.entry_id == "memory", "sessão transitória aberta (current_entry = memory)")
	var state_json := JSON.stringify(recorder.snapshot())
	var dialogue_section: Dictionary = recorder.game_state.dialogue.to_dict()
	var section_keys := dialogue_section.keys()
	section_keys.sort()
	t.check(section_keys == ["choices", "completed"], "GameState.dialogue só tem completed + choices")
	t.check(dialogue_section["completed"].is_empty() and dialogue_section["choices"] == {DIALOGUE_ID: {"start": "learn"}}, "GameState: só a escolha (sem conclusão enquanto a sessão está aberta)")
	var leaked: Array = []
	for fragment in [current.text, dialogue.get_entry("start").text, current.speaker_id, "current_entry", "current_session", "selected_choice", "dialogue.vardhelm.choice.memory"]:
		if state_json.contains(String(fragment)):
			leaked.append(fragment)
	t.check(leaked.is_empty(), "nada transitório no GameState (texto, falante, entrada atual, sessão, rótulo da escolha): %s" % str(leaked))
	var runtime_json := JSON.stringify(controller.persistent_state.to_dict())
	t.check(not runtime_json.contains(current.text) and not runtime_json.contains("memory"), "nada transitório no DialogueRuntimeState")


# 3–5. identidade por IDs — teste crítico
func _test_identity(t) -> void:
	t.section("C5 — identidade de diálogo por IDs")
	var original := _dialogue()
	var altered := _dialogue()
	for entry: DialogueEntry in altered.entries:
		entry.text = "TEXTO ALTERADO " + entry.entry_id
		entry.speaker_id = "falante.alterado"
		for choice: DialogueChoice in entry.choices:
			choice.text_key = "rotulo.alterado." + choice.choice_id
	altered.get_entry("start").choices.reverse()
	var results: Array = []
	for data in [original, altered]:
		var bus := GameEventBus.new()
		var recorder := GameStateShadowRecorder.new()
		recorder.attach(bus)
		var publisher := GameplayEventPublisher.new(bus)
		var controller := _controller()
		publisher.observe_dialogue(controller)
		controller.start_dialogue(data, "start")
		publisher.handle_choice_submitted("learn")
		controller.select_choice("learn")
		controller.advance()
		controller.advance()
		results.append([controller.persistent_state.to_dict(), recorder.game_state.dialogue.to_dict()])
	t.check(altered.get_entry("start").choices[0].choice_id == "leave", "índice visual alterado (escolhas invertidas)")
	t.check(t.same_json(results[0][0], results[1][0]), "runtime: texto/falante/rótulo/índice alterados -> mesmo estado persistente")
	t.check(t.same_json(results[0][1], results[1][1]), "GameState: mesmo DialogueState (IDs persistentes inalterados)")
	t.check(results[1][1] == {"completed": {DIALOGUE_ID: true}, "choices": {DIALOGUE_ID: {"start": "learn"}}}, "chave = dialogue_id canônico + entry_id + choice_id")


# 1–5. restauração do diálogo no sandbox — teste crítico
func _test_dialogue_restore(t) -> void:
	t.section("C5 — restauração do diálogo (sandbox)")
	var state := _dialogue_state()
	var plan := _restorer().diagnose(state)
	var completed_item := plan.find("dialogue.completed.%s" % DIALOGUE_ID)
	var choice_item := plan.find("dialogue.choices.%s.start" % DIALOGUE_ID)
	t.check(completed_item["status"] == "adapter-supported" and String(completed_item["destination"]).contains("DialogueRuntimeState.completed[vardhelm_intro]"), "dialogue.completed: adapter-supported -> DialogueRuntimeState")
	t.check(choice_item["status"] == "adapter-supported" and String(choice_item["destination"]).contains("[vardhelm_intro][start]"), "dialogue.choices: adapter-supported -> última escolha por entry")
	var targets := _targets(t)
	# Sessão transitória aberta no mesmo runtime: a restauração não pode tocá-la.
	var controller := _controller()
	controller.persistent_state = targets.dialogue_state
	controller.start_dialogue(_dialogue(), "start")
	var session := controller.current_session
	var result := _restorer().apply_to_sandbox(state, targets)
	t.check(result.success and not result.partial_failure, "restauração concluída (%s)" % str(result.errors))
	t.check(targets.dialogue_state.is_completed(RUNTIME_DIALOGUE_ID), "completed = true no runtime")
	t.check(targets.dialogue_state.last_choice(RUNTIME_DIALOGUE_ID, "start") == "learn", "última escolha correta (start -> learn)")
	t.check(Array(_adapter_result(result, "dialogue")["applied"]).size() == 2, "adapter aplicou e verificou os 2 registros")
	t.check(controller.current_session == session and session.current_entry_id == "start", "sessão transitória não foi restaurada nem alterada")
	var diff := result.differences
	t.check(diff["differences"].is_empty() and diff["missing_in_left"].is_empty() and diff["missing_in_right"].is_empty(), "runtime restaurado × GameState: diálogo idêntico (%s)" % diff["summary"])
	var restored := GameStateProjector.project(targets.world_state, targets.quest_state, null, targets.dialogue_state).state
	t.check(t.same_json(restored.dialogue.to_dict(), state.dialogue.to_dict()), "projeção do runtime devolve o mesmo DialogueState")
	var stale := _targets(t)
	stale.dialogue_state.record_choice(RUNTIME_DIALOGUE_ID, "start", "leave")
	stale.dialogue_state.mark_completed("outro_dialogo")
	_restorer().apply_to_sandbox(GameState.new(), stale)
	t.check(stale.dialogue_state.completed.is_empty() and stale.dialogue_state.choices.is_empty(), "GameState sem diálogo: destino volta ao padrão (nada inventado)")


func _test_dialogue_restore_limits(t) -> void:
	t.section("C5 — diálogo: limites explícitos")
	var ghost := _dialogue_state()
	ghost.dialogue.record_choice(DIALOGUE_ID, "memory", "ghost")
	var targets := _targets(t)
	var result := _restorer().apply_to_sandbox(ghost, targets)
	var entry := _adapter_result(result, "dialogue")
	t.check(result.success and Array(entry["unsupported"]).has("dialogue.choices.%s.memory" % DIALOGUE_ID) and targets.dialogue_state.last_choice(RUNTIME_DIALOGUE_ID, "memory") == "", "escolha que não existe na definição: unsupported, não inventada")
	var unknown := GameState.new()
	unknown.dialogue.mark_completed("dialogue.outro.x")
	t.check(_restorer().diagnose(unknown).find("dialogue.completed.dialogue.outro.x")["status"] == "unsupported", "dialogue_id sem alias no catálogo: unsupported")
	var no_definition := _targets(t)
	no_definition.dialogue_definitions = {}
	var undefined := _restorer().apply_to_sandbox(_dialogue_state(), no_definition)
	t.check(undefined.success and Array(_adapter_result(undefined, "dialogue")["requires_adapter"]).size() == 2, "sem definição do diálogo: requires_adapter (não restaura às cegas)")
	var no_destination := _restorer().apply_to_sandbox(_dialogue_state(), _targets(t, false))
	t.check(no_destination.success and Array(_adapter_result(no_destination, "dialogue")["requires_adapter"]).size() == 2, "sem destino no sandbox: requires_adapter com motivo")


# Teste crítico — não duplicação memória × consequência
func _test_no_duplication(t) -> void:
	t.section("C5 — memória ≠ consequência")
	var state := _dialogue_state()
	state.world.set_flag("vardhelm_first_echo_complete")
	state.world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first")
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.quests.set_objective_complete("quest.vardhelm.first_echo", "observe")
	state.quests.complete_quest("quest.vardhelm.first_echo")
	state.memory.resolve_echo("echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	var targets := _targets(t)
	var result := _restorer().apply_to_sandbox(state, targets)
	var restored := GameStateProjector.project(targets.world_state, targets.quest_state, null, targets.dialogue_state).state
	t.check(result.success, "restauração concluída (%s)" % str(result.errors))
	t.check(not restored.world.consequences.has("memory.vardhelm.first_echo") and not state.world.consequences.has("memory.vardhelm.first_echo"), "memory.vardhelm.first_echo não aparece como consequence")
	t.check(not restored.memory.memories.has("consequence.vardhelm.first_echo_complete") and not state.memory.memories.has("consequence.vardhelm.first_echo_complete"), "consequence.vardhelm.first_echo_complete não aparece como memory")
	t.check(restored.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and restored.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo", "14/13. consequência derivada continua consequência; memória derivada continua memória (origem echo)")
	t.check(targets.world_state.memories.count("vardhelm_first_echo_complete") == 1 and not Array(targets.world_state.memories).has("vardhelm_first_echo_memory"), "WorldState.memories: consequência uma vez, memória nunca")


# 7. contrato de derivação
func _test_derivation_contract(t) -> void:
	t.section("C5 — RuntimeStateDerivationContract")
	var base := RuntimeStateDerivationContract.new()
	t.check(base.observation_ids().is_empty() and not base.derive_observation_state("observation.vardhelm.tool_rack", true) and base.describe_observation("observation.vardhelm.tool_rack").is_empty(), "padrão: observação não derivável")
	t.check(base.echo_ids().is_empty() and not base.derive_echo_state() and base.describe_echo(GameIdCatalog.ECHO_FIRST).is_empty(), "padrão: Eco não derivável")
	t.check(not base.derive_quest_presentation() and base.describe_quest_presentation("quest.vardhelm.first_echo").is_empty(), "padrão: apresentação da quest não derivável")
	t.check(not base.derive_environment_state() and base.environment_state_ids().is_empty(), "padrão: ambiente não derivável")
	var base_object: Variant = base
	t.check(base_object is RefCounted and not (base_object is Node), "contrato é objeto comum (não nó, não Autoload)")
	var state := _dialogue_state()
	state.world.set_flag("observation_maintenance_board_seen")
	state.world.discover_observation("observation.vardhelm.maintenance_board")
	state.quests.start_quest("quest.vardhelm.first_echo")
	var targets := _targets(t)
	var result := _restorer().apply_to_sandbox(state, targets)
	t.check(result.success and Array(_adapter_result(result, "quest_presentation")["requires_adapter"]).size() == 1 and Array(_adapter_result(result, "environment_presentation")["requires_adapter"]).size() == 1 and Array(_adapter_result(result, "observation")["requires_adapter"]).size() == 1, "sem derivações no sandbox: requires_adapter, sem falha e sem inventar")


# 8. nenhum Callable privado / dependência da experiência no Save V2 — teste crítico
func _test_no_private_dependency(t) -> void:
	t.section("C5 — sem dependência de métodos privados da experiência")
	var callables: Array = []
	var removed: Array = []
	var properties: Array = []
	for property in RuntimeRestoreTargets.new().get_property_list():
		properties.append(property["name"])
		if property["type"] == TYPE_CALLABLE:
			callables.append(property["name"])
	for name in ["echo_state_refresher", "quest_presentation_refresher", "environment_refresher", "ambient_life", "observations", "echoes"]:
		if properties.has(name):
			removed.append(name)
	t.check(callables.is_empty(), "RuntimeRestoreTargets sem nenhuma propriedade Callable (%s)" % str(callables))
	t.check(removed.is_empty(), "RuntimeRestoreTargets sem nós/derivações específicos da experiência (%s)" % str(removed))
	t.check(properties.has("derivations") and properties.has("dialogue_state"), "RuntimeRestoreTargets usa contratos formais (derivations, dialogue_state)")
	# O detector reprova o padrão do C4 (prova de que o teste falharia).
	t.check(not _violations("targets.echo_state_refresher = Callable(slice, \"_apply_loaded_visual_state\")", FORBIDDEN_IN_SAVE_V2).is_empty(), "detector reprova Callable para método privado do slice")
	var save_v2 := _scan("res://scripts/save_v2", FORBIDDEN_IN_SAVE_V2)
	t.check(save_v2.is_empty(), "Save V2 / RestorePlan / adapters sem VardhelmVerticalSlice, nós, AmbientLife ou métodos privados: %s" % str(save_v2))
	var state := _scan("res://scripts/state", FORBIDDEN_IN_STATE)
	t.check(state.is_empty(), "GameState sem dependência do slice: %s" % str(state))
	var provider := FileAccess.get_file_as_string("res://scripts/vardhelm/vardhelm_runtime_state_provider.gd")
	var private_access := RegEx.create_from_string("_slice\\._[a-z]")
	t.check(not provider.is_empty() and private_access.search(provider) == null, "VardhelmRuntimeStateProvider usa só a superfície pública do slice")
	var used := ["derive_echo_state", "derive_quest_presentation", "derive_environment_state"]
	t.check(used.all(func(method): return provider.contains("_slice.%s()" % method)), "provider chama as derivações públicas derive_* do slice")


func _scan(root: String, forbidden: Array) -> Array:
	var out: Array = []
	var dir := DirAccess.open(root)
	if dir == null:
		return ["diretório ausente: %s" % root]
	for file_name in dir.get_files():
		if file_name.ends_with(".gd"):
			var path := "%s/%s" % [root, file_name]
			for violation in _violations(FileAccess.get_file_as_string(path), forbidden):
				out.append("%s: %s" % [file_name, violation])
	for sub in dir.get_directories():
		out.append_array(_scan("%s/%s" % [root, sub], forbidden))
	return out


## Tokens proibidos em linhas de código (comentários ignorados).
func _violations(source: String, forbidden: Array) -> Array:
	var out: Array = []
	for line in source.split("\n"):
		var code := line.strip_edges()
		if code.begins_with("#"):
			continue
		var comment := code.find(" #")
		if comment >= 0:
			code = code.substr(0, comment)
		for token in forbidden:
			if code.contains(String(token)):
				out.append(token)
	return out
