extends RefCounted

## Bloco C11 — continuidade jogável de Vardhelm (headless, determinístico).
## O jogo com input real, andando e com frames, está em c11_continuity_playtest.gd.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c11.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)


class SpySaveService extends SaveService:
	var calls := 0

	func load_game(_w: WorldState, _q: QuestState, _p: Node3D = null) -> Dictionary:
		calls += 1
		return {}

	func save_game(_w: WorldState, _q: QuestState, _l: String, _p: Node3D = null) -> bool:
		calls += 1
		return true


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
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			if index == 0:
				(child as Button).pressed.emit()
				return
			index -= 1


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _new_game(t) -> Array:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	var spy := SpySaveService.new()
	game.save_service = spy
	game.player.set_physics_process(false)
	game.player.global_position = SAVE_POSITION
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type))
	return [game, spy]


func _count(type: String) -> int:
	return _events.filter(func(e): return e == type).size()


func _detector(game: VardhelmVerticalSlice) -> InteractionDetector:
	return game.player.get_node("InteractionDetector") as InteractionDetector


func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo": [slice.echo.revealed, slice.echo.interaction_enabled, (slice.echo.get_node("Visual") as MeshInstance3D).visible],
		"banner": slice.completion_banner.visible, "objective": slice.objective_label.text,
		"environment": env, "observations": observations, "npc": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_interaction(t)
	_test_hud(t)
	_test_story_flow(t)
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


func _test_interaction(t) -> void:
	t.section("C11 — interação: Durn alcançável, diálogo sem interferência")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var board := _observation(game, "maintenance_board")
	t.check(game._npc_interactable.interaction_priority == board.interaction_priority and game.echo.interaction_priority > board.interaction_priority, "Durn com a mesma prioridade das observações (%d): vence o mais próximo; Eco acima (%d)" % [game._npc_interactable.interaction_priority, game.echo.interaction_priority])
	var detector := _detector(game)
	game.interaction_hint.visible = true
	game._npc_interactable.interact(game.player)
	t.check(game.dialogue_controller.is_active() and not detector.is_physics_processing() and not game.interaction_hint.visible, "conversa aberta: detector suspenso e dica oculta (o E não examina o mundo)")
	_press_choice(game, 0)
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()
	t.check(detector.is_physics_processing(), "conversa concluída: detector volta")
	var player_source := FileAccess.get_file_as_string("res://scripts/player/player_controller.gd")
	t.check(player_source.contains("Input.is_key_pressed(KEY_CTRL)") and player_source.contains("input_vector = Vector2.ZERO"), "com Ctrl pressionado (Ctrl+S) o personagem não anda")


func _test_hud(t) -> void:
	t.section("C11 — HUD: status sempre abaixo do objetivo")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var hud := game.objective_panel.get_parent()
	t.check(hud is VBoxContainer and hud == game.status_label.get_parent() and hud.get_child(0) == game.objective_panel and hud.get_child(1) == game.status_label, "objetivo e status empilhados no mesmo VBoxContainer (HudTop)")
	t.check(game.objective_panel.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN and game.status_label.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN and game.objective_panel.custom_minimum_size.x == 390.0, "larguras preservadas (objetivo 390 px; status não estica o painel)")
	# Destaque de Save/Load não vaza para um status escrito pelo jogo nesse meio-tempo.
	game._show_save_v2_message(SaveV2PlayerMessages.KEY_SAVED)
	var message := game.status_label.text
	game.status_label.text = "Você registrou o primeiro Eco. Ctrl+S salva seu progresso."
	game._clear_save_v2_message(message)
	t.check(game.status_label.text.begins_with("Você registrou") and not game.status_label.has_theme_stylebox_override("normal") and game.status_label.get_theme_font_size("font_size") == 12, "status escrito pelo jogo durante a mensagem fica, mas sem o destaque de save/load")
	var slice_source := FileAccess.get_file_as_string("res://scripts/vardhelm/vardhelm_vertical_slice.gd")
	t.check(not slice_source.contains("STATUS_LABEL_Y") and not slice_source.contains("status_label.position"), "sem coordenada fixa para o status (layout pelo container)")


func _test_story_flow(t) -> void:
	t.section("C11 — fluxo do jogador: Durn → Eco → memória → observação → Save/Load")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	game._npc_interactable.interact(game.player)
	_press_choice(game, 0)
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()
	t.check(game.quest_controller.states.active.has("vardhelm_first_echo") and game.echo.interaction_enabled and _count("dialogue_completed") == 1 and _count("quest_started") == 1, "conversa → quest iniciada → Eco disponível (eventos únicos)")
	_key(t, KEY_S)
	var state_a := {"functional": _functional(game), "position": game.player.global_position}
	game.echo.interact(game.player)
	t.check(_count("echo_triggered") == 1 and _count("consequence_applied") == 2 and _count("quest_completed") == 1, "Eco: um echo_triggered, consequência aplicada uma vez, quest concluída uma vez")
	_observation(game, "tool_rack").interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_a["functional"]) and game.player.global_position == state_a["position"], "Save antes do Eco → Eco → Load: de volta ao estado A")
	t.check(not game.memory_panel.visible and not game.observation_panel.visible and not game.dialogue_controller.is_active() and _detector(game).is_physics_processing() and game.player.velocity == Vector3.ZERO, "após o Load: sem painel preso, detector ativo, sem velocidade herdada")
	# Refazer o Eco depois do Load: eventos voltam a acontecer exatamente uma vez (resync).
	var before := _events.size()
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	var redo := _events.slice(before)
	t.check(redo.count("echo_triggered") == 1 and redo.count("consequence_applied") == 1 and redo.count("observation_discovered") == 3, "Eco e observações refeitos após o Load geram eventos uma única vez (%s)" % str(redo))
	_key(t, KEY_S)
	var state_d := {"functional": _functional(game), "position": game.player.global_position}
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "Save do estado D: GameState sombra acompanhava o runtime")
	game.player.global_position = MOVED_POSITION
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_d["functional"]) and game.player.global_position == state_d["position"] and game.npc.interaction_enabled, "Save depois do Eco → alterar → Load (repetido): estado D")
	var world := game.narrative_controller.world_state
	var projected: GameState = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and projected.memory.memories.size() == 4 and projected.world.observations.size() == 3 and game.quest_controller.states.completed.size() == 1, "nenhuma consequência, memória, observação ou quest duplicada")
	t.check(_count("game_saved") == 2 and _count("game_loaded") == 3, "game_saved/game_loaded só após sucesso (%d / %d)" % [_count("game_saved"), _count("game_loaded")])
	t.check(spy.calls == 0, "SaveService legado nunca chamado")
