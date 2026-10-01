extends RefCounted

## Testes do modo sombra (Bloco A3) no caminho por eventos do Bloco B1:
##   controladores reais (fora da árvore) -> GameplayEventPublisher -> GameEventBus
##   -> GameStateShadowRecorder -> GameState
## e do GameStateComparator. Sem a cena de Vardhelm.

const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const NPC_SCENE_PATH := "res://scenes/npc/npc.tscn"

const NO_SAVE_TOKENS := ["SaveService", "save_game", "load_game", "user://", "FileAccess"]
const SHADOW_SCRIPT_PATHS := [
	"res://scripts/state/game_state_shadow_recorder.gd",
	"res://scripts/state/game_state_comparator.gd",
	"res://scripts/state/game_state_comparison.gd",
	"res://scripts/state/game_state.gd",
	"res://scripts/state/game_player_state.gd",
	"res://scripts/state/game_world_state.gd",
	"res://scripts/state/game_quest_state.gd",
	"res://scripts/state/game_dialogue_state.gd",
	"res://scripts/state/game_memory_state.gd",
	"res://scripts/state/game_npc_state.gd",
	"res://scripts/state/game_state_serde.gd",
]


## Monta bus + recorder inscrito + publisher (mesma montagem do slice).
func _rig() -> Dictionary:
	var bus := GameEventBus.new()
	var recorder := GameStateShadowRecorder.new()
	recorder.attach(bus)
	var publisher := GameplayEventPublisher.new(bus)
	return {"bus": bus, "recorder": recorder, "publisher": publisher}


func run(t) -> void:
	_test_initial_state(t)
	_test_consequence_goes_to_consequences(t)
	_test_first_echo(t)
	_test_observation_and_fragment(t)
	_test_quests_with_real_controller(t)
	_test_dialogue_with_real_controller(t)
	_test_durn(t)
	_test_unknown_ids(t)
	_test_serialization(t)
	_test_no_save_or_tree_dependency(t)
	_test_comparator(t)


# 19. estado inicial determinístico · 2. scenario
func _test_initial_state(t) -> void:
	t.section("A3 recorder — estado inicial")
	var a := _rig()
	var b := _rig()
	a["publisher"].publish_scenario_entered()
	b["publisher"].publish_scenario_entered()
	var recorder: GameStateShadowRecorder = a["recorder"]
	t.check(recorder.game_state.state_version == 1, "state_version = 1")
	t.check(recorder.game_state.player.scenario_id == "scenario.vardhelm", "scenario.vardhelm registrado (scenario_entered)")
	t.check(t.same_json(recorder.snapshot(), b["recorder"].snapshot()), "dois rigs iniciam com estado idêntico (determinístico)")
	var initial := recorder.snapshot()
	t.check(initial["world"]["flags"].is_empty() and initial["quests"].is_empty() and initial["memory"]["memories"].is_empty(), "estado inicial vazio além da localização")
	t.check(recorder.diagnostics.is_empty(), "sem diagnósticos no início")


# 9 e 10. first_echo_complete -> consequences, nunca memories
func _test_consequence_goes_to_consequences(t) -> void:
	t.section("A3 recorder — consequência")
	var rig := _rig()
	var narrative := NarrativeController.new()
	rig["publisher"].observe_narrative(narrative)
	narrative.apply_consequence("vardhelm_first_echo_complete")
	var state: GameState = rig["recorder"].game_state
	t.check(state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "first_echo_complete em world.consequences")
	t.check(state.world.get_consequence("consequence.vardhelm.first_echo_complete").get("source_id") == "echo.vardhelm.first", "fonte = Eco")
	t.check(state.memory.memories.is_empty(), "first_echo_complete NÃO vai para memory.memories")
	t.check(state.world.has_flag("vardhelm_first_echo_complete"), "flag legada espelhada (compatibilidade)")
	t.check(narrative.world_state.memories.has("vardhelm_first_echo_complete"), "runtime segue com o próprio comportamento (fonte de verdade)")
	narrative.free()


