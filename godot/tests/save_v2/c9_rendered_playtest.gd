extends SceneTree

## Blocos C9/C10 — PLAYTEST AUTOMATIZADO + MEDIÇÃO com RENDERIZAÇÃO (não é teste humano).
##
##   godot --path godot --windowed --resolution 960x540 --script res://tests/save_v2/c9_rendered_playtest.gd -- --out=<dir absoluto> [--samples=5]
##
## NÃO faz parte do runner headless (state_test_runner.gd). Abre a janela do jogo,
## avança frames reais, usa Ctrl+S/Ctrl+L de verdade (flags V2 ligadas SOMENTE
## nas instâncias deste playtest; defaults do projeto intocados) e grava:
##   <out>/c9_report_<modo>.json  e capturas <out>/*.png (só no modo renderizado).
## O modo vem de SaveV2LoadMetrics.render_mode(): uma execução headless é rotulada
## "headless" e NUNCA entra na série "rendered".
## Arquivos próprios em user://c9_playtest/; o save antigo do usuário é
## preservado (backup + restauração).

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const DIR := "user://c9_playtest"
const V2_FILE := "user://c9_playtest/echoes_of_the_soul_save_v2.json"
const C2_SHADOW_FILE := "user://c9_playtest/c2_shadow.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const STEP_KEYS := ["total", "rehearsal", "sandbox1_file_validation", "sandbox1_create", "sandbox1_restore", "sandbox1_discard",
	"snapshot", "rollback_rehearsal", "sandbox2_create", "sandbox2_restore", "sandbox2_discard", "apply", "post_restore", "rollback"]

var _out := ""
var _samples := 5
var _mode := ""
var _checks: Array = []
var _failures: Array = []
var _events: Array = []
var _metrics := {}
var _frame_samples := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--samples="):
			_samples = maxi(1, int(arg.substr(10)))
	_mode = SaveV2LoadMetrics.render_mode()
	var series := "rendered" if _mode == "rendered" else "headless"
	DirAccess.make_dir_recursive_absolute(DIR)
	if not _out.is_empty():
		DirAccess.make_dir_recursive_absolute(_out)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	print("[C9] modo: ", SaveV2LoadMetrics.rendering_info())
	await _frames(10)
	var idle := await _idle_frames(60)
	await _performance()
	await _flow_1()
	await _flow_2()
	await _flow_3()
	await _flow_4()
	await _flow_5()
	await _flow_6()
	await _flow_7()
	await _flow_8()
	await _flow_9()
	_isolate()
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	if backup != null:
		var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
		file.store_string(String(backup))
		file.close()
	var dir := DirAccess.open(DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(DIR)
	var summary := {}
	for scenario in _metrics:
		summary[scenario] = {}
		for step in _metrics[scenario]:
			summary[scenario][step] = SaveV2LoadMetrics.summarize(_metrics[scenario][step])
	var frames := {"idle_frame_ms": idle}
	for scenario in _frame_samples:
		frames[scenario] = SaveV2LoadMetrics.summarize(_frame_samples[scenario])
	var report := {"series": series, "rendering": SaveV2LoadMetrics.rendering_info(), "samples": _samples,
		"timings_ms": summary, "frame_with_load_ms": frames, "checks": _checks.size(), "failures": _failures}
	print("[C9] RESUMO ", JSON.stringify(report))
	if not _out.is_empty():
		var file := FileAccess.open(_out.path_join("c9_report_%s.json" % series), FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("[C9] checks=%d falhas=%d" % [_checks.size(), _failures.size()])
	for failure in _failures:
		print("[C9] FAIL ", failure)
	quit(0 if _failures.is_empty() else 1)


# ---------------------------------------------------------------------------
# utilidades
# ---------------------------------------------------------------------------

func _check(condition: bool, label: String) -> void:
	_checks.append(label)
	print("[C9] %s %s" % ["ok  " if condition else "FAIL", label])
	if not condition:
		_failures.append(label)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _idle_frames(count: int) -> Dictionary:
	var samples: Array = []
	for i in count:
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	return SaveV2LoadMetrics.summarize(samples)


func _isolate() -> void:
	for child in root.get_children():
		if child is VardhelmVerticalSlice:
			root.remove_child(child)
			child.queue_free()


func _new_game(v2_on: bool = true) -> VardhelmVerticalSlice:
	_isolate()
	await process_frame
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	game.name = "PlaytestGame"
	root.add_child(game)
	game.shadow_save_v2.service = SaveV2Service.new(C2_SHADOW_FILE)
	game.save_v2_operational_config = SaveV2OperationalConfig.create(v2_on, V2_FILE, v2_on)
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type), [GameEventCatalog.GAME_SAVED, GameEventCatalog.GAME_LOADED])
	await _frames(5)
	return game


