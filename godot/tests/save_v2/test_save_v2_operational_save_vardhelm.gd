extends RefCounted

## Bloco C8 — ciclo V2 completo com o Vardhelm REAL, pelo Ctrl+S/Ctrl+L de verdade
## (SAVE_V2_OPERATIONAL_SAVE_ENABLED + SAVE_V2_OPERATIONAL_LOAD_ENABLED ligadas só
## nas instâncias de teste). Cada cenário usa uma instância nova e isolada.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const V2_FILE := "user://save_v2_tests/echoes_of_the_soul_save_v2_shadow.json"
const LEGACY_SENTINEL := "{\"legacy\":\"sentinela C8 — não pode ser sobrescrita pelo V2\"}"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const SAVE_ROTATION := Vector3(0.0, 1.1, 0.0)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const MOVED_ROTATION := Vector3(0.0, -2.0, 0.0)

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


func _new_game(t, v2_on: bool = true) -> VardhelmVerticalSlice:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	game.name = "MainGame"
	t.root.add_child(game)
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	game.save_v2_operational_config = SaveV2OperationalConfig.create(v2_on, V2_FILE, v2_on)
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
		"echo_revealed": slice.echo.revealed,
		"echo_interaction": slice.echo.interaction_enabled,
		"echo_visual": (slice.echo.get_node("Visual") as MeshInstance3D).visible,
		"echo_light": (slice.echo.get_node("Light") as OmniLight3D).visible,
		"afterglow": slice._post_echo_marker.visible,
		"banner": slice.completion_banner.visible,
		"objective": slice.objective_label.text,
		"environment_states": env,
		"observations": observations,
		"npc_interaction": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
		"dialogue_open": slice.dialogue_controller.is_active() or slice.dialogue_box.visible,
	}


func _project(slice: VardhelmVerticalSlice) -> GameState:
	return SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(slice).build_targets())["state"]


func _file_state() -> Dictionary:
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V2_FILE))
	return envelope["state"]


func _save(t, game: VardhelmVerticalSlice) -> Dictionary:
	_key(t, KEY_S)
	return {"functional": _functional(game), "state": _project(game), "file_state": _file_state(),
		"position": game.player.global_position, "rotation": game.player.global_rotation}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_write_sentinel()
	_test_save_disabled(t)
	_test_before_echo_cycle(t)
	_test_after_echo(t)
	_test_save_after_load(t)
	_test_double_save(t)
	_test_dialogue_open(t)
	_test_failure_events(t)
	_test_old_load_isolation(t)
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


func _write_sentinel() -> void:
	var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
	file.store_string(LEGACY_SENTINEL)
	file.close()


# 1, 24: flag OFF — Ctrl+S antigo
func _test_save_disabled(t) -> void:
	t.section("C8 Vardhelm — V2 Save desligado (Ctrl+S antigo)")
	var game := _new_game(t, false)
	_talk(game)
	_key(t, KEY_S)
	t.check(game.last_v2_save_result == null and FileAccess.get_file_as_string(OLD_SAVE_PATH) != LEGACY_SENTINEL, "flag OFF: Ctrl+S antigo grava o save antigo; V2 operacional não chamado")
	t.check(not game.shadow_save_v2.last_save_report.is_empty(), "flag OFF: sombra C2 continua gravando em paralelo (comportamento atual)")
	_write_sentinel()


# 3–4, 8, 13–19, 26: antes do Eco
func _test_before_echo_cycle(t) -> void:
	t.section("C8 Vardhelm — antes do Eco: Ctrl+S V2 → Eco → Ctrl+L V2 → Ctrl+S V2")
	var game := _new_game(t, true)
	_talk(game)
	var saved := _save(t, game)
	var save_result := game.last_v2_save_result
	t.check(save_result != null and save_result.is_success(), "Ctrl+S V2: %s" % (save_result.describe() if save_result != null else "sem resultado"))
	t.check(save_result.shadow_divergence.is_empty(), "23. sombra já estava sincronizada com o runtime no save (%s)" % str(save_result.shadow_divergence))
	t.check(FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_SENTINEL and game.shadow_save_v2.last_save_report.is_empty(), "24. save antigo NÃO gravado nem sobrescrito")
	t.check(_events == ["game_saved"], "30. game_saved após SUCCESS")
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	game.player.global_position = MOVED_POSITION
	game.player.global_rotation = MOVED_ROTATION
	t.check(not (game.echo.get_node("Visual") as MeshInstance3D).visible, "26. esfera oculta ao resolver o Eco ao vivo (bug corrigido)")
	_key(t, KEY_L)
	var load_result := game.last_v2_load_result
	t.check(load_result != null and load_result.is_success(), "4. Ctrl+L V2: %s" % (load_result.describe() if load_result != null else "sem resultado"))
	print("   info tempos (load, ms): ", load_result.timings_ms)
	var functional := _functional(game)
	t.check(t.same_json(functional, saved["functional"]), "8. estado ANTES do Eco restaurado (Eco, esfera, luz, marcador, banner, ambiente, observações, diálogo)")
	var projected := _project(game)
	t.check(GameStateComparator.compare(saved["state"], projected).is_equal(), "0 diferenças persistentes")
	t.check(not projected.memory.has_memory("memory.vardhelm.first_echo") and projected.memory.memories.is_empty(), "14. sem memória do Eco nem fragmentos")
	t.check(not projected.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "15. consequência posterior desfeita")
	t.check(functional["environment_states"].is_empty(), "ambiente sem echo_awakened")
	t.check(game.player.global_position == saved["position"] and game.player.global_rotation.is_equal_approx(saved["rotation"]), "18/19. posição exata e rotação")
	t.check(_events == ["game_saved", "game_loaded"], "30. game_loaded após validação pós-restore")
	_key(t, KEY_S)
	t.check(game.last_v2_save_result.is_success() and t.same_json(_file_state(), saved["file_state"]), "6. Load → Save: arquivo equivalente ao do save original")


