extends RefCounted

## Save V2 (Bloco C1) — serviço, round trips, corrupção e atomicidade.
## Isolado em user://save_v2_tests/ (removido ao final). Não usa o arquivo
## do SaveService atual nem o caminho padrão do Save V2.

const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const SERVICE_FORBIDDEN_TOKENS := [
	"SaveService", "save_game(", "load_game(", "PlayerController", "Player", "DialogueBox",
	"DialogueController", "QuestController", "NarrativeController", "AmbientLife", "Input",
	"Control", "Node3D", "GameEventBus", "publish",
]
const SAVE_V2_SCRIPTS := [
	"res://scripts/save_v2/save_v2_service.gd",
	"res://scripts/save_v2/save_v2_envelope.gd",
	"res://scripts/save_v2/save_v2_serializer.gd",
	"res://scripts/save_v2/save_v2_checksum.gd",
	"res://scripts/save_v2/save_v2_validator.gd",
	"res://scripts/save_v2/save_v2_errors.gd",
	"res://scripts/save_v2/save_v2_result.gd",
]

var _counter := 0


func _service(name: String) -> SaveV2Service:
	_counter += 1
	var service := SaveV2Service.new("%s/%s_%d.json" % [TEST_DIR, name, _counter])
	var fixed_time := [1000]
	service.clock = func() -> int:
		fixed_time[0] += 10
		return fixed_time[0]
	return service


func _diff_text(comparison: GameStateComparison) -> String:
	if comparison.is_equal():
		return ""
	var lines: Array[String] = []
	for difference in comparison.differences:
		lines.append("%s: original=%s carregado=%s" % [difference["path"], str(difference["left"]), str(difference["right"])])
	for path in comparison.missing_in_right:
		lines.append("%s: ausente no carregado" % path)
	for path in comparison.missing_in_left:
		lines.append("%s: só no carregado" % path)
	return " | " + "; ".join(lines)


## Round trip completo: GameState A -> arquivo -> GameState B; compara A e B.
func _roundtrip(t, state: GameState, label: String) -> GameState:
	var service := _service("rt")
	var saved := service.save_game_state(state)
	t.check(saved.ok, "%s: save (%s)" % [label, saved.describe()])
	var loaded := service.load_game_state()
	t.check(loaded.ok, "%s: load (%s)" % [label, loaded.describe()])
	if not loaded.ok:
		return null
	var comparison := GameStateComparator.compare(state, loaded.state, "original", "carregado")
	t.check(comparison.is_equal() and not comparison.has_unexpected_ids(), "%s: original == carregado%s" % [label, _diff_text(comparison)])
	t.check(t.same_json(state.to_dict(), loaded.state.to_dict()), "%s: to_dict idêntico" % label)
	t.check(loaded.state != state, "%s: estado carregado é outra instância" % label)
	return loaded.state


## Estado construído pelo caminho real de eventos (publisher -> bus -> recorder).
func _rig() -> Dictionary:
	var bus := GameEventBus.new()
	var recorder := GameStateShadowRecorder.new()
	recorder.attach(bus)
	return {"bus": bus, "recorder": recorder, "publisher": GameplayEventPublisher.new(bus)}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var old_save_existed := FileAccess.file_exists(OLD_SAVE_PATH)
	_test_roundtrips(t)
	_test_player_location(t)
	_test_memory_consequence_dialogue(t)
	_test_corruption(t)
	_test_service_behaviour(t)
	_test_isolation(t, old_save_existed)
	_cleanup()


