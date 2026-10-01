extends RefCounted

## Bloco C9 — prontidão de adoção com o Vardhelm REAL (headless; a série
## renderizada é medida por c9_rendered_playtest.gd). Flags ON só nas
## instâncias de teste. UX (mensagens localizadas), saves antigos, ciclo V2,
## eventos e sincronização do GameState.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const V2_FILE := "user://save_v2_tests/echoes_of_the_soul_save_v2_shadow.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const SAVE_ROTATION := Vector3(0.0, 1.1, 0.0)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const LEGACY_TEXT := "{\"version\":2,\"language\":\"pt-BR\",\"world\":{\"flags\":{},\"values\":{},\"memories\":[]},\"quests\":{\"active\":{},\"completed\":{},\"objective_progress\":{}}}"

var _events: Array = []


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


func _new_game(t, path: String = V2_FILE) -> VardhelmVerticalSlice:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	game.name = "MainGame"
	t.root.add_child(game)
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	game.save_v2_operational_config = SaveV2OperationalConfig.create(true, path, true)
	game.player.set_physics_process(false)
	game.player.global_position = SAVE_POSITION
	game.player.global_rotation = SAVE_ROTATION
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type), [GameEventCatalog.GAME_SAVED, GameEventCatalog.GAME_LOADED])
	return game


func _talk(game: VardhelmVerticalSlice) -> void:
	game._npc_interactable.interact(game.player)
	_press_choice(game, 0)
	game.dialogue_box.continue_button.pressed.emit()
	game.dialogue_box.continue_button.pressed.emit()


func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo": [slice.echo.revealed, slice.echo.interaction_enabled, (slice.echo.get_node("Visual") as MeshInstance3D).visible, (slice.echo.get_node("Light") as OmniLight3D).visible],
		"afterglow": slice._post_echo_marker.visible, "banner": slice.completion_banner.visible, "objective": slice.objective_label.text,
		"environment_states": env, "observations": observations, "npc": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
	}


func _project(slice: VardhelmVerticalSlice) -> GameState:
	return SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(slice).build_targets())["state"]


func _text(game: VardhelmVerticalSlice, key: String) -> String:
	return game.localization.tr_key(key)


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	_test_cycle(t)
	_test_dialogue_ux(t)
	_test_failure_ux(t)
	_test_save_failure_ux(t)
	_test_legacy_saves(t)
	_isolate(t)
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


# 10–23: ciclo V2 com as duas flags ON
func _test_cycle(t) -> void:
	t.section("C9 Vardhelm — ciclo V2 (flags ON)")
	var game := _new_game(t)
	_talk(game)
	_key(t, KEY_S)
	t.check(game.last_v2_save_result.is_success() and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_SAVED), "10. V2 save + mensagem localizada")
	var before_echo := {"functional": _functional(game), "state": _project(game), "position": game.player.global_position}
	t.check(GameStateComparator.compare(game.shadow_state.game_state, before_echo["state"]).is_equal(), "23. após Save: GameState == runtime persistente")
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_LOADED), "11. V2 load + mensagem localizada")
	t.check(t.same_json(_functional(game), before_echo["functional"]) and game.player.global_position == before_echo["position"], "12/20. antes do Eco restaurado (Eco, esfera, luz, ambiente, banner, observações, posição)")
	t.check(GameStateComparator.compare(game.shadow_state.game_state, before_echo["state"]).is_equal(), "23. após Load: GameState == estado carregado")
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	_key(t, KEY_S)
	var after_echo := {"functional": _functional(game), "state": _project(game)}
	print("   info divergência sombra × runtime no save pós-load: ", game.last_v2_save_result.shadow_divergence)
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "23. novo Save não grava estado antigo (sombra == runtime)")
	game.player.global_position = MOVED_POSITION
	game.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "leave")
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	var projected := _project(game)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), after_echo["functional"]) and GameStateComparator.compare(projected, after_echo["state"]).is_equal(), "13. depois do Eco restaurado")
	t.check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn", "14. diálogo persistente")
	t.check(projected.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and not projected.memory.memories.has("consequence.vardhelm.first_echo_complete"), "15. memória (≠ consequência)")
	t.check(projected.world.observations.size() == 3, "16. observações")
	t.check(projected.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and game.narrative_controller.world_state.memories.count("vardhelm_first_echo_complete") == 1, "17. consequência, sem duplicação")
	t.check(game.quest_controller.states.is_completed("vardhelm_first_echo"), "18. quest")
	t.check(game.npc.interaction_enabled, "19. NPC")
	t.check(_events == ["game_saved", "game_loaded", "game_saved", "game_loaded"], "21. eventos só após sucesso (%s)" % str(_events))
	print("   info tempos load (headless, ms): ", game.last_v2_load_result.timings_ms)


