extends SceneTree

## Bloco C25 — PLAYTEST AUTOMATIZADO DOS HORÁRIOS (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c25_the_hours_playtest.gd -- --out=<dir>
##
## Frames, física e input reais (sem teleporte), nos dois caminhos da primeira escolha:
##   "Sentir o quê?": Durn → Eco → Durn → painel → gancho → Durn conta os horários → talha →
##   pátio → rua → quadro de turnos (comparação) → novo objetivo; Save/Load na rua antes e
##   depois da comparação.
##   "Não senti nada.": … → gancho → Durn aponta a folha → a folha, lida → mesmo objetivo.
## Helpers de caminhada iguais aos do C23.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c25_playtest/v2.json"
const LANE_X := 1.6
const YARD_Y := -11.65
const DURN_HOME := Vector3(-4.0, 0.25, -2.0)
const PANEL_APPROACH := [Vector3(-2.8, 0.25, 1.0), Vector3(-5.6, 0.25, 2.9)]
const HOURS := preload("res://scripts/vardhelm/vardhelm_hours_investigation.gd")

var game: VardhelmVerticalSlice
var district: VardhelmFoundryDistrict
var _out := ""
var _checks := 0
var _failures: Array = []
var _stalls := 0
var _recording := false
var _seen: Dictionary = {}
## Lado do desvio do andador: alterna a cada desvio (como alguém que contorna quem cruza a frente).
var _detour_side := 1.0
var _events: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	print("[C25] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _seconds(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await _frames(1)


func _key(code: Key, ctrl: bool = false) -> void:
	if ctrl:
		_modifier(true)
		await _frames(1)
	for pressed in [true, false]:
		var event := InputEventKey.new()
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


## Anda até o alvo SEM desvio automático: se algo bloquear, conta como travamento.
func _walk_to(target: Vector3, stop_distance: float = 0.3, max_frames: int = 400, allow_detour := false) -> bool:
	var camera := game.player.camera
	var best := INF
	var stalled := 0
	var detour := 0
	for i in max_frames:
		var delta := target - game.player.global_position
		delta.y = 0.0
		if delta.length() <= stop_distance:
			break
		if delta.length() < best - 0.01:
			best = delta.length()
			stalled = 0
		else:
			stalled += 1
			if allow_detour and stalled > 30 and detour == 0:
				detour = 25
				stalled = 0
				_detour_side = -_detour_side
			if stalled == 20 and not allow_detour:
				_stalls += 1
				print("[C25] travou em %s a caminho de %s" % [game.player.global_position, target])
			if stalled > 60:
				if allow_detour:
					print("[C25] diag: parado em %s; diálogo=%s física=%s" % [game.player.global_position, game.dialogue_controller.is_active(), game.player.is_physics_processing()])
				break
		var forward := -camera.global_transform.basis.z
		forward.y = 0.0
		var right := camera.global_transform.basis.x
		right.y = 0.0
		var dir := delta.normalized()
		if detour > 0:
			detour -= 1
			dir = Vector3(-dir.z, 0.0, dir.x) * _detour_side
		var up_amount := dir.dot(forward.normalized())
		var right_amount := dir.dot(right.normalized())
		_set_action("move_up", up_amount > 0.25)
		_set_action("move_down", up_amount < -0.25)
		_set_action("move_right", right_amount > 0.25)
		_set_action("move_left", right_amount < -0.25)
		await physics_frame
		if _recording:
			_seen[String(_candidate().name) if _candidate() != null else "-"] = true
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	await _frames(3)
	return _flat(game.player.global_position, target) <= stop_distance + 0.2


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _candidate() -> Interactable:
	return game.player.get_node("InteractionDetector").current_candidate


## A cápsula do jogador sobrepõe algum colisor onde ele está?
func _in_collision() -> bool:
	var shape_node := game.player.get_node("CollisionShape3D") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape
	query.collision_mask = game.player.collision_mask
	query.exclude = [game.player.get_rid()]
	query.transform = Transform3D(Basis(), game.player.global_position + Vector3(0, shape_node.position.y + 0.02, 0))
	return not game.player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _talk(choice: int) -> void:
	await _key(KEY_E)
	await _frames(6)
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 20:
		var buttons: Array = game.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			game.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[choice] as Button).pressed.emit()
		guard += 1
		await _frames(3)