func _test_roundtrips(t) -> void:
	t.section("C1 — round trips")
	# 1 e 13. estado inicial / dados vazios
	_roundtrip(t, GameState.new(), "1. estado inicial")
	var empty := GameState.new()
	empty.player.scenario_id = "scenario.vardhelm"
	_roundtrip(t, empty, "13. dados vazios (todas as seções vazias)")

	# 2–8 pelo caminho real de eventos
	var rig := _rig()
	var bus: GameEventBus = rig["bus"]
	var recorder: GameStateShadowRecorder = rig["recorder"]
	var publisher: GameplayEventPublisher = rig["publisher"]
	var controller := DialogueController.new()
	var quests := QuestController.new()
	var narrative := NarrativeController.new()
	var echo := EchoMemoryInteractable.new()
	var observation := EnvironmentalObservation.new()
	observation.observation_id = "maintenance_board"
	observation.memory_id = "vardhelm_memory_maintenance_board"
	publisher.observe_dialogue(controller)
	publisher.observe_quests(quests)
	publisher.observe_narrative(narrative)
	publisher.observe_echo(echo)
	publisher.observe_observation(observation)
	publisher.publish_scenario_entered()

	controller.start_dialogue(JsonDataLoader.load_dialogue(DIALOGUE_PATH), "start")
	_roundtrip(t, recorder.game_state, "2. após diálogo iniciado")
	publisher.handle_choice_submitted("learn")
	controller.select_choice("learn")
	narrative.apply_consequence("vardhelm_heard_echo")
	_roundtrip(t, recorder.game_state, "3. após escolha")
	while controller.is_active():
		if not controller.advance():
			break
	quests.start_quest("vardhelm_first_echo")
	_roundtrip(t, recorder.game_state, "4. após quest iniciada")
	narrative.apply_consequence("vardhelm_first_echo_complete")
	_roundtrip(t, recorder.game_state, "7. após consequência")
	quests.complete_objective("vardhelm_first_echo", "observe")
	quests.complete_quest("vardhelm_first_echo")
	echo.memory_revealed.emit(echo.memory_id)
	_roundtrip(t, recorder.game_state, "5/6. após Primeiro Eco e sua memória")
	var actor := Node3D.new()
	observation.interact(actor)
	var after_observation := _roundtrip(t, recorder.game_state, "8. após observação")
	t.check(after_observation != null and after_observation.memory.is_fragment("memory.vardhelm.maintenance_board"), "8. fragmento sobrevive ao round trip")
	t.check(bus.published_count() > 0 and recorder.diagnostics.is_empty(), "estados 2–8 vieram de eventos reais do B1")
	for node in [controller, quests, narrative, echo, observation, actor]:
		node.free()

	# 10–12 e NPC
	var rich := GameState.new()
	for flag in ["vardhelm_heard_echo", "vardhelm_first_echo_complete", "observation_maintenance_board_seen", "observation_sealed_panel_seen", "observation_tool_rack_seen", "mystery_flag"]:
		rich.world.set_flag(flag, flag != "mystery_flag")
	rich.world.set_value("counter", 3)
	rich.world.set_value("ratio", 0.1)
	rich.world.set_value("label_key", "world.state.remembered")
	for id in ["maintenance_board", "sealed_panel", "tool_rack"]:
		rich.world.discover_observation("observation.vardhelm.%s" % id)
		rich.memory.register_memory("memory.vardhelm.%s" % id, "observation", "observation.vardhelm.%s" % id)
	rich.memory.resolve_echo("echo.vardhelm.first")
	rich.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	rich.npcs.set_interaction_enabled("npc.vardhelm.durn", false)
	var loaded := _roundtrip(t, rich, "10–12. múltiplos flags, memórias e observações")
	if loaded != null:
		t.check(loaded.world.flags.size() == 6 and loaded.world.flags["mystery_flag"] == false, "10. todos os flags (inclusive false) preservados")
		t.check(loaded.memory.memories.size() == 4, "11. múltiplas memórias preservadas")
		t.check(loaded.world.observations.size() == 3, "12. múltiplas observações preservadas")
		t.check(loaded.world.get_value("counter") == 3.0 and loaded.world.get_value("ratio") == rich.world.get_value("ratio"), "números preservados")
		t.check(typeof(loaded.world.get_value("label_key")) == TYPE_STRING, "strings preservadas")
		t.check(not loaded.npcs.is_interaction_enabled("npc.vardhelm.durn"), "estado de NPC preservado")


