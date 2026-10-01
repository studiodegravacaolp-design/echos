extends RefCounted

## Bloco C10 — endurecimento da adoção com o Vardhelm REAL (headless): UI
## transitória descartada após Load SUCCESS, mensagens visíveis e localizadas,
## câmera do jogo preservada pelo sandbox, velocidade zerada após teleporte, Durn,
## e o ciclo V2 completo. Flags ON só nas instâncias de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const V2_FILE := "user://save_v2_tests/echoes_of_the_soul_save_v2_shadow.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const SAVE_ROTATION := Vector3(0.0, 1.1, 0.0)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)

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


## C12: conversa até o fim; em entradas com escolhas, escolhe a primeira (o Durn pós-Eco tem duas).
func _finish_dialogue(slice: VardhelmVerticalSlice) -> void:
	while slice.dialogue_controller.is_active():
		var has_choice := false
		for child in slice.dialogue_box.choices_box.get_children():
			if child is Button and not child.is_queued_for_deletion():
				has_choice = true
		if has_choice:
			_press_choice(slice, 0)
		else:
			slice.dialogue_box.continue_button.pressed.emit()


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


func _transient_ui(game: VardhelmVerticalSlice) -> Array:
	return [game.memory_panel.visible, game.observation_panel.visible, game.memory_notification_panel.visible]


func _message_state(game: VardhelmVerticalSlice) -> Dictionary:
	var style := game.status_label.get_theme_stylebox("normal") as StyleBoxFlat
	return {
		"text": game.status_label.text,
		"font_size": game.status_label.get_theme_font_size("font_size"),
		"highlighted": game.status_label.has_theme_stylebox_override("normal"),
		"accent": style.border_color if style != null and game.status_label.has_theme_stylebox_override("normal") else Color.BLACK,
	}


func _expect_message(t, game: VardhelmVerticalSlice, key: String, label: String) -> void:
	var state := _message_state(game)
	var severity := SaveV2PlayerMessages.severity_of(key)
	t.check(state["text"] == game.localization.tr_key(key) and state["font_size"] == VardhelmVerticalSlice.SAVE_V2_MESSAGE_FONT_SIZE and state["highlighted"], "%s: \"%s\" (fonte %d, destacada, %s)" % [label, state["text"], state["font_size"], severity])
	var technical := false
	for token in ["FAILURE", "REJECTED", "ROLLBACK", "MISMATCH", "CHECKSUM", "_ERROR", "V2"]:
		if String(state["text"]).contains(token):
			technical = true
	t.check(not technical, "%s: sem código técnico" % label)


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_default_flags(t)
	_test_transient_ui_and_camera(t)
	_test_messages(t)
	_test_durn(t)
	_test_cycle(t)
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


# 23
func _test_default_flags(t) -> void:
	t.section("C10 Vardhelm — flags padrão")
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	t.check(game.save_v2_operational_config.enabled and game.save_v2_operational_config.save_enabled, "23. instância padrão do jogo: Load/Save V2 ON (C10.5)")
	_isolate(t)


# 2, 11
func _test_transient_ui_and_camera(t) -> void:
	t.section("C10 Vardhelm — UI transitória e câmera após Load")
	var game := _new_game(t)
	_talk(game)
	_key(t, KEY_S)
	game.echo.interact(game.player)
	_observation(game, "tool_rack").interact(game.player)
	t.check(game.memory_panel.visible and game.observation_panel.visible, "antes do Load: painéis transitórios do estado atual visíveis")
	var game_camera := game.player.camera
	t.check(t.root.get_viewport().get_camera_3d() == game_camera, "câmera atual = câmera do jogador")
	game.player.global_position = MOVED_POSITION
	game.player.velocity = Vector3(0.0, -19.7, 0.0)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success(), "Load V2: %s" % game.last_v2_load_result.describe())
	t.check(_transient_ui(game) == [false, false, false], "2. UI transitória do estado anterior descartada após Load SUCCESS")
	t.check(game.objective_panel.visible and game.status_label.visible and not game.completion_banner.visible, "HUD estrutural mantida; banner derivado do estado carregado (antes do Eco)")
	t.check(t.root.get_viewport().get_camera_3d() == game_camera and game_camera.current, "11. câmera do jogador continua a atual (o sandbox não a rouba)")
	t.check(game.player.velocity == Vector3.ZERO and game.player.global_position == SAVE_POSITION, "11. player no ponto salvo, velocidade anterior descartada")
	# Load que falha não descarta a UI (o estado não mudou).
	game.echo.interact(game.player)
	_observation(game, "sealed_panel").interact(game.player)
	var tampered := FileAccess.get_file_as_string(V2_FILE).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	var before := _transient_ui(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.VALIDATION_FAILURE and _transient_ui(game) == before, "Load com falha: UI transitória intocada (runtime não mudou)")
	# Diálogo aberto: recusa não fecha o diálogo.
	_key(t, KEY_S)
	game._npc_interactable.interact(game.player)
	var session := game.dialogue_controller.current_session
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE and game.dialogue_box.visible and game.dialogue_controller.current_session == session, "recusa por diálogo: diálogo e sessão intactos")
	t.check(t.root.get_viewport().get_camera_3d() == game_camera, "câmera intacta também na recusa")
	_press_choice(game, 1)
	_finish_dialogue(game)
	# Rollback: câmera continua a do jogador.
	game.echo.interact(game.player)
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
	coordinator.fault_injection_apply_step = "echo"
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal")))
	t.check(game.last_v2_load_result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and t.root.get_viewport().get_camera_3d() == game_camera, "rollback: câmera do jogador continua a atual")