# 9: depois do Eco
func _test_after_echo(t) -> void:
	t.section("C8 Vardhelm — depois do Eco: Ctrl+S V2 → alterar → Ctrl+L V2")
	var game := _new_game(t, true)
	_talk(game)
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	var saved := _save(t, game)
	t.check(game.last_v2_save_result.is_success() and game.last_v2_save_result.shadow_divergence.is_empty(), "Ctrl+S V2 depois do Eco; sombra sincronizada")
	game.player.global_position = MOVED_POSITION
	game.player.global_rotation = MOVED_ROTATION
	game.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "leave")
	game.narrative_controller.world_state.set_flag("alteracao_deliberada", true)
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success(), "Ctrl+L V2: %s" % game.last_v2_load_result.describe())
	var functional := _functional(game)
	t.check(t.same_json(functional, saved["functional"]), "9. estado pós-Eco restaurado — idêntico ao jogo ao vivo, inclusive esfera (26)")
	var projected := _project(game)
	t.check(GameStateComparator.compare(saved["state"], projected).is_equal(), "0 diferenças persistentes")
	t.check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn" and not functional["dialogue_open"], "10. diálogo persistente restaurado, diálogo não aberto")
	var fragments_ok := true
	for id in OBSERVATIONS:
		var canonical := GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id)
		fragments_ok = fragments_ok and projected.world.is_observation_discovered(canonical) and projected.memory.is_fragment(String(GameIdCatalog.OBSERVATION_FRAGMENTS[canonical]))
	t.check(fragments_ok, "13/14. observações e fragmentos")
	t.check(projected.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and not projected.world.consequences.has("memory.vardhelm.first_echo") and not projected.memory.memories.has("consequence.vardhelm.first_echo_complete"), "14/15. memória ≠ consequência")
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and Array(world.memories).size() == 2, "15. consequências sem duplicação")
	t.check(game.quest_controller.states.is_completed("vardhelm_first_echo") and game.npc.interaction_enabled, "16/17. quest e NPC")
	t.check(game.player.global_position == saved["position"] and game.player.global_rotation.is_equal_approx(saved["rotation"]), "18/19. posição e rotação")
	var cold: Dictionary = game.last_v2_load_result.timings_ms
	_key(t, KEY_L)
	var warm: Dictionary = game.last_v2_load_result.timings_ms
	print("   info tempos load 1º (ms): ", cold)
	print("   info tempos load 2º (ms): ", warm)
	print("   info tempos save (ms): ", game.last_v2_save_result.timings_ms)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), saved["functional"]), "32. Ctrl+L repetido: idempotente")
	t.check(float(cold.get("rehearsal", 0.0)) > 0.0 and float(cold.get("rollback_rehearsal", 0.0)) > 0.0 and cold.has("apply") and cold.has("post_restore") and cold.has("total"), "27/28. custo medido por etapa")


# 5–7, 23: estado A → B → Load → Save → Load = A
func _test_save_after_load(t) -> void:
	t.section("C8 Vardhelm — save após load (A → B → Load → Save → B' → Load = A)")
	var game := _new_game(t, true)
	_talk(game)
	var state_a := _save(t, game)
	game.echo.interact(game.player)
	_observation(game, "maintenance_board").interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and GameStateComparator.compare(game.shadow_state.game_state, state_a["state"]).is_equal(), "5/23. após Load: sombra == estado A")
	_key(t, KEY_S)
	t.check(game.last_v2_save_result.is_success() and game.last_v2_save_result.shadow_divergence.is_empty() and t.same_json(_file_state(), state_a["file_state"]), "6. Save após Load grava o estado A (sombra sincronizada)")
	game.echo.interact(game.player)
	_observation(game, "tool_rack").interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_a["functional"]) and GameStateComparator.compare(_project(game), state_a["state"]).is_equal(), "7. Save → Load → Save → Load: estado A")