func _volumes() -> Array:
	var out: Array = []
	for n in ["VardhelmHum", "VardhelmSteam", "VardhelmMachinery"]:
		out.append(snappedf((game.get_node("VardhelmAudio/%s" % n) as AudioStreamPlayer).volume_db, 0.1))
	return out


func _ride() -> bool:
	var start_y := game.player.global_position.y
	await _key(KEY_E)
	var waited := 0.0
	while waited < 4.0 and (district.riding or absf(game.player.global_position.y - start_y) < 5.0):
		await _seconds(0.1)
		waited += 0.1
	await _seconds(0.5)
	return not district.riding and absf(game.player.global_position.y - start_y) > 5.0


## Forja (início) → passagem ao lado da bancada → portão → patamar → talha. Só andando.
func _forge_to_hoist(entry_x: float) -> bool:
	var approach := await _walk_to(Vector3(entry_x, 0.25, 3.7), 0.25)
	_recording = true
	# Entrar e atravessar: em linha reta para o sul, do ponto de entrada até depois da bancada.
	var through := await _walk_to(Vector3(entry_x, 0.25, 5.55), 0.2)
	var gate := await _walk_to(Vector3(0.8, 0.25, 6.9), 0.3)
	var landing := await _walk_to(Vector3(0.0, 0.25, 9.1), 0.3)
	await _frames(10)
	_recording = false
	return approach and through and gate and landing


## Patamar → portão → passagem → dentro da Forja. Só andando.
func _hoist_to_forge() -> bool:
	_recording = true
	var gate := await _walk_to(Vector3(0.8, 0.25, 6.9), 0.3)
	var lane := await _walk_to(Vector3(LANE_X, 0.25, 5.75), 0.25)
	var through := await _walk_to(Vector3(LANE_X, 0.25, 3.7), 0.25)
	_recording = false
	var inside := await _walk_to(Vector3(0.0, 0.25, 3.0), 0.3)
	return gate and lane and through and inside


## Largura livre (física) numa seção: varre `axis` ("x" ou "z") de a até b com o outro eixo fixo;
## devolve a maior faixa contínua onde a cápsula real cabe, somada à largura do jogador (0,8 m).
func _free_width(axis: String, fixed: float, a: float, b: float, floor_y: float) -> float:
	var shape_node := game.player.get_node("CollisionShape3D") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_node.shape
	query.collision_mask = game.player.collision_mask
	query.exclude = [game.player.get_rid()]
	var space := game.player.get_world_3d().direct_space_state
	var best := 0.0
	var run := 0.0
	var v := a
	while v <= b:
		var p := Vector3(v, floor_y + shape_node.position.y + 0.02, fixed) if axis == "x" else Vector3(fixed, floor_y + shape_node.position.y + 0.02, v)
		query.transform = Transform3D(Basis(), p)
		if space.intersect_shape(query, 1).is_empty():
			run += 0.05
			best = maxf(best, run)
		else:
			run = 0.0
		v += 0.05
	return best + 0.8 if best > 0.0 else 0.0


func _street() -> VardhelmAmbientLife:
	return district.life_named("StreetLife")


func _street_observation(id: String) -> EnvironmentalObservation:
	return _street().get_node("EnvironmentalObservations/%s" % id) as EnvironmentalObservation


## Pátio (frente da gaiola) → portão sul → rua. Só andando, sem desvio automático.
func _yard_to_street() -> bool:
	var a := await _walk_to(Vector3(1.4, YARD_Y, 14.6), 0.35)
	var b := await _walk_to(Vector3(2.3, YARD_Y, 17.0), 0.35)
	var c := await _walk_to(Vector3(2.3, YARD_Y, 25.0), 0.35)
	var d := await _walk_to(Vector3(0.4, YARD_Y, 30.0), 0.35)
	var gate := await _walk_to(Vector3(0.2, YARD_Y, 33.6), 0.3)
	var out := await _walk_to(Vector3(0.0, YARD_Y, 37.0), 0.35)
	return a and b and c and d and gate and out


## Rua → portão sul → pátio (frente da gaiola).
func _street_to_yard() -> bool:
	var a := await _walk_to(Vector3(0.0, YARD_Y, 36.5), 0.35, 600, true)
	var gate := await _walk_to(Vector3(0.2, YARD_Y, 31.0), 0.3)
	var b := await _walk_to(Vector3(2.3, YARD_Y, 25.0), 0.35)
	var c := await _walk_to(Vector3(2.3, YARD_Y, 17.0), 0.35)
	var d := await _walk_to(Vector3(1.4, YARD_Y, 14.6), 0.35)
	var e := await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.3)
	return a and gate and b and c and d and e


