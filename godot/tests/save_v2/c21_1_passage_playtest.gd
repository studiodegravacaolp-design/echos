extends SceneTree

## Bloco C21.1 — PLAYTEST AUTOMATIZADO DA PASSAGEM Forja 01 ↔ talha ↔ pátio (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c21_1_passage_playtest.gd -- --out=<dir>
##
## Só andando (ações de movimento, frames e física reais), nada de teleporte:
##   1. aproximar-se da passagem ao lado da bancada;
##   2. entrar e 3. atravessar em linha reta, de três pontos de entrada diferentes (folga lateral);
##   4. alcançar a talha (dica "E • Descer ao pátio");
##   5. completar a passagem (E);
##   6. retornar (E no pátio, andar do patamar até dentro da Forja);
##   7. atravessar de novo — o ciclo completo duas vezes;
## e Save/Load na Forja e no pátio (posição, rotação, observações, trabalhadores, áudio, câmera).
## Também: o jogador nunca chega nem carrega dentro de colisão; a dica aparece já no portão;
## volta imediata pela talha; Save/Load colado à talha (em cima e embaixo); o percurso antes e
## depois do Primeiro Eco; nenhuma outra interação no caminho; o suporte de ferramentas ao lado.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c21_1_playtest/v2.json"
const LANE_X := 1.6
const YARD_Y := -11.65