# 9. posição/rotação
func _test_player_location(t) -> void:
	t.section("C1 — posição e rotação")
	var state := GameState.new()
	state.player.position = Vector3(-8.123456, 0.25, 5.987654)
	state.player.rotation = Vector3(0.0, -2.35619, 0.1)
	var loaded := _roundtrip(t, state, "9. posição/rotação")
	if loaded == null:
		return
	t.check(loaded.player.scenario_id == "scenario.vardhelm", "scenario_id preservado")
	t.check(loaded.player.position == state.player.position, "posição exata (Vector3 == Vector3)")
	t.check(loaded.player.rotation == state.player.rotation, "rotação exata (Vector3 == Vector3)")
	# Componentes que o parser JSON do Godot altera no último bit do double.
	var odd := GameState.new()
	odd.player.position = Vector3(1e-3, 0.0010000000474974513, -1e-5)
	odd.player.rotation = Vector3(0.1, -3.14159, 1e-3)
	odd.world.set_value("ratio", 0.0010000000474974513)
	var odd_loaded := _roundtrip(t, odd, "9b. floats afetados pelo parser JSON")
	if odd_loaded != null:
		t.check(odd_loaded.player.position == odd.player.position and odd_loaded.player.rotation == odd.player.rotation, "Vector3 exato mesmo com floats afetados pelo parser")
		t.check(is_equal_approx(float(odd_loaded.world.get_value("ratio")), float(odd.world.get_value("ratio"))), "double fora de Vector3: igual dentro da precisão do parser JSON")


func _test_memory_consequence_dialogue(t) -> void:
	t.section("C1 — memória, consequência e diálogo")
	var state := GameState.new()
	state.world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first")
	state.memory.resolve_echo("echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.tool_rack", "observation", "observation.vardhelm.tool_rack")
	state.dialogue.mark_completed("dialogue.vardhelm.intro")
	state.dialogue.record_choice("dialogue.vardhelm.intro", "start", "learn")
	state.dialogue.record_choice("dialogue.vardhelm.intro", "start", "leave")
	var loaded := _roundtrip(t, state, "memória/consequência/diálogo")
	if loaded == null:
		return
	t.check(loaded.memory.memories["memory.vardhelm.first_echo"] == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "memory.vardhelm.first_echo preservada com origem echo")
	t.check(loaded.memory.is_fragment("memory.vardhelm.tool_rack") and not loaded.memory.is_fragment("memory.vardhelm.first_echo"), "fragmento e memória do Eco continuam separados (sem composição)")
	t.check(loaded.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "first_echo_complete em world.consequences")
	t.check(not loaded.memory.has_memory("consequence.vardhelm.first_echo_complete") and not JSON.stringify(loaded.memory.to_dict()).contains("consequence"), "first_echo_complete NÃO aparece em memory.memories")
	t.check(loaded.world.get_consequence("consequence.vardhelm.first_echo_complete") == {"applied": true, "source_type": "echo", "source_id": "echo.vardhelm.first"}, "fonte da consequência preservada")
	t.check(loaded.dialogue.is_completed("dialogue.vardhelm.intro"), "dialogue.completed preservado")
	t.check(loaded.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "leave", "dialogue.choices preservado (dialogue_id, entry_id, choice_id = última escolha)")


