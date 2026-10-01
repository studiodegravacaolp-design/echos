extends RefCounted

## Bloco C3 — teste REAL de Vardhelm:
##   jogo principal: Durn -> diálogo -> escolha -> quest -> Primeiro Eco -> memória
##   -> consequência -> observação -> Ctrl+S -> Ctrl+L (load antigo operacional)
##   depois: carregar V2 -> diagnóstico -> SANDBOX (2ª instância isolada) -> comparação
## O RestorePlan nunca é aplicado ao jogo principal.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"


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


func _runtime_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress,
		slice.echo.revealed, slice.echo.interaction_enabled, slice.npc.interaction_enabled, slice.objective_label.text, slice.status_label.text,
		slice.player.global_position, slice.player.global_rotation], "", true)


func _targets_for(slice: VardhelmVerticalSlice, sandbox: bool) -> RuntimeRestoreTargets:
	var targets := RuntimeRestoreTargets.new()
	targets.is_sandbox = sandbox
	targets.scenario_id = GameIdCatalog.SCENARIO_VARDHELM
	targets.player = slice.player
	targets.world_state = slice.narrative_controller.world_state
	targets.quest_state = slice.quest_controller.states
	targets.npcs = {GameIdCatalog.canonical_id(GameIdCatalog.KIND_NPC, slice.npc.npc_id): slice.npc}
	return targets


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null

	# --- jogo principal ---------------------------------------------------
	_isolate(t)
	var main := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(main)
	# C10.5: V2 é o padrão; esta suíte testa explicitamente o caminho LEGADO (+ sombra C2).
	main.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	main.shadow_save_v2.service = SaveV2Service.new(TEST_DIR + "/restorer_vardhelm.json")
	main.player.global_position = Vector3(1.25, 0.25, -0.75)
	main.player.global_rotation = Vector3(0.0, 0.6, 0.0)
	main._npc_interactable.interact(main.player)
	_press_choice(main, 0)
	main.dialogue_box.continue_button.pressed.emit()
	main.dialogue_box.continue_button.pressed.emit()
	main.echo.interact(main.player)
	(main.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation).interact(main.player)
	_key(t, KEY_S)
	_key(t, KEY_L)
	var main_after_load := _runtime_json(main)
	var events_after_load := main.shadow_events.published_count()

	t.section("C3 Vardhelm — V2 carregado e diagnóstico")
	t.check(main.shadow_save_v2.last_load_report.get("v2", {}).get("ok", false), "Ctrl+L real: V2 carregado em paralelo ao load antigo (operacional)")
	var loaded := main.shadow_save_v2.service.load_game_state()
	t.check(loaded.ok, "GameState V2 carregado para o diagnóstico (%s)" % loaded.describe())
	if not loaded.ok:
		main.queue_free()
		return
	var state := loaded.state
	var loaded_json := JSON.stringify(state.to_dict(), "", true)
	var restorer := GameStateRuntimeRestorer.new()
	var plan := restorer.diagnose(state)
	var counts := plan.counts()
	print("   info plano do fluxo real: ", counts)
	t.check(counts["supported"] > 0 and counts["requires_adapter"] > 0 and counts["not_implemented"] == 1, "plano classifica todos os campos do GameState real")
	t.check(counts["unsupported"] == 0, "nenhum campo do fluxo real sem destino conhecido")
	for item in plan.by_status("requires_adapter"):
		print("   info requires_adapter: ", item["source_path"], " -> ", item["destination"])
	t.check(_runtime_json(main) == main_after_load, "diagnóstico não altera o jogo principal")
	var refused := restorer.apply_to_sandbox(state, _targets_for(main, false))
	t.check(not refused.success and refused.applied.is_empty(), "restaurar no jogo principal é recusado (alvo não-sandbox)")
	t.check(_runtime_json(main) == main_after_load, "jogo principal intacto após a recusa")

	# --- sandbox: 2ª instância isolada -----------------------------------
	t.section("C3 Vardhelm — sandbox")
	var sandbox := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	sandbox.name = "RestoreSandbox"
	t.root.add_child(sandbox)
	sandbox.player.set_physics_process(false)  # congelado: sem gravidade na comparação
	sandbox.shadow_save_v2 = null
	var targets := _targets_for(sandbox, true)
	var result := restorer.apply_to_sandbox(state, targets)
	t.check(result.success and not result.partial_failure, "restauração aplicada ao sandbox (%s)" % str(result.errors))
	t.check(sandbox.player.global_position == state.player.position and sandbox.player.global_rotation.is_equal_approx(state.player.rotation), "posição/rotação reais restauradas no sandbox")
	var diff := result.differences
	print("   info sandbox restaurado × GameState V2: ", diff["summary"])
	t.check(diff["differences"].is_empty() and diff["missing_in_left"].is_empty() and diff["unexpected_ids"].is_empty(), "GameStateProjected(sandbox) × GameStateLoaded: nenhuma diferença de valor")
	var gap: Array = diff["missing_in_right"]
	var only_dialogue := true
	for path in gap:
		if not String(path).begins_with("dialogue."):
			only_dialogue = false
	t.check(only_dialogue and gap.size() == 2, "única lacuna: dialogue.completed e dialogue.choices (requires_adapter)")
	t.check(not sandbox.echo.revealed and sandbox.objective_label.text.begins_with("Fale com Durn"), "apresentação do sandbox não reaplicada (Eco/objetivo = requires_adapter)")
	t.check(JSON.stringify(state.to_dict(), "", true) == loaded_json, "GameState carregado preservado")
	t.check(sandbox.shadow_events.published_count() == 1, "restauração não publica eventos (sandbox só tem o scenario_entered do boot)")

	# O que o load antigo restaurou no jogo principal × o que o V2 restaurou no sandbox.
	var main_world := main.narrative_controller.world_state
	var sandbox_world := sandbox.narrative_controller.world_state
	t.check(JSON.stringify(main_world.flags, "", true) == JSON.stringify(sandbox_world.flags, "", true), "flags: sandbox (V2) == jogo principal após load antigo")
	# Cópias: ordenar não pode tocar nos arrays reais do runtime.
	var main_memories: Array = main_world.memories.duplicate()
	var sandbox_memories: Array = sandbox_world.memories.duplicate()
	print("   info WorldState.memories — principal: ", main_memories, " | sandbox (V2): ", sandbox_memories)
	main_memories.sort()
	sandbox_memories.sort()
	t.check(main_memories == sandbox_memories, "WorldState.memories: mesmos itens no sandbox (V2) e no jogo principal (ordem não é preservada pelo GameState)")
	t.check(JSON.stringify([main.quest_controller.states.completed, main.quest_controller.states.objective_progress], "", true) == JSON.stringify([sandbox.quest_controller.states.completed, sandbox.quest_controller.states.objective_progress], "", true), "quests: sandbox (V2) == jogo principal")

	t.section("C3 Vardhelm — jogo principal intacto")
	t.check(_runtime_json(main) == main_after_load, "21. runtime principal não foi alterado pelo sandbox")
	t.check(main.shadow_events.published_count() == events_after_load, "nenhum evento novo no jogo principal")
	t.check(main.shadow_state.game_state.world.is_observation_discovered("observation.vardhelm.maintenance_board"), "GameState sombra do jogo principal segue sombra (não foi substituído)")

	sandbox.queue_free()
	main.queue_free()
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