# 7 e 8. Primeiro Eco registra echo e memory
func _test_first_echo(t) -> void:
	t.section("A3 recorder — Primeiro Eco")
	var rig := _rig()
	var echo := EchoMemoryInteractable.new()
	rig["publisher"].observe_echo(echo)
	echo.memory_revealed.emit(echo.memory_id)
	var state: GameState = rig["recorder"].game_state
	t.check(state.memory.is_echo_resolved("echo.vardhelm.first"), "echo.vardhelm.first = resolved")
	t.check(state.memory.memories.get("memory.vardhelm.first_echo", {}) == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "memory.vardhelm.first_echo registrada com origem echo")
	t.check(state.world.consequences.is_empty(), "registrar a memória do Eco não aplica consequência")
	echo.free()


# 11, 12 e 13. observação, fragmento, memória sem consequência
func _test_observation_and_fragment(t) -> void:
	t.section("A3 recorder — observação e fragmento")
	var rig := _rig()
	var observation := EnvironmentalObservation.new()
	observation.observation_id = "tool_rack"
	observation.memory_id = "vardhelm_memory_tool_rack"
	rig["publisher"].observe_observation(observation)
	var actor := Node3D.new()
	observation.interact(actor)
	var state: GameState = rig["recorder"].game_state
	t.check(state.world.is_observation_discovered("observation.vardhelm.tool_rack"), "observação em world.observations")
	t.check(state.world.has_flag("observation_tool_rack_seen"), "flag legada de observação espelhada")
	t.check(state.memory.memories.get("memory.vardhelm.tool_rack", {}) == {"source_type": "observation", "source_id": "observation.vardhelm.tool_rack"}, "fragmento de memória com source_type = observation")
	t.check(state.memory.is_fragment("memory.vardhelm.tool_rack"), "é fragmento")
	t.check(state.world.consequences.is_empty(), "memória/observação NÃO cria consequência")
	observation.interact(actor)
	t.check(state.memory.memories.size() == 1, "segunda interação não duplica o fragmento")
	actor.free()
	observation.free()


# 5 e 6. quest iniciada/concluída pelo QuestController real
func _test_quests_with_real_controller(t) -> void:
	t.section("A3 recorder — quests (QuestController real)")
	var rig := _rig()
	var recorder: GameStateShadowRecorder = rig["recorder"]
	var quests := QuestController.new()
	rig["publisher"].observe_quests(quests)
	quests.start_quest("vardhelm_first_echo")
	t.check(recorder.game_state.quests.get_status("quest.vardhelm.first_echo") == "active", "quest iniciada -> active")
	quests.complete_objective("vardhelm_first_echo", "observe")
	quests.complete_quest("vardhelm_first_echo")
	t.check(recorder.game_state.quests.get_status("quest.vardhelm.first_echo") == "completed", "quest concluída -> completed")
	t.check(recorder.game_state.quests.is_objective_complete("quest.vardhelm.first_echo", "observe"), "objetivo registrado")
	t.check(recorder.game_state.world.consequences.is_empty(), "conclusão da quest NÃO aplica consequência (decisão #5)")
	t.check(quests.states.is_completed("vardhelm_first_echo"), "runtime continua sendo a fonte (QuestState intacto)")
	quests.free()


