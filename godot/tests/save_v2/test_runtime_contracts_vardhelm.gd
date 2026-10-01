extends RefCounted

## Bloco C5 — contratos de runtime com o Vardhelm REAL.
##   jogo principal: Durn -> diálogo -> quest -> Primeiro Eco -> observação -> Ctrl+S -> Ctrl+L
##   depois: GameState V2 -> RestorePlan -> adapters -> VardhelmRuntimeStateProvider -> sandbox
## Nenhum método privado do slice é chamado pelo Save V2; o jogo principal nunca é tocado.

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


## Estado funcional (mesma leitura do C4) + diálogo persistente.
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
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
	}


func _main_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress,
		_functional(slice), slice.dialogue_controller.is_active(), slice.dialogue_box.visible, slice.status_label.text,
		slice.player.global_position, slice.player.global_rotation], "", true)


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
	main.shadow_save_v2.service = SaveV2Service.new(TEST_DIR + "/contracts_vardhelm.json")
	main.player.global_position = Vector3(-1.5, 0.25, 1.75)
	main._npc_interactable.interact(main.player)
	_press_choice(main, 0)
	main.dialogue_box.continue_button.pressed.emit()
	main.dialogue_box.continue_button.pressed.emit()
	main.echo.interact(main.player)
	_observation(main, "maintenance_board").interact(main.player)
	_key(t, KEY_S)
	_key(t, KEY_L)
	var main_before := _main_json(main)
	var main_events := main.shadow_events.published_count()
	var main_functional := _functional(main)
	var original_shadow := main.shadow_state.game_state

	t.section("C5 Vardhelm — destino de diálogo no jogo principal")
	var main_dialogue := main.dialogue_controller.persistent_state
	t.check(main_dialogue.is_completed("vardhelm_intro") and main_dialogue.last_choice("vardhelm_intro", "start") == "learn", "DialogueController registrou conclusão + última escolha (start -> learn)")
	var main_projection := GameStateProjector.project(main.narrative_controller.world_state, main.quest_controller.states, null, main_dialogue).state
	t.check(t.same_json(main_projection.dialogue.to_dict(), original_shadow.dialogue.to_dict()), "destino de runtime == DialogueState do GameState sombra")
	t.check(not main.dialogue_controller.is_active() and main.dialogue_controller.current_session == null, "nenhuma sessão transitória após o diálogo")

	# --- diagnóstico ------------------------------------------------------
	t.section("C5 Vardhelm — plano")
	var loaded := main.shadow_save_v2.service.load_game_state()
	t.check(loaded.ok, "GameState V2 carregado (%s)" % loaded.describe())
	if not loaded.ok:
		main.queue_free()
		return
	var state := loaded.state
	var restorer := GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default())
	var plan := restorer.diagnose(state)
	var counts := plan.counts()
	print("   info plano do fluxo real (C5): ", counts)
	for item in plan.by_step("dialogue"):
		print("   info ", item["source_path"], " -> ", item["destination"], " [", item["status"], "]")
	t.check(counts["supported"] == 13 and counts["adapter-supported"] == 10 and counts["requires_adapter"] == 0 and counts["unsupported"] == 0 and counts["not_implemented"] == 1, "fluxo real: 13 supported · 10 adapter-supported · 0 requires_adapter · 0 unsupported · 1 not_implemented")
	t.check(state.dialogue.is_completed(GameIdCatalog.DIALOGUE_INTRO) and state.dialogue.get_choice(GameIdCatalog.DIALOGUE_INTRO, "start") == "learn", "Save V2 preserva dialogue.completed + dialogue.choices")

	# --- sandbox via provider ---------------------------------------------
	t.section("C5 Vardhelm — GameState -> RestorePlan -> Adapter -> Provider -> Sandbox")
	var sandbox := _sandbox(t, "ContractSandbox")
	var provider := VardhelmRuntimeStateProvider.new(sandbox)
	var targets := provider.build_targets()
	t.check(not targets.is_sandbox, "provider não declara sandbox sozinho")
	targets.is_sandbox = true
	t.check(targets.derivations == provider and targets.dialogue_state == sandbox.dialogue_controller.persistent_state, "alvos montados pelo provider (derivações + destino de diálogo)")
	var result := restorer.apply_to_sandbox(state, targets)
	t.check(result.success and not result.partial_failure, "restauração concluída (%s)" % str(result.errors))
	t.check(Array(result.completed_steps) == RestorePlan.STEPS, "ordem: %s" % " → ".join(PackedStringArray(result.completed_steps)))
	var dialogue := sandbox.dialogue_controller.persistent_state
	t.check(dialogue.is_completed("vardhelm_intro") and dialogue.last_choice("vardhelm_intro", "start") == "learn", "diálogo restaurado: completed + última escolha")
	t.check(not sandbox.dialogue_controller.is_active() and not sandbox.dialogue_box.visible, "conversa NÃO reaberta; caixa de diálogo oculta (transiente não restaurado)")

	t.section("C5 Vardhelm — derivações pelo provider")
	var echo := provider.describe_echo(GameIdCatalog.ECHO_FIRST)
	t.check(echo == {"revealed": true, "interaction_enabled": false}, "10. Eco derivado: resolvido, sem interação")
	t.check(provider.describe_observation(GameIdCatalog.OBSERVATION_MAINTENANCE_BOARD) == {"revealed": true, "fragment_registered": true} and provider.describe_observation(GameIdCatalog.OBSERVATION_TOOL_RACK) == {"revealed": false, "fragment_registered": false}, "9. observação derivada pelo ID canônico (descoberta × padrão)")
	t.check(provider.describe_quest_presentation("quest.vardhelm.first_echo") == {"completion_presented": true}, "12. apresentação da quest derivada (conclusão apresentada)")
	t.check(provider.environment_state_ids().has(GameIdCatalog.ENVSTATE_ECHO_AWAKENED), "11. estado de ambiente derivado (envstate.vardhelm.echo_awakened)")
	var restored := GameStateProjector.project(targets.world_state, targets.quest_state, targets.player, targets.dialogue_state).state
	t.check(t.same_json(restored.memory.to_dict(), state.memory.to_dict()), "13. memórias derivadas == GameState (Eco = memória; observação = fragmento)")
	t.check(restored.memory.is_fragment("memory.vardhelm.maintenance_board") and restored.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo", "13. fragmento continua fragmento, sem composição")
	t.check(t.same_json(restored.world.consequences, state.world.consequences), "14. consequências derivadas (com fonte do catálogo) == GameState")
	t.check(not restored.world.consequences.has("memory.vardhelm.first_echo") and not restored.memory.memories.has("consequence.vardhelm.first_echo_complete"), "memory ≠ consequence no runtime restaurado")

	t.section("C5 Vardhelm — comparação")
	var diff := result.differences
	print("   info sandbox × GameState carregado: ", diff["summary"])
	t.check(diff["differences"].is_empty() and diff["missing_in_left"].is_empty() and diff["missing_in_right"].is_empty() and diff["unexpected_ids"].is_empty(), "runtime sandbox × GameState carregado: 0 diferenças, nada faltando (diálogo incluído)")
	var original_vs_restored := GameStateComparator.compare(original_shadow, restored, "original", "restaurado")
	t.check(original_vs_restored.is_equal(), "GameState original (sombra) == GameState restaurado (%s)" % original_vs_restored.summary())
	var restored_functional := _functional(sandbox)
	# C8: o bug da esfera (EchoMemoryInteractable guardava o nó visual antes de ele
	# existir) foi corrigido; ao vivo e restaurado coincidem.
	t.check(main_functional["echo_visual"] == false and restored_functional["echo_visual"] == false, "C8: esfera do Eco consistente — oculta ao vivo e no restaurado (bug corrigido)")
	var comparable_main := main_functional.duplicate(true)
	var comparable_restored := restored_functional.duplicate(true)
	comparable_main.erase("echo_visual")
	comparable_restored.erase("echo_visual")
	t.check(t.same_json(comparable_restored, comparable_main), "sandbox == jogo principal em todo o estado funcional + diálogo persistente (exceto o bug conhecido)")
	t.check(sandbox.shadow_events.published_count() == 1, "adapters/provider não publicam eventos")

	# --- jogo principal intacto ------------------------------------------
	t.section("C5 Vardhelm — jogo principal intacto")
	t.check(_main_json(main) == main_before, "ZERO diferenças no runtime principal (incluindo diálogo) após diagnóstico + provider + sandbox")
	t.check(main.shadow_events.published_count() == main_events, "nenhum evento novo no jogo principal")
	t.check(main.shadow_state.game_state == original_shadow, "GameState sombra do jogo principal não substituído")

	sandbox.queue_free()
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