var game: VardhelmVerticalSlice
var district: VardhelmFoundryDistrict
var _out := ""
var _checks := 0
var _failures: Array = []
## Travamentos: frames seguidos sem progresso enquanto anda (medido em toda caminhada).
var _stalls := 0
## Candidatos vistos enquanto anda pela passagem (só a talha ou nada é esperado).
var _recording := false
var _seen: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> void:
	_checks += 1
	print("[C21.1] %s %s" % ["ok  " if condition else "FAIL", label])
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
				detour = 35
				stalled = 0
			if stalled == 20 and not allow_detour:
				_stalls += 1
				print("[C21.1] travou em %s a caminho de %s" % [game.player.global_position, target])
			if stalled > 60:
				if allow_detour:
					print("[C21.1] diag: parado em %s; diálogo=%s física=%s" % [game.player.global_position, game.dialogue_controller.is_active(), game.player.is_physics_processing()])
				break
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


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c21_1_playtest")
	print("[C21.1] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c21_1_playtest/c2.json")
	district = game.foundry_district
	await _frames(20)
	var volumes := _volumes()

	# Geometria: a bancada saiu do caminho; nada mais mudou na passagem.
	var bench := game.get_node("VardhelmSetDressing/WorkbenchTop") as Node3D
	var story := game.get_node("VP01_Vardhelm/Generated/Props/WorkbenchStory") as Node3D
	var vent := game.get_node("VP01_Vardhelm/Generated/Props/EmberVent") as Node3D
	var gap := (vent.global_position.x - 0.5) - (bench.global_position.x + 1.6)
	_check(is_equal_approx(bench.global_position.x, -0.6) and is_equal_approx(story.global_position.x, -0.6) and vent.global_position.is_equal_approx(Vector3(3, 1.1, 5)), "bancada e ferramentas 0,6 m a oeste; respiro de brasas no lugar de sempre")
	_check(gap >= 1.45, "vão entre a bancada e o respiro de brasas: %.2f m (jogador 0,80 m)" % gap)

	# 1–3. aproximar, entrar e atravessar de três pontos de entrada (folga lateral).
	var entries_ok: Array = []
	for entry_x in [1.45, 1.7, 1.95]:
		var ok := await _walk_to(Vector3(entry_x, 0.25, 3.7), 0.25)
		ok = ok and await _walk_to(Vector3(entry_x, 0.25, 5.55), 0.2)
		entries_ok.append(ok)
		await _walk_to(Vector3(0.0, 0.25, 3.0), 0.3)
	_check(entries_ok.all(func(v): return v), "atravessa em linha reta entrando em x 1,45 / 1,70 / 1,95 (folga lateral de 0,5 m) %s" % str(entries_ok))

	# 4–7. o ciclo completo, duas vezes.
	for cycle in 2:
		var there := await _forge_to_hoist(1.6)
		var candidate_ok := _candidate() == district.hoist_top and game.interaction_hint.visible and game.interaction_hint_label.text == "E  •  Descer ao pátio"
		_check(there and candidate_ok, "ciclo %d: da Forja até a talha andando; \"E • Descer ao pátio\"" % (cycle + 1))
		if cycle == 0:
			await _screenshot("a_patamar")
		var down := await _ride()
		await _frames(10)
		_check(down and not _in_collision() and district.player_in_district and _candidate() == district.hoist_bottom and game.interaction_hint_label.text == "E  •  Subir à Forja 01", "ciclo %d: desceu; no pátio, \"E • Subir à Forja 01\"" % (cycle + 1))
		var up := await _ride()
		_check(up and not _in_collision() and not district.player_in_district and game.player.global_position.y > -0.5, "ciclo %d: subiu de volta ao patamar" % (cycle + 1))
		var back := await _hoist_to_forge()
		_check(back and game.player.global_position.z < 3.5, "ciclo %d: do patamar de volta para dentro da Forja pela passagem" % (cycle + 1))
	var unexpected := _seen.keys().filter(func(k): return not (k in ["-", "Hoist_hoist_top", "Hoist_hoist_bottom"]))
	_check(unexpected.is_empty(), "na faixa, no portão e no patamar nenhuma outra interação vira candidata (vistos: %s)" % str(_seen.keys()))
	_check(_stalls == 0, "nenhum travamento em nenhuma caminhada (%d)" % _stalls)
	_check(game.player.camera.current and _volumes() == volumes, "câmera do jogador e áudio iguais depois das passagens (%s)" % str(_volumes()))

	# Save/Load na Forja (perto da passagem).
	await _walk_to(Vector3(LANE_X, 0.25, 4.8), 0.25)
	game.player.rotation.y = deg_to_rad(21.0)
	await _frames(2)
	await _key(KEY_S, true)
	var forge_saved := game.player.global_position
	await _walk_to(Vector3(0.0, 0.25, 3.0), 0.3)
	game.player.rotation.y = 0.0
	await _key(KEY_L, true)
	await _frames(10)
	_check(game.last_v2_load_result != null and game.last_v2_load_result.is_success() and _flat(game.player.global_position, forge_saved) < 0.1 and absf(angle_difference(game.player.rotation.y, deg_to_rad(21.0))) < 0.02 and not district.player_in_district, "Save/Load na Forja (na passagem): posição e rotação; área da Forja")

	# Save/Load no pátio.
	await _forge_to_hoist(1.6)
	await _ride()
	await _walk_to(Vector3(1.8, YARD_Y, 16.5), 0.4)
	await _walk_to(Vector3(1.9, YARD_Y, 19.9), 0.4)
	await _frames(6)
	await _key(KEY_E)
	await _frames(10)
	var carts := district.observation_root().get_node("foundry_coal_carts") as EnvironmentalObservation
	game.player.rotation.y = deg_to_rad(-40.0)
	await _frames(2)
	await _key(KEY_S, true)
	var yard_saved := game.player.global_position
	await _walk_to(Vector3(1.0, YARD_Y, 14.5), 0.4)
	await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.3)
	await _frames(6)
	await _ride()
	await _key(KEY_L, true)
	await _frames(20)
	_check(game.last_v2_load_result.is_success() and _flat(game.player.global_position, yard_saved) < 0.1 and absf(angle_difference(game.player.rotation.y, deg_to_rad(-40.0))) < 0.02 and district.player_in_district and carts.revealed, "Save/Load no pátio: posição, rotação, área e observação")
	_check(district.life.get_node("AmbientWorkers").get_child_count() == 6 and game.get_node("AmbientLife/AmbientWorkers").get_child_count() == 7 and game.player.camera.current and _volumes() == volumes, "trabalhadores (6 no pátio, 7 na Forja), câmera e áudio coerentes depois do Load")
	await _screenshot("b_patio_depois_do_load")

	# Save/Load colado à talha, embaixo: não nasce preso e a volta funciona na hora.
	await _walk_to(Vector3(1.0, YARD_Y, 14.5), 0.4)
	await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.3)
	await _key(KEY_S, true)
	var bottom_saved := game.player.global_position
	await _walk_to(Vector3(2.0, YARD_Y, 15.0), 0.4)
	await _key(KEY_L, true)
	await _frames(10)
	var bottom_ok := game.last_v2_load_result.is_success() and _flat(game.player.global_position, bottom_saved) < 0.1 and not _in_collision()
	var steps := await _walk_to(Vector3(0.8, YARD_Y, 13.6), 0.3)
	steps = steps and await _walk_to(Vector3(0.0, YARD_Y, 12.75), 0.3)
	await _frames(6)
	var up_after_load := await _ride()
	_check(bottom_ok and steps and up_after_load and not _in_collision(), "Save/Load colado à talha no pátio: sem colisão, anda na hora, sobe pela talha")
	# Volta imediata: logo ao chegar em cima, E de novo desce; e de novo sobe.
	var again_down := await _ride()
	var again_up := await _ride()
	_check(again_down and again_up and not _in_collision(), "volta imediata pela talha (desce e sobe sem sair do lugar)")
	# Save/Load colado à talha, em cima.
	await _key(KEY_S, true)
	var top_saved := game.player.global_position
	await _walk_to(Vector3(0.8, 0.25, 6.9), 0.3)
	await _walk_to(Vector3(LANE_X, 0.25, 4.6), 0.25)
	await _key(KEY_L, true)
	await _frames(10)
	var top_ok := game.last_v2_load_result.is_success() and _flat(game.player.global_position, top_saved) < 0.1 and not _in_collision() and not district.player_in_district
	await _frames(6)
	var down_after_load := await _ride()
	_check(top_ok and down_after_load and district.player_in_district, "Save/Load colado à talha no patamar: sem colisão, desce pela talha em seguida")
	await _ride()
	await _hoist_to_forge()
	# A dica aparece já ao passar o portão (sem procurar ponto exato).
	await _walk_to(Vector3(LANE_X, 0.25, 5.75), 0.25)
	await _walk_to(Vector3(0.6, 0.25, 7.0), 0.2)
	await _frames(8)
	_check(_candidate() == district.hoist_top and game.interaction_hint.visible, "a dica \"E • Descer ao pátio\" aparece ao cruzar o portão, na entrada do patamar (%s)" % game.player.global_position)
	await _hoist_to_forge()
	# Interações vizinhas: o suporte de ferramentas continua examinável.
	await _walk_to(Vector3(-2.9, 0.25, 2.4), 0.3)
	await _frames(6)
	var rack_ok := _candidate() != null and _candidate().name == "tool_rack"
	await _key(KEY_E)
	await _frames(10)
	_check(rack_ok and game.observation_panel.visible, "suporte de ferramentas ao lado da bancada continua examinável")

	# Antes e depois do Primeiro Eco: Durn → Eco → passagem de novo.
	var approach_stalls := _stalls
	await _walk_to(Vector3(-2.8, 0.25, 1.0), 0.6, 400, true)
	await _walk_to(Vector3(-4.0, 0.25, -2.0), 1.2, 400, true)
	await _frames(8)
	var talked := _candidate() == game._npc_interactable
	await _talk(0)
	await _walk_to(game.echo.global_position, 1.2, 600, true)
	await _frames(6)
	await _key(KEY_E)
	await _frames(20)
	var echoed := game.quest_controller.states.is_completed("vardhelm_first_echo")
	await _seconds(5.5)
	await _walk_to(Vector3(0.5, 0.25, 0.8), 0.5, 500, true)
	await _walk_to(Vector3(0.0, 0.25, 3.0), 0.4, 400, true)
	# Travamentos ao ir até Durn e o Eco não são da passagem (rotas fora do escopo do C21.1).
	var approach_only := _stalls - approach_stalls
	var stalls_before := _stalls
	var after_there := await _forge_to_hoist(1.6)
	var after_down := await _ride()
	var after_up := await _ride()
	var after_back := await _hoist_to_forge()
	_check(talked and echoed and after_there and after_down and after_up and after_back and _stalls == stalls_before, "depois do Primeiro Eco: Forja → talha → pátio → talha → Forja andando, sem travar")
	_check(_stalls - approach_only == 0, "nenhum travamento nas caminhadas da passagem no teste inteiro (%d; fora da passagem: %d)" % [_stalls - approach_only, approach_only])

	var dir := DirAccess.open("user://c21_1_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c21_1_playtest")
	print("[C21.1] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C21.1] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))
