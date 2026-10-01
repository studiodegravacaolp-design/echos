extends SceneTree

## Bloco C11 — PLAYTEST AUTOMATIZADO DE CONTINUIDADE (não é teste humano).
## C12: o trecho final cobre a ponte pós-Eco (Durn reage uma vez → pista → painel selado).
## C13: confere a reação do mundo ao Eco (estado A/B) em cada Save/Load e o banner fora do objetivo.
## C14: encerramento (silêncio ao concluir o painel) e gancho (fala final de Durn).
##
##   godot --path godot --windowed --resolution 1152x648 --script res://tests/save_v2/c11_continuity_playtest.gd -- --out=<dir>
##
## Joga Vardhelm como um jogador, só com INPUT REAL (Input.parse_input_event /
## ações de movimento, clique do mouse nas escolhas, Enter no diálogo, E para
## interagir, Ctrl+S/Ctrl+L), na configuração PADRÃO do jogo (V2), com frames reais.
## Fora do runner headless. Arquivos em user:// próprio da cópia de testes; o save
## antigo e o V2 do usuário não são tocados (caminho do V2 redirecionado).

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const V2_FILE := "user://c11_playtest/v2.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]

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
	print("[C11] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame


func _key(code: Key, ctrl: bool = false, by_keycode: bool = false) -> void:
	if ctrl:
		# Como no teclado: Ctrl é pressionado antes e solto depois da tecla.
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
		# Empacou contra um obstáculo (ex.: Durn no caminho): contorna pela lateral.
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
	var reached := Vector2(target.x - game.player.global_position.x, target.z - game.player.global_position.z).length() <= stop_distance + 0.2
	return reached


func _set_action(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _candidate_name() -> String:
	var candidate = game.player.get_node("InteractionDetector").current_candidate
	return String(candidate.name) if candidate != null else "-"


func _functional() -> Dictionary:
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo": [game.echo.revealed, game.echo.interaction_enabled, (game.echo.get_node("Visual") as MeshInstance3D).visible],
		"banner": game.completion_banner.visible, "objective": game.objective_label.text,
		"environment": env, "observations": observations, "npc": game.npc.interaction_enabled,
		"dialogue": game.dialogue_controller.persistent_state.to_dict(),
		"quest": [game.quest_controller.states.active.duplicate(), game.quest_controller.states.completed.duplicate()],
	}


func _projection() -> GameState:
	return SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]


func _screenshot(name: String) -> void:
	if SaveV2LoadMetrics.render_mode() != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(name + ".png"))


## C13: as três reações do mundo ao Primeiro Eco.
func _world_reacted() -> bool:
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var worker := game.get_node("AmbientLife/AmbientWorkers/worker_bench_01")
	var lamp := game.get_node("VardhelmSetDressing/WorkLight_00") as OmniLight3D
	var machinery := game.get_node("VardhelmAudio/VardhelmMachinery") as AudioStreamPlayer
	return ambient.is_after_echo_world_applied() and worker.get_meta("routine") == "after_echo" and lamp.light_color.is_equal_approx(Color("#BFE3EA")) and game.get_node("VardhelmSetDressing/WorkLightFixture_00").get_child(0).material_override != null and is_equal_approx(machinery.volume_db, -30.0)


func _world_quiet() -> bool:
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var worker := game.get_node("AmbientLife/AmbientWorkers/worker_bench_01")
	var lamp := game.get_node("VardhelmSetDressing/WorkLight_00") as OmniLight3D
	var machinery := game.get_node("VardhelmAudio/VardhelmMachinery") as AudioStreamPlayer
	return not ambient.is_after_echo_world_applied() and worker.get_meta("routine") == "default" and lamp.light_color.is_equal_approx(Color("#FF8A3D")) and is_equal_approx(lamp.light_energy, 0.35) and game.get_node("VardhelmSetDressing/WorkLightFixture_00").get_child(0).material_override == null and is_equal_approx(machinery.volume_db, -20.0)