func _write_raw(service: SaveV2Service, text: String) -> void:
	var file := FileAccess.open(service.path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Grava o envelope na forma canônica (a mesma que o serviço gera).
func _write_envelope(service: SaveV2Service, envelope: Dictionary) -> void:
	_write_raw(service, SaveV2Serializer.to_file_text(envelope))


func _good_envelope() -> Dictionary:
	var state := GameState.new()
	state.player.position = Vector3(1, 2, 3)
	state.world.set_flag("vardhelm_heard_echo")
	return SaveV2Envelope.create(state.to_dict(), SaveV2Envelope.make_metadata("shadow", 10, 20))


func _resealed(envelope: Dictionary) -> Dictionary:
	var copy := envelope.duplicate(true)
	copy["checksum"] = SaveV2Checksum.compute(copy)
	return copy


func _expect_load(t, service: SaveV2Service, code: String, label: String) -> void:
	var result := service.load_game_state()
	t.check(not result.ok and result.code == code and result.state == null, "%s -> %s (obtido: %s)" % [label, code, result.describe()])


func _test_corruption(t) -> void:
	t.section("C1 — corrupção (sem fallback)")
	var service := _service("corrupt")
	_expect_load(t, service, SaveV2Errors.FILE_NOT_FOUND, "1. arquivo inexistente")
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_write_raw(service, "{ isto não é json")
	_expect_load(t, service, SaveV2Errors.CORRUPTED_DATA, "2. JSON inválido")
	_write_raw(service, "")
	_expect_load(t, service, SaveV2Errors.CORRUPTED_DATA, "2b. arquivo vazio")
	_write_raw(service, "{}")
	_expect_load(t, service, SaveV2Errors.INVALID_ENVELOPE, "3. envelope vazio")
	_write_raw(service, "[1, 2, 3]")
	_expect_load(t, service, SaveV2Errors.INVALID_ENVELOPE, "3b. envelope não Dictionary")
	var good := _good_envelope()
	var e := good.duplicate(true)
	e["format"] = "outro_formato"
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_FORMAT, "4. format errado")
	e = good.duplicate(true)
	e.erase("schema_version")
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_ENVELOPE, "5. schema ausente")
	e = good.duplicate(true)
	e["schema_version"] = 3
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.UNSUPPORTED_SCHEMA, "6. schema futuro")
	e = good.duplicate(true)
	e["metadata"] = {"slot_id": "", "created_at": 1, "updated_at": 2}
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_METADATA, "7. metadata inválido")
	e = good.duplicate(true)
	e.erase("state")
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_STATE, "8. state ausente")
	e = good.duplicate(true)
	e["state"] = "estado"
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_STATE, "9. state inválido")
	e = good.duplicate(true)
	e.erase("checksum")
	_write_envelope(service, e)
	_expect_load(t, service, SaveV2Errors.INVALID_CHECKSUM, "10. checksum ausente")
	e = good.duplicate(true)
	e["checksum"] = "sha256:" + "f".repeat(64)
	_write_envelope(service, e)
	_expect_load(t, service, SaveV2Errors.INVALID_CHECKSUM, "11. checksum incorreto")
	var saved := service.save_game_state(GameState.from_dict(good["state"]))
	t.check(saved.ok, "save íntegro para o teste de adulteração")
	var text := FileAccess.get_file_as_string(service.path)
	_write_raw(service, text.replace("\"vardhelm_heard_echo\":true", "\"vardhelm_heard_echo\":false"))
	_expect_load(t, service, SaveV2Errors.INVALID_CHECKSUM, "12. payload alterado depois do checksum (edição do arquivo)")
	e = good.duplicate(true)
	e["state"]["player"]["location"]["position"] = [1, 2]
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_STATE, "13. Vector3 inválido")
	e = good.duplicate(true)
	e["state"]["quests"] = {"quest.vardhelm.first_echo": {"status": 1, "objectives": {}}}
	_write_envelope(service, _resealed(e))
	_expect_load(t, service, SaveV2Errors.INVALID_STATE, "14. tipo inválido em campo conhecido")
	_write_raw(service, JSON.stringify({"version": 2, "language": "pt-BR", "world": {"flags": {}, "values": {}, "memories": []}, "quests": {}}))
	_expect_load(t, service, SaveV2Errors.INVALID_FORMAT, "save do SaveService antigo não é aceito como Save V2")
	_write_raw(service, JSON.stringify(_good_envelope(), "\t", true, true))
	_expect_load(t, service, SaveV2Errors.INVALID_CHECKSUM, "arquivo íntegro mas reformatado (fora da forma canônica)")
	_write_raw(service, SaveV2Serializer.to_file_text(_good_envelope()) + "\n")
	_expect_load(t, service, SaveV2Errors.INVALID_CHECKSUM, "byte extra no fim do arquivo")


