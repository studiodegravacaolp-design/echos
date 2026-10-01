extends RefCounted

## Bloco C7 — Load V2 OPERACIONAL com o Vardhelm REAL, pelo Ctrl+L de verdade.
##   Ctrl+S (antigo + Save V2 sombra do C2) -> alterar o jogo -> Ctrl+L
##   flag ON  -> SaveV2RuntimeLoadCoordinator (rehearsal, snapshot, apply, validação, rollback)
##   flag OFF -> load antigo exatamente como antes
## Cada cenário usa uma instância nova e isolada do jogo.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const V2_FILE := "user://save_v2_tests/echoes_of_the_soul_save_v2_shadow.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const SAVE_ROTATION := Vector3(0.0, 1.1, 0.0)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const MOVED_ROTATION := Vector3(0.0, -2.0, 0.0)


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _key(t, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	t.root.push_input(event)


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _new_game(t, v2_enabled: bool) -> VardhelmVerticalSlice:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	game.name = "MainGame"
	t.root.add_child(game)
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	game.save_v2_operational_config = SaveV2OperationalConfig.create(v2_enabled, V2_FILE)
	game.player.set_physics_process(false)
	game.player.global_position = SAVE_POSITION
	game.player.global_rotation = SAVE_ROTATION
	return game


func _talk(game: VardhelmVerticalSlice) -> void:
	game._npc_interactable.interact(game.player)
	_press_choice(game, 0)
	game.dialogue_box.continue_button.pressed.emit()
	game.dialogue_box.continue_button.pressed.emit()


func _resolve_echo(game: VardhelmVerticalSlice) -> void:
	game.echo.interact(game.player)


func _observe(game: VardhelmVerticalSlice, ids: Array) -> void:
	for id in ids:
		_observation(game, id).interact(game.player)


## Estado funcional + apresentação derivada (sem UI transitória, animação, áudio, timers).
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
		"dialogue_open": slice.dialogue_controller.is_active() or slice.dialogue_box.visible,
	}


func _without_visual(functional: Dictionary) -> Dictionary:
	var copy := functional.duplicate(true)
	copy.erase("echo_visual")
	return copy


func _project(slice: VardhelmVerticalSlice) -> GameState:
	return GameStateProjector.project(slice.narrative_controller.world_state, slice.quest_controller.states, slice.player, slice.dialogue_controller.persistent_state).state


func _raw(slice: VardhelmVerticalSlice) -> String:
	var targets := VardhelmRuntimeStateProvider.new(slice).build_targets()
	return JSON.stringify([SaveV2RuntimeSnapshot.raw_of(targets), SaveV2RuntimeSnapshot.describe(targets), _without_visual(_functional(slice)),
		slice.player.global_position, slice.player.global_rotation], "", true)


## Captura o que foi salvo pelo Ctrl+S: GameState (sombra = conteúdo do arquivo V2) + estado funcional.
func _save(t, game: VardhelmVerticalSlice) -> Dictionary:
	_key(t, KEY_S)
	return {"state": GameState.from_dict(game.shadow_state.snapshot()), "functional": _functional(game),
		"position": game.player.global_position, "rotation": game.player.global_rotation}


func _no_rehearsal_left(t) -> bool:
	for child in t.root.get_children():
		if String(child.name).begins_with("SaveV2LoadRehearsal"):
			return false
	return true


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_initial_state(t)
	_test_before_echo(t)
	_test_after_echo(t)
	_test_reset_runtime(t)
	_test_corrupted(t)
	_test_apply_and_rollback_failure(t)
	_test_disabled(t)
	_test_isolation(t)
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


