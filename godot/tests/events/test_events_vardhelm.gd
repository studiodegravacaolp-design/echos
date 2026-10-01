extends RefCounted

## Integração dos eventos estruturados com a cena REAL de Vardhelm (Bloco B1).
## O fluxo segue os caminhos do jogo (Interactable e botões da DialogueBox),
## sem Save/Load. Itens 16–33 e 35.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"

## Sequência REAL observada no runtime para o fluxo completo (documentada em
## docs/architecture/BLOCK_B1_STRUCTURED_EVENTS.md §8).
const EXPECTED_FLOW := [
	"scenario_entered",
	"dialogue_started",
	"dialogue_choice_selected",
	"consequence_applied",        # heard_echo (consequência da escolha "learn")
	"dialogue_completed",
	"quest_started",
	"consequence_applied",        # first_echo_complete (fonte: Eco)
	"world_state_changed",        # echo_awakened (reação do AmbientLife)
	"quest_progressed",
	"quest_completed",
	"echo_triggered",
	"memory_recovered",           # memory.vardhelm.first_echo
	"observation_discovered",
	"memory_recovered",           # fragmento memory.vardhelm.maintenance_board
]

## Ordem real do Primeiro Eco (uma única interação com o Eco).
const EXPECTED_FIRST_ECHO := [
	"consequence_applied",
	"world_state_changed",
	"quest_progressed",
	"quest_completed",
	"echo_triggered",
	"memory_recovered",
]


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
	return JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress, slice.echo.revealed, slice.echo.interaction_enabled, slice.objective_label.text, slice.status_label.text], "", true)


## Percorre o fluxo completo e devolve {slice, recorded, echo_events}.
func _run_flow(t) -> Dictionary:
	var slice := _boot(t)
	# Boot: scenario_entered já foi publicado; um gravador inscrito agora não o
	# veria, então o recorder do próprio GameState é a fonte da contagem inicial.
	var recorded := RecordedEvents.new()
	recorded.attach(slice.shadow_events)
	slice._npc_interactable.interact(slice.player)
	_press_choice(slice, 0)   # learn
	_press_continue(slice)    # memory -> end
	_press_continue(slice)    # end -> fim
	var before_echo := recorded.count()
	slice.echo.interact(slice.player)
	var echo_events: Array[String] = recorded.types().slice(before_echo)
	var observation := slice.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation
	observation.interact(slice.player)
	return {"slice": slice, "recorded": recorded, "echo_events": echo_events}


func run(t) -> void:
	_test_boot_event(t)
	var flow := _run_flow(t)
	var slice: VardhelmVerticalSlice = flow["slice"]
	var recorded: RecordedEvents = flow["recorded"]
	_test_event_types(t, slice, recorded)
	_test_order(t, slice, recorded, flow["echo_events"])
	_test_no_duplicates(t, slice, recorded)
	_test_game_state_receives(t, slice)
	_test_projector_publishes_nothing(t, slice)
	_test_bus_does_not_control_gameplay(t, slice)
	_test_save_service_not_integrated(t, slice)
	_test_npc_and_scenario_completed(t, slice)
	slice.queue_free()
	_test_determinism(t)


# 16. scenario_entered
func _test_boot_event(t) -> void:
	t.section("B1 Vardhelm — boot")
	var slice := _boot(t)
	t.check(slice.shadow_events != null and slice.shadow_publisher != null, "EventBus e publisher criados pela experiência")
	t.check(slice.shadow_events.published_count() == 1, "boot publica exatamente 1 evento")
	t.check(slice.shadow_state.consumed_event_ids == ["evt-000001"], "16. scenario_entered consumido pelo recorder no boot")
	t.check(slice.shadow_state.game_state.player.scenario_id == "scenario.vardhelm", "scenario_entered -> player.location.scenario_id")
	slice.queue_free()


