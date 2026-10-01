extends RefCounted

## Bloco C4 — adapters com o Vardhelm REAL.
##   jogo principal: Durn -> diálogo -> quest -> Primeiro Eco -> observação -> Ctrl+S -> Ctrl+L
##   depois: V2 -> diagnóstico (adapters) -> sandboxes (2ª/3ª instâncias) -> comparação
## As derivações chegam pelo VardhelmRuntimeStateProvider (C5) do sandbox. O jogo
## principal nunca é tocado.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _key(t, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	t.root.push_input(event)


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


## Estado funcional/apresentação derivado (sem textos transitórios de status).
func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in ["maintenance_board", "sealed_panel", "tool_rack"]:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo_revealed": slice.echo.revealed,
		"echo_interaction": slice.echo.interaction_enabled,
		"echo_visual": (slice.echo.get_node("Visual") as MeshInstance3D).visible,
		"afterglow": slice._post_echo_marker.visible,
		"banner": slice.completion_banner.visible,
		"objective": slice.objective_label.text,
		"environment_states": env,
		"observations": observations,
		"npc_interaction": slice.npc.interaction_enabled,
	}


func _main_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress,
		_functional(slice), slice.status_label.text, slice.player.global_position, slice.player.global_rotation], "", true)


func _targets_for(slice: VardhelmVerticalSlice) -> RuntimeRestoreTargets:
	# C5: alvos e derivações pelo contrato formal (VardhelmRuntimeStateProvider);
	# nenhum método privado do slice é passado ao Save V2.
	var targets := VardhelmRuntimeStateProvider.new(slice).build_targets()
	targets.is_sandbox = true
	return targets