# Operacional 1 + 12: estado inicial
func _test_initial_state(t) -> void:
	t.section("C7 Vardhelm — OP1 estado inicial (flag ON, Ctrl+L real)")
	var game := _new_game(t, true)
	var saved := _save(t, game)
	var events_before := game.shadow_events.published_count()
	game.player.global_position = MOVED_POSITION
	_talk(game)
	_resolve_echo(game)
	_observe(game, ["maintenance_board"])
	t.check(game.echo.revealed and game.completion_banner.visible, "runtime alterado (diálogo, quest, Eco, observação, posição)")
	_key(t, KEY_L)
	var result := game.last_v2_load_result
	t.check(result != null and result.is_success(), "12. Ctrl+L com flag ON executou o V2: %s" % (result.describe() if result != null else "sem resultado"))
	t.check(game.shadow_save_v2.last_load_report.is_empty(), "12. load antigo NÃO executado (sem relatório C2 de load)")
	t.check(t.same_json(_functional(game), saved["functional"]), "runtime volta ao estado inicial salvo (Eco, banner, ambiente, observações, diálogo, objetivo)")
	t.check(GameStateComparator.compare(saved["state"], _project(game)).is_equal(), "0 diferenças persistentes contra o GameState salvo")
	t.check(game.player.global_position == saved["position"], "posição do save")
	t.check(game.shadow_events.published_count() - events_before >= 0 and _no_rehearsal_left(t), "sandboxes de rehearsal removidos da árvore")


# Operacional 2: antes do Eco
func _test_before_echo(t) -> void:
	t.section("C7 Vardhelm — OP2 antes do Eco")
	var game := _new_game(t, true)
	_talk(game)
	var saved := _save(t, game)
	_resolve_echo(game)
	_observe(game, OBSERVATIONS)
	game.player.global_position = MOVED_POSITION
	game.player.global_rotation = MOVED_ROTATION
	_key(t, KEY_L)
	var result := game.last_v2_load_result
	t.check(result != null and result.is_success(), "11. Load V2: %s" % (result.describe() if result != null else "sem resultado"))
	var functional := _functional(game)
	t.check(t.same_json(functional, saved["functional"]), "11. exatamente o estado ANTES do Eco (inclui esfera, marcador, banner, ambiente)")
	t.check(not game.echo.revealed and game.echo.interaction_enabled, "21. Eco não resolvido e interativo")
	var projected := _project(game)
	t.check(GameStateComparator.compare(saved["state"], projected).is_equal(), "0 diferenças persistentes")
	t.check(projected.quests.get_status("quest.vardhelm.first_echo") == GameQuestState.STATUS_ACTIVE, "19. quest ativa")
	t.check(not projected.memory.has_memory("memory.vardhelm.first_echo") and projected.memory.memories.is_empty(), "16. sem memória do Eco nem fragmentos")
	t.check(not projected.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and projected.world.is_consequence_applied(GameIdCatalog.CONSEQUENCE_HEARD_ECHO), "18. só heard_echo")
	t.check(functional["observations"].values().all(func(pair): return pair == [false, false]), "17. observações voltam a não descobertas")
	t.check(game.player.global_position == saved["position"] and game.player.global_rotation.is_equal_approx(saved["rotation"]), "13/14. posição e rotação do save")
	t.check(game.narrative_controller.world_state.memories.count("vardhelm_first_echo_complete") == 0, "consequência posterior removida")


