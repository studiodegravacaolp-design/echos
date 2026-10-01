extends SceneTree

## Bloco C21 — PLAYTEST AUTOMATIZADO DO DISTRITO DAS FUNDIÇÕES (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c21_foundry_district_playtest.gd -- --out=<dir>
##
## Frames reais, física real, input real (ações de movimento, E, Ctrl+S/Ctrl+L), na
## configuração padrão (Save V2):
##   A. do início da Forja 01 até o patamar: a dica "E • Descer ao pátio";
##   B. E na talha: o jogador chega ao pátio (névoa e luz da área, gaiola embaixo, controle de volta);
##   C–E. andar pelo pátio e examinar os carrinhos, a talha de corrente e a porta da fundição;
##   F. vida: os trabalhadores do pátio seguem as rotas;
##   G. limites: não sai do pátio nem cai (leste, sul, oeste);
##   H. Save no pátio → subir → Load: de volta ao pátio, tudo coerente, nada duplicado;
##   I. subir; Durn e o Eco continuam funcionando na Forja 01;
##   J. descer de novo: o respiro da Forja 01 solta menos fumaça e a porta conta isso.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c21_playtest/v2.json"
const YARD_Y := -11.65

var game: VardhelmVerticalSlice
var district: VardhelmFoundryDistrict
var _out := ""
var _checks := 0
var _failures: Array = []


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
	print("[C21] %s %s" % ["ok  " if condition else "FAIL", label])
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


## Anda até o alvo com as ações de movimento (relativas à câmera), como o jogador.
func _walk_to(target: Vector3, stop_distance: float = 0.5, max_frames: int = 500, allow_detour := true) -> bool:
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
		if allow_detour and stalled > 30 and detour == 0:
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
	_release()
	await _frames(4)
	return _flat(game.player.global_position, target) <= stop_distance + 0.2


## Anda numa direção por um tempo (para testar limites).
func _push(direction: Vector3, frames: int) -> void:
	var camera := game.player.camera
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	var right := camera.global_transform.basis.x
	right.y = 0.0
	var dir := direction.normalized()
	var up_amount := dir.dot(forward.normalized())
	var right_amount := dir.dot(right.normalized())
	_set_action("move_up", up_amount > 0.25)
	_set_action("move_down", up_amount < -0.25)
	_set_action("move_right", right_amount > 0.25)
	_set_action("move_left", right_amount < -0.25)
	for i in frames:
		await physics_frame
	_release()
	await _frames(4)


func _release() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _candidate() -> Interactable:
	return game.player.get_node("InteractionDetector").current_candidate


func _candidate_name() -> String:
	return String(_candidate().name) if _candidate() != null else "-"


func _observation(id: String) -> EnvironmentalObservation:
	return district.observation_root().get_node(id) as EnvironmentalObservation


func _fog() -> float:
	return (game.get_node("VP01_Vardhelm/WorldEnvironment") as WorldEnvironment).environment.fog_height


func _ambient() -> float:
	return (game.get_node("VP01_Vardhelm/WorldEnvironment") as WorldEnvironment).environment.ambient_light_energy


func _cage_y() -> float:
	return (game.get_node("VP02_FoundryDistrict/Generated/Props/HoistCage") as Node3D).position.y


## E na talha e espera a chegada (fade + passagem).
func _ride() -> bool:
	var start_y := game.player.global_position.y
	await _key(KEY_E)
	var waited := 0.0
	while waited < 4.0 and (district.riding or absf(game.player.global_position.y - start_y) < 5.0):
		await _seconds(0.1)
		waited += 0.1
	await _seconds(0.6)
	return not district.riding and absf(game.player.global_position.y - start_y) > 5.0


func _examine(id: String, approach: Vector3) -> bool:
	await _walk_to(approach, 0.4, 600)
	await _frames(6)
	if _candidate_name() != id:
		print("[C21] candidato em %s: %s" % [game.player.global_position, _candidate_name()])
		return false
	await _key(KEY_E)
	await _frames(12)
	return game.observation_panel.visible and _observation(id).revealed


## Da Forja 01 ao patamar: a bancada fica na frente do portão; a passagem é o vão entre
## ela e o respiro de brasas (lado leste; 1,5 m desde o C21.1), como um jogador faria.
func _forge_to_landing() -> bool:
	await _walk_to(Vector3(2.05, 0.25, 3.6), 0.3, 400)
	await _walk_to(Vector3(2.05, 0.25, 5.2), 0.25, 200, false)
	await _walk_to(Vector3(1.2, 0.25, 6.0), 0.3, 200, false)
	await _walk_to(Vector3(0.2, 0.25, 6.8), 0.3, 200, false)
	return await _walk_to(Vector3(0.0, 0.25, 9.1), 0.35, 300)