func _examine(id: String, approach: Vector3) -> bool:
	await _walk_to(approach, 0.35, 900, true)
	await _frames(8)
	if _candidate() == null or String(_candidate().name) != id:
		print("[C25] candidato em %s: %s" % [game.player.global_position, String(_candidate().name) if _candidate() != null else "-"])
		return false
	await _key(KEY_E)
	await _frames(10)
	return game.observation_panel.visible and _street_observation(id).revealed


func _new_game() -> void:
	if game != null:
		root.remove_child(game)
		game.queue_free()
		await _frames(4)
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c25_playtest/c2.json")
	district = game.foundry_district
	_events.clear()
	game.shadow_events.subscribe(func(e: GameEvent) -> void: _events.append([e.event_type, String(e.payload.get("quest_id", ""))]))
	await _frames(20)


func _tr(key: String) -> String:
	return game.localization.tr_key(key)


## Conversa com Durn onde ele estiver, andando até ele. Devolve as falas.
func _talk_to_durn(choice: int) -> Array:
	await _walk_to(game.npc.global_position, 1.1, 600, true)
	await _frames(8)
	var lines: Array = []
	if _candidate() != game._npc_interactable:
		print("[C25] candidato perto de Durn: %s" % (String(_candidate().name) if _candidate() != null else "-"))
		return lines
	await _key(KEY_E)
	await _frames(6)
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 20:
		lines.append(game.dialogue_box.text_label.text)
		var buttons: Array = game.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			game.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[choice] as Button).pressed.emit()
		guard += 1
		await _frames(3)
	return lines


func _examine_forge(id: String, target: Vector3, waypoints: Array = []) -> bool:
	for waypoint in waypoints:
		await _walk_to(waypoint, 0.6, 400, true)
	await _walk_to(target, 1.0, 600, true)
	await _frames(8)
	if _candidate() == null or String(_candidate().name) != id:
		print("[C25] candidato em %s: %s" % [game.player.global_position, String(_candidate().name) if _candidate() != null else "-"])
		return false
	await _key(KEY_E)
	await _frames(10)
	return game.observation_panel.visible


## Do começo até o gancho de Durn ("Então não fui só eu."), andando.
func _play_to_hook(intro_choice: int) -> bool:
	var intro := await _talk_to_durn(intro_choice)
	await _walk_to(game.echo.global_position, 1.2, 600, true)
	await _frames(6)
	await _key(KEY_E)
	await _frames(20)
	await _seconds(5.0)
	var after_echo := await _talk_to_durn(0)
	var panel_node := game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as Node3D
	var panel := await _examine_forge("sealed_panel", panel_node.global_position, PANEL_APPROACH)
	await _seconds(1.0)
	var hook := await _talk_to_durn(0)
	if not (intro.size() > 0 and after_echo.size() > 0 and panel and hook.has("Então não fui só eu.")):
		print("[C25] gancho: intro=%s pos_eco=%s painel=%s gancho=%s" % [intro, after_echo, panel, hook])
		return false
	return true