func _count(type: String) -> int:
	return _events.filter(func(e): return e == type).size()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.make_dir_recursive_absolute("user://c11_playtest")
	print("[C11] modo: ", SaveV2LoadMetrics.rendering_info())
	game = (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new("user://c11_playtest/c2.json")
	var spy := SpySaveService.new()
	game.save_service = spy
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type))
	await _frames(20)
	_check(game.save_v2_operational_config.enabled and game.save_v2_operational_config.save_enabled, "configuração padrão: Save/Load V2")
	await _screenshot("01_entrada")

	# --- ENTRAR → EXPLORAR ------------------------------------------------------
	var spawn := game.player.global_position
	var explored := await _walk_to(spawn + Vector3(-2.0, 0.0, -1.5), 0.6, 120)
	_check(game.player.global_position.distance_to(spawn) > 1.0, "explorar: o jogador anda com as ações de movimento (%s → %s)" % [spawn, game.player.global_position])
	_check(game.interaction_hint.visible or _candidate_name() == "-", "dica de interação aparece só perto de algo interagível")

	# --- ENCONTRAR DURN → CONVERSAR ---------------------------------------------
	var reached := await _walk_to(game.npc.global_position, 1.2)
	_check(reached and _candidate_name() == "Interactable" and game.interaction_hint_label.text.contains("Durn"), "Durn encontrado andando; dica \"%s\" (candidato %s)" % [game.interaction_hint_label.text, _candidate_name()])
	await _key(KEY_E)
	_check(game.dialogue_controller.is_active() and game.dialogue_box.speaker_label.text == "Durn" and game.dialogue_box.text_label.text == "...Você também sentiu isso?", "E abre a conversa com Durn (\"%s\")" % game.dialogue_box.text_label.text)
	_check(not game.player.get_node("InteractionDetector").is_physics_processing() and not game.interaction_hint.visible, "durante a conversa o E não examina o mundo (detector suspenso, dica oculta)")
	await _screenshot("02_durn")
	await _key(KEY_E)
	_check(game.dialogue_controller.current_session != null and game.dialogue_controller.current_session.current_entry_id == "start", "E durante a conversa não reinicia nem pula a fala")
	var buttons := _choice_buttons()
	await _click(buttons[0])
	_check(game.dialogue_controller.is_active() and game.dialogue_controller.current_session.current_entry_id == "memory", "escolha com clique do mouse (\"Sentir o quê?\")")
	await _key(KEY_ENTER, false, true)
	await _key(KEY_ENTER, false, true)
	await _frames(6)
	_check(not game.dialogue_controller.is_active() and not game.dialogue_box.visible, "Enter conclui a conversa; ela não reabre sozinha")
	_check(game.player.get_node("InteractionDetector").is_physics_processing(), "detector volta a funcionar depois da conversa")
	_check(game.quest_controller.states.active.has("vardhelm_first_echo") and game.echo.interaction_enabled, "objetivo avança: quest ativa, Eco disponível")

	# --- ESTADO A (antes do Eco) → SAVE ------------------------------------------
	await _key(KEY_S, true)
	_check(game.last_v2_save_result != null and game.last_v2_save_result.is_success() and game.status_label.text == "Jogo salvo.", "SAVE (estado A, antes do Eco)")
	var state_a := {"functional": _functional(), "position": game.player.global_position, "projection": _projection()}
	_check(_world_quiet(), "C13: antes do Eco o mundo está no estado A")

	# --- ESTADO B/C (Eco resolvido, continuar explorando) ------------------------
	reached = await _walk_to(game.echo.global_position, 1.2)
	_check(reached and _candidate_name() == "FirstEcho", "Eco alcançado andando (candidato %s)" % _candidate_name())
	var before_echo := _events.size()
	await _key(KEY_E)
	await _frames(8)
	_check(game.echo.revealed and not (game.echo.get_node("Visual") as MeshInstance3D).visible and game.memory_panel.visible and game.completion_banner.visible, "Primeiro Eco: esfera some, memória aparece, banner de conclusão")
	_check(game.get_node("AmbientLife").environment_states.has("echo_awakened"), "consequência percebida no mundo (echo_awakened)")
	_check(_world_reacted(), "C13: o mundo reage sem texto (lâmpada sobre o painel fria e falhando, trabalhador sai da rotina, máquinas mais baixas)")
	_check(not game.completion_banner.get_global_rect().intersects(game.objective_panel.get_global_rect()) and root.get_visible_rect().encloses(game.completion_banner.get_global_rect()), "C13: banner do Eco não cobre o objetivo (%s × %s)" % [game.completion_banner.get_global_rect(), game.objective_panel.get_global_rect()])
	await _screenshot("03_eco")
	var echo_events := _events.slice(before_echo)
	var echo_counts := {}
	for type in echo_events:
		echo_counts[type] = int(echo_counts.get(type, 0)) + 1
	_check(echo_counts.get("echo_triggered", 0) == 1 and echo_counts.get("consequence_applied", 0) == 1 and echo_counts.get("quest_completed", 0) == 1, "eventos do Eco sem duplicação %s" % str(echo_counts))
	reached = await _walk_to((game.get_node("AmbientLife/EnvironmentalObservations/tool_rack") as Node3D).global_position, 1.0)
	await _key(KEY_E)
	await _frames(4)
	_check(game.observation_panel.visible, "observação examinada depois do Eco (tool_rack)")
	# C13: sem o painel da observação, para ver o mundo depois do Eco.
	await create_timer(5.5).timeout
	await _screenshot("03b_exploracao_pos_eco")
	await _walk_to(spawn + Vector3(3.0, 0.0, 0.0), 0.6, 200)

	# --- LOAD → volta ao estado A --------------------------------------------------
	await _key(KEY_L, true)
	var trace: Array = [game.player.global_position]
	for i in 6:
		await physics_frame
		trace.append(game.player.global_position)
	print("[C11] diag pos após load (frame a frame): ", trace, " salvo=", state_a["position"], " vel=", game.player.velocity, " on_floor=", game.player.is_on_floor())
	_check(game.last_v2_load_result != null and game.last_v2_load_result.is_success() and game.status_label.text == "Jogo carregado.", "LOAD (volta ao estado A)")
	if JSON.stringify(_functional()) != JSON.stringify(state_a["functional"]):
		print("[C11] diag A salvo:    ", JSON.stringify(state_a["functional"]))
		print("[C11] diag A carregado:", JSON.stringify(_functional()))
	print("[C11] diag A pos ", state_a["position"], " -> ", game.player.global_position, " proj_eq=", GameStateComparator.compare(state_a["projection"], _projection()).summary())
	_check(JSON.stringify(_functional()) == JSON.stringify(state_a["functional"]) and game.player.global_position.distance_to(state_a["position"]) < 0.05 and GameStateComparator.compare(state_a["projection"], _projection()).is_equal(), "estado A restaurado (Eco, esfera, quest, ambiente, observações, diálogo, posição)")
	_check(_world_quiet(), "C13: Load do estado A desfaz a reação do mundo (lâmpada quente, trabalhador na bancada, máquinas normais)")
	_check(not game.memory_panel.visible and not game.observation_panel.visible and root.get_viewport().get_camera_3d() == game.player.camera and game.player.velocity.length() < 0.01, "após o Load: sem painel preso, câmera do jogador, sem velocidade herdada")
	await _screenshot("04_load_estado_a")
	var p0 := game.player.global_position
	await _walk_to(p0 + Vector3(1.5, 0.0, 1.5), 0.5, 90)
	_check(game.player.global_position.distance_to(p0) > 0.5, "jogador continua andando imediatamente após o Load")

	# --- ESTADO D (Eco + memória + observações + consequência) → SAVE ---------------
	await _walk_to(game.echo.global_position, 1.2)
	await _key(KEY_E)
	await _frames(4)
	# C17: o painel selado agora fica num anteparo (só se chega pela frente); o andador,
	# que vai em linha reta, passa antes por um ponto à frente dele, como um jogador faria.
	# Ordem de jogador: painel e ferramentas pela rota central aberta; o quadro por último
	# (desde antes do C17 o andador não o alcança: Durn fecha o corredor forja × máquina).
	var approach := {"sealed_panel": [Vector3(-2.8, 0.25, 1.0), Vector3(-5.6, 0.25, 2.9)]}
	var walk_order := ["sealed_panel", "tool_rack", "maintenance_board"]
	for id in walk_order:
		var target := (game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as Node3D).global_position
		if approach.has(id):
			for waypoint in approach[id]:
				await _walk_to(waypoint, 0.6, 400)
				print("[C11] diag ponto ", waypoint, " jogador=", game.player.global_position)
		var ok_walk := await _walk_to(target, 1.0)
		print("[C11] diag obs ", id, " alvo=", target, " jogador=", game.player.global_position, " chegou=", ok_walk, " cand=", _candidate_name())
		if _candidate_name() == id:
			await _key(KEY_E)
		await _frames(3)
	var discovered := OBSERVATIONS.filter(func(id): return (game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation).revealed)
	_check(game.echo.revealed and discovered.size() >= 2, "estado D: Eco resolvido e observações examinadas andando (%s)" % str(discovered))
	await _key(KEY_S, true)
	var state_d := {"functional": _functional(), "position": game.player.global_position, "projection": _projection()}
	_check(game.last_v2_save_result.is_success() and game.last_v2_save_result.shadow_divergence.is_empty(), "SAVE (estado D); sombra acompanhava o runtime")
	await _walk_to(spawn, 0.6, 300)
	game.npc.set_interaction_enabled(false)
	await _key(KEY_L, true)
	await _frames(6)
	_check(game.last_v2_load_result.is_success() and JSON.stringify(_functional()) == JSON.stringify(state_d["functional"]) and GameStateComparator.compare(state_d["projection"], _projection()).is_equal() and game.player.global_position.distance_to(state_d["position"]) < 0.05, "LOAD (estado D restaurado: Eco, memória, observações, consequência, quest, NPC, posição)")
	_check(_world_reacted(), "C13: Load do estado D mantém a reação do mundo (sem reaplicar o Eco)")
	await _screenshot("05_load_estado_d")

	# --- C12: Durn depois do Eco (reação única), Load durante diálogo, escolha → Save → Load ---
	await _walk_to(game.npc.global_position, 1.2)
	await _key(KEY_E)
	_check(game.dialogue_controller.current_session != null and game.dialogue_controller.current_session.dialogue.dialogue_id == "vardhelm_after_echo" and game.dialogue_box.text_label.text == "...Você voltou.", "C12: depois do Eco Durn reage (\"%s\"), não repete a conversa inicial" % game.dialogue_box.text_label.text)
	await _key(KEY_L, true)
	_check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE and game.dialogue_box.visible and game.status_label.text == "Termine a conversa antes de carregar o jogo.", "Load durante a conversa: recusado, conversa intacta")
	await _screenshot("06_load_recusado_dialogo")
	buttons = _choice_buttons()
	await _click(buttons[1])
	buttons = _choice_buttons()
	await _click(buttons[0])
	_check(game.dialogue_box.text_label.text == "Não.", "C12: \"Você sabe o que era?\" → \"Não.\"")
	await _key(KEY_ENTER, false, true)
	_check(game.dialogue_box.text_label.text.contains("painel selado"), "C12: pista concreta (\"%s\")" % game.dialogue_box.text_label.text)
	await _screenshot("06b_pista_painel")
	await _key(KEY_ENTER, false, true)
	await _key(KEY_ENTER, false, true)
	await _frames(4)
	var after_state := game.dialogue_controller.persistent_state
	_check(not game.dialogue_controller.is_active() and after_state.last_choice("vardhelm_after_echo", "start") == "unsure" and after_state.last_choice("vardhelm_intro", "start") == "learn", "escolha \"Não sei o que foi aquilo.\" e conversa concluída; escolha inicial preservada")
	_check(game.quest_controller.states.active.has("vardhelm_sealed_panel") and game.objective_label.text == "Procure o painel selado no fundo do setor.", "C12: nova investigação (\"%s\")" % game.objective_label.text)
	_check(game.status_label.text != VardhelmVerticalSlice.ECHO_DONE_STATUS, "C13: status do Eco não fica preso durante a investigação (\"%s\")" % game.status_label.text)
	await _key(KEY_S, true)
	game.dialogue_controller.persistent_state.record_choice("vardhelm_after_echo", "start", "found")
	await _walk_to(spawn, 0.6, 300)
	await _key(KEY_L, true)
	await _frames(4)
	_check(game.last_v2_load_result.is_success() and game.dialogue_controller.persistent_state.last_choice("vardhelm_after_echo", "start") == "unsure" and not game.dialogue_controller.is_active(), "Load restaura a última escolha sem reabrir a conversa")
	var repeated := JSON.stringify(_functional())
	await _key(KEY_L, true)
	await _frames(4)
	_check(game.last_v2_load_result.is_success() and JSON.stringify(_functional()) == repeated, "Load repetido: mesmo estado")
	await _walk_to(game.npc.global_position, 1.2)
	await _key(KEY_E)
	_check(game.dialogue_controller.current_session != null and game.dialogue_controller.current_session.current_entry_id == "clue" and _choice_buttons().is_empty(), "C12: falar de novo com Durn só lembra a pista (não repete)")
	await _key(KEY_ENTER, false, true)
	await _key(KEY_ENTER, false, true)
	await _frames(4)
	_check(not game.dialogue_controller.is_active(), "lembrete concluído com Enter")
	var panel_pos := (game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as Node3D).global_position
	# C17: pela frente do anteparo (a rota central aberta), como no estado D.
	for waypoint in approach["sealed_panel"]:
		await _walk_to(waypoint, 0.6, 400)
	await _walk_to(panel_pos, 1.0)
	await _screenshot("06c0_perto_do_painel")
	if _candidate_name() == "sealed_panel":
		await _key(KEY_E)
	await _frames(4)
	_check(game.quest_controller.states.is_completed("vardhelm_sealed_panel") and game.observation_text.text.contains("vibração"), "C12: painel selado examinado andando → investigação concluída (\"%s\")" % game.objective_label.text)
	await _screenshot("06c_painel_selado")
	# --- C14: encerramento (silêncio) e gancho (fala final de Durn) ---------------
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var hum := game.get_node("VardhelmAudio/VardhelmHum") as AudioStreamPlayer
	var lamp := game.get_node("VardhelmSetDressing/WorkLight_00") as OmniLight3D
	_check(ambient.is_closing_silence_active(), "C14: examinar o painel inicia o encerramento")
	await create_timer(2.2).timeout
	# C14.1: todas as fontes de ambiente no piso durante o silêncio (o zumbido contínuo
	# era o que mascarava: a -42 dB ainda ficava em ~-58 dBFS).
	var ambient_volumes := func() -> Array: return ["VardhelmHum", "VardhelmSteam", "VardhelmMachinery"].map(func(n): return snappedf((game.get_node("VardhelmAudio/%s" % n) as AudioStreamPlayer).volume_db, 0.1))
	_check(ambient_volumes.call().all(func(v): return v <= -69.9) and lamp.light_energy < 0.05, "C14.2: silêncio — zumbido/vapor/máquinas %s dB, luz do painel apagada (%.2f)" % [str(ambient_volumes.call()), lamp.light_energy])
	await _screenshot("06d_silencio")
	var waited := 0.0
	while ambient.is_closing_silence_active() and waited < 12.0:
		await create_timer(0.25).timeout
		waited += 0.25
	_check(not ambient.is_closing_silence_active() and ambient_volumes.call() == [-6.0, -16.0, -30.0] and ambient.is_after_echo_world_applied(), "C14.1: depois de %.1f s o som volta ao repouso pós-Eco %s dB e a luz volta a falhar" % [waited, str(ambient_volumes.call())])
	await _walk_to(game.npc.global_position, 1.2)
	await _key(KEY_E)
	var final_lines: Array = []
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 6:
		final_lines.append(game.dialogue_box.text_label.text)
		if final_lines.size() == 2:
			await _screenshot("06e_durn_final")
		await _key(KEY_ENTER, false, true)
		guard += 1
	await _frames(4)
	_check(final_lines == ["...Você ouviu, não ouviu?", "Então não fui só eu.", "..."], "C14: gancho — Durn: %s" % " / ".join(final_lines))
	await _key(KEY_E)
	var silent_line := game.dialogue_box.text_label.text if game.dialogue_controller.is_active() else ""
	await _key(KEY_ENTER, false, true)
	await _frames(4)
	_check(silent_line == "..." and not game.dialogue_controller.is_active(), "C14: depois, Durn só fica em silêncio (\"%s\")" % silent_line)
	await _key(KEY_S, true)
	var state_g := {"functional": _functional(), "projection": _projection()}
	await _walk_to(spawn, 0.6, 300)
	await _key(KEY_L, true)
	await _frames(4)
	_check(game.last_v2_load_result.is_success() and JSON.stringify(_functional()) == JSON.stringify(state_g["functional"]) and GameStateComparator.compare(state_g["projection"], _projection()).is_equal(), "C12: Save/Load com a investigação concluída")

	# --- duplicação e legado ----------------------------------------------------------
	var world := game.narrative_controller.world_state
	_check(_world_reacted(), "C13: no fim, Vardhelm continua no estado pós-Eco (lâmpada, trabalhador, máquinas)")
	_check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and game.quest_controller.states.completed.size() == 2, "nenhuma consequência/quest duplicada no runtime")
	if not discovered.has("sealed_panel"):
		discovered.append("sealed_panel")
	var projected := _projection()
	_check(projected.memory.memories.size() == 1 + discovered.size() and projected.world.observations.size() == discovered.size(), "nenhuma memória/observação duplicada (%d memórias)" % projected.memory.memories.size())
	_check(_count("game_saved") == 4 and _count("game_loaded") == 5, "game_saved/game_loaded só após sucesso (%d / %d)" % [_count("game_saved"), _count("game_loaded")])
	_check(spy.calls == 0, "SaveService legado nunca chamado (%d)" % spy.calls)
	await _screenshot("07_final")

	var dir := DirAccess.open("user://c11_playtest")
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute("user://c11_playtest")
	print("[C11] checks=%d falhas=%d" % [_checks, _failures.size()])
	for failure in _failures:
		print("[C11] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)
