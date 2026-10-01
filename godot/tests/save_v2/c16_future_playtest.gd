extends SceneTree

## Bloco C16 — PLAYTEST AUTOMATIZADO DA POSSIBILIDADE FUTURA (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c16_future_playtest.gd -- --out=<dir>
##
## Input real (ações de movimento, E, clique na escolha, Enter, Ctrl+S/Ctrl+L), configuração
## PADRÃO (V2), frames reais. Três partidas:
##   A. "Sentir o quê?" → Eco → voltar ao lugar de Durn: o E fala com Durn (sem folha);
##   B. "Não senti nada." → Eco → voltar ao lugar de Durn: a folha pode ser examinada
##      → Save → alterar → Load → a folha continua → Load repetido;
##   C. Save ANTES da escolha → "Não senti nada." → Eco → folha → Load: sem folha.
## Helpers de input/caminhada iguais aos dos playtests do C11/C15.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c16_playtest/v2.json"
const DURN_HOME := Vector3(-4.0, 0.25, -2.0)

var game: VardhelmVerticalSlice
var spy: SpySaveService
var _out := ""
var _checks := 0
var _failures: Array = []
var _events: Array = []


class SpySaveService extends SaveService:
	var calls := 0

	func load_game(_w: WorldState, _q: QuestState, _p: Node3D = null) -> Dictionary:
		calls += 1
		return {}

	func save_game(_w: WorldState, _q: QuestState, _l: String, _p: Node3D = null) -> bool:
		calls += 1
		return true


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	print("[C16] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _key(code: Key, ctrl: bool = false, by_keycode: bool = false) -> void:
	if ctrl:
		_modifier(true)
		await _frames(1)
	for pressed in [true, false]:
		var event := InputEventKey.new()
		if by_keycode:
			event.keycode = code
		else:
			event.physical_keycode = code
		event.ctrl_pressed = ctrl
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(1)
	if ctrl:
		_modifier(false)
		await _frames(1)


func _modifier(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_CTRL
	event.physical_keycode = KEY_CTRL
	event.ctrl_pressed = pressed
	event.pressed = pressed
	Input.parse_input_event(event)


func _click(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	var viewport_point := control.get_viewport().get_final_transform() * center
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = viewport_point
		event.global_position = viewport_point
		Input.parse_input_event(event)
		await _frames(1)


func _choice_buttons() -> Array:
	var buttons: Array = []
	for child in game.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	return buttons


## Anda até o alvo usando as ações de movimento (relativas à câmera), como o jogador.
func _walk_to(target: Vector3, stop_distance: float = 1.3, max_frames: int = 600) -> bool:
	var camera := game.player.camera
	var best := INF
	var stalled := 0
	var detour := 0
	for i in max_frames:
		var delta := target - game.player.global_position
		delta.y = 0.0
		if delta.length() <= stop_distance:
			break
		if delta.length() < best - 0.02:
			best = delta.length()
			stalled = 0
		else:
			stalled += 1
		if stalled > 30 and detour == 0:
			detour = 35
			stalled = 0
		var forward := -camera.global_transform.basis.z
		forward.y = 0.0
		var right := camera.global_transform.basis.x
		right.y = 0.0
		var dir := delta.normalized()
		if detour > 0:
			detour -= 1
			dir = Vector3(-dir.z, 0.0, dir.x)
		var up_amount := dir.dot(forward.normalized())
		var right_amount := dir.dot(right.normalized())
		_set_action("move_up", up_amount > 0.25)
		_set_action("move_down", up_amount < -0.25)
		_set_action("move_right", right_amount > 0.25)
		_set_action("move_left", right_amount < -0.25)
		await physics_frame
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	await _frames(4)
	return Vector2(target.x - game.player.global_position.x, target.z - game.player.global_position.z).length() <= stop_distance + 0.2


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _candidate_name() -> String:
	var candidate = game.player.get_node("InteractionDetector").current_candidate
	return String(candidate.name) if candidate != null else "-"


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _count(type: String) -> int:
	return _events.filter(func(e): return e == type).size()


func _notes() -> EnvironmentalObservation:
	return game.get_node("AmbientLife/EnvironmentalObservations/durn_notes") as EnvironmentalObservation


func _new_game() -> void:
	if game != null and is_instance_valid(game):
		root.remove_child(game)
		game.queue_free()
		await _frames(2)
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c16_playtest/c2.json")
	spy = SpySaveService.new()
	game.save_service = spy
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type))
	await _frames(20)


## Primeira conversa com Durn, respondendo com clique; termina com Enter.
func _first_talk(choice: int) -> void:
	await _walk_to(game.npc.global_position, 1.2)
	await _key(KEY_E)
	await _frames(4)
	var buttons := _choice_buttons()
	await _click(buttons[choice])
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 4:
		await _key(KEY_ENTER, false, true)
		guard += 1
	await _frames(4)


## Eco e a caminhada de Durn (caminho B), como o jogador espera.
func _echo() -> void:
	await _walk_to(game.echo.global_position, 1.2)
	await _key(KEY_E)
	await _frames(4)
	var waited := 0.0
	while waited < 6.0:
		await create_timer(0.25).timeout
		waited += 0.25
		if game._durn_walk == null and waited > 1.5:
			break


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c16_playtest")
	print("[C16] modo: ", SaveV2LoadMetrics.rendering_info())

	# --- A. "Sentir o quê?" --------------------------------------------------------
	await _new_game()
	await _first_talk(0)
	_check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn", "A: \"Sentir o quê?\"")
	await _echo()
	await _walk_to(DURN_HOME, 1.0)
	_check(_candidate_name() == "Interactable" and game.interaction_hint_label.text.contains("Durn") and not _notes().interaction_enabled and not (_notes().get_node("Marker") as Node3D).visible, "A: no lugar de Durn, o E fala com ele; nenhuma folha (dica \"%s\")" % game.interaction_hint_label.text)
	await _screenshot("a_lugar_de_durn")
	var spy_a := spy.calls

	# --- B. "Não senti nada." --------------------------------------------------------
	await _new_game()
	await _first_talk(1)
	_check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "leave", "B: \"Não senti nada.\"")
	_check(not _notes().interaction_enabled, "B antes do Eco: ainda nenhuma folha")
	await _echo()
	_check(game.is_durn_away_from_home() and _notes().interaction_enabled and (_notes().get_node("Marker") as Node3D).visible, "B depois do Eco: Durn saiu; a folha ficou no lugar dele")
	await _walk_to(DURN_HOME, 1.0)
	_check(_candidate_name() == "durn_notes" and game.interaction_hint_label.text.contains("Examinar"), "B: no lugar de Durn, o E examina a folha (dica \"%s\")" % game.interaction_hint_label.text)
	await _screenshot("b_folha_no_lugar_de_durn")
	await _key(KEY_E)
	await _frames(4)
	_check(game.observation_panel.visible and game.observation_text.text.begins_with("Uma folha dobrada, caída onde Durn costumava ficar."), "B: \"%s\"" % game.observation_text.text)
	await _screenshot("b_folha_examinada")
	await _key(KEY_S, true)
	_check(game.last_v2_save_result != null and game.last_v2_save_result.is_success(), "B: SAVE depois de examinar")
	await _walk_to(game.echo.global_position, 1.5, 300)
	game.npc.global_position = DURN_HOME
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and _notes().interaction_enabled and _notes().revealed and game.is_durn_away_from_home(), "B: LOAD — a folha continua lá (examinada), Durn fora do lugar")
	await _walk_to(DURN_HOME, 1.0)
	_check(_candidate_name() == "durn_notes", "B: depois do Load, a mesma possibilidade no mesmo lugar")
	var discovered_before := _count("observation_discovered")
	await _key(KEY_E)
	await _frames(4)
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and _notes().interaction_enabled and _count("observation_discovered") == discovered_before and _count("consequence_applied") == 2, "B: reexame + Load repetido — nada duplicado (descobertas %d, consequências %d)" % [_count("observation_discovered"), _count("consequence_applied")])
	_check(game.get_node("AmbientLife/EnvironmentalObservations").get_children().filter(func(c): return c.name == "durn_notes").size() == 1 and game.get_children().filter(func(c): return c is NPCController).size() == 1, "B: uma folha, um Durn")
	var spy_b := spy.calls

	# --- C. Save ANTES da escolha ------------------------------------------------------
	await _new_game()
	await _key(KEY_S, true)
	await _first_talk(1)
	await _echo()
	await _walk_to(DURN_HOME, 1.0)
	if _candidate_name() == "durn_notes":
		await _key(KEY_E)
		await _frames(4)
	_check(_notes().revealed, "C: folha examinada depois da escolha")
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and not _notes().interaction_enabled and not _notes().revealed and not game.is_durn_away_from_home() and not game.narrative_controller.world_state.has_flag("vardhelm_felt_nothing"), "C: Load do save de antes da escolha — sem folha, Durn no lugar")
	await _walk_to(DURN_HOME + Vector3(1.0, 0.0, 0.0), 0.8)
	_check(_candidate_name() == "Interactable", "C: no lugar de Durn, o E volta a falar com ele (candidato %s)" % _candidate_name())
	_check(spy_a + spy_b + spy.calls == 0, "SaveService legado nunca chamado")

	var dir := DirAccess.open("user://c16_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c16_playtest")
	print("[C16] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C16] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
