extends SceneTree

## Bloco C18 — PLAYTEST AUTOMATIZADO DO CICLO DAS JANELAS CONTEXTUAIS (não é teste humano).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c18_contextual_windows_playtest.gd -- --out=<dir>
##
## Frames reais, física real, andando com as ações de movimento; o detector de interação
## decide o candidato como no jogo. A dica "E • …" é amostrada a cada frame:
##   A. chegar ao suporte de ferramentas → a dica aparece;
##   B. ficar parado → a dica fica, sem reiniciar (sem novo fade-in);
##   C. sair → a dica não some na hora (ainda visível ~0,3 s depois);
##   D. longe → a dica fecha depois do atraso (~0,75 s + fade-out 0,15 s);
##   E. sair e voltar logo → o fechamento é cancelado, a dica nunca some;
##   F. oscilar na borda da área → nenhuma piscada;
##   G. uma só dica; H. conversa com Durn: a dica sai e a distância não fecha a conversa;
##   I. o E ainda examina; N. Save → mudar → Load não deixa dica indevida.
## Eco, painel e folha (J/K/L) são cobertos pelos playtests do C11/C15/C16/C17.3.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c18_playtest/v2.json"
const RACK := Vector3(-3.5, 0.25, 2.3)
const AWAY := Vector3(2.0, 0.25, 2.3)