# 17–26, 28. tipos no fluxo real
func _test_event_types(t, slice: VardhelmVerticalSlice, recorded: RecordedEvents) -> void:
	t.section("B1 Vardhelm — eventos do fluxo real")
	t.check(recorded.matching("dialogue_started", {"dialogue_id": "dialogue.vardhelm.intro"}).size() == 1, "17. dialogue_started {dialogue.vardhelm.intro}")
	t.check(recorded.matching("dialogue_choice_selected", {"dialogue_id": "dialogue.vardhelm.intro", "entry_id": "start", "choice_id": "learn"}).size() == 1, "18. dialogue_choice_selected {intro, start, learn}")
	t.check(recorded.matching("dialogue_completed", {"dialogue_id": "dialogue.vardhelm.intro"}).size() == 1, "19. dialogue_completed")
	t.check(recorded.matching("quest_started", {"quest_id": "quest.vardhelm.first_echo"}).size() == 1, "20. quest_started {quest.vardhelm.first_echo}")
	t.check(recorded.matching("quest_progressed", {"quest_id": "quest.vardhelm.first_echo", "objective_id": "observe"}).size() == 1, "21. quest_progressed {first_echo, observe}")
	t.check(recorded.matching("quest_completed", {"quest_id": "quest.vardhelm.first_echo"}).size() == 1, "22. quest_completed")
	t.check(recorded.matching("echo_triggered", {"echo_id": "echo.vardhelm.first"}).size() == 1, "23. echo_triggered {echo.vardhelm.first}")
	t.check(recorded.matching("memory_recovered", {"memory_id": "memory.vardhelm.first_echo", "source_type": "echo", "source_id": "echo.vardhelm.first"}).size() == 1, "24. memory_recovered (Eco)")
	t.check(recorded.matching("memory_recovered", {"memory_id": "memory.vardhelm.maintenance_board", "source_type": "observation", "source_id": "observation.vardhelm.maintenance_board"}).size() == 1, "24. memory_recovered (fragmento de observação)")
	t.check(recorded.matching("consequence_applied", {"consequence_id": "consequence.vardhelm.first_echo_complete", "source_type": "echo", "source_id": "echo.vardhelm.first"}).size() == 1, "25. consequence_applied (first_echo_complete, fonte Eco)")
	t.check(recorded.matching("consequence_applied", {"consequence_id": "consequence.vardhelm.heard_echo", "source_type": "dialogue", "source_id": "dialogue.vardhelm.intro"}).size() == 1, "25. consequence_applied (heard_echo, fonte diálogo)")
	t.check(recorded.matching("observation_discovered", {"observation_id": "observation.vardhelm.maintenance_board", "memory_id": "memory.vardhelm.maintenance_board"}).size() == 1, "26. observation_discovered {observation, memory}")
	t.check(recorded.matching("world_state_changed", {"state_id": "envstate.vardhelm.echo_awakened"}).size() == 1, "28. world_state_changed {echo_awakened} (mudança real do AmbientLife)")
	t.check(recorded.count("npc_state_changed") == 0, "Durn não muda de estado no fluxo: nenhum npc_state_changed")
	t.check(recorded.count("scenario_completed") == 0 and recorded.count("game_saved") == 0 and recorded.count("game_loaded") == 0, "tipos preparados/reservados não são publicados pelo gameplay")
	for event in recorded.events:
		var text := JSON.stringify(event.to_dict())
		t.check(not text.contains("Durn") and not text.contains("Um instante") and not text.contains("ECO DE"), "%s sem texto de UI" % event.event_id)
	t.check(slice.shadow_publisher.diagnostics.is_empty() and slice.shadow_events.rejected.is_empty(), "nenhum ID fora do catálogo e nenhum evento rejeitado")


# 30. ordem determinística
func _test_order(t, _slice: VardhelmVerticalSlice, recorded: RecordedEvents, echo_events: Array[String]) -> void:
	t.section("B1 Vardhelm — ordem causal")
	var full: Array = ["scenario_entered"]
	full.append_array(Array(recorded.types()))
	t.check(JSON.stringify(full) == JSON.stringify(EXPECTED_FLOW), "sequência completa igual à ordem real documentada")
	t.check(JSON.stringify(echo_events) == JSON.stringify(EXPECTED_FIRST_ECHO), "30. Primeiro Eco: consequence → world_state → quest_progressed → quest_completed → echo_triggered → memory_recovered")
	var ticks_ok := true
	for index in range(1, recorded.events.size()):
		if recorded.events[index].tick != recorded.events[index - 1].tick + 1:
			ticks_ok = false
	t.check(ticks_ok, "ticks consecutivos (sem lacunas nem reordenação)")
	print("   info sequência real: ", " → ".join(PackedStringArray(full)))