# 3: diálogo aberto
func _test_dialogue_ux(t) -> void:
	t.section("C9 Vardhelm — UX: Load com diálogo aberto")
	var game := _new_game(t)
	_talk(game)
	_key(t, KEY_S)
	game.dialogue_controller.start_dialogue(game.dialogue_data, "start")
	var session := game.dialogue_controller.current_session
	var hint := "texto anterior do status"
	game.status_label.text = hint
	_events.clear()
	_key(t, KEY_L)
	var message := game.status_label.text
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE and message == _text(game, SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE), "3. recusa com mensagem localizada: \"%s\"" % message)
	t.check(not message.contains("LOAD_REJECTED") and game.dialogue_controller.current_session == session and game.dialogue_box.visible, "diálogo continua aberto, sessão intacta, sem código técnico")
	t.check(_events.is_empty() and game.shadow_save_v2.last_load_report.is_empty(), "22. sem evento e sem load antigo")
	game._clear_save_v2_message(message)
	t.check(game.status_label.text == hint, "mensagem some e devolve o texto anterior (timer de %.0f s)" % VardhelmVerticalSlice.SAVE_V2_MESSAGE_SECONDS)
	game.status_label.text = "outro status"
	game._clear_save_v2_message(message)
	t.check(game.status_label.text == "outro status", "não apaga um status mais recente")


# 4–5: falha de load e de rollback
func _test_failure_ux(t) -> void:
	t.section("C9 Vardhelm — UX: falhas de Load")
	var game := _new_game(t)
	_talk(game)
	_key(t, KEY_S)
	var file := FileAccess.open(V2_FILE, FileAccess.READ)
	var tampered := file.get_as_text().replace("\"learn\"", "\"leave\"")
	file.close()
	var writer := FileAccess.open(V2_FILE, FileAccess.WRITE)
	writer.store_string(tampered)
	writer.close()
	var before := JSON.stringify(_functional(game), "", true)
	_events.clear()
	_key(t, KEY_L)
	t.check(game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_LOAD_INVALID) and not game.status_label.text.contains("VALIDATION"), "4. checksum: mensagem simples, sem código (\"%s\")" % game.status_label.text)
	t.check(JSON.stringify(_functional(game), "", true) == before and _events.is_empty(), "runtime intacto, sem game_loaded")
	_key(t, KEY_S)
	game.echo.interact(game.player)
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
	coordinator.fault_injection_apply_step = "echo"
	_events.clear()
	var restored_before := JSON.stringify(_functional(game), "", true)
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal")))
	t.check(game.last_v2_load_result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_LOAD_FAILED_RESTORED), "falha com rollback: \"%s\"" % game.status_label.text)
	t.check(JSON.stringify(_functional(game), "", true) == restored_before and _events.is_empty(), "rollback: estado anterior, sem game_loaded")
	coordinator.fault_injection_rollback_step = "quests"
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal")))
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_LOAD_UNSAFE), "5. rollback falhou: \"%s\"" % game.status_label.text)
	t.check(not game.last_v2_load_result.is_success() and _events.is_empty() and game.shadow_save_v2.last_load_report.is_empty() and is_instance_valid(game) and game.is_inside_tree(), "sem sucesso falso, sem evento, sem load antigo, runtime não destruído")


# 6: falha de save
func _test_save_failure_ux(t) -> void:
	t.section("C9 Vardhelm — UX: falha de Save")
	var game := _new_game(t, TEST_DIR)
	_talk(game)
	_events.clear()
	_key(t, KEY_S)
	t.check(game.last_v2_save_result.status == SaveV2RuntimeSaveResult.WRITE_FAILURE and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_SAVE_WRITE_FAILED), "6. falha de escrita: \"%s\"" % game.status_label.text)
	t.check(_events.is_empty() and not game.status_label.text.contains("IO_ERROR"), "22. sem game_saved, sem código técnico")


# 8–9: saves antigos
func _test_legacy_saves(t) -> void:
	t.section("C9 Vardhelm — saves antigos")
	var legacy_file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
	legacy_file.store_string(LEGACY_TEXT)
	legacy_file.close()
	if FileAccess.file_exists(V2_FILE):
		DirAccess.remove_absolute(V2_FILE)
	var game := _new_game(t)
	var inventory := SaveV2PersistenceInventory.inspect(SaveService.SAVE_PATH, V2_FILE)
	t.check(inventory["scenario"] == SaveV2PersistenceInventory.SCENARIO_LEGACY_ONLY, "8. A: só save antigo detectado")
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.code == SaveV2Errors.FILE_NOT_FOUND and game.status_label.text == _text(game, SaveV2PlayerMessages.KEY_LOAD_LEGACY_ONLY), "jogador informado: \"%s\"" % game.status_label.text)
	t.check(FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_TEXT and game.shadow_save_v2.last_load_report.is_empty(), "save antigo não lido pelo V2, não alterado; sem fallback")
	_talk(game)
	_key(t, KEY_S)
	var coexist := SaveV2PersistenceInventory.inspect(SaveService.SAVE_PATH, V2_FILE)
	t.check(coexist["scenario"] == SaveV2PersistenceInventory.SCENARIO_BOTH and FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_TEXT, "9. B: antigo + V2 coexistem; V2 não sobrescreve o antigo")
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_TEXT, "com os dois presentes, o V2 carrega só o V2")