var game: VardhelmVerticalSlice
var _out := ""
var _checks := 0
var _failures: Array = []
## Amostras por frame: {"ms", "visible", "alpha", "candidate", "state"}.
var _samples: Array = []
var _sampling := false


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
	print("[C18] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		_sample()
		await process_frame


func _sample() -> void:
	if not _sampling:
		return
	var candidate := _candidate()
	_samples.append({
		"ms": Time.get_ticks_msec(),
		"visible": game.interaction_hint.visible,
		"alpha": game.interaction_hint.modulate.a,
		"candidate": String(candidate.name) if candidate != null else "-",
		"state": game.hint_lifecycle.state,
	})


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


## Anda em direção ao alvo (ações de movimento relativas à câmera) até chegar ou até
## `until` devolver true. Devolve true se parou por `until` (ou chegou, sem `until`).
func _walk_to(target: Vector3, stop_distance: float = 0.4, max_frames: int = 400, until := Callable()) -> bool:
	var camera := game.player.camera
	var hit := false
	for i in max_frames:
		if until.is_valid() and until.call():
			hit = true
			break
		var delta := target - game.player.global_position
		delta.y = 0.0
		if delta.length() <= stop_distance:
			hit = not until.is_valid()
			break
		var forward := -camera.global_transform.basis.z
		forward.y = 0.0
		var right := camera.global_transform.basis.x
		right.y = 0.0
		var dir := delta.normalized()
		var up_amount := dir.dot(forward.normalized())
		var right_amount := dir.dot(right.normalized())
		_set_action("move_up", up_amount > 0.25)
		_set_action("move_down", up_amount < -0.25)
		_set_action("move_right", right_amount > 0.25)
		_set_action("move_left", right_amount < -0.25)
		await physics_frame
		_sample()
	_release()
	return hit


func _release() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _place_player(pos: Vector3) -> void:
	game.player.global_position = pos
	game.player.velocity = Vector3.ZERO
	await _frames(4)


func _candidate() -> Interactable:
	return game.player.get_node("InteractionDetector").current_candidate


func _is_rack() -> bool:
	return _candidate() != null and _candidate().name == "tool_rack"


func _no_candidate() -> bool:
	return _candidate() == null


func _wait_seconds(seconds: float) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await _frames(1)


func _start_samples() -> void:
	_samples.clear()
	_sampling = true


## Transições visível→invisível dentro das amostras (cada uma é uma "piscada" se a
## dica volta logo depois).
func _hidden_frames() -> int:
	return _samples.filter(func(s): return not s["visible"]).size()


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
	DirAccess.make_dir_recursive_absolute("user://c18_playtest")
	print("[C18] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c18_playtest/c2.json")
	var spy := SpySaveService.new()
	game.save_service = spy
	await _frames(20)
	var lifecycle := game.hint_lifecycle
	var hint := game.interaction_hint

	# --- A. chegar ------------------------------------------------------------------------
	await _place_player(AWAY)
	await _frames(int(ceil((lifecycle.close_delay + lifecycle.fade_out) * 60.0)) + 20)
	_check(not hint.visible and _candidate() == null, "estado 1: longe do suporte, sem dica")
	var opens_before := lifecycle.open_count
	await _walk_to(RACK, 0.3, 400, _is_rack)
	await _frames(12)
	_check(_is_rack() and hint.visible and game.interaction_hint_label.text == "E  •  Examinar" and lifecycle.open_count == opens_before + 1, "A. andando até o suporte de ferramentas, \"E • Examinar\" aparece (fade-in %.2f s)" % lifecycle.fade_in)
	_check(is_equal_approx(hint.modulate.a, 1.0), "A. … e termina opaca (alpha %.2f)" % hint.modulate.a)
	await _screenshot("a_dica_aparece")

	# --- B. ficar --------------------------------------------------------------------------
	await _walk_to(RACK, 0.3, 200)
	_start_samples()
	await _wait_seconds(1.5)
	_sampling = false
	_check(_hidden_frames() == 0 and lifecycle.open_count == opens_before + 1 and _samples.all(func(s): return s["state"] == "visible" and is_equal_approx(s["alpha"], 1.0)), "B. parado na área por 1,5 s: a dica fica, opaca, sem reiniciar (%d frames)" % _samples.size())

	# --- C/D. sair -------------------------------------------------------------------------
	_start_samples()
	var left := await _walk_to(AWAY, 0.3, 400, _no_candidate)
	var left_ms := Time.get_ticks_msec()
	await _walk_to(AWAY, 0.3, 200)
	var remaining := 1.3 - (Time.get_ticks_msec() - left_ms) / 1000.0
	if remaining > 0.0:
		await _wait_seconds(remaining)
	_sampling = false
	var after_leave: Array = _samples.filter(func(s): return s["ms"] >= left_ms)
	var early: Array = after_leave.filter(func(s): return s["ms"] - left_ms <= 300)
	var first_hidden := -1
	for s in after_leave:
		if not s["visible"]:
			first_hidden = s["ms"] - left_ms
			break
	_check(left and not early.is_empty() and early.all(func(s): return s["visible"]), "C. ao sair, a dica não some na hora (visível nos primeiros 0,3 s: %d frames)" % early.size())
	_check(first_hidden >= 700 and first_hidden <= 1150 and not hint.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "D. longe, a dica fecha depois do atraso + fade-out (sumiu %d ms após sair)" % first_hidden)
	var fading: Array = after_leave.filter(func(s): return s["state"] == "closing")
	_check(not fading.is_empty() and fading.all(func(s): return s["visible"]) and fading.any(func(s): return s["alpha"] < 0.99), "D. o fechamento é um fade-out curto (%d frames em closing)" % fading.size())
	await _screenshot("d_dica_fechada")

	# --- E. sair e voltar logo ---------------------------------------------------------------
	await _walk_to(RACK, 0.3, 400, _is_rack)
	await _walk_to(RACK, 0.3, 200)
	await _frames(10)
	var opens_e := lifecycle.open_count
	_start_samples()
	await _walk_to(AWAY, 0.3, 400, _no_candidate)
	var out_ms := Time.get_ticks_msec()
	await _frames(6)
	var pending_seen := lifecycle.is_close_pending()
	await _walk_to(RACK, 0.3, 400, _is_rack)
	var back_ms := Time.get_ticks_msec() - out_ms
	await _wait_seconds(1.2)
	_sampling = false
	_check(pending_seen and _hidden_frames() == 0 and lifecycle.open_count == opens_e and lifecycle.state == ContextualWindowLifecycle.STATE_VISIBLE, "E. saiu e voltou em %d ms: fechamento cancelado, a dica nunca sumiu, sem novo fade-in" % back_ms)

	# --- F. oscilar na borda -----------------------------------------------------------------
	var opens_f := lifecycle.open_count
	_start_samples()
	var crossings := 0
	for i in 4:
		if await _walk_to(AWAY, 0.3, 400, _no_candidate):
			crossings += 1
		await _frames(3)
		if await _walk_to(RACK, 0.3, 400, _is_rack):
			crossings += 1
		await _frames(3)
	_sampling = false
	var seen_candidates := {}
	for s in _samples:
		seen_candidates[s["candidate"]] = true
	_check(crossings == 8 and _hidden_frames() == 0 and lifecycle.open_count == opens_f and seen_candidates.has("-"), "F. entrando/saindo da borda 8 vezes: nenhuma piscada, nenhum fade-in novo (%d frames)" % _samples.size())

	# --- G. uma dica -------------------------------------------------------------------------
	var hints := game.get_node("NarrativeUI").find_children("InteractionHint", "", true, false)
	_check(hints.size() == 1, "G. uma única janela de dica em cena")

	# --- I. o E ainda examina ------------------------------------------------------------------
	await _key(KEY_E)
	await _frames(20)
	_check(game.observation_panel.visible and _is_rack(), "I. com a dica aberta, E examina o suporte (painel de observação aberto)")
	await _screenshot("i_examinar")

	# --- H. conversa com Durn ----------------------------------------------------------------
	await _place_player(Vector3(-4.0, 0.25, -0.6))
	await _frames(10)
	var talk_ok := _candidate() != null and _candidate() == game._npc_interactable and hint.visible
	await _key(KEY_E)
	await _frames(6)
	var in_dialogue := game.dialogue_controller.is_active()
	_start_samples()
	await _place_player(AWAY)
	await _wait_seconds(1.5)
	_sampling = false
	_check(talk_ok and in_dialogue and _hidden_frames() == _samples.size() and game.dialogue_controller.is_active(), "H. conversa com Durn: a dica sai na hora, não volta e a distância não fecha a conversa")
	await _screenshot("h_conversa")
	while game.dialogue_controller.is_active():
		var buttons: Array = game.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			game.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[0] as Button).pressed.emit()
		await _frames(3)
	await _frames(10)

	# --- N. Save / Load ----------------------------------------------------------------------
	await _place_player(AWAY)
	await _wait_seconds(1.2)
	await _key(KEY_S, true)
	var save_text := FileAccess.get_file_as_string(V2_FILE).to_lower()
	_check(game.last_v2_save_result != null and game.last_v2_save_result.is_success() and not save_text.contains("hint") and not save_text.contains("window") and not save_text.contains("contextual"), "M. Save V2 sem nada da janela contextual")
	await _walk_to(RACK, 0.3, 400, _is_rack)
	await _frames(10)
	var visible_before_load := hint.visible
	await _key(KEY_L, true)
	await _frames(6)
	_start_samples()
	await _wait_seconds(1.3)
	_sampling = false
	_check(visible_before_load and game.last_v2_load_result != null and game.last_v2_load_result.is_success() and _candidate() == null and not hint.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "N. Load de volta para longe: a dica aberta antes do Load fecha pelo ciclo normal, nada fica preso")
	_check(game.get_node("NarrativeUI").find_children("InteractionHint", "", true, false).size() == 1, "N. … e continua uma dica só (o Load não cria outra)")
	await _walk_to(RACK, 0.3, 400, _is_rack)
	await _frames(12)
	_check(hint.visible and game.interaction_hint_label.text == "E  •  Examinar", "depois do Load, chegar ao suporte mostra a dica de novo")
	_check(spy.calls == 0, "SaveService legado nunca chamado (%d)" % spy.calls)

	var dir := DirAccess.open("user://c18_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c18_playtest")
	print("[C18] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C18] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