func _key(physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	root.push_input(event)


func _talk(game: VardhelmVerticalSlice, choice: int = 0) -> void:
	game._npc_interactable.interact(game.player)
	await _frames(2)
	var buttons: Array = []
	for child in game.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[choice] as Button).pressed.emit()
	await _frames(2)
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()
		await _frames(1)


func _explore(game: VardhelmVerticalSlice) -> void:
	for point in [Vector3(-1.5, 0.25, 1.75), Vector3(2.0, 0.25, -1.0), Vector3(-3.0, 0.25, 3.0)]:
		game.player.global_position = point
		await _frames(3)


func _resolve_echo_and_observe(game: VardhelmVerticalSlice, observations: Array = OBSERVATIONS) -> void:
	game.echo.interact(game.player)
	await _frames(2)
	for id in observations:
		(game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation).interact(game.player)
		await _frames(1)


func _functional(game: VardhelmVerticalSlice) -> Dictionary:
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo": [game.echo.revealed, game.echo.interaction_enabled, (game.echo.get_node("Visual") as MeshInstance3D).visible, (game.echo.get_node("Light") as OmniLight3D).visible],
		"afterglow": game._post_echo_marker.visible, "banner": game.completion_banner.visible, "objective": game.objective_label.text,
		"environment_states": env, "observations": observations, "npc": game.npc.interaction_enabled,
		"dialogue": game.dialogue_controller.persistent_state.to_dict(),
	}


func _project(game: VardhelmVerticalSlice) -> GameState:
	return SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]


## Estado salvo (funcional + persistente + posição exata no instante do save).
func _save(game: VardhelmVerticalSlice) -> Dictionary:
	_key(KEY_S)
	return {"functional": _functional(game), "state": _project(game), "position": game.player.global_position, "rotation": game.player.global_rotation}


## Ctrl+L real; mede o tempo do frame que contém o load (inclui a renderização).
func _load(game: VardhelmVerticalSlice, scenario: String = "") -> SaveV2RuntimeLoadResult:
	var started := Time.get_ticks_usec()
	_key(KEY_L)
	var result := game.last_v2_load_result
	var snapshot := {"functional": _functional(game), "state": _project(game), "position": game.player.global_position, "rotation": game.player.global_rotation}
	await process_frame
	var frame_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if not scenario.is_empty() and result != null:
		_record(scenario, result.timings_ms, frame_ms)
	game.set_meta("c9_after_load", snapshot)
	return result


func _record(scenario: String, timings: Dictionary, frame_ms: float) -> void:
	if not _metrics.has(scenario):
		_metrics[scenario] = {}
		_frame_samples[scenario] = []
	for step in STEP_KEYS:
		if timings.has(step):
			if not _metrics[scenario].has(step):
				_metrics[scenario][step] = []
			_metrics[scenario][step].append(float(timings[step]))
	_frame_samples[scenario].append(frame_ms)


func _after(game: VardhelmVerticalSlice) -> Dictionary:
	return game.get_meta("c9_after_load")