# 3 e 4. escolha (última) e diálogo concluído pelo DialogueController real
func _test_dialogue_with_real_controller(t) -> void:
	t.section("A3 recorder — diálogo (DialogueController real)")
	var data := JsonDataLoader.load_dialogue(DIALOGUE_PATH)
	t.check(data != null, "diálogo real de Vardhelm carregado")
	if data == null:
		return
	var rig := _rig()
	var recorder: GameStateShadowRecorder = rig["recorder"]
	var publisher: GameplayEventPublisher = rig["publisher"]
	var controller := DialogueController.new()
	publisher.observe_dialogue(controller)

	controller.start_dialogue(data, "start")
	# Mesma ordem do jogo: a escolha é lida antes de o slice avançar a sessão.
	publisher.handle_choice_submitted("learn")
	controller.select_choice("learn")
	t.check(recorder.game_state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "learn", "escolha registrada em choices[intro][start]")
	t.check(not recorder.game_state.dialogue.is_completed("dialogue.vardhelm.intro"), "ainda não concluído no meio do diálogo")
	while controller.is_active():
		if not controller.advance():
			break
	t.check(recorder.game_state.dialogue.is_completed("dialogue.vardhelm.intro"), "diálogo concluído -> completed")

	controller.start_dialogue(data, "start")
	publisher.handle_choice_submitted("leave")
	controller.select_choice("leave")
	t.check(recorder.game_state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "leave", "diálogo repetido: persiste a ÚLTIMA escolha")
	t.check(recorder.game_state.dialogue.to_dict()["choices"]["dialogue.vardhelm.intro"].size() == 1, "uma escolha por ponto de decisão (sem histórico)")
	publisher.handle_choice_submitted("nao_existe")
	t.check(recorder.game_state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "leave", "escolha inexistente é ignorada")
	controller.free()


# 14. Durn usa npc.vardhelm.durn
func _test_durn(t) -> void:
	t.section("A3 recorder — Durn")
	var packed := load(NPC_SCENE_PATH) as PackedScene
	var npc := packed.instantiate() as NPCController
	npc.npc_id = "vardhelm.durn"
	var rig := _rig()
	var recorder: GameStateShadowRecorder = rig["recorder"]
	var publisher: GameplayEventPublisher = rig["publisher"]
	publisher.observe_npc(npc)
	publisher.poll()
	t.check(recorder.game_state.npcs.to_dict().is_empty(), "Durn no padrão: nenhum registro")
	npc.set_interaction_enabled(false)
	publisher.poll()
	t.check(recorder.game_state.npcs.to_dict() == {"npc.vardhelm.durn": {"interaction_enabled": false}}, "diferença do padrão registrada como npc.vardhelm.durn")
	npc.set_interaction_enabled(true)
	publisher.poll()
	t.check(recorder.game_state.npcs.to_dict().is_empty(), "volta ao padrão remove o registro")
	t.check(publisher.diagnostics.is_empty() and recorder.diagnostics.is_empty(), "vardhelm.durn reconhecido pelo catálogo")
	npc.free()


func _test_unknown_ids(t) -> void:
	t.section("A3 recorder — IDs fora do catálogo")
	var rig := _rig()
	var recorder: GameStateShadowRecorder = rig["recorder"]
	var bus: GameEventBus = rig["bus"]
	var publisher: GameplayEventPublisher = rig["publisher"]
	var quests := QuestController.new()
	publisher.observe_quests(quests)
	quests.start_quest("quest_ghost")
	t.check(bus.published_count() == 0, "ID de runtime fora do catálogo: publisher não publica")
	t.check(publisher.diagnostics.size() == 1, "publisher registra diagnóstico")
	bus.publish(GameEventCatalog.CONSEQUENCE_APPLIED, {"consequence_id": "mystery_consequence"}, "test")
	bus.publish(GameEventCatalog.OBSERVATION_DISCOVERED, {"observation_id": "unknown_spot"}, "test")
	var state := recorder.game_state
	t.check(state.world.consequences.is_empty() and state.quests.quests.is_empty() and state.world.observations.is_empty(), "IDs não canônicos não entram nas seções canônicas")
	t.check(recorder.diagnostics.size() == 2, "recorder registra diagnóstico por evento não aplicável")
	quests.free()


