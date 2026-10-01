extends RefCounted

## Bloco C6 — pipeline diagnóstico completo com o Vardhelm REAL:
##   jogo -> GameState capturado -> SaveV2DiagnosticCoordinator.save -> arquivo
##   -> coordenador NOVO -> load -> checksum -> GameState -> RestorePlan
##   -> VardhelmDiagnosticSandbox (instância nova) -> adapters -> comparação
## Também: antes/depois do Eco, posição exata, Old Load × V2 (instâncias
## isoladas), idempotência, save duplicado e não mutação do jogo principal.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const DIAGNOSTIC_FILE := "user://save_v2_tests/echoes_of_the_soul_save_v2_diagnostic.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const FIXED_CLOCK := 1700000000
const PLAYER_POSITION := Vector3(-1.5, 0.25, 1.75)
const PLAYER_ROTATION := Vector3(0.0, 1.1, 0.0)


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _ctrl(physical: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	return event


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


## Estado funcional + apresentação derivada (sem UI transitória, animação, áudio ou timers).
func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo_revealed": slice.echo.revealed,
		"echo_interaction": slice.echo.interaction_enabled,
		"echo_visual": (slice.echo.get_node("Visual") as MeshInstance3D).visible,
		"afterglow": slice._post_echo_marker.visible,
		"banner": slice.completion_banner.visible,
		"objective": slice.objective_label.text,
		"environment_states": env,
		"observations": observations,
		"npc_interaction": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
	}


func _main_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress,
		_functional(slice), slice.dialogue_controller.is_active(), slice.dialogue_box.visible, slice.status_label.text,
		slice.player.global_position, slice.player.global_rotation], "", true)


func _project(slice: VardhelmVerticalSlice) -> GameState:
	return GameStateProjector.project(slice.narrative_controller.world_state, slice.quest_controller.states, slice.player, slice.dialogue_controller.persistent_state).state


## Jogo principal real até antes (false) ou depois (true) do Primeiro Eco.
func _play(t, through_echo: bool) -> VardhelmVerticalSlice:
	_isolate(t)
	var main := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	main.name = "MainGame"
	t.root.add_child(main)
	# C10.5: V2 é o padrão; esta suíte testa explicitamente o caminho LEGADO (+ sombra C2).
	main.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	main.shadow_save_v2.service = SaveV2Service.new(TEST_DIR + "/c2_shadow.json")
	main.player.global_position = PLAYER_POSITION
	main.player.global_rotation = PLAYER_ROTATION
	main._npc_interactable.interact(main.player)
	_press_choice(main, 0)
	main.dialogue_box.continue_button.pressed.emit()
	main.dialogue_box.continue_button.pressed.emit()
	if through_echo:
		main.echo.interact(main.player)
		for id in OBSERVATIONS:
			_observation(main, id).interact(main.player)
	# Ctrl+S real (SaveService antigo + sombra C2) — o jogo segue normal.
	t.root.push_input(_ctrl(KEY_S))
	return main


func _coordinator() -> SaveV2DiagnosticCoordinator:
	var coordinator := SaveV2DiagnosticCoordinator.new(SaveV2DiagnosticConfig.create(true, DIAGNOSTIC_FILE))
	coordinator.service.clock = func() -> int: return FIXED_CLOCK
	return coordinator


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_flag_off(t)
	_test_before_echo(t)
	_test_after_echo(t)
	_isolate(t)
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	if backup != null:
		var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
		file.store_string(String(backup))
		file.close()
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _test_flag_off(t) -> void:
	t.section("C6 Vardhelm — flag desligada")
	var sandbox := VardhelmDiagnosticSandbox.new(t.root, "DiagnosticOff")
	var report := SaveV2DiagnosticCoordinator.new().load_and_restore(sandbox)
	t.check(report.status == SaveV2DiagnosticReport.DISABLED and sandbox.slice == null, "flag OFF (padrão): nenhum sandbox criado, nada carregado")