func _matches(game: VardhelmVerticalSlice, saved: Dictionary) -> bool:
	var after := _after(game)
	# C10 (a cada Load comparado): câmera do jogador continua a atual e a UI transitória do estado anterior foi descartada.
	_check(root.get_viewport().get_camera_3d() == game.player.camera and not game.memory_panel.visible and not game.observation_panel.visible, "(C10) após cada Load comparado: câmera do jogador ativa; painéis do estado anterior fechados")
	return JSON.stringify(after["functional"], "", true) == JSON.stringify(saved["functional"], "", true) \
		and GameStateComparator.compare(saved["state"], after["state"]).is_equal() \
		and after["position"] == saved["position"] and after["rotation"].is_equal_approx(saved["rotation"])


func _screenshot(name: String) -> void:
	if _mode != "rendered" or _out.is_empty():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png(_out.path_join(name + ".png"))


# ---------------------------------------------------------------------------
# performance (Parte 1)
# ---------------------------------------------------------------------------

func _performance() -> void:
	# 1. primeiro Load do processo (cold) e 2. segundo Load (warm), quest ativa.
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	var saved := _save(game)
	await _frames(3)
	game.player.global_position = Vector3(3.0, 0.25, -2.0)
	var cold := await _load(game, "1_primeiro_load_cold")
	_check(cold != null and cold.is_success() and _matches(game, saved), "perf: primeiro Load (cold) restaurado")
	game.player.global_position = Vector3(3.0, 0.25, -2.0)
	await _frames(3)
	var warm := await _load(game, "2_segundo_load_warm")
	_check(warm.is_success(), "perf: segundo Load (warm)")
	# 3–8, `_samples` amostras cada.
	await _perf_scenario("3_antes_do_eco", func(g): await _talk(g), func(g): g.echo.interact(g.player))
	await _perf_scenario("4_depois_do_eco", func(g): await _talk(g); await _resolve_echo_and_observe(g, []), func(g): g.player.global_position = Vector3(4.0, 0.25, -3.0))
	await _perf_scenario("5_com_observacoes", func(g): await _talk(g); await _resolve_echo_and_observe(g), func(g): g.player.global_position = Vector3(4.0, 0.25, -3.0))
	await _perf_scenario("6_dialogo_persistido", func(g): await _talk(g, 1), func(g): g.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "learn"))
	await _perf_scenario("7_quest_ativa", func(g): await _talk(g), func(g): g.player.global_position = Vector3(4.0, 0.25, -3.0))
	await _perf_scenario("8_quest_concluida", func(g): await _talk(g); await _resolve_echo_and_observe(g, []), func(g): g.npc.set_interaction_enabled(false))
	# Rollback aplicado (falha injetada no apply).
	game = await _new_game()
	await _talk(game)
	_key(KEY_S)
	for i in _samples:
		game.echo.interact(game.player)
		var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
		coordinator.fault_injection_apply_step = "echo"
		var started := Time.get_ticks_usec()
		var result := coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(root, "SaveV2LoadRehearsal"))
		await process_frame
		_record("9_com_rollback", result.timings_ms, float(Time.get_ticks_usec() - started) / 1000.0)
	# Save V2.
	var save_samples: Array = []
	for i in _samples:
		_key(KEY_S)
		save_samples.append(float(game.last_v2_save_result.timings_ms.get("total", 0.0)))
		await _frames(2)
	_metrics["save_v2"] = {"total": save_samples}


func _perf_scenario(scenario: String, prepare: Callable, perturb: Callable) -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await prepare.call(game)
	var saved := _save(game)
	await _frames(3)
	var ok := true
	for i in _samples:
		await perturb.call(game)
		await _frames(2)
		var result := await _load(game, scenario)
		ok = ok and result != null and result.is_success() and _matches(game, saved)
		await _frames(2)
	_check(ok, "perf: %s — %d loads restauram o save" % [scenario, _samples])


# ---------------------------------------------------------------------------
# fluxos do playtest (Parte 11)
# ---------------------------------------------------------------------------