# 20. serializado e reconstruído
func _test_serialization(t) -> void:
	t.section("A3 recorder — serialização")
	var rig := _rig()
	var bus: GameEventBus = rig["bus"]
	var recorder: GameStateShadowRecorder = rig["recorder"]
	bus.publish(GameEventCatalog.CONSEQUENCE_APPLIED, {"consequence_id": "consequence.vardhelm.heard_echo", "source_type": "dialogue", "source_id": "dialogue.vardhelm.intro"}, "test")
	bus.publish(GameEventCatalog.QUEST_STARTED, {"quest_id": "quest.vardhelm.first_echo"}, "test")
	bus.publish(GameEventCatalog.DIALOGUE_CHOICE_SELECTED, {"dialogue_id": "dialogue.vardhelm.intro", "entry_id": "start", "choice_id": "learn"}, "test")
	bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first"}, "test")
	bus.publish(GameEventCatalog.MEMORY_RECOVERED, {"memory_id": "memory.vardhelm.first_echo", "source_type": "echo", "source_id": "echo.vardhelm.first"}, "test")
	var data := recorder.snapshot()
	var parsed: Dictionary = t.json_roundtrip(data)
	t.check(GameState.validate_dict(parsed).is_empty(), "snapshot sombra é um GameState válido")
	t.check(t.same_json(GameState.from_dict(parsed).to_dict(), data), "reconstruído a partir do Dictionary sem perda")


# 15 e 16. sem SaveService e sem SceneTree
func _test_no_save_or_tree_dependency(t) -> void:
	t.section("A3 — sem dependência de SaveService/SceneTree")
	var rig := _rig()
	var state_object: Variant = rig["recorder"].game_state
	var recorder_object: Variant = rig["recorder"]
	t.check(state_object is RefCounted and not (state_object is Node), "GameState é RefCounted, não Node")
	t.check(recorder_object is RefCounted and not (recorder_object is Node), "recorder é objeto de runtime, não Node/Autoload")
	for path in SHADOW_SCRIPT_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			t.check(false, "%s legível" % path)
			continue
		var hits: Array[String] = []
		for line in file.get_as_text().split("\n"):
			var code := line.split("#")[0]
			for token in NO_SAVE_TOKENS:
				if code.contains(token):
					hits.append(token)
			if not path.ends_with("shadow_recorder.gd") and (code.contains("SceneTree") or code.contains("get_tree")):
				hits.append("SceneTree")
		t.check(hits.is_empty(), "%s sem SaveService/arquivo/SceneTree %s" % [path.get_file(), str(hits) if not hits.is_empty() else ""])


# 18. comparação detecta divergências
func _test_comparator(t) -> void:
	t.section("A3 comparador")
	var left := GameState.new()
	var right := GameState.new()
	var same := GameStateComparator.compare(left, right, "shadow", "projection")
	t.check(same.is_equal() and not same.has_unexpected_ids(), "estados iguais: nenhuma divergência")
	t.check(same.matching.size() > 0, "caminhos iguais listados")

	left.world.apply_consequence("consequence.vardhelm.heard_echo", "dialogue", "dialogue.vardhelm.intro")
	right.world.apply_consequence("consequence.vardhelm.heard_echo", "echo", "echo.vardhelm.first")
	left.dialogue.mark_completed("dialogue.vardhelm.intro")
	right.quests.start_quest("quest.vardhelm.first_echo")
	right.memory.register_memory("vardhelm_memory_tool_rack", "observation", "tool_rack")
	right.player.position = Vector3(1, 0, 0)
	var diff := GameStateComparator.compare(left, right, "shadow", "projection")
	t.check(not diff.is_equal(), "estados diferentes detectados")
	t.check(diff.divergent_paths("world.consequences.consequence.vardhelm.heard_echo.source").size() == 2, "diferença de valor (fonte da consequência)")
	t.check(diff.missing_in_right.has("dialogue.completed.dialogue.vardhelm.intro"), "campo ausente no lado direito")
	t.check(diff.missing_in_left.has("quests.quest.vardhelm.first_echo"), "campo ausente no lado esquerdo")
	t.check(diff.divergent_paths("player.location.position").size() == 1, "diferença de posição")
	var unexpected: Array = []
	for item in diff.unexpected_ids:
		unexpected.append(item["id"])
	t.check(unexpected.has("vardhelm_memory_tool_rack") and unexpected.has("tool_rack"), "IDs inesperados (aliases legados no estado canônico) detectados")
	t.check(right.memory.has_memory("vardhelm_memory_tool_rack") and left.world.is_consequence_applied("consequence.vardhelm.heard_echo"), "comparação não altera nenhum dos lados")
