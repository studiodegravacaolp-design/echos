extends RefCounted

## Testes do núcleo de eventos estruturados (Bloco B1): GameEvent,
## GameEventCatalog, GameEventBus e RecordedEvents. Itens 1–15 e 34.

const EVENT_SCRIPT_PATHS := [
	"res://scripts/events/game_event.gd",
	"res://scripts/events/event_bus.gd",
	"res://scripts/events/event_catalog.gd",
	"res://scripts/events/recorded_events.gd",
]
## O bus e o evento não conhecem nenhum sistema de gameplay.
const BUS_FORBIDDEN_TOKENS := [
	"DialogueController", "QuestController", "NarrativeController", "SaveService",
	"AmbientLife", "WorldState", "QuestState", "GameState", "Control", "Label", "Node3D",
]


func run(t) -> void:
	_test_event(t)
	_test_catalog(t)
	_test_bus(t)
	_test_immutability(t)
	_test_payload_rules(t)
	_test_fifo_order(t)
	_test_not_autoload(t)


# 1–6. Event
func _test_event(t) -> void:
	t.section("B1 — GameEvent")
	var bus := GameEventBus.new()
	var event := bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first"}, "echo")
	t.check(event != null, "1. evento criado")
	t.check(event.event_id == "evt-000001", "event_id sequencial e determinístico")
	t.check(event.event_type == "echo_triggered", "2. possui tipo genérico (não por entidade)")
	t.check(event.schema_version == 1, "3. possui schema_version")
	t.check(event.source == "echo", "4. possui source")
	t.check(event.payload == {"echo_id": "echo.vardhelm.first"}, "5. possui payload com o ID da entidade como dado")
	t.check(event.tick == 1, "tick = número de sequência (sem relógio do SO)")
	var data := event.to_dict()
	t.check(data.keys().size() == 6 and data["payload"] == {"echo_id": "echo.vardhelm.first"}, "6. convertido para Dictionary")
	t.check(not data.has("timestamp"), "sem timestamp do sistema operacional")
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	t.check(typeof(parsed) == TYPE_DICTIONARY and parsed["event_type"] == "echo_triggered", "Dictionary do evento sobrevive a texto JSON")


func _test_catalog(t) -> void:
	t.section("B1 — GameEventCatalog")
	var expected := [
		"scenario_entered", "dialogue_started", "dialogue_choice_selected", "dialogue_completed",
		"quest_started", "quest_progressed", "quest_completed", "echo_triggered", "memory_recovered",
		"consequence_applied", "observation_discovered", "npc_state_changed", "world_state_changed",
		"scenario_completed", "game_saved", "game_loaded",
	]
	var types := GameEventCatalog.all_types()
	t.check(types.size() == expected.size(), "catálogo tem exatamente os %d tipos do B1" % expected.size())
	for event_type in expected:
		t.check(GameEventCatalog.is_known_type(event_type), "tipo '%s' no catálogo" % event_type)
	for event_type in types:
		t.check(not event_type.contains("vardhelm") and not event_type.contains("."), "tipo '%s' é genérico (sem ID de entidade)" % event_type)
	t.check(not GameEventCatalog.is_reserved("game_saved") and not GameEventCatalog.is_reserved("game_loaded"), "game_saved/game_loaded em uso desde o C2 (publicados só pelo Save V2 sombra)")
	t.check(GameEventCatalog.is_reserved("scenario_completed"), "scenario_completed preparado, sem encerramento real no gameplay")
	t.check(not GameEventCatalog.is_reserved("echo_triggered"), "tipos em uso não são reservados")


# 7–11. Bus
func _test_bus(t) -> void:
	t.section("B1 — GameEventBus")
	var bus := GameEventBus.new()
	var a := RecordedEvents.new()
	var b := RecordedEvents.new()
	a.attach(bus)
	b.attach(bus)
	var event := bus.publish(GameEventCatalog.QUEST_STARTED, {"quest_id": "quest.vardhelm.first_echo"}, "quest")
	t.check(event != null and bus.published_count() == 1, "7. publica")
	t.check(a.count() == 1 and a.events[0] == event, "8. listener recebe o evento")
	t.check(b.count() == 1 and b.events[0] == event, "9. dois listeners recebem o mesmo evento")
	t.check(bus.subscriber_count() == 2, "dois inscritos")
	t.check(not bus.subscribe(a.record), "inscrição duplicada recusada")
	t.check(bus.unsubscribe(a.record), "10. unsubscribe funciona")
	bus.publish(GameEventCatalog.QUEST_COMPLETED, {"quest_id": "quest.vardhelm.first_echo"}, "quest")
	t.check(a.count() == 1, "11. listener não recebe depois do unsubscribe")
	t.check(b.count() == 2, "listener restante continua recebendo")
	var filtered := RecordedEvents.new()
	filtered.attach(bus, [GameEventCatalog.QUEST_COMPLETED])
	bus.publish(GameEventCatalog.QUEST_STARTED, {"quest_id": "quest.vardhelm.first_echo"}, "quest")
	bus.publish(GameEventCatalog.QUEST_COMPLETED, {"quest_id": "quest.vardhelm.first_echo"}, "quest")
	t.check(filtered.types() == ["quest_completed"], "inscrição filtrada por tipo")


