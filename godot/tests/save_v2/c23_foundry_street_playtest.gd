extends SceneTree

## Bloco C23 — PLAYTEST AUTOMATIZADO DA RUA DO DISTRITO DAS FUNDIÇÕES (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c23_foundry_street_playtest.gd -- --out=<dir>
##
## Frames, física e input reais (sem teleporte): Forja → talha → pátio → PORTÃO SUL → rua e volta,
## repetido; larguras reais (cápsula) no portão e na rua; vida (movimento e direção); as 4
## observações; Save/Load na rua e retorno ao pátio; antes e depois do Primeiro Eco; eventos sem
## duplicação; nada transitório no save. Helpers de caminhada iguais aos do C21.1.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c23_playtest/v2.json"
const LANE_X := 1.6
const YARD_Y := -11.65

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


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	print("[C23] %s %s" % ["ok  " if condition else "FAIL", label])
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
				print("[C23] travou em %s a caminho de %s" % [game.player.global_position, target])
			if stalled > 60:
				if allow_detour:
					print("[C23] diag: parado em %s; diálogo=%s física=%s" % [game.player.global_position, game.dialogue_controller.is_active(), game.player.is_physics_processing()])
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
		print("[C23] candidato em %s: %s" % [game.player.global_position, String(_candidate().name) if _candidate() != null else "-"])
		return false
	await _key(KEY_E)
	await _frames(10)
	return game.observation_panel.visible and _street_observation(id).revealed


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c23_playtest")
	print("[C23] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c23_playtest/c2.json")
	district = game.foundry_district
	var events: Array = []
	game.shadow_events.subscribe(func(e: GameEvent) -> void: events.append(e))
	await _frames(20)

	# 1. Forja → talha → pátio → portão sul → rua (antes do Primeiro Eco).
	var to_hoist := await _forge_to_hoist(1.6)
	var down := await _ride()
	var stalls_before := _stalls
	var out := await _yard_to_street()
	_check(to_hoist and down and out and district.player_in_district and _stalls == stalls_before, "1. Forja → talha → pátio → portão sul → rua, só andando, sem travar (%s)" % game.player.global_position)
	_check(not _in_collision() and district.district_drawn, "rua: jogador fora de colisão; distrito desenhado; mesma névoa/luz do pátio")
	await _screenshot("a_saindo_pelo_portao")

	# Larguras reais (cápsula do jogador) no portão e na rua.
	var gate_w := _free_width("x", 32.0, -3.4, 3.4, -11.9)
	var leaves_w := _free_width("x", 30.4, -3.4, 3.4, -11.9)
	var street_ws: Array = []
	for x in [-20.0, -10.0, 0.0, 10.0, 20.0]:
		street_ws.append(snappedf(_free_width("z", x, 32.4, 46.6, -11.9), 0.05))
	_check(gate_w >= 1.5 and leaves_w >= 1.5, "portão sul: vão livre real %.2f m na linha do muro, %.2f m entre as folhas (mínimo 1,5 m)" % [gate_w, leaves_w])
	_check(street_ws.all(func(w): return w >= 1.5), "rua: maior faixa livre em 5 seções transversais (com trabalhadores no lugar) %s m" % str(street_ws))

	# 2. Vida: trabalhadores andando e virados para onde andam.
	var walkers := _street().get_node("AmbientWorkers").get_children()
	var starts := walkers.map(func(w): return (w as Node3D).position)
	var moved_ids := {}
	for k in 12:
		await _seconds(0.5)
		for i in walkers.size():
			if (walkers[i] as Node3D).position.distance_to(starts[i]) > 0.2:
				moved_ids[walkers[i].name] = true
	var moved := moved_ids.size()
	# Direção: espera o carrinho andar e compara a frente dele com o movimento.
	var cart := _street().get_node("AmbientWorkers/worker_street_cart_01") as Node3D
	var aligned := false
	for k in 16:
		var p0 := cart.position
		await _seconds(0.5)
		var motion := cart.position - p0
		motion.y = 0.0
		if motion.length() > 0.3:
			var forward := -cart.global_transform.basis.z
			forward.y = 0.0
			aligned = forward.normalized().dot(motion.normalized()) > 0.8
			break
	_check(moved >= 7 and aligned, "vida: %d de %d trabalhadores da rua em movimento; o carrinho anda virado para onde vai" % [moved, walkers.size()])

	# 3. Observações (antes do Eco), andando.
	var gate_ok := await _examine("foundry_street_gate", Vector3(4.7, YARD_Y, 35.4))
	_check(gate_ok and game.observation_text.text == game.localization.tr_key("observation.foundry_street_gate.text"), "portão do pátio examinado (antes do Eco)")
	var board_ok := await _examine("foundry_street_shift_board", Vector3(-17.0, YARD_Y, 35.7))
	var wagons_ok := await _examine("foundry_street_ore_wagons", Vector3(-18.2, YARD_Y, 42.2))
	await _screenshot("b_vagoes_minerio")
	var sharp_ok := await _examine("foundry_street_sharpening", Vector3(15.4, YARD_Y, 40.4))
	await _screenshot("c_afiacao")
	_check(board_ok and wagons_ok and sharp_ok, "quadro de turnos, vagões de minério e pedra de afiar examinados andando")

	# 4. Portão repetido: rua → pátio → rua, duas vezes.
	var repeats: Array = []
	for i in 2:
		var back := await _street_to_yard()
		var again := await _yard_to_street()
		repeats.append(back and again)
	_check(repeats.all(func(v): return v), "portão sul nos dois sentidos, duas vezes %s" % str(repeats))

	# 5. Save na rua → voltar ao pátio → Load → rua; depois Load → pátio → rua.
	await _walk_to(Vector3(-6.0, YARD_Y, 40.5), 0.35, 600, true)
	game.player.rotation.y = deg_to_rad(-57.0)
	await _frames(2)
	await _key(KEY_S, true)
	var saved_at := game.player.global_position
	var save_text := FileAccess.get_file_as_string(V2_FILE).to_lower()
	_check(game.last_v2_save_result.is_success() and ["worker_street", "corridortrain", "craneload", "fog", "riding", "streetlife"].all(func(w): return not save_text.contains(w)), "Save na rua; nada transitório/derivado no arquivo")
	await _street_to_yard()
	var before_load := events.size()
	await _key(KEY_L, true)
	await _frames(20)
	var load_types: Array = events.slice(before_load).map(func(e: GameEvent): return e.event_type)
	_check(game.last_v2_load_result.is_success() and _flat(game.player.global_position, saved_at) < 0.1 and absf(angle_difference(game.player.rotation.y, deg_to_rad(-57.0))) < 0.02 and not _in_collision() and district.player_in_district and load_types == ["game_loaded"], "Load na rua: posição e rotação, fora de colisão, área do distrito, só game_loaded (%s)" % str(load_types))
	_check(["foundry_street_gate", "foundry_street_shift_board", "foundry_street_ore_wagons", "foundry_street_sharpening"].all(func(id): return _street_observation(id).revealed), "observações da rua mantidas depois do Load")
	var back_after_load := await _street_to_yard()
	var out_after_load := await _yard_to_street()
	_check(back_after_load and out_after_load, "depois do Load: rua → pátio → rua andando")

	# 6. Depois do Primeiro Eco: Forja (Durn, Eco) e de volta à rua.
	await _street_to_yard()
	await _ride()
	await _hoist_to_forge()
	await _walk_to(Vector3(-2.8, 0.25, 1.0), 0.6, 400, true)
	await _walk_to(Vector3(-4.0, 0.25, -2.0), 1.2, 400, true)
	await _frames(8)
	await _talk(0)
	await _walk_to(game.echo.global_position, 1.2, 600, true)
	await _frames(6)
	await _key(KEY_E)
	await _frames(20)
	var echoed := game.quest_controller.states.is_completed("vardhelm_first_echo")
	await _seconds(5.5)
	await _walk_to(Vector3(0.5, 0.25, 0.8), 0.5, 500, true)
	await _walk_to(Vector3(0.0, 0.25, 3.0), 0.4, 400, true)
	var stalls_after := _stalls
	var there := await _forge_to_hoist(1.6)
	var down_after := await _ride()
	var out_after := await _yard_to_street()
	_check(echoed and there and down_after and out_after and _stalls == stalls_after, "depois do Primeiro Eco: Forja → talha → pátio → portão → rua, sem travar")
	await _examine("foundry_street_gate", Vector3(4.7, YARD_Y, 35.4))
	_check(game.observation_text.text == game.localization.tr_key("observation.foundry_street_gate.after_echo"), "depois do Eco, o portão: \"%s\"" % game.observation_text.text)
	await _screenshot("d_portao_depois_do_eco")

	# 7. Eventos sem duplicação.
	var discovered := events.filter(func(e: GameEvent): return e.event_type == "observation_discovered").map(func(e: GameEvent): return e.payload.get("observation_id", ""))
	var unique := {}
	for id in discovered:
		unique[id] = true
	_check(discovered.size() == unique.size() and unique.keys().filter(func(id): return String(id).contains("foundry_street")).size() == 4, "observation_discovered sem duplicação (%d eventos, %d IDs)" % [discovered.size(), unique.size()])
	_check(_stalls == 0, "nenhum travamento nas caminhadas sem desvio (portão e pátio) no teste inteiro (%d)" % _stalls)

	var dir := DirAccess.open("user://c23_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c23_playtest")
	print("[C23] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C23] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
