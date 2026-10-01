extends RefCounted

## Save V2 (Bloco C1) — integração com o GameState REAL de Vardhelm:
##   fluxo do jogo -> eventos B1 -> GameState sombra -> Save V2 -> Load V2 -> comparação
## Usa caminho isolado e não toca no SaveService, em Ctrl+S/Ctrl+L nem no gameplay.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_PATH := "user://save_v2_tests/vardhelm_integration.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func _runtime_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress, slice.echo.revealed, slice.objective_label.text, slice.status_label.text, slice.player.global_position], "", true)


func run(t) -> void:
	t.section("C1 Vardhelm — GameState real -> Save V2 -> Load V2")
	var old_save_existed := FileAccess.file_exists(OLD_SAVE_PATH)
	var slice := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(slice)
	slice.player.global_position = Vector3(1.37, 0.25, -2.61)
	slice.player.global_rotation = Vector3(0.0, 0.785398, 0.0)
	slice._npc_interactable.interact(slice.player)
	_press_choice(slice, 0)
	slice.dialogue_box.continue_button.pressed.emit()
	slice.dialogue_box.continue_button.pressed.emit()
	slice.echo.interact(slice.player)
	(slice.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation).interact(slice.player)

	var recorder := slice.shadow_state
	recorder.sync_sampled_state()
	var original := recorder.game_state
	var runtime_before := _runtime_json(slice)
	var events_before := slice.shadow_events.published_count()
	var original_json := JSON.stringify(original.to_dict(), "", true)

	var service := SaveV2Service.new(TEST_PATH)
	var saved := service.save_game_state(original)
	t.check(saved.ok, "Save V2 do GameState real (%s)" % saved.describe())
	var loaded := service.load_game_state()
	t.check(loaded.ok, "Load V2 (%s)" % loaded.describe())
	if not loaded.ok:
		slice.queue_free()
		return
	var comparison := GameStateComparator.compare(original, loaded.state, "original", "carregado")
	var diff: Array[String] = []
	for difference in comparison.differences:
		diff.append("%s: %s != %s" % [difference["path"], str(difference["left"]), str(difference["right"])])
	t.check(comparison.is_equal() and not comparison.has_unexpected_ids(), "GameState real original == carregado %s" % ("; ".join(diff) if not diff.is_empty() else ""))
	print("   info ", comparison.summary())
	var state := loaded.state
	t.check(state.player.scenario_id == "scenario.vardhelm" and state.player.position == original.player.position and state.player.rotation == original.player.rotation, "scenario_id, posição e rotação reais exatas")
	t.check(state.memory.has_memory("memory.vardhelm.first_echo") and state.memory.is_fragment("memory.vardhelm.maintenance_board"), "memória do Primeiro Eco e fragmento separados")
	t.check(state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and not state.memory.has_memory("consequence.vardhelm.first_echo_complete"), "first_echo_complete em consequences, fora de memories")
	t.check(state.dialogue.is_completed("dialogue.vardhelm.intro") and state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "learn", "dialogue.completed e dialogue.choices preservados")
	t.check(state.quests.get_status("quest.vardhelm.first_echo") == "completed", "quest preservada")

	t.section("C1 Vardhelm — sombra e gameplay intactos")
	t.check(_runtime_json(slice) == runtime_before, "gameplay/runtime inalterados pelo Save V2 (WorldState, QuestState, Eco, UI, posição)")
	t.check(slice.shadow_events.published_count() == events_before, "Save/Load V2 não publicam eventos (game_saved/game_loaded ainda não integrados)")
	t.check(recorder.game_state == original and JSON.stringify(original.to_dict(), "", true) == original_json, "GameState sombra não é substituído nem alterado pelo load")
	t.check(state != recorder.game_state, "estado carregado é uma cópia só para verificação")
	t.check(FileAccess.file_exists(OLD_SAVE_PATH) == old_save_existed, "arquivo do SaveService antigo não foi tocado")

	service.delete_save()
	DirAccess.remove_absolute(TEST_PATH.get_base_dir())
	slice.queue_free()