func _flow_1() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _explore(game)
	await _talk(game)
	var quest_save := _save(game)
	_check(game.last_v2_save_result.is_success() and _events == ["game_saved"], "F1: Save V2 com quest iniciada + game_saved")
	await _frames(3)
	await _resolve_echo_and_observe(game)
	var saved := _save(game)
	var synced := GameStateComparator.compare(game.shadow_state.game_state, saved["state"]).is_equal()
	await _frames(3)
	game.player.global_position = Vector3(5.0, 0.25, 4.0)
	await _frames(3)
	var result := await _load(game)
	_check(result.is_success() and _matches(game, saved), "F1: Load V2 restaura posição, quest, Eco, memória, observações, consequência, NPC, ambiente, diálogo")
	var state: GameState = _after(game)["state"]
	_check(state.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and state.world.observations.size() == 3 and state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and state.quests.get_status("quest.vardhelm.first_echo") == GameQuestState.STATUS_COMPLETED, "F1: memória, observações, consequência, quest")
	_check(synced and GameStateComparator.compare(game.shadow_state.game_state, saved["state"]).is_equal(), "F1: GameState == runtime após Save e == carregado após Load")
	_check(_events == ["game_saved", "game_saved", "game_loaded"], "F1: eventos só após sucesso (%s)" % str(_events))
	_check(not quest_save.is_empty(), "F1: save intermediário registrado")
	await _screenshot("f1_after_load")


func _flow_2() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	var saved := _save(game)
	await _screenshot("f2_1_saved_before_echo")
	await _resolve_echo_and_observe(game)
	game.player.global_position = Vector3(4.0, 0.25, -3.0)
	await _frames(5)
	_check(not (game.echo.get_node("Visual") as MeshInstance3D).visible, "F2: esfera oculta ao resolver (ao vivo)")
	await _screenshot("f2_2_echo_resolved_world_changed")
	var result := await _load(game)
	_check(result.is_success() and _matches(game, saved), "F2: estado ANTES do Eco (esfera, luz, ambiente, banner, observações, posição)")
	var after := _after(game)
	_check(after["functional"]["echo"] == [false, true, true, true] and after["functional"]["environment_states"].is_empty() and not after["functional"]["banner"], "F2: esfera e luz visíveis, sem ambiente pós-Eco, sem banner")
	await _frames(5)
	await _screenshot("f2_3_after_load_before_echo")


func _flow_3() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	await _resolve_echo_and_observe(game)
	var saved := _save(game)
	game.player.global_position = Vector3(4.0, 0.25, -3.0)
	game.narrative_controller.world_state.set_flag("mundo_alterado", true)
	game.npc.set_interaction_enabled(false)
	await _frames(5)
	var result := await _load(game)
	_check(result.is_success() and _matches(game, saved) and not game.narrative_controller.world_state.has_flag("mundo_alterado"), "F3: estado DEPOIS do Eco restaurado")
	await _frames(5)
	await _screenshot("f3_after_load_after_echo")


func _flow_4() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	_key(KEY_S)
	await _frames(2)
	game._npc_interactable.interact(game.player)
	await _frames(3)
	var session := game.dialogue_controller.current_session
	_check(game.dialogue_box.speaker_label.text == "Durn", "F4 (C10): falante exibido como Durn")
	_events.clear()
	var result := await _load(game)
	var message := game.status_label.text
	_check(result.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE and message == game.localization.tr_key(SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE), "F4: recusa clara (\"%s\")" % message)
	_check(game.dialogue_controller.current_session == session and game.dialogue_box.visible and _events.is_empty(), "F4: diálogo continua aberto, nada destruído, sem evento")
	await _screenshot("f4_dialogue_load_rejected")
	var waited := 0.0
	while game.status_label.text == message and waited < VardhelmVerticalSlice.SAVE_V2_MESSAGE_SECONDS + 1.5:
		await create_timer(0.25).timeout
		waited += 0.25
	_check(game.status_label.text != message and game.dialogue_box.visible, "F4: mensagem some sozinha (%.2f s) e o diálogo segue aberto" % waited)


