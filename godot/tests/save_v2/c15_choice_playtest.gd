extends SceneTree

## Bloco C15 — PLAYTEST AUTOMATIZADO DA PRIMEIRA ESCOLHA COM CONSEQUÊNCIA (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c15_choice_playtest.gd -- --out=<dir>
##
## Input real (ações de movimento, E, clique na escolha, Enter, Ctrl+S/Ctrl+L), configuração
## PADRÃO (V2), frames reais. Caminho "Não senti nada.": antes da escolha (A) → escolha →
## Eco → Durn vai sozinho até onde o Eco aconteceu → Save → alterar → Load → consequência continua →
## Load repetido → nada duplica → Durn e o painel alcançáveis andando.
## Helpers de input/caminhada iguais aos do playtest do C11.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c15_playtest/v2.json"
const ALONE_SPOT := Vector3(1.1, 0.25, -3.4)

var game: VardhelmVerticalSlice
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
	print("[C15] %s %s" % ["ok  " if condition else "FAIL", label])
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


func _durns() -> int:
	return game.get_children().filter(func(c): return c is NPCController).size()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c15_playtest")
	print("[C15] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c15_playtest/c2.json")
	var spy := SpySaveService.new()
	game.save_service = spy
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type))
	await _frames(20)
	var home := game.npc.global_position

	# --- ANTES DA ESCOLHA (estado A) ---------------------------------------------
	var reached := await _walk_to(game.npc.global_position, 1.2)
	_check(reached and _candidate_name() == "Interactable", "Durn encontrado andando")
	await _key(KEY_E)
	await _frames(4)
	await _screenshot("01_durn_pergunta")
	var buttons := _choice_buttons()
	_check(buttons.size() == 2 and (buttons[1] as Button).text == "Não senti nada.", "as duas respostas de sempre")
	# --- ESCOLHA -------------------------------------------------------------------
	await _click(buttons[1])
	_check(game.dialogue_box.text_label.text == "Se acontecer de novo... procure por mim.", "\"Não senti nada.\" → \"Se acontecer de novo... procure por mim.\"")
	await _key(KEY_ENTER, false, true)
	await _frames(6)
	_check(not game.dialogue_controller.is_active() and game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "leave" and game.narrative_controller.world_state.has_flag("vardhelm_felt_nothing"), "decisão registrada, consequência aplicada")
	_check(game.npc.global_position.is_equal_approx(home) and not game.status_label.text.contains("felt") and not game.status_label.text.contains("onsequ"), "nada aparece de imediato; nenhum texto técnico (status \"%s\")" % game.status_label.text)
	# --- ECO → DURN VAI SOZINHO ----------------------------------------------------
	reached = await _walk_to(game.echo.global_position, 1.2)
	await _key(KEY_E)
	await _frames(4)
	_check(game.echo.revealed, "Primeiro Eco")
	await create_timer(2.5).timeout
	await _screenshot("02_eco_durn_saindo")
	var waited := 0.0
	while game._durn_walk != null and waited < 10.0:
		await create_timer(0.25).timeout
		waited += 0.25
	_check(game.npc.global_position.distance_to(ALONE_SPOT) < 0.05 and _durns() == 1, "Durn foi sozinho até onde o Eco aconteceu (%s)" % game.npc.global_position)
	await _walk_to(Vector3(0.5, 0.25, -0.5), 0.6, 300)
	await _screenshot("03_durn_onde_o_eco_aconteceu")
	# --- SAVE → ALTERAR → LOAD -----------------------------------------------------
	await _key(KEY_S, true)
	_check(game.last_v2_save_result != null and game.last_v2_save_result.is_success(), "SAVE (Durn onde o Eco aconteceu)")
	await _walk_to(game.echo.global_position, 1.5, 300)
	game.npc.global_position = home
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and game.npc.global_position.distance_to(ALONE_SPOT) < 0.05 and game._durn_walk == null and _durns() == 1, "LOAD: Durn já está onde o Eco aconteceu (sem caminhar de novo, um só Durn)")
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and game.npc.global_position.distance_to(ALONE_SPOT) < 0.05 and _durns() == 1, "LOAD repetido: mesmo lugar")
	await _screenshot("04_depois_do_load")
	# --- DURN E O PAINEL CONTINUAM ALCANÇÁVEIS ANDANDO -----------------------------
	reached = await _walk_to(game.npc.global_position, 1.2)
	_check(reached and _candidate_name() == "Interactable" and game.interaction_hint_label.text.contains("Durn"), "Durn alcançável andando no novo lugar (dica \"%s\")" % game.interaction_hint_label.text)
	await _key(KEY_E)
	_check(game.dialogue_box.text_label.text == "...Você voltou.", "conversa pós-Eco do C12 no novo lugar")
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 10:
		var choice := _choice_buttons()
		if choice.is_empty():
			await _key(KEY_ENTER, false, true)
		else:
			await _click(choice[0])
		guard += 1
	await _frames(4)
	var panel_pos := (game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as Node3D).global_position
	# C17.3: os trabalhadores têm corpo; a linha reta do Eco até o painel passa rente ao
	# trabalhador da bigorna. Como um jogador, pela rota aberta: leste da forja → frente do painel.
	for waypoint in [Vector3(-2.8, 0.25, 1.0), Vector3(-5.6, 0.25, 2.9)]:
		await _walk_to(waypoint, 0.6, 400)
	await _walk_to(panel_pos, 1.0)
	_check(_candidate_name() == "sealed_panel", "o E continua examinando o painel (candidato %s)" % _candidate_name())
	if _candidate_name() == "sealed_panel":
		await _key(KEY_E)
	await _frames(4)
	_check(game.quest_controller.states.is_completed("vardhelm_sealed_panel"), "painel examinado")
	await _screenshot("05_painel")
	await create_timer(9.0).timeout
	await _walk_to(game.npc.global_position, 1.2)
	await _key(KEY_E)
	_check(game.dialogue_box.text_label.text == "...Você ouviu, não ouviu?", "gancho do C14 no novo lugar de Durn")
	guard = 0
	while game.dialogue_controller.is_active() and guard < 6:
		await _key(KEY_ENTER, false, true)
		guard += 1
	await _frames(4)
	# --- DUPLICAÇÃO E LEGADO ---------------------------------------------------------
	var world := game.narrative_controller.world_state
	_check(world.memories.count("vardhelm_felt_nothing") == 1 and _count("consequence_applied") == 2 and _durns() == 1, "nada duplicado (consequências aplicadas: %d; Durns: %d)" % [_count("consequence_applied"), _durns()])
	_check(spy.calls == 0, "SaveService legado nunca chamado (%d)" % spy.calls)

	var dir := DirAccess.open("user://c15_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c15_playtest")
	print("[C15] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C15] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