# 19. antes do Eco
func _test_before_echo(t) -> void:
	t.section("C6 Vardhelm — antes do Eco")
	var main := _play(t, false)
	var expected := GameState.from_dict(main.shadow_state.snapshot())
	var main_functional := _functional(main)
	var main_before := _main_json(main)
	var saved := _coordinator().save(expected)
	t.check(saved.is_success(), "V2 save diagnóstico (%s)" % saved.describe())
	var sandbox := VardhelmDiagnosticSandbox.new(t.root, "DiagnosticBeforeEcho")
	var report := _coordinator().load_and_restore(sandbox, expected)
	t.check(report.is_success(), "V2 load -> sandbox: %s" % report.describe())
	if not report.is_success():
		return
	var restored := _functional(sandbox.slice)
	t.check(not restored["echo_revealed"] and restored["echo_interaction"] and restored["echo_visual"], "Eco não resolvido: oculto, interativo, esfera presente")
	t.check(t.same_json(restored, main_functional), "estado funcional idêntico ao jogo antes do Eco (incluindo esfera e diálogo)")
	t.check(GameStateComparator.compare(expected, _project(sandbox.slice)).is_equal(), "GameState restaurado == GameState capturado")
	t.check(_main_json(main) == main_before, "jogo principal intacto")
	sandbox.discard()
	t.check(sandbox.is_discarded() and sandbox.slice == null, "sandbox descartado depois do diagnóstico")


