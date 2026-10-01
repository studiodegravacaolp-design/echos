extends SceneTree

## Bloco C17.3 — PLAYTEST AUTOMATIZADO DA COLISÃO DOS TRABALHADORES (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c17_3_worker_collision_playtest.gd -- --out=<dir>
##
## Física real (move_and_slide do jogador, frames reais), andando com as ações de
## movimento como nos playtests do C11/C15/C16:
##   A. andar direto contra um trabalhador parado: o jogador para no corpo, não atravessa;
##   B. contornar o trabalhador e chegar do outro lado;
##   C/D. ficar no meio da rota de um trabalhador: ele continua indo e voltando (não trava);
##   E. Durn inalterado (um só corpo, a mesma interação);
##   F/G/H. Eco, painel e lugar da folha (C16) continuam alcançáveis andando;
##   I. perto de cada trabalhador o E não os escolhe (nenhum vira candidato);
##   J. Save → mover → Load: nada duplicado, trabalhadores com um corpo cada.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c17_3_playtest/v2.json"

var game: VardhelmVerticalSlice
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
	print("[C17.3] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


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
func _walk_to(target: Vector3, stop_distance: float = 1.3, max_frames: int = 600, allow_detour := true) -> bool:
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
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	await _frames(4)
	return Vector2(target.x - game.player.global_position.x, target.z - game.player.global_position.z).length() <= stop_distance + 0.2


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _place_player(pos: Vector3) -> void:
	game.player.global_position = pos
	game.player.velocity = Vector3.ZERO
	await _frames(4)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _worker(id: String) -> Node3D:
	return game.get_node("AmbientLife/AmbientWorkers/%s" % id) as Node3D


func _candidate() -> Interactable:
	return game.player.get_node("InteractionDetector").current_candidate


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
	DirAccess.make_dir_recursive_absolute("user://c17_3_playtest")
	print("[C17.3] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c17_3_playtest/c2.json")
	var spy := SpySaveService.new()
	game.save_service = spy
	await _frames(20)

	# --- A. andar direto contra um trabalhador quase parado (bigorna) -------------------
	var anvil := _worker("worker_anvil_01")
	await _place_player(anvil.global_position + Vector3(0, 0.25, 1.8))
	await _walk_to(anvil.global_position, 0.05, 150, false)
	var gap := _flat(game.player.global_position, anvil.global_position)
	_check(gap >= 0.55, "A. andando direto contra o trabalhador, o jogador para no corpo (%.2f m entre os centros; cápsulas 0,25 + 0,4)" % gap)
	await _screenshot("a_contra_o_trabalhador")

	# --- B. contornar -----------------------------------------------------------------------
	# Como um jogador: um passo para o lado do trabalhador e segue em frente (sem o
	# desvio automático do andador, que gira 90° e entra no bolsão da forja).
	var side := anvil.global_position + Vector3(0.8, 0.25, 0.9)
	var behind := anvil.global_position + Vector3(0.55, 0.25, -1.3)
	var stepped := await _walk_to(side, 0.3, 300, false)
	var around := await _walk_to(behind, 0.4, 300, false)
	_check(stepped and around, "B. um passo para o lado e o jogador contorna o trabalhador até o outro lado (%s)" % game.player.global_position)

	# --- C/D. o trabalhador segue a rota com o jogador no caminho --------------------------
	var bench := _worker("worker_bench_01")
	await _place_player(Vector3(-2.05, 0.25, 2.0))
	var seen_west := false
	var seen_east := false
	var waited := 0.0
	while waited < 12.0 and not (seen_west and seen_east):
		await create_timer(0.1).timeout
		waited += 0.1
		seen_west = seen_west or bench.position.x < -2.35
		seen_east = seen_east or bench.position.x > -1.75
	_check(seen_west and seen_east, "C/D. com o jogador no meio da rota, o trabalhador da bancada vai e volta (%.1f s; não trava nem treme)" % waited)
	var hauler := _worker("worker_hauler_01")
	var start := hauler.position
	await create_timer(5.0).timeout
	_check(hauler.position.distance_to(start) > 0.5, "o carregador continua andando (%s → %s)" % [start, hauler.position])

	# --- E. Durn ---------------------------------------------------------------------------
	var durn_bodies: Array = game.npc.find_children("*", "CollisionObject3D", true, false)
	var durn_shapes: Array = game.npc.get_children().filter(func(c): return c is CollisionShape3D)
	_check(durn_bodies.size() == 1 and durn_bodies[0] is Interactable and durn_shapes.size() == 1 and game.npc.global_position.is_equal_approx(Vector3(-4.0, 0.25, -2.0)), "E. Durn: um corpo, uma área de interação, no lugar de sempre (sem colisor extra)")

	# --- I. o E não escolhe trabalhadores -------------------------------------------------
	var captured: Array = []
	for worker in game.get_node("AmbientLife/AmbientWorkers").get_children():
		await _place_player((worker as Node3D).global_position + Vector3(0, 0.25, 0.75))
		await _frames(3)
		var candidate := _candidate()
		if candidate != null and worker.is_ancestor_of(candidate):
			captured.append(String(worker.name))
	_check(captured.is_empty(), "I. ao lado de cada trabalhador, o E não os escolhe (%s)" % str(captured))

	# --- F/G/H. Eco, painel, lugar da folha ------------------------------------------------
	await _place_player(Vector3(0.0, 0.25, 3.0))
	var echo_ok := await _walk_to(game.echo.global_position, 1.2)
	_check(echo_ok, "F. Eco alcançável andando (%s)" % game.player.global_position)
	await _walk_to(Vector3(-2.8, 0.25, 1.0), 0.6, 400)
	await _walk_to(Vector3(-5.6, 0.25, 2.9), 0.6, 400)
	var panel_ok := await _walk_to(Vector3(-6.7, 0.25, 1.8), 1.0)
	_check(panel_ok and _candidate() != null and _candidate().name == "sealed_panel", "G. painel alcançável pela frente (candidato %s)" % (_candidate().name if _candidate() != null else "-"))
	await _walk_to(Vector3(-2.8, 0.25, 1.0), 0.6, 400)
	var notes_ok := await _walk_to(Vector3(-4.0, 0.25, -2.0), 1.2)
	_check(notes_ok, "H. o lugar de Durn / da folha (C16) continua alcançável (%s)" % game.player.global_position)
	await _screenshot("h_lugar_de_durn")

	# --- J. Save/Load ----------------------------------------------------------------------
	await _key(KEY_S, true)
	var saved_at := game.player.global_position
	await _place_player(Vector3(0.0, 0.25, 3.0))
	await _key(KEY_L, true)
	await _frames(6)
	var workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	var bodies_ok := workers.all(func(w): return w.find_children("*", "CollisionObject3D", true, false).size() == 1)
	_check(game.last_v2_load_result != null and game.last_v2_load_result.is_success() and workers.size() == 7 and bodies_ok and _flat(game.player.global_position, saved_at) < 0.1, "J. Save → mover → Load: sucesso, 7 trabalhadores com um corpo cada, jogador no ponto salvo")
	_check(spy.calls == 0, "SaveService legado nunca chamado (%d)" % spy.calls)

	var dir := DirAccess.open("user://c17_3_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c17_3_playtest")
	print("[C17.3] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C17.3] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