# 20: save duplo
func _test_double_save(t) -> void:
	t.section("C8 Vardhelm — Ctrl+S V2 duas vezes")
	var game := _new_game(t, true)
	_talk(game)
	game.echo.interact(game.player)
	_key(t, KEY_S)
	var first := FileAccess.get_file_as_string(V2_FILE)
	var first_state := _file_state()
	_key(t, KEY_S)
	var second: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V2_FILE))
	t.check(t.same_json(second["state"], first_state), "20. state idêntico (timestamp de metadata não conta como diferença)")
	var loaded := SaveV2Service.new(V2_FILE).load_game_state()
	t.check(loaded.ok and (FileAccess.get_file_as_string(V2_FILE) == first or loaded.envelope["metadata"]["updated_at"] != JSON.parse_string(first)["metadata"]["updated_at"]), "21/22. envelope/checksum válidos; só a metadata pode mudar")


# 11–12: diálogo aberto
func _test_dialogue_open(t) -> void:
	t.section("C8 Vardhelm — diálogo aberto")
	var game := _new_game(t, true)
	_talk(game)
	_key(t, KEY_S)
	var file_before := FileAccess.get_file_as_string(V2_FILE)
	game.dialogue_controller.start_dialogue(game.dialogue_data, "start")
	var session := game.dialogue_controller.current_session
	t.check(game.dialogue_controller.is_active() and game.dialogue_box.visible, "sessão de diálogo aberta")
	var before := JSON.stringify([_functional(game), game.player.global_position], "", true)
	_events.clear()
	_key(t, KEY_L)
	var rejected := game.last_v2_load_result
	t.check(rejected.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE, "12. Ctrl+L com diálogo aberto: LOAD_REJECTED_TRANSIENT_DIALOGUE")
	t.check(game.dialogue_controller.current_session == session and session.current_entry_id == "start" and game.dialogue_box.visible, "sessão não fechada, não reaberta, não destruída")
	t.check(JSON.stringify([_functional(game), game.player.global_position], "", true) == before and _events.is_empty() and game.shadow_save_v2.last_load_report.is_empty(), "runtime intocado, sem evento, sem load antigo")
	# Escolha feita com a sessão ainda aberta: Ctrl+S grava só o persistente.
	_press_choice(game, 1)
	t.check(game.dialogue_controller.is_active(), "sessão continua aberta (entrada 'end')")
	_key(t, KEY_S)
	var saved := game.last_v2_save_result
	t.check(saved.is_success() and saved.dialogue_session_open, "11. Ctrl+S durante diálogo: permitido, só DialogueRuntimeState persistente")
	var text := FileAccess.get_file_as_string(V2_FILE)
	var state := _file_state()
	t.check(state["dialogue"]["choices"]["dialogue.vardhelm.intro"]["start"] == "leave" and not text.contains("procure por mim") and not text.contains("dialogue.vardhelm.farewell") and not text.contains("current_entry") and text != file_before, "10. última escolha gravada; texto/entrada da sessão não gravados")
	game.dialogue_box.continue_button.pressed.emit()
	t.check(not game.dialogue_controller.is_active(), "jogador conclui o diálogo")
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success(), "Ctrl+L permitido depois do diálogo: %s" % game.last_v2_load_result.describe())


# 21, 31: falha não publica
func _test_failure_events(t) -> void:
	t.section("C8 Vardhelm — falhas sem evento de sucesso")
	var game := _new_game(t, true)
	_talk(game)
	_key(t, KEY_S)
	var tampered := FileAccess.get_file_as_string(V2_FILE).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	_events.clear()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.VALIDATION_FAILURE and _events.is_empty(), "21/31. checksum corrompido: VALIDATION_FAILURE, nenhum game_loaded")
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
	_key(t, KEY_S)
	_events.clear()
	coordinator.fault_injection_apply_step = "echo"
	var rolled := coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal"))
	t.check(rolled.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and _events.is_empty(), "29/31. rollback: nenhum game_loaded")
	print("   info tempos com rollback (ms): ", rolled.timings_ms)


# 25: isolamento do load antigo
func _test_old_load_isolation(t) -> void:
	t.section("C8 Vardhelm — Old Load isolado")
	var game := _new_game(t, true)
	_talk(game)
	_key(t, KEY_S)
	t.check(FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_SENTINEL, "19/24. saves antigos não modificados pelo V2")
	var v2_state := JSON.stringify(_functional(game), "", true)
	var old := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	old.name = "OldLoadInstance"
	t.root.add_child(old)
	old.shadow_save_v2 = null
	# C10.5: V2 é o padrão; a instância do Old Load usa explicitamente o caminho LEGADO.
	old.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	old.player.set_physics_process(false)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_L
	event.ctrl_pressed = true
	event.pressed = true
	old._unhandled_input(event)
	t.check(old.last_v2_load_result == null, "25. instância com flags OFF usa o caminho legado (sentinela não é um save legível)")
	t.check(JSON.stringify(_functional(game), "", true) == v2_state and FileAccess.get_file_as_string(OLD_SAVE_PATH) == LEGACY_SENTINEL, "instâncias isoladas; save antigo intacto")
	old.get_parent().remove_child(old)
	old.queue_free()