func _sandbox(t, name: String) -> VardhelmVerticalSlice:
	var sandbox := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	sandbox.name = name
	t.root.add_child(sandbox)
	sandbox.player.set_physics_process(false)
	sandbox.shadow_save_v2 = null
	return sandbox


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null

	# --- jogo principal ---------------------------------------------------
	_isolate(t)
	var main := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(main)
	# C10.5: V2 é o padrão; esta suíte testa explicitamente o caminho LEGADO (+ sombra C2).
	main.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	main.shadow_save_v2.service = SaveV2Service.new(TEST_DIR + "/adapters_vardhelm.json")
	main.player.global_position = Vector3(-1.5, 0.25, 1.75)
	main._npc_interactable.interact(main.player)
	_press_choice(main, 0)
	main.dialogue_box.continue_button.pressed.emit()
	main.dialogue_box.continue_button.pressed.emit()
	# Ponto "Eco ainda não resolvido": GameState sombra + estado funcional do jogo.
	var pre_echo_state := GameState.from_dict(main.shadow_state.snapshot())
	var pre_echo_functional := _functional(main)
	main.echo.interact(main.player)
	_observation(main, "maintenance_board").interact(main.player)
	_key(t, KEY_S)
	_key(t, KEY_L)
	var main_before := _main_json(main)
	var main_events := main.shadow_events.published_count()
	var main_functional := _functional(main)
	var original_shadow := main.shadow_state.game_state

	# --- diagnóstico ------------------------------------------------------
	t.section("C4 Vardhelm — diagnóstico com adapters")
	var loaded := main.shadow_save_v2.service.load_game_state()
	t.check(loaded.ok, "GameState V2 carregado (%s)" % loaded.describe())
	if not loaded.ok:
		main.queue_free()
		return
	var state := loaded.state
	var restorer := GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default())
	var plan := restorer.diagnose(state)
	var counts := plan.counts()
	print("   info plano do fluxo real (C4): ", counts)
	for item in plan.by_status("adapter-supported"):
		print("   info adapter-supported: ", item["source_path"], " -> ", item["destination"])
	for item in plan.by_status("requires_adapter"):
		print("   info requires_adapter: ", item["source_path"], " — ", item["note"])
	t.check(counts["supported"] == 13 and counts["adapter-supported"] == 10 and counts["requires_adapter"] == 0 and counts["unsupported"] == 0 and counts["not_implemented"] == 1, "fluxo real (C5): 13 supported · 10 adapter-supported · 0 requires_adapter · 0 unsupported · 1 not_implemented")
	var original_vs_loaded := GameStateComparator.compare(original_shadow, state, "original", "carregado")
	t.check(original_vs_loaded.is_equal(), "GameState original (sombra) == GameState carregado (%s)" % original_vs_loaded.summary())

	# --- sandbox: Eco resolvido ------------------------------------------
	t.section("C4 Vardhelm — sandbox (Eco resolvido)")
	var sandbox := _sandbox(t, "AdapterSandbox")
	var result := restorer.apply_to_sandbox(state, _targets_for(sandbox))
	t.check(result.success and not result.partial_failure, "restauração com adapters no sandbox (%s)" % str(result.errors))
	t.check(Array(result.completed_steps) == RestorePlan.STEPS, "ordem: %s" % " → ".join(PackedStringArray(result.completed_steps)))
	var restored := _functional(sandbox)
	print("   info principal: ", JSON.stringify(main_functional, "", true))
	print("   info sandbox:   ", JSON.stringify(restored, "", true))
	# C4 registrou aqui um defeito pré-existente (EchoMemoryInteractable guardava
	# `_visual` antes de o slice criar o nó; a esfera ficava visível ao vivo).
	# Corrigido no C8: ao vivo e restaurado precisam coincidir.
	t.check(main_functional["echo_visual"] == false and restored["echo_visual"] == false, "C8: esfera do Eco consistente — oculta ao vivo e no restaurado (bug corrigido)")
	var comparable_main := main_functional.duplicate(true)
	var comparable_restored := restored.duplicate(true)
	comparable_main.erase("echo_visual")
	comparable_restored.erase("echo_visual")
	t.check(JSON.stringify(comparable_restored, "", true) == JSON.stringify(comparable_main, "", true), "sandbox volta ao MESMO estado funcional do jogo (Eco, interação, marcador, banner, objetivo, ambiente, observações, NPC)")
	t.check(restored["environment_states"].has("echo_awakened"), "AmbientLife reconstruiu echo_awakened a partir do estado restaurado")
	var diff := result.differences
	var missing_ok := true
	for path in diff["missing_in_right"]:
		if not String(path).begins_with("dialogue."):
			missing_ok = false
	print("   info sandbox × GameState carregado: ", diff["summary"])
	t.check(diff["differences"].is_empty() and diff["missing_in_left"].is_empty() and diff["unexpected_ids"].is_empty() and missing_ok, "runtime sandbox × GameState carregado: nada falta além de diálogo (C5: nem ele)")
	var restored_state := GameStateProjector.project(sandbox.narrative_controller.world_state, sandbox.quest_controller.states, sandbox.player).state
	var original_vs_restored := GameStateComparator.compare(original_shadow, restored_state, "original", "restaurado")
	var only_dialogue := original_vs_restored.differences.is_empty() and original_vs_restored.missing_in_left.is_empty()
	for path in original_vs_restored.missing_in_right:
		if not path.begins_with("dialogue."):
			only_dialogue = false
	t.check(only_dialogue, "GameState original × GameState restaurado: só o diálogo difere (%s)" % original_vs_restored.summary())
	t.check(sandbox.shadow_events.published_count() == 1, "adapters não publicam eventos")

	# --- sandbox: Eco não resolvido --------------------------------------
	t.section("C4 Vardhelm — sandbox (Eco não resolvido)")
	var sandbox2 := _sandbox(t, "AdapterSandboxPreEcho")
	var pre := restorer.apply_to_sandbox(pre_echo_state, _targets_for(sandbox2))
	var pre_restored := _functional(sandbox2)
	pre_restored["npc_interaction"] = pre_echo_functional["npc_interaction"]
	t.check(pre.success, "restauração do estado pré-Eco (%s)" % str(pre.errors))
	t.check(not sandbox2.echo.revealed and sandbox2.echo.interaction_enabled, "Eco não resolvido: oculto e interativo, como no jogo antes do Eco")
	t.check(JSON.stringify(pre_restored, "", true) == JSON.stringify(pre_echo_functional, "", true), "estado funcional pré-Eco reproduzido (objetivo, Eco, ambiente, observações)")

	# --- jogo principal intacto ------------------------------------------
	t.section("C4 Vardhelm — jogo principal intacto")
	t.check(_main_json(main) == main_before, "ZERO diferenças no runtime principal após diagnóstico + adapters + sandboxes")
	t.check(main.shadow_events.published_count() == main_events, "nenhum evento novo no jogo principal")
	t.check(main.shadow_state.game_state == original_shadow, "GameState sombra do jogo principal não substituído")

	sandbox.queue_free()
	sandbox2.queue_free()
	main.queue_free()
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	if backup != null:
		var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
		file.store_string(String(backup))
		file.close()
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)
