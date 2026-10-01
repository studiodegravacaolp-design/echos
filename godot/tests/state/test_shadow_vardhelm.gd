extends RefCounted

## Integração do modo sombra com a cena REAL de Vardhelm (Bloco A3).
## Percorre o fluxo pelos mesmos caminhos do jogo (Interactable e botões da
## DialogueBox), sem Save/Load, e verifica que o GameState sombra acompanha o
## runtime — que continua sendo a fonte de verdade — sem alterá-lo.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"


func _boot(t) -> VardhelmVerticalSlice:
	var slice := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(slice)
	return slice


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func _press_continue(slice: VardhelmVerticalSlice) -> void:
	slice.dialogue_box.continue_button.pressed.emit()


func _runtime_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress], "", true)


func run(t) -> void:
	var slice := _boot(t)
	var recorder := slice.shadow_state

	# 1, 2, 19 — boot
	t.section("A3 Vardhelm — boot")
	t.check(recorder != null and recorder.game_state != null, "GameState criado no boot da experiência")
	t.check(recorder.game_state.player.scenario_id == "scenario.vardhelm", "scenario.vardhelm registrado")
	var boot_snapshot := recorder.snapshot()
	var other := _boot(t)
	t.check(t.same_json(boot_snapshot, other.shadow_state.snapshot()), "dois boots produzem o mesmo estado inicial (determinístico)")
	other.queue_free()
	t.check(recorder.game_state.player.position == slice.player.global_position, "posição amostrada do Player")

	# Durn -> diálogo (caminho real: Interactable e botões da DialogueBox)
	t.section("A3 Vardhelm — Durn e diálogo")
	t.check(slice.npc.npc_id == "vardhelm.durn" and GameIdCatalog.canonical_id("npc", slice.npc.npc_id) == "npc.vardhelm.durn", "Durn mapeado para npc.vardhelm.durn")
	slice._npc_interactable.interact(slice.player)
	t.check(slice.dialogue_controller.is_active(), "diálogo iniciado pelo Interactable de Durn")
	_press_choice(slice, 0)  # "learn"
	t.check(recorder.game_state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "learn", "escolha 'learn' registrada em choices[intro][start]")
	t.check(recorder.game_state.world.is_consequence_applied("consequence.vardhelm.heard_echo"), "heard_echo em world.consequences")
	t.check(not recorder.game_state.memory.has_memory("consequence.vardhelm.heard_echo") and recorder.game_state.memory.memories.is_empty(), "consequência não virou memória")
	_press_continue(slice)  # memory -> end
	_press_continue(slice)  # end -> fim
	t.check(not slice.dialogue_controller.is_active(), "diálogo encerrado")
	t.check(recorder.game_state.dialogue.is_completed("dialogue.vardhelm.intro"), "diálogo concluído -> completed")
	t.check(recorder.game_state.quests.get_status("quest.vardhelm.first_echo") == "active", "quest iniciada -> active")

	# Primeiro Eco
	t.section("A3 Vardhelm — Primeiro Eco")
	t.check(slice.echo.interact(slice.player), "Eco interagido")
	var state := recorder.game_state
	t.check(state.memory.is_echo_resolved("echo.vardhelm.first"), "echo.vardhelm.first = resolved")
	t.check(state.memory.has_memory("memory.vardhelm.first_echo"), "memory.vardhelm.first_echo registrada")
	t.check(state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "first_echo_complete em world.consequences")
	t.check(state.world.get_consequence("consequence.vardhelm.first_echo_complete").get("source_type") == "echo", "fonte = Eco")
	t.check(not state.memory.has_memory("consequence.vardhelm.first_echo_complete"), "first_echo_complete NÃO está em memories")
	t.check(state.quests.get_status("quest.vardhelm.first_echo") == "completed" and state.quests.is_objective_complete("quest.vardhelm.first_echo", "observe"), "quest concluída com objetivo")
	t.check(state.world.consequences.size() == 2, "nenhuma consequência duplicada pela quest")

	# Observação
	t.section("A3 Vardhelm — observação")
	var observation := slice.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation
	observation.interact(slice.player)
	t.check(state.world.is_observation_discovered("observation.vardhelm.maintenance_board"), "observação em world.observations")
	t.check(state.memory.is_fragment("memory.vardhelm.maintenance_board"), "fragmento memory.vardhelm.maintenance_board (source observation)")
	t.check(state.world.consequences.size() == 2, "observação/fragmento não criou consequência")
	t.check(state.npcs.to_dict().is_empty(), "Durn permanece no padrão: sem registro de NPC")

	# Runtime continua sendo a fonte e não foi alterado pelo modo sombra
	t.section("A3 Vardhelm — runtime intacto")
	var runtime_world := slice.narrative_controller.world_state
	t.check(Array(runtime_world.memories) == ["vardhelm_heard_echo", "vardhelm_first_echo_complete"], "WorldState.memories do runtime igual ao A0 (sombra não interfere)")
	t.check(slice.observation_text.text.begins_with("As anotações continuam as mesmas"), "texto pós-Eco exibido como no A0")
	t.check(slice.status_label.text == "Você registrou o primeiro Eco. Ctrl+S salva seu progresso.", "status da UI igual ao A0")

	# 17 e 18 — comparação com o projetor
	t.section("A3 Vardhelm — sombra × projetor")
	var before := _runtime_json(slice)
	var comparison := recorder.compare_with_runtime(runtime_world, slice.quest_controller.states)
	t.check(_runtime_json(slice) == before, "projetor/comparação não alteram o runtime")
	t.check(comparison.differences.is_empty(), "nenhuma diferença de valor entre sombra e projeção")
	t.check(not comparison.has_unexpected_ids(), "nenhum ID inesperado")
	t.check(comparison.missing_in_left.is_empty(), "nada que a projeção veja falta na sombra")
	var only_dialogue := true
	for path in comparison.missing_in_right:
		if not path.begins_with("dialogue."):
			only_dialogue = false
	t.check(only_dialogue and comparison.missing_in_right.size() == 2, "única divergência: DialogueState, invisível ao projetor (esperado)")
	print("   info ", comparison.summary())

	# 20 — serialização
	t.section("A3 Vardhelm — serialização")
	var data := recorder.snapshot()
	var parsed: Dictionary = t.json_roundtrip(data)
	t.check(GameState.validate_dict(parsed).is_empty(), "GameState sombra válido")
	t.check(t.same_json(GameState.from_dict(parsed).to_dict(), data), "GameState sombra reconstruído sem perda")

	# 3 — diálogo repetido: última escolha
	t.section("A3 Vardhelm — diálogo repetido")
	# C12: depois do Eco o Durn abre a conversa pós-Eco; aqui o assunto é repetir a conversa inicial.
	slice.dialogue_controller.start_dialogue(slice.dialogue_data, "start")
	_press_choice(slice, 1)  # "leave"
	t.check(recorder.game_state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "leave", "última escolha substitui a anterior")
	t.check(recorder.diagnostics.is_empty(), "nenhum ID do fluxo real ficou fora do catálogo")

	slice.queue_free()