# 3–9
func _test_messages(t) -> void:
	t.section("C10 Vardhelm — mensagens visíveis e localizadas")
	var game := _new_game(t)
	_talk(game)
	var original_font: int = game.status_label.get_theme_font_size("font_size")
	var previous := game.status_label.text
	_key(t, KEY_S)
	_expect_message(t, game, SaveV2PlayerMessages.KEY_SAVED, "3. SAVE SUCCESS")
	game._clear_save_v2_message(game.status_label.text)
	t.check(game.status_label.text == previous and game.status_label.get_theme_font_size("font_size") == original_font and not game.status_label.has_theme_stylebox_override("normal"), "mensagem some e o status volta ao estilo original (fonte %d)" % original_font)
	_key(t, KEY_L)
	_expect_message(t, game, SaveV2PlayerMessages.KEY_LOADED, "5. LOAD SUCCESS")
	game._npc_interactable.interact(game.player)
	_key(t, KEY_L)
	_expect_message(t, game, SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE, "7. LOAD REJECTED DIALOGUE")
	_press_choice(game, 1)
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()
	var tampered := FileAccess.get_file_as_string(V2_FILE).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	_key(t, KEY_L)
	_expect_message(t, game, SaveV2PlayerMessages.KEY_LOAD_INVALID, "6. LOAD FAILURE")
	_key(t, KEY_S)
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
	coordinator.fault_injection_apply_step = "echo"
	coordinator.fault_injection_rollback_step = "quests"
	game.echo.interact(game.player)
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal")))
	_expect_message(t, game, SaveV2PlayerMessages.KEY_LOAD_UNSAFE, "8. ROLLBACK FAILURE")
	var failing := _new_game(t, TEST_DIR)
	_talk(failing)
	_key(t, KEY_S)
	_expect_message(t, failing, SaveV2PlayerMessages.KEY_SAVE_WRITE_FAILED, "4. SAVE FAILURE")
	var accents := {}
	for key in [SaveV2PlayerMessages.KEY_SAVED, SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE, SaveV2PlayerMessages.KEY_LOAD_UNSAFE]:
		failing._show_save_v2_message(key)
		accents[_message_state(failing)["accent"].to_html()] = key
	t.check(accents.size() == 3, "9. sucesso, aviso e erro com destaques distintos (%s)" % str(accents.keys()))


# 10
func _test_durn(t) -> void:
	t.section("C10 Vardhelm — Durn")
	var game := _new_game(t)
	game._npc_interactable.interact(game.player)
	t.check(game.dialogue_box.speaker_label.text == "Durn", "10. falante na caixa de diálogo = Durn (\"%s\")" % game.dialogue_box.speaker_label.text)
	t.check(GameIdCatalog.canonical_id(GameIdCatalog.KIND_NPC, game.npc.npc_id) == "npc.vardhelm.durn", "ID interno continua npc.vardhelm.durn")
	_press_choice(game, 0)
	game.dialogue_box.continue_button.pressed.emit()
	game.dialogue_box.continue_button.pressed.emit()
	_key(t, KEY_S)
	var state: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V2_FILE))["state"]
	t.check(state["dialogue"]["completed"].has("dialogue.vardhelm.intro") and not FileAccess.get_file_as_string(V2_FILE).contains("\"Durn\""), "DialogueState inalterado (IDs, sem texto do falante)")


# 12–21
func _test_cycle(t) -> void:
	t.section("C10 Vardhelm — ciclo V2")
	var game := _new_game(t)
	_talk(game)
	_key(t, KEY_S)
	var before_echo := {"functional": _functional(game), "state": _project(game)}
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), before_echo["functional"]) and GameStateComparator.compare(_project(game), before_echo["state"]).is_equal() and game.player.global_position == SAVE_POSITION, "12/13/14. Save → Load: antes do Eco restaurado")
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	_key(t, KEY_S)
	var after_echo := {"functional": _functional(game), "state": _project(game)}
	game.player.global_position = MOVED_POSITION
	game.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "leave")
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	var projected := _project(game)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), after_echo["functional"]) and GameStateComparator.compare(projected, after_echo["state"]).is_equal(), "15. depois do Eco restaurado")
	t.check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn", "16. diálogo")
	t.check(projected.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and not projected.memory.memories.has("consequence.vardhelm.first_echo_complete"), "17. memória ≠ consequência")
	t.check(projected.world.observations.size() == 3, "18. observações")
	t.check(game.narrative_controller.world_state.memories.count("vardhelm_first_echo_complete") == 1, "19. consequências sem duplicação")
	t.check(game.quest_controller.states.is_completed("vardhelm_first_echo"), "20. quests")
	t.check(game.npc.interaction_enabled, "21. NPC")
	t.check(_events == ["game_saved", "game_loaded", "game_saved", "game_loaded"], "eventos só após sucesso (%s)" % str(_events))
	t.check(GameStateComparator.compare(game.shadow_state.game_state, after_echo["state"]).is_equal(), "GameState sombra == estado carregado")