func _hours_events(from: int) -> Array:
	return _events.slice(from).filter(func(e): return String(e[1]).contains("hours")).map(func(e): return "%s:%s" % [e[0], String(e[1]).trim_prefix("quest.vardhelm.")])


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c25_playtest")
	print("[C25] modo: ", SaveV2LoadMetrics.rendering_info())

	# --- Caminho "Sentir o quê?" ------------------------------------------------------
	await _new_game()
	var hooked := await _play_to_hook(0)
	_check(hooked and game.quest_controller.states.active.has(HOURS.THE_HOURS_QUEST_ID) and game.objective_label.text == _tr(HOURS.OBJECTIVE_ASK_DURN_KEY), "A. do começo ao gancho, andando; \"%s\"" % game.objective_label.text)
	await _screenshot("a_objetivo_pergunte_a_durn")
	var lines := await _talk_to_durn(0)
	_check(lines.size() == 4 and String(lines[1]).contains("5h58") and game.objective_label.text == _tr(HOURS.OBJECTIVE_COMPARE_KEY), "A. Durn conta os horários: %s" % " / ".join(lines))
	await _screenshot("b_objetivo_comparar")
	var stalls_before := _stalls
	await _walk_to(Vector3(0.0, 0.25, 3.0), 0.4, 600, true)
	var to_hoist := await _forge_to_hoist(1.6)
	var down := await _ride()
	var out := await _yard_to_street()
	_check(to_hoist and down and out and _stalls == stalls_before, "A. Forja → talha → pátio → rua, andando (%s)" % game.player.global_position)
	# Save na rua antes da comparação.
	await _walk_to(Vector3(-15.5, YARD_Y, 37.5), 0.4, 900, true)
	await _key(KEY_S, true)
	var saved_at := game.player.global_position
	var from := _events.size()
	var board := await _examine("foundry_street_shift_board", Vector3(-17.0, YARD_Y, 35.7))
	_check(board and game.observation_text.text == _tr(HOURS.SHIFT_BOARD_HOURS_TEXT_KEY), "A. quadro de turnos, lido com os horários: \"%s\"" % game.observation_text.text)
	await _screenshot("c_quadro_de_turnos_comparado")
	await _seconds(5.5)
	_check(game.objective_label.text == _tr(HOURS.OBJECTIVE_FIND_OUT_KEY) and _hours_events(from) == ["quest_progressed:the_hours", "quest_completed:the_hours", "quest_started:those_hours"], "A. novo objetivo: \"%s\" %s" % [game.objective_label.text, str(_hours_events(from))])
	await _screenshot("d_novo_objetivo")
	# Load antes da comparação → compara de novo (uma vez).
	from = _events.size()
	await _key(KEY_L, true)
	await _frames(20)
	_check(game.last_v2_load_result.is_success() and _flat(game.player.global_position, saved_at) < 0.1 and game.objective_label.text == _tr(HOURS.OBJECTIVE_COMPARE_KEY) and _hours_events(from).is_empty(), "A. Load antes da comparação: de volta, sem reemitir nada")
	from = _events.size()
	board = await _examine("foundry_street_shift_board", Vector3(-17.0, YARD_Y, 35.7))
	_check(board and _hours_events(from).size() == 3 and game.objective_label.text == _tr(HOURS.OBJECTIVE_FIND_OUT_KEY), "A. depois do Load, a comparação acontece de novo, uma vez")
	await _seconds(5.5)
	# Save depois da comparação → Load.
	await _key(KEY_S, true)
	from = _events.size()
	await _key(KEY_L, true)
	await _frames(20)
	_check(game.last_v2_load_result.is_success() and game.objective_label.text == _tr(HOURS.OBJECTIVE_FIND_OUT_KEY) and _events.slice(from).map(func(e): return e[0]) == ["game_loaded"], "A. Load depois da comparação: novo objetivo mantido; só game_loaded")
	var save_text := FileAccess.get_file_as_string(V2_FILE).to_lower()
	_check(save_text.contains("quest.vardhelm.those_hours") and not save_text.contains("5h58"), "A. no save: as quests, nenhum texto derivado")
	var states: Array = (game.get_node("AmbientLife") as VardhelmAmbientLife).environment_states.keys()
	_check(not states.any(func(s): return String(s).contains("open") or String(s).contains("broken")) and game.find_children("*Elyra*", "", true, false).is_empty(), "A. painel continua fechado; Elyra ausente")

	# --- Caminho "Não senti nada." ----------------------------------------------------
	await _new_game()
	hooked = await _play_to_hook(1)
	_check(hooked and game.objective_label.text == _tr(HOURS.OBJECTIVE_READ_NOTES_KEY) and game.is_durn_away_from_home(), "B. do começo ao gancho, andando; Durn longe do lugar de sempre; \"%s\"" % game.objective_label.text)
	lines = await _talk_to_durn(0)
	_check(lines == ["...Você disse que não sentiu nada.", "Está na folha. Onde eu ficava."] and not game.hours.knows_hours(), "B. Durn não conta: %s" % " / ".join(lines))
	await _screenshot("e_durn_aponta_a_folha")
	var read := await _examine_forge("durn_notes", DURN_HOME)
	_check(read and game.observation_text.text == _tr(HOURS.NOTES_HOURS_TEXT_KEY) and game.objective_label.text == _tr(HOURS.OBJECTIVE_COMPARE_KEY), "B. a folha, lida: \"%s\"" % game.observation_text.text)
	await _screenshot("f_folha_lida")
	await _seconds(5.5)
	lines = await _talk_to_durn(0)
	_check(lines == ["..."], "B. depois, Durn em silêncio %s" % str(lines))

	var dir := DirAccess.open("user://c25_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c25_playtest")
	print("[C25] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C25] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