func _landing_to_forge() -> bool:
	await _walk_to(Vector3(0.2, 0.25, 6.8), 0.3, 300, false)
	await _walk_to(Vector3(1.2, 0.25, 6.0), 0.3, 200, false)
	await _walk_to(Vector3(2.05, 0.25, 5.2), 0.25, 200, false)
	return await _walk_to(Vector3(2.05, 0.25, 3.6), 0.3, 300, false)


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


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c21_playtest")
	print("[C21] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c21_playtest/c2.json")
	var spy := SpySaveService.new()
	game.save_service = spy
	district = game.foundry_district
	await _frames(20)
	_check(not district.player_in_district and is_equal_approx(_fog(), -0.6) and is_equal_approx(_ambient(), 0.3), "início na Forja 01: névoa e luz da Forja como antes")
	var hoist_post := game.get_node("VP02_FoundryDistrict/Generated/Props/Hoist_Post_0") as Node3D
	var coal_pile := game.get_node("VP02_FoundryDistrict/Generated/Props/CoalPile_A") as Node3D
	_check(not district.district_drawn and not coal_pile.is_visible_in_tree() and hoist_post.is_visible_in_tree(), "dentro da Forja 01 o pátio não é desenhado; a talha continua visível (orientação)")

	# --- A. até o patamar -----------------------------------------------------------------
	var reached := await _forge_to_landing()
	await _frames(12)
	_check(reached and _candidate() == district.hoist_top and game.interaction_hint.visible and game.interaction_hint_label.text == "E  •  Descer ao pátio", "A. andando até o patamar: \"E • Descer ao pátio\" (candidato %s)" % _candidate_name())
	_check(district.district_drawn and coal_pile.is_visible_in_tree(), "A. perto do patamar o pátio lá embaixo volta a ser desenhado")
	await _screenshot("a_patamar_talha")

	# --- B. descer --------------------------------------------------------------------------
	var rode := await _ride()
	_check(rode and game.player.global_position.y < -11.0 and _flat(game.player.global_position, Vector3(0, 0, 12.75)) < 0.4, "B. E na talha: o jogador chega ao pátio (%s)" % game.player.global_position)
	_check(district.player_in_district and is_equal_approx(_fog(), -11.2) and is_equal_approx(_ambient(), 0.42) and is_equal_approx(_cage_y(), 0.0), "B. área do pátio: névoa baixa, luz de céu encoberto, gaiola embaixo")
	_check(game.player.is_physics_processing() and not district.riding, "B. o controle volta ao jogador depois da passagem")
	await _frames(12)
	_check(_candidate() == district.hoist_bottom and game.interaction_hint_label.text == "E  •  Subir à Forja 01", "B. na frente da gaiola: \"E • Subir à Forja 01\"")
	await _screenshot("b_patio_chegada")

	# --- C–E. examinar ----------------------------------------------------------------------
	await _walk_to(Vector3(2.2, YARD_Y, 16.0), 0.5, 400)
	var carts := await _examine("foundry_coal_carts", Vector3(1.9, YARD_Y, 19.9))
	_check(carts and game.observation_text.text == game.localization.tr_key("observation.foundry_coal_carts.text"), "C. carrinhos de carvão examinados andando até eles")
	await _screenshot("c_carrinhos")
	await _walk_to(Vector3(2.2, YARD_Y, 24.6), 0.5, 400)
	await _walk_to(Vector3(-6.0, YARD_Y, 23.6), 0.5, 500)
	var pulley := await _examine("foundry_chain_pulley", Vector3(-10.7, YARD_Y, 23.3))
	_check(pulley and game.observation_text.text == game.localization.tr_key("observation.foundry_chain_pulley.text"), "D. talha de corrente examinada")
	await _screenshot("d_talha_corrente")
	await _walk_to(Vector3(-7.5, YARD_Y, 20.0), 0.5, 400)
	var door := await _examine("foundry_forge_door", Vector3(-6.0, YARD_Y, 9.3))
	_check(door and game.observation_text.text == game.localization.tr_key("observation.foundry_forge_door.text"), "E. porta da fundição examinada (antes do Eco)")
	await _screenshot("e_porta_fundicao")

	# --- F. vida ------------------------------------------------------------------------------
	var workers := district.life.get_node("AmbientWorkers").get_children()
	var starts := workers.map(func(w): return (w as Node3D).position)
	await _seconds(4.0)
	var moved := 0
	for i in workers.size():
		if (workers[i] as Node3D).position.distance_to(starts[i]) > 0.2:
			moved += 1
	_check(moved >= 4, "F. vida: %d de %d trabalhadores do pátio em movimento em 4 s" % [moved, workers.size()])

	# --- G. limites ---------------------------------------------------------------------------
	await _walk_to(Vector3(6.0, YARD_Y, 29.0), 0.5, 500)
	await _push(Vector3(1, 0, 0), 240)
	var east := game.player.global_position
	await _push(Vector3(0, 0, 1), 240)
	var south := game.player.global_position
	await _walk_to(Vector3(-8.0, YARD_Y, 28.0), 0.5, 500)
	await _push(Vector3(-1, 0, 0), 240)
	var west := game.player.global_position
	_check(east.x < 14.8 and south.z < 31.8 and west.x > -14.8 and [east, south, west].all(func(p): return p.y > -12.1), "G. limites: leste %.1f, sul %.1f, oeste %.1f — não sai do pátio nem cai" % [east.x, south.z, west.x])
	await _screenshot("g_limite_oeste")

	# --- H. Save no pátio → subir → Load ------------------------------------------------------
	await _walk_to(Vector3(-3.0, YARD_Y, 19.0), 0.5, 500)
	await _key(KEY_S, true)
	var saved_at := game.player.global_position
	_check(game.last_v2_save_result != null and game.last_v2_save_result.is_success(), "H. Save V2 no pátio")
	await _walk_to(Vector3(-1.2, YARD_Y, 14.0), 0.5, 500)
	await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.4, 300)
	await _frames(8)
	var up := await _ride()
	_check(up and game.player.global_position.y > -0.5 and not district.player_in_district, "H. subiu pela talha para a Forja 01")
	await _key(KEY_L, true)
	await _frames(20)
	_check(game.last_v2_load_result != null and game.last_v2_load_result.is_success() and _flat(game.player.global_position, saved_at) < 0.1 and absf(game.player.global_position.y - saved_at.y) < 0.2, "H. Load V2: de volta ao ponto salvo no pátio")
	_check(district.player_in_district and is_equal_approx(_fog(), -11.2) and is_equal_approx(_cage_y(), 0.0) and _observation("foundry_coal_carts").revealed and _observation("foundry_forge_door").revealed, "H. depois do Load: área, névoa e gaiola coerentes; observações do pátio mantidas")
	var districts := game.get_children().filter(func(c): return c is VardhelmFoundryDistrict).size()
	_check(districts == 1 and district.life.get_node("AmbientWorkers").get_child_count() == 6 and game.get_node("NarrativeUI").find_children("InteractionHint", "", true, false).size() == 1, "H. nada duplicado (um pátio, 6 trabalhadores, uma dica)")

	# --- I. subir; Durn e o Eco -----------------------------------------------------------------
	await _walk_to(Vector3(-1.2, YARD_Y, 14.0), 0.5, 500)
	await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.4, 300)
	await _frames(8)
	await _ride()
	_check(not district.player_in_district and is_equal_approx(_fog(), -0.6) and is_equal_approx(_ambient(), 0.3) and is_equal_approx(_cage_y(), 11.9), "I. de volta à Forja 01: névoa e luz da Forja restauradas, gaiola em cima")
	var inside := await _landing_to_forge()
	_check(inside, "I. do patamar de volta para dentro da Forja pela passagem do portão (%s)" % game.player.global_position)
	await _walk_to(Vector3(-2.8, 0.25, 1.0), 0.6, 400)
	await _walk_to(Vector3(-4.0, 0.25, -2.0), 1.2, 400)
	await _frames(8)
	var talked := _candidate() == game._npc_interactable
	await _talk(0)
	_check(talked and game.quest_controller.states.active.has("vardhelm_first_echo"), "I. Durn: o E e a conversa continuam funcionando")
	await _walk_to(game.echo.global_position, 1.2, 600)
	await _frames(6)
	await _key(KEY_E)
	await _frames(20)
	_check(game.quest_controller.states.is_completed("vardhelm_first_echo"), "I. Eco: continua funcionando (quest concluída)")

	# --- J. descer de novo: a reação derivada -------------------------------------------------
	await _seconds(6.0)
	await _walk_to(Vector3(2.0, 0.25, 2.0), 0.6, 500)
	await _forge_to_landing()
	await _frames(8)
	var down_again := await _ride()
	_check(down_again and district.after_echo_applied and is_equal_approx(district.smoke_ratio("ForgeVentSmoke"), 0.35), "J. depois do Eco: o respiro da Forja 01 solta menos fumaça (%.2f)" % district.smoke_ratio("ForgeVentSmoke"))
	await _walk_to(Vector3(-3.0, YARD_Y, 12.0), 0.5, 400)
	var door_after := await _examine("foundry_forge_door", Vector3(-6.0, YARD_Y, 9.3))
	_check(door_after and game.observation_text.text == game.localization.tr_key("observation.foundry_forge_door.after_echo"), "J. a porta da fundição conta que o barulho lá em cima baixou")
	await _screenshot("j_porta_depois_do_eco")
	_check(spy.calls == 0, "SaveService legado nunca chamado (%d)" % spy.calls)

	var dir := DirAccess.open("user://c21_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c21_playtest")
	print("[C21] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C21] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