# 12. imutabilidade
func _test_immutability(t) -> void:
	t.section("B1 — imutabilidade")
	var bus := GameEventBus.new()
	var mutator := func(event: GameEvent) -> void:
		var payload := event.payload
		payload["memory_id"] = "alterado"
		payload["extra"] = true
	var observer := RecordedEvents.new()
	bus.subscribe(mutator)
	observer.attach(bus)
	var event := bus.publish(GameEventCatalog.MEMORY_RECOVERED, {"memory_id": "memory.vardhelm.first_echo", "source_type": "echo", "source_id": "echo.vardhelm.first"}, "echo")
	t.check(event.payload == {"memory_id": "memory.vardhelm.first_echo", "source_type": "echo", "source_id": "echo.vardhelm.first"}, "12. evento original não é alterado pelo listener")
	t.check(observer.events[0].payload["memory_id"] == "memory.vardhelm.first_echo", "listener seguinte recebe o payload intacto")
	var source := {"echo_id": "echo.vardhelm.first"}
	var event2 := bus.publish(GameEventCatalog.ECHO_TRIGGERED, source, "echo")
	source["echo_id"] = "mudado_depois"
	t.check(event2.payload["echo_id"] == "echo.vardhelm.first", "alterar o Dictionary de origem depois da publicação não afeta o evento")


# 13–15. regras de tipo e payload
func _test_payload_rules(t) -> void:
	t.section("B1 — validação de tipo e payload")
	var bus := GameEventBus.new()
	var recorded := RecordedEvents.new()
	recorded.attach(bus)
	t.check(bus.publish("echo.vardhelm.first_triggered", {"echo_id": "echo.vardhelm.first"}, "echo") == null, "13. tipo inválido/por entidade é rejeitado")
	t.check(bus.publish("", {}, "x") == null, "tipo vazio rejeitado")
	var node := Node.new()
	t.check(bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first", "ref": node}, "echo") == null, "14. payload com Node é rejeitado")
	t.check(bus.publish(GameEventCatalog.WORLD_STATE_CHANGED, {"state_id": node}, "world") == null, "Node no lugar de um ID é rejeitado")
	node.free()
	t.check(bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": Vector3.ONE}, "echo") == null, "Vector3 (não JSON) rejeitado")
	t.check(bus.publish(GameEventCatalog.QUEST_PROGRESSED, {"quest_id": "quest.vardhelm.first_echo"}, "quest") == null, "campo obrigatório ausente rejeitado")
	t.check(bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first", "title": "ECO DE MEMÓRIA"}, "echo") == null, "campo não previsto (ex.: texto de UI) rejeitado")
	t.check(bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": ""}, "echo") == null, "ID vazio rejeitado")
	t.check(bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first"}, "") == null, "source vazio rejeitado")
	t.check(recorded.count() == 0 and bus.published_count() == 0, "nada rejeitado é entregue nem numerado")
	t.check(bus.rejected.size() == 9, "rejeições registradas")
	var ok := bus.publish(GameEventCatalog.NPC_STATE_CHANGED, {"npc_id": "npc.vardhelm.durn", "interaction_enabled": false}, "npc")
	var text := JSON.stringify(ok.to_dict())
	t.check(ok != null and JSON.parse_string(text) is Dictionary, "15. payload serializável em JSON")


func _test_fifo_order(t) -> void:
	t.section("B1 — ordem de entrega (FIFO)")
	var bus := GameEventBus.new()
	var first := RecordedEvents.new()
	var cascade := func(event: GameEvent) -> void:
		if event.event_type == GameEventCatalog.ECHO_TRIGGERED:
			bus.publish(GameEventCatalog.MEMORY_RECOVERED, {"memory_id": "memory.vardhelm.first_echo", "source_type": "echo", "source_id": "echo.vardhelm.first"}, "echo")
	var last := RecordedEvents.new()
	first.attach(bus)
	bus.subscribe(cascade)
	last.attach(bus)
	bus.publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": "echo.vardhelm.first"}, "echo")
	t.check(first.types() == ["echo_triggered", "memory_recovered"], "primeiro listener vê a ordem causal")
	t.check(last.types() == ["echo_triggered", "memory_recovered"], "listener posterior também recebe echo_triggered antes do evento publicado em cascata")


# 34. EventBus não é Autoload
func _test_not_autoload(t) -> void:
	t.section("B1 — EventBus não é Autoload/singleton")
	var bus_object: Variant = GameEventBus.new()
	t.check(bus_object is RefCounted and not (bus_object is Node), "EventBus é RefCounted, não Node")
	t.check(GameEventBus.new() != GameEventBus.new(), "cada experiência cria seu próprio EventBus (sem singleton)")
	t.check(ProjectSettings.get_setting("autoload/GameEventBus", null) == null, "nenhum autoload GameEventBus no projeto")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	t.check(project != null and not project.get_as_text().contains("[autoload]"), "project.godot sem seção [autoload]")
	for path in EVENT_SCRIPT_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		var hits: Array[String] = []
		for line in file.get_as_text().split("\n"):
			var code := line.split("#")[0]
			for token in BUS_FORBIDDEN_TOKENS:
				if code.contains(token):
					hits.append(token)
		t.check(hits.is_empty(), "%s não conhece gameplay/estado/UI %s" % [path.get_file(), str(hits) if not hits.is_empty() else ""])