func _flow_5() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	game._npc_interactable.interact(game.player)
	await _frames(2)
	var buttons: Array = []
	for child in game.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[1] as Button).pressed.emit()
	await _frames(2)
	_key(KEY_S)
	var save_ok := game.last_v2_save_result.is_success() and game.last_v2_save_result.dialogue_session_open
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()
		await _frames(1)
	game.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "learn")
	game.player.global_position = Vector3(4.0, 0.25, -3.0)
	await _frames(3)
	var result := await _load(game)
	_check(save_ok and result.is_success() and game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "leave", "F5: última escolha persistida (leave)")
	_check(not game.dialogue_controller.is_active() and not game.dialogue_box.visible, "F5: sessão NÃO reaberta")


func _flow_6() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	_key(KEY_S)
	var text := FileAccess.get_file_as_string(V2_FILE).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	await _resolve_echo_and_observe(game, ["tool_rack"])
	var before := _functional(game)
	_events.clear()
	var result := await _load(game)
	_check(result.status == SaveV2RuntimeLoadResult.VALIDATION_FAILURE and game.status_label.text == game.localization.tr_key(SaveV2PlayerMessages.KEY_LOAD_INVALID), "F6: checksum — mensagem clara (\"%s\")" % game.status_label.text)
	_check(JSON.stringify(_after(game)["functional"]) == JSON.stringify(before) and _events.is_empty(), "F6: runtime intacto, sem evento")
	await _screenshot("f6_checksum_failure")


func _flow_7() -> void:
	var game: VardhelmVerticalSlice = await _new_game()
	await _talk(game)
	_key(KEY_S)
	await _resolve_echo_and_observe(game, ["sealed_panel"])
	var before := _functional(game)
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config, null, game.shadow_events)
	coordinator.fault_injection_apply_step = "echo"
	_events.clear()
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(root, "SaveV2LoadRehearsal")))
	_check(game.last_v2_load_result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and JSON.stringify(_functional(game)) == JSON.stringify(before), "F7: falha no apply → rollback → estado anterior")
	_check(game.status_label.text == game.localization.tr_key(SaveV2PlayerMessages.KEY_LOAD_FAILED_RESTORED) and _events.is_empty(), "F7: mensagem ao jogador, sem game_loaded")
	coordinator.fault_injection_rollback_step = "quests"
	game._present_v2_load_result(coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(root, "SaveV2LoadRehearsal")))
	_check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE and game.status_label.text == game.localization.tr_key(SaveV2PlayerMessages.KEY_LOAD_UNSAFE) and _events.is_empty(), "F7: rollback failure — \"%s\", sem sucesso falso" % game.status_label.text)
	await _frames(3)
	await _screenshot("f7_rollback_failure_message")


func _flow_8() -> void:
	var game: VardhelmVerticalSlice = await _new_game(false)
	await _talk(game)
	_key(KEY_S)
	await _frames(2)
	_key(KEY_L)
	await _frames(2)
	_check(game.last_v2_save_result == null and game.last_v2_load_result == null and FileAccess.file_exists(OLD_SAVE_PATH) and not game.shadow_save_v2.last_load_report.is_empty(), "F8: flags OFF explícitas → Ctrl+S/Ctrl+L legados")
	_check(SaveV2OperationalConfig.new().enabled and SaveV2OperationalConfig.new().save_enabled, "F8: padrão do projeto = V2 (C10.5)")


func _flow_9() -> void:
	var sentinel := "{\"legacy\":\"sentinela C9\"}"
	var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
	file.store_string(sentinel)
	file.close()
	var game: VardhelmVerticalSlice = await _new_game(true)
	await _talk(game)
	_key(KEY_S)
	await _frames(2)
	_key(KEY_L)
	await _frames(2)
	_check(game.last_v2_save_result.is_success() and game.last_v2_load_result.is_success() and FileAccess.get_file_as_string(OLD_SAVE_PATH) == sentinel and game.shadow_save_v2.last_load_report.is_empty() and game.shadow_save_v2.last_save_report.is_empty(), "F9: flags ON → somente V2, sem fallback, save antigo intocado")