# Operacional 3, 4, 5, 7: depois do Eco
func _test_after_echo(t) -> void:
	t.section("C7 Vardhelm — OP3 depois do Eco")
	var game := _new_game(t, true)
	_talk(game)
	_resolve_echo(game)
	_observe(game, OBSERVATIONS)
	var saved := _save(t, game)
	# Alterações deliberadas.
	game.player.global_position = MOVED_POSITION
	game.player.global_rotation = MOVED_ROTATION
	game.dialogue_controller.persistent_state.record_choice("vardhelm_intro", "start", "leave")
	game.narrative_controller.world_state.set_flag("alteracao_deliberada", true)
	game.npc.set_interaction_enabled(false)
	var events_before := game.shadow_events.published_count()
	_key(t, KEY_L)
	var result := game.last_v2_load_result
	t.check(result != null and result.is_success(), "Load V2: %s" % (result.describe() if result != null else "sem resultado"))
	var functional := _functional(game)
	var projected := _project(game)
	t.check(GameStateComparator.compare(saved["state"], projected).is_equal(), "0 diferenças persistentes contra o save")
	# C8: bug da esfera corrigido; ao vivo e após o load a esfera fica oculta.
	t.check(saved["functional"]["echo_visual"] == false and functional["echo_visual"] == false, "C8: esfera do Eco consistente — oculta ao vivo e após o Load V2 (bug corrigido)")
	t.check(t.same_json(_without_visual(functional), _without_visual(saved["functional"])), "12. estado funcional do save")
	t.check(game.player.global_position == saved["position"] and game.player.global_rotation.is_equal_approx(saved["rotation"]), "13/14. OP4 posição e rotação do save")
	var dialogue := game.dialogue_controller.persistent_state
	t.check(dialogue.is_completed("vardhelm_intro") and dialogue.last_choice("vardhelm_intro", "start") == "learn" and not functional["dialogue_open"], "15. OP5 DialogueRuntimeState restaurado; diálogo não aberto")
	t.check(game.echo.revealed and not game.echo.interaction_enabled, "21. Eco resolvido")
	t.check(game.npc.interaction_enabled, "20. NPC restaurado")
	t.check(game.quest_controller.states.is_completed("vardhelm_first_echo") and not game.quest_controller.states.active.has("vardhelm_first_echo"), "19. quest concluída")
	t.check(not game.narrative_controller.world_state.has_flag("alteracao_deliberada"), "alteração deliberada desfeita")
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and Array(world.memories).size() == 2, "18/31. OP7 consequências corretas, sem duplicação")
	t.check(projected.memory.get_memory_source_type("memory.vardhelm.first_echo") == "echo" and not projected.world.consequences.has("memory.vardhelm.first_echo") and not projected.memory.memories.has("consequence.vardhelm.first_echo_complete"), "16. memória ≠ consequência")
	t.check(game.shadow_events.published_count() == events_before + 1, "C8: Load V2 publica só game_loaded, após SUCCESS")
	t.check(GameStateComparator.compare(game.shadow_state.game_state, saved["state"]).is_equal() and game.shadow_state.game_state != result.state, "sombra reacompanha o estado carregado (cópia; continua sombra)")
	var after_first := _raw(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and _raw(game) == after_first, "32. Load V2 repetido: idempotente")
	# Runtime internamente inconsistente (derivado ≠ persistente): o rollback não seria
	# comprovável -> recusado antes de tocar em qualquer coisa.
	_observation(game, "tool_rack").revealed = false
	var inconsistent := _raw(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.RESTORE_REJECTED and game.last_v2_load_result.code == SaveV2RuntimeLoadResult.CODE_SNAPSHOT_NOT_REVERSIBLE and _raw(game) == inconsistent, "runtime inconsistente: SNAPSHOT_NOT_REVERSIBLE, nada tocado")


# Operacional 6: runtime recriado
func _test_reset_runtime(t) -> void:
	t.section("C7 Vardhelm — OP6 runtime recriado")
	var game := _new_game(t, true)
	_talk(game)
	_resolve_echo(game)
	_observe(game, OBSERVATIONS)
	var saved := _save(t, game)
	var fresh := _new_game(t, true)
	_key(t, KEY_L)
	t.check(fresh.last_v2_load_result != null and fresh.last_v2_load_result.is_success(), "Load V2 em runtime novo: %s" % fresh.last_v2_load_result.describe())
	var projected := _project(fresh)
	var fragments_ok := true
	for id in OBSERVATIONS:
		var canonical := GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id)
		var node := _observation(fresh, id)
		fragments_ok = fragments_ok and node.revealed and node.memory_registered and projected.world.is_observation_discovered(canonical) \
			and projected.memory.is_fragment(String(GameIdCatalog.OBSERVATION_FRAGMENTS[canonical]))
	t.check(fragments_ok, "17. observações + fragmentos correspondentes restaurados (sem composição)")
	t.check(GameStateComparator.compare(saved["state"], projected).is_equal(), "0 diferenças persistentes")


# Operacional 8: checksum corrompido
func _test_corrupted(t) -> void:
	t.section("C7 Vardhelm — OP8 checksum corrompido")
	var game := _new_game(t, true)
	_talk(game)
	_save(t, game)
	_resolve_echo(game)
	var text := FileAccess.get_file_as_string(V2_FILE).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var before := _raw(game)
	var events_before := game.shadow_events.published_count()
	_key(t, KEY_L)
	var result := game.last_v2_load_result
	t.check(result != null and result.status == SaveV2RuntimeLoadResult.VALIDATION_FAILURE and result.code == SaveV2Errors.INVALID_CHECKSUM, "22. VALIDATION_FAILURE/INVALID_CHECKSUM")
	t.check(_raw(game) == before and not result.snapshot_taken, "34. runtime exatamente igual (nada tocado)")
	t.check(game.shadow_save_v2.last_load_report.is_empty() and game.shadow_events.published_count() == events_before, "sem fallback para o load antigo")
	# C9: o jogador vê mensagem localizada (sem código técnico); o código vai para o log.
	t.check(game.status_label.text == game.localization.tr_key(SaveV2PlayerMessages.KEY_LOAD_INVALID) and not game.status_label.text.contains("VALIDATION_FAILURE"), "falha mostrada ao jogador (mensagem localizada)")