func _test_service_behaviour(t) -> void:
	t.section("C1 — serviço e atomicidade")
	var service := _service("svc")
	t.check(not service.has_save(), "has_save() falso antes de salvar")
	t.check(service.load_game_state().code == SaveV2Errors.FILE_NOT_FOUND, "load sem arquivo -> FILE_NOT_FOUND")
	var first := service.save_game_state(GameState.new(), "slot_a")
	t.check(first.ok and service.has_save(), "save cria o arquivo")
	t.check(not FileAccess.file_exists(service.path + ".tmp") and not FileAccess.file_exists(service.path + ".bak"), "escrita atômica não deixa .tmp/.bak")
	var created_at := int(first.envelope["metadata"]["created_at"])
	var second := service.save_game_state(GameState.new(), "slot_a")
	t.check(second.ok and int(second.envelope["metadata"]["created_at"]) == created_at, "created_at preservado ao sobrescrever")
	t.check(int(second.envelope["metadata"]["updated_at"]) > created_at, "updated_at atualizado")
	t.check(second.envelope["metadata"]["slot_id"] == "slot_a", "slot_id em metadata")
	var bad := GameState.new()
	bad.state_version = 99
	var refused := service.save_game_state(bad)
	t.check(not refused.ok and refused.code == SaveV2Errors.INVALID_STATE, "GameState inválido não é gravado")
	t.check(service.load_game_state().ok, "save anterior intacto após recusa")
	_write_raw(service, "corrompido")
	var replaced := service.save_game_state(GameState.new())
	t.check(replaced.ok and replaced.details.size() == 1 and service.load_game_state().ok, "save sobre arquivo corrompido: substitui e reporta")
	var stale := FileAccess.open(service.path + ".bak", FileAccess.WRITE)
	stale.store_string("resto antigo")
	stale.close()
	t.check(service.save_game_state(GameState.new()).ok and not FileAccess.file_exists(service.path + ".bak"), ".bak antigo é descartado na próxima gravação")
	t.check(service.delete_save() and not service.has_save(), "delete_save() remove o save")
	t.check(not service.delete_save(), "delete_save() sem arquivo retorna false")
	var default_service := SaveV2Service.new()
	t.check(default_service.path == "user://echoes_of_the_soul_save_v2_shadow.json", "caminho padrão próprio do Save V2")
	t.check(default_service.path != OLD_SAVE_PATH, "caminho diferente do save do SaveService")


func _test_isolation(t, old_save_existed: bool) -> void:
	t.section("C1 — isolamento do SaveService antigo")
	t.check(FileAccess.file_exists(OLD_SAVE_PATH) == old_save_existed, "arquivo do SaveService antigo não foi criado nem removido")
	t.check(not FileAccess.file_exists(SaveV2Service.DEFAULT_PATH), "testes não gravam no caminho padrão do Save V2")
	for path in SAVE_V2_SCRIPTS:
		var hits: Array[String] = []
		for line in FileAccess.open(path, FileAccess.READ).get_as_text().split("\n"):
			var code := line.split("#")[0]
			for token in SERVICE_FORBIDDEN_TOKENS:
				if code.contains(token):
					hits.append(token)
		t.check(hits.is_empty(), "%s não conhece SaveService/gameplay/UI/Input/eventos %s" % [path.get_file(), str(hits) if not hits.is_empty() else ""])
	var old_service := FileAccess.open("res://scripts/save/save_service.gd", FileAccess.READ).get_as_text()
	t.check(not old_service.contains("SaveV2") and not old_service.contains("save_v2"), "SaveService não referencia o Save V2")
	var service_object: Variant = SaveV2Service.new()
	t.check(service_object is RefCounted and not (service_object is Node), "SaveV2Service é objeto comum (não Node/Autoload)")


func _cleanup() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)