# 20–35. depois do Eco
func _test_after_echo(t) -> void:
	t.section("C6 Vardhelm — depois do Eco: save V2 diagnóstico")
	var main := _play(t, true)
	var expected := GameState.from_dict(main.shadow_state.snapshot())
	var main_functional := _functional(main)
	var main_before := _main_json(main)
	var main_events := main.shadow_events.published_count()
	var shadow_before := JSON.stringify(main.shadow_state.snapshot(), "", true)
	var shadow_object := main.shadow_state.game_state

	var saver := _coordinator()
	var saved := saver.save(expected)
	t.check(saved.is_success() and saved.checksum_verified, "V2 save real (%s)" % saved.describe())
	var text := FileAccess.get_file_as_string(DIAGNOSTIC_FILE)
	var split := SaveV2Checksum.split_file_text(text)
	t.check(split["ok"] and SaveV2Checksum.compute_from_text(String(split["covered"])) == saved.checksum, "arquivo literal lido: checksum confere")
	t.check(not FileAccess.get_file_as_string(OLD_SAVE_PATH).is_empty() and FileAccess.get_file_as_string(OLD_SAVE_PATH) != text, "save antigo (Ctrl+S) e arquivo V2 diagnóstico são arquivos distintos")
	var again := saver.save(expected)
	t.check(again.is_success() and FileAccess.get_file_as_string(DIAGNOSTIC_FILE) == text, "31. mesmo GameState salvo duas vezes: arquivo idêntico")

	t.section("C6 Vardhelm — depois do Eco: load V2 -> sandbox")
	var sandbox := VardhelmDiagnosticSandbox.new(t.root, "DiagnosticAfterEcho")
	var report := _coordinator().load_and_restore(sandbox, expected)
	t.check(report.is_success(), "V2 load real em diagnóstico: %s" % report.describe())
	if not report.is_success():
		return
	print("   info plano: ", report.plan_counts)
	print("   info etapas: ", " → ".join(PackedStringArray(report.steps)))
	t.check(report.checksum_verified and report.steps.find("checksum") < report.steps.find("sandbox"), "checksum validado antes do restore")
	# 3 observações descobertas (C5 usava 1): 17 supported · 14 adapter-supported.
	t.check(report.plan_counts == {"supported": 17, "adapter-supported": 14, "requires_adapter": 0, "unsupported": 0, "not_implemented": 1}, "RestorePlan validado: 17 · 14 · 0 requires_adapter · 0 unsupported · 1 not_implemented")
	var state := report.state
	var slice := sandbox.slice
	var restored := _project(slice)
	t.check(GameStateComparator.compare(expected, state).is_equal(), "GameState reconstruído do arquivo == capturado")
	t.check(GameStateComparator.compare(expected, restored).is_equal(), "runtime restaurado == GameState capturado (player, world, consequences, observations, quests, dialogue, memory, npcs)")

	t.section("C6 Vardhelm — depois do Eco: campos")
	t.check(slice.player.global_position == state.player.position and slice.player.global_position.is_equal_approx(PLAYER_POSITION), "21. posição exata (sem checkpoint)")
	t.check(slice.player.global_rotation.is_equal_approx(PLAYER_ROTATION) and PLAYER_ROTATION != Vector3.ZERO, "21. rotação não padrão preservada")
	t.check(state.player.scenario_id == GameIdCatalog.SCENARIO_VARDHELM and report.targets.scenario_id == state.player.scenario_id, "scenario_id preservado")
	var dialogue := slice.dialogue_controller.persistent_state
	t.check(dialogue.is_completed("vardhelm_intro") and dialogue.last_choice("vardhelm_intro", "start") == "learn", "22. diálogo concluído + última escolha")
	t.check(not slice.dialogue_controller.is_active() and slice.dialogue_controller.current_session == null and not slice.dialogue_box.visible, "caixa não reaberta; entrada/texto/escolhas/falante não restaurados")
	var world := slice.narrative_controller.world_state
	var observations_ok := true
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		var canonical := GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id)
		observations_ok = observations_ok and node.revealed and node.memory_registered and world.has_flag("observation_%s_seen" % id) \
			and world.values.get("observation.%s.seen" % id) == true and state.world.is_observation_discovered(canonical)
	t.check(observations_ok, "14. três observações: nó, flag, value e GameState")
	var fragments_ok := true
	for id in OBSERVATIONS:
		var memory_id: String = GameIdCatalog.OBSERVATION_FRAGMENTS[GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id)]
		fragments_ok = fragments_ok and restored.memory.is_fragment(memory_id) and restored.memory.get_memory_source_type(memory_id) == "observation"
	t.check(fragments_ok and restored.memory.memories.size() == 4, "13. 3 fragmentos de observação (sem composição) + memória do Eco")
	t.check(restored.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and not restored.memory.is_fragment("memory.vardhelm.first_echo"), "13. memory.vardhelm.first_echo com origem echo")
	var consequences_ok := true
	for consequence_id in [GameIdCatalog.CONSEQUENCE_HEARD_ECHO, "consequence.vardhelm.first_echo_complete"]:
		var record: Dictionary = restored.world.consequences.get(consequence_id, {})
		var source: Dictionary = GameIdCatalog.CONSEQUENCE_SOURCES[consequence_id]
		consequences_ok = consequences_ok and record.get("source_type") == source["source_type"] and record.get("source_id") == source["source_id"]
	t.check(consequences_ok and restored.world.consequences.size() == 2, "15. heard_echo + first_echo_complete com origem do GameIdCatalog")
	t.check(not restored.world.consequences.has("memory.vardhelm.first_echo") and not restored.memory.memories.has("consequence.vardhelm.first_echo_complete"), "memory ≠ consequence")
	var echo := VardhelmRuntimeStateProvider.new(slice).describe_echo(GameIdCatalog.ECHO_FIRST)
	t.check(echo == {"revealed": true, "interaction_enabled": false}, "16. Eco derivado: resolvido, sem interação")
	t.check(slice.npc.interaction_enabled == main.npc.interaction_enabled, "17. NPC")
	var restored_functional := _functional(slice)
	t.check(restored_functional["banner"] and restored_functional["afterglow"] and restored_functional["environment_states"].has("echo_awakened"), "18. apresentação derivada: conclusão, marcador, echo_awakened")
	# C8: bug da esfera corrigido — ao vivo e restaurado coincidem.
	t.check(main_functional["echo_visual"] == false and restored_functional["echo_visual"] == false, "C8: esfera do Eco consistente — oculta ao vivo e no restaurado (bug corrigido)")
	var comparable_main := main_functional.duplicate(true)
	var comparable_restored := restored_functional.duplicate(true)
	comparable_main.erase("echo_visual")
	comparable_restored.erase("echo_visual")
	t.check(t.same_json(comparable_restored, comparable_main), "20. estado funcional idêntico ao jogo depois do Eco (exceto o bug conhecido)")

	t.section("C6 Vardhelm — idempotência")
	var sandbox_b := VardhelmDiagnosticSandbox.new(t.root, "DiagnosticAfterEchoB")
	var report_b := _coordinator().load_and_restore(sandbox_b, expected)
	t.check(report_b.is_success() and t.same_json(_functional(sandbox_b.slice), restored_functional) and GameStateComparator.compare(_project(sandbox_b.slice), restored).is_equal(), "32/33. restore em sandboxes independentes: mesmo estado final")
	var world_b := sandbox_b.slice.narrative_controller.world_state
	var no_duplicates := world_b.memories.count("vardhelm_first_echo_complete") == 1 and world_b.memories.count("vardhelm_heard_echo") == 1 \
		and Array(world_b.memories).size() == 2 and sandbox_b.slice.quest_controller.states.completed.size() == 1 \
		and (sandbox_b.slice.dialogue_controller.persistent_state.choices["vardhelm_intro"] as Dictionary).size() == 1
	t.check(no_duplicates, "sem duplicação de consequência, memória, quest ou escolha")

	t.section("C6 Vardhelm — Old Load × V2 Load (instâncias isoladas)")
	var sandbox_json := JSON.stringify(_functional(slice), "", true)
	var old := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	old.name = "OldLoadInstance"
	t.root.add_child(old)
	# C10.5: V2 é o padrão; esta suíte testa explicitamente o caminho LEGADO (+ sombra C2).
	old.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	old.shadow_save_v2 = null
	old.player.set_physics_process(false)
	# Ctrl+L antigo entregue SÓ a esta instância (o jogo principal não recebe).
	old._unhandled_input(_ctrl(KEY_L))
	var old_state := _project(old)
	var old_vs_expected := GameStateComparator.compare(expected, old_state, "esperado", "old_load")
	var v2_vs_expected := GameStateComparator.compare(expected, restored, "esperado", "v2_load")
	print("   info Old Load × esperado: ", old_vs_expected.summary())
	print("   info   ausentes no old load: ", old_vs_expected.missing_in_right)
	print("   info   diferenças no old load: ", old_vs_expected.divergent_paths())
	print("   info V2 Load × esperado: ", v2_vs_expected.summary())
	t.check(v2_vs_expected.is_equal(), "V2 Load == GameState esperado")
	var old_dialogue_missing := old_vs_expected.missing_in_right.any(func(path): return String(path).begins_with("dialogue."))
	t.check(old_dialogue_missing, "Old Load não restaura diálogo (SaveService antigo não o grava) — registrado")
	t.check(not old_vs_expected.is_equal(), "Old Load difere do esperado (limitações + bug save_service.gd:44 registrados, não corrigidos)")
	t.check(JSON.stringify(_functional(slice), "", true) == sandbox_json, "Old Load não contaminou o sandbox V2")
	old.get_parent().remove_child(old)
	old.queue_free()

	t.section("C6 Vardhelm — não mutação do jogo principal")
	t.check(_main_json(main) == main_before, "34. ZERO diferenças no jogo principal após V2 save + load + restore + sandbox + comparação + Old Load isolado")
	t.check(main.shadow_events.published_count() == main_events, "ZERO eventos novos no jogo principal")
	t.check(main.shadow_state.game_state == shadow_object and JSON.stringify(main.shadow_state.snapshot(), "", true) == shadow_before, "GameState sombra do jogo principal inalterado (continua shadow)")
	sandbox.discard()
	sandbox_b.discard()
	t.check(sandbox.is_discarded() and sandbox_b.is_discarded() and t.root.get_node_or_null("DiagnosticAfterEcho") == null, "sandboxes descartados")