# Operacional 9 e 10 (coordenador com falha injetada, mesmos alvos do Ctrl+L)
func _test_apply_and_rollback_failure(t) -> void:
	t.section("C7 Vardhelm — OP9 falha no apply -> rollback")
	var game := _new_game(t, true)
	_talk(game)
	_save(t, game)
	_resolve_echo(game)
	_observe(game, ["sealed_panel"])
	var before := _raw(game)
	var coordinator := SaveV2RuntimeLoadCoordinator.new(game.save_v2_operational_config)
	coordinator.fault_injection_apply_step = "echo"
	var result := coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal"))
	t.check(result.status == SaveV2RuntimeLoadResult.APPLY_FAILURE and result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and result.main_touched, "27. APPLY_FAILURE + rollback: %s" % result.describe())
	t.check(_raw(game) == before, "9/35. runtime == snapshot após rollback (inclui ambiente, Eco, observações)")
	t.check((game.echo.get_node("Visual") as MeshInstance3D).visible == false, "esfera oculta após rollback (C8: igual ao jogo ao vivo)")

	t.section("C7 Vardhelm — OP10 falha do rollback")
	coordinator.fault_injection_rollback_step = "quests"
	var failed := coordinator.load_into_runtime(VardhelmRuntimeStateProvider.new(game).build_targets(), VardhelmDiagnosticSandbox.new(t.root, "SaveV2LoadRehearsal"))
	t.check(failed.status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE and failed.original_failure.get("status") == SaveV2RuntimeLoadResult.APPLY_FAILURE and not failed.is_success(), "10/28. ROLLBACK_FAILURE detectado, sem falso sucesso: %s" % failed.describe())
	t.check(game.shadow_save_v2.last_load_report.is_empty(), "sem fallback automático para o load antigo")
	t.check(_no_rehearsal_left(t), "sandboxes removidos mesmo após falhas")


# Operacional 11: flag OFF
func _test_disabled(t) -> void:
	t.section("C7 Vardhelm — OP11 flag OFF (comportamento antigo)")
	var game := _new_game(t, false)
	_talk(game)
	_save(t, game)
	_resolve_echo(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result == null, "V2 não chamado")
	# O load antigo aborta em save_service.gd:44 (bug conhecido, não corrigido); o
	# Ctrl+L de sempre segue até a comparação sombra do C2.
	t.check(not game.shadow_save_v2.last_load_report.is_empty(), "load antigo executado (Ctrl+L de sempre + comparação sombra C2)")
	t.check(_no_rehearsal_left(t), "nenhum sandbox criado")


# 29–30: isolamento
func _test_isolation(t) -> void:
	t.section("C7 Vardhelm — isolamento Old Load × V2 Load")
	var game := _new_game(t, true)
	_talk(game)
	_resolve_echo(game)
	_observe(game, OBSERVATIONS)
	var saved := _save(t, game)
	var v2 := _new_game(t, true)
	_key(t, KEY_L)
	var v2_raw := _raw(v2)
	var old := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	old.name = "OldLoadInstance"
	t.root.add_child(old)
	old.shadow_save_v2 = null
	# C10.5: V2 é o padrão; a instância do Old Load usa explicitamente o caminho LEGADO.
	old.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	old.player.set_physics_process(false)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_L
	event.ctrl_pressed = true
	event.pressed = true
	old._unhandled_input(event)
	t.check(v2.last_v2_load_result.is_success() and GameStateComparator.compare(saved["state"], _project(v2)).is_equal(), "30. V2 Load == save")
	t.check(old.last_v2_load_result == null and not GameStateComparator.compare(saved["state"], _project(old)).is_equal(), "29. Old Load (flag OFF) na outra instância: caminho legado, com as limitações conhecidas")
	t.check(_raw(v2) == v2_raw, "instâncias não se misturam")
	old.get_parent().remove_child(old)
	old.queue_free()