# duplicação
func _test_no_duplicates(t, slice: VardhelmVerticalSlice, recorded: RecordedEvents) -> void:
	t.section("B1 Vardhelm — duplicação")
	t.check(recorded.count("echo_triggered") == 1, "Primeiro Eco gera um único echo_triggered")
	t.check(recorded.matching("memory_recovered", {"memory_id": "memory.vardhelm.first_echo"}).size() == 1, "Primeiro Eco gera um único memory_recovered")
	t.check(recorded.matching("consequence_applied", {"consequence_id": "consequence.vardhelm.first_echo_complete"}).size() == 1, "Primeiro Eco gera um único consequence_applied")
	var before := recorded.count()
	t.check(not slice.echo.interact(slice.player), "Eco já resolvido não aceita nova interação (runtime)")
	var observation := slice.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation
	observation.interact(slice.player)
	t.check(recorded.count() == before, "reexaminar observação e tocar no Eco resolvido não geram eventos novos")
	t.check(slice.shadow_publisher.suppressed_repeats.size() == 1, "reexame registrado como repetição suprimida (não é fato novo)")


# 31. GameState recebe os mesmos eventos
func _test_game_state_receives(t, slice: VardhelmVerticalSlice) -> void:
	t.section("B1 Vardhelm — GameState consome os eventos")
	var recorder := slice.shadow_state
	t.check(recorder.consumed_event_ids.size() == slice.shadow_events.published_count(), "31. recorder consumiu todos os eventos publicados")
	var expected_ids: Array[String] = []
	for index in slice.shadow_events.published_count():
		expected_ids.append("evt-%06d" % (index + 1))
	t.check(recorder.consumed_event_ids == expected_ids, "na mesma ordem de publicação")
	var state := recorder.game_state
	t.check(state.memory.has_memory("memory.vardhelm.first_echo") and state.memory.is_fragment("memory.vardhelm.maintenance_board"), "memórias aplicadas a partir dos eventos")
	t.check(state.world.consequences.size() == 2 and state.quests.get_status("quest.vardhelm.first_echo") == "completed", "consequências e quest aplicadas a partir dos eventos")
	t.check(recorder.diagnostics.is_empty(), "nenhum evento inaplicável")


# 32. projetor não publica eventos
func _test_projector_publishes_nothing(t, slice: VardhelmVerticalSlice) -> void:
	t.section("B1 Vardhelm — projetor")
	var before := slice.shadow_events.published_count()
	var consumed := slice.shadow_state.consumed_event_ids.size()
	var comparison := slice.shadow_state.compare_with_runtime(slice.narrative_controller.world_state, slice.quest_controller.states)
	GameStateProjector.project(slice.narrative_controller.world_state, slice.quest_controller.states, slice.player)
	t.check(slice.shadow_events.published_count() == before, "32. projetor/comparação não publicam eventos")
	t.check(slice.shadow_state.consumed_event_ids.size() == consumed, "recorder não recebe nada do projetor")
	t.check(comparison.differences.is_empty() and not comparison.has_unexpected_ids() and comparison.missing_in_left.is_empty(), "sombra (via eventos) × projeção: 0 diferenças, 0 IDs inesperados")
	var only_dialogue := true
	for path in comparison.missing_in_right:
		if not path.begins_with("dialogue."):
			only_dialogue = false
	t.check(only_dialogue, "única divergência continua sendo o DialogueState (invisível ao projetor)")
	print("   info ", comparison.summary())


# 35. EventBus não controla gameplay
func _test_bus_does_not_control_gameplay(t, slice: VardhelmVerticalSlice) -> void:
	t.section("B1 Vardhelm — EventBus não controla gameplay")
	var before := _runtime_json(slice)
	var bus := slice.shadow_events
	bus.publish(GameEventCatalog.QUEST_STARTED, {"quest_id": "quest.vardhelm.first_echo"}, "test")
	bus.publish(GameEventCatalog.CONSEQUENCE_APPLIED, {"consequence_id": "consequence.vardhelm.heard_echo"}, "test")
	bus.publish(GameEventCatalog.NPC_STATE_CHANGED, {"npc_id": "npc.vardhelm.durn", "interaction_enabled": false}, "test")
	bus.publish(GameEventCatalog.SCENARIO_COMPLETED, {"scenario_id": "scenario.vardhelm"}, "test")
	t.check(_runtime_json(slice) == before, "35. eventos sintéticos no bus não alteram WorldState, QuestState, Eco nem UI")
	t.check(slice.npc.interaction_enabled, "npc_state_changed não altera o NPC real")


# 33. SaveService não recebe integração
func _test_save_service_not_integrated(t, slice: VardhelmVerticalSlice) -> void:
	t.section("B1 — SaveService fora dos eventos")
	var file := FileAccess.open("res://scripts/save/save_service.gd", FileAccess.READ)
	var text := file.get_as_text()
	t.check(not text.contains("GameEvent") and not text.contains("publish") and not text.contains("Event"), "33. SaveService não referencia eventos")
	for path in ["res://scripts/events/gameplay_event_publisher.gd", "res://scripts/events/event_bus.gd", "res://scripts/events/game_event.gd", "res://scripts/state/game_state_shadow_recorder.gd"]:
		var source := FileAccess.open(path, FileAccess.READ).get_as_text()
		var code_lines: Array[String] = []
		for line in source.split("\n"):
			code_lines.append(line.split("#")[0])
		var code := "\n".join(code_lines)
		t.check(not code.contains("SaveService") and not code.contains("save_game") and not code.contains("load_game"), "%s não integra o SaveService" % path.get_file())
	t.check(slice.shadow_events.rejected.size() == 0, "nenhum game_saved/game_loaded publicado")


# 27, 29. npc_state_changed e scenario_completed
func _test_npc_and_scenario_completed(t, slice: VardhelmVerticalSlice) -> void:
	t.section("B1 Vardhelm — NPC e encerramento preparado")
	var recorded := RecordedEvents.new()
	recorded.attach(slice.shadow_events)
	slice.shadow_publisher.poll()
	t.check(recorded.count() == 0, "poll sem mudança real não publica nada")
	slice.npc.set_interaction_enabled(false)
	slice.shadow_publisher.poll()
	t.check(recorded.matching("npc_state_changed", {"npc_id": "npc.vardhelm.durn", "interaction_enabled": false}).size() == 1, "27. npc_state_changed só na mudança real de Durn")
	slice.shadow_publisher.poll()
	t.check(recorded.count("npc_state_changed") == 1, "sem mudança nova: nenhum evento extra")
	t.check(slice.shadow_state.game_state.npcs.to_dict() == {"npc.vardhelm.durn": {"interaction_enabled": false}}, "recorder aplica npc_state_changed")
	slice.npc.set_interaction_enabled(true)
	slice.shadow_publisher.poll()
	t.check(slice.shadow_state.game_state.npcs.to_dict().is_empty(), "retorno ao padrão também é evento e limpa o registro")
	slice.shadow_publisher.publish_scenario_completed("scenario.vardhelm")
	t.check(recorded.matching("scenario_completed", {"scenario_id": "scenario.vardhelm"}).size() == 1, "29. scenario_completed publicável (preparado, sem encerramento no gameplay)")
	t.check(slice.shadow_state.diagnostics.is_empty(), "recorder aceita scenario_completed sem alterar o GameState")


# 30. determinismo entre execuções
func _test_determinism(t) -> void:
	t.section("B1 Vardhelm — determinismo")
	var first := _run_flow(t)
	var second := _run_flow(t)
	var a: RecordedEvents = first["recorded"]
	var b: RecordedEvents = second["recorded"]
	t.check(t.same_json(a.to_dicts(), b.to_dicts()), "duas execuções do fluxo produzem eventos idênticos (tipos, ordem, IDs, ticks, payloads)")
	(first["slice"] as Node).queue_free()
	(second["slice"] as Node).queue_free()
