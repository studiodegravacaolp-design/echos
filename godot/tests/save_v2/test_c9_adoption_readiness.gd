extends RefCounted

## Bloco C9 — prontidão de adoção (sem a cena): modo de execução, métricas,
## mensagens ao jogador × log técnico, localização, inventário de saves
## (legado × V2) e instrumentação por sandbox.

const OP := preload("res://tests/save_v2/test_save_v2_operational_load.gd")
const TEST_DIR := "user://save_v2_tests"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const TECHNICAL_TOKENS := ["LOAD_FAILURE", "VALIDATION_FAILURE", "POST_RESTORE_MISMATCH", "ROLLBACK_FAILURE", "ROLLBACK_SUCCESS", "APPLY_FAILURE", "RESTORE_REJECTED", "WRITE_FAILURE", "SAVE_REJECTED", "INVALID_CHECKSUM", "V2", "%s"]

var _nodes: Array[Node] = []
var _sandboxes: Array = []


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_render_mode(t)
	_test_metrics(t)
	_test_messages(t)
	_test_localization(t)
	_test_inventory(t)
	_test_instrumentation(t)
	for sandbox in _sandboxes:
		sandbox.discard()
		for next in sandbox.spawned:
			next.discard()
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _path(name: String) -> String:
	return "%s/%s" % [TEST_DIR, name]


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


# 1. configuração renderizada × headless
func _test_render_mode(t) -> void:
	t.section("C9 — modo de execução")
	var info := SaveV2LoadMetrics.rendering_info()
	t.check(SaveV2LoadMetrics.render_mode() == "headless" and info["mode"] == "headless" and info.has("rendering_method") and info.has("adapter"), "runner automatizado identificado como headless (%s)" % str(info))
	var playtest := FileAccess.get_file_as_string("res://tests/save_v2/c9_rendered_playtest.gd")
	t.check(not playtest.is_empty() and playtest.contains("SaveV2LoadMetrics.render_mode()") and playtest.contains("\"rendered\""), "playtest renderizado separa as séries (recusa rotular headless como renderizado)")
	t.check(not FileAccess.get_file_as_string("res://tests/state/state_test_runner.gd").contains("c9_rendered_playtest"), "playtest renderizado fora do runner headless")


# 2. estatística
func _test_metrics(t) -> void:
	t.section("C9 — métricas")
	t.check(SaveV2LoadMetrics.summarize([5.0, 1.0, 3.0]) == {"count": 3, "min": 1.0, "max": 5.0, "mean": 3.0, "median": 3.0}, "ímpar: min/max/média/mediana")
	t.check(SaveV2LoadMetrics.summarize([4.0, 1.0, 3.0, 2.0])["median"] == 2.5, "par: mediana = média dos centrais")
	t.check(SaveV2LoadMetrics.summarize([]) == {"count": 0}, "sem amostra: count 0 (nada inventado)")


func _load_result(status: String, code: String = SaveV2Errors.OK) -> SaveV2RuntimeLoadResult:
	var result := SaveV2RuntimeLoadResult.new()
	result.status = status
	result.code = code
	result.message = "detalhe técnico interno"
	return result


# 4–6. mensagem do jogador × log técnico
func _test_messages(t) -> void:
	t.section("C9 — mensagem do jogador × log técnico")
	var cases := {
		SaveV2RuntimeLoadResult.SUCCESS: SaveV2PlayerMessages.KEY_LOADED,
		SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE: SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE,
		SaveV2RuntimeLoadResult.VALIDATION_FAILURE: SaveV2PlayerMessages.KEY_LOAD_INVALID,
		SaveV2RuntimeLoadResult.RESTORE_REJECTED: SaveV2PlayerMessages.KEY_LOAD_REJECTED,
		SaveV2RuntimeLoadResult.APPLY_FAILURE: SaveV2PlayerMessages.KEY_LOAD_FAILED_RESTORED,
		SaveV2RuntimeLoadResult.POST_RESTORE_MISMATCH: SaveV2PlayerMessages.KEY_LOAD_FAILED_RESTORED,
		SaveV2RuntimeLoadResult.ROLLBACK_FAILURE: SaveV2PlayerMessages.KEY_LOAD_UNSAFE,
	}
	var wrong: Array = []
	for status in cases:
		if SaveV2PlayerMessages.load_key(_load_result(status)) != cases[status]:
			wrong.append(status)
	t.check(wrong.is_empty(), "cada status de load -> mensagem própria (%s)" % str(wrong))
	t.check(SaveV2PlayerMessages.load_key(_load_result(SaveV2RuntimeLoadResult.LOAD_FAILURE, SaveV2Errors.FILE_NOT_FOUND)) == SaveV2PlayerMessages.KEY_LOAD_NO_SAVE
		and SaveV2PlayerMessages.load_key(_load_result(SaveV2RuntimeLoadResult.LOAD_FAILURE, SaveV2Errors.FILE_NOT_FOUND), true) == SaveV2PlayerMessages.KEY_LOAD_LEGACY_ONLY, "sem save V2: distingue 'nenhum save' de 'só save antigo'")
	var rollback := _load_result(SaveV2RuntimeLoadResult.ROLLBACK_FAILURE, SaveV2RuntimeLoadResult.CODE_APPLY_ERROR)
	rollback.original_failure = {"status": "APPLY_FAILURE", "code": "APPLY_ERROR"}
	rollback.rollback_details.append("falha no passo 'quests' (injetada)")
	var log := SaveV2PlayerMessages.load_log(rollback)
	t.check(log.contains("ROLLBACK_FAILURE") and log.contains("APPLY_FAILURE") and log.contains("falha no passo 'quests'"), "log técnico: código + falha original + falha do rollback")
	var save := SaveV2RuntimeSaveResult.new()
	save.status = SaveV2RuntimeSaveResult.WRITE_FAILURE
	t.check(SaveV2PlayerMessages.save_key(save) == SaveV2PlayerMessages.KEY_SAVE_WRITE_FAILED, "save: falha de escrita")
	save.status = SaveV2RuntimeSaveResult.SAVE_REJECTED
	t.check(SaveV2PlayerMessages.save_key(save) == SaveV2PlayerMessages.KEY_SAVE_FAILED, "save: recusado/inválido")
	save.status = SaveV2RuntimeSaveResult.SUCCESS
	t.check(SaveV2PlayerMessages.save_key(save) == SaveV2PlayerMessages.KEY_SAVED, "save: sucesso")


# 7. localização
func _test_localization(t) -> void:
	t.section("C9 — localização")
	var catalog: Dictionary = JSON_LOADER.read_dictionary(LOCALE_PATH)
	var missing: Array = []
	var technical: Array = []
	for key in SaveV2PlayerMessages.ALL_KEYS:
		var text := String(catalog.get(key, ""))
		if text.is_empty() or text == key:
			missing.append(key)
		for token in TECHNICAL_TOKENS:
			if text.contains(token):
				technical.append("%s:%s" % [key, token])
	t.check(missing.is_empty(), "todas as mensagens no catálogo pt-BR (%s)" % str(missing))
	t.check(technical.is_empty(), "nenhuma mensagem expõe código técnico (%s)" % str(technical))
	var service := LocalizationService.new()
	service.register_catalog("pt-BR", catalog)
	t.check(service.tr_key(SaveV2PlayerMessages.KEY_LOAD_UNSAFE) == "Não foi possível carregar o jogo com segurança.", "LocalizationService resolve as chaves (pt-BR)")
	service.free()
	var sources := ""
	for path in ["res://scripts/save_v2/save_v2_player_messages.gd", "res://scripts/save_v2/save_v2_runtime_load_coordinator.gd", "res://scripts/save_v2/save_v2_runtime_save_coordinator.gd"]:
		sources += FileAccess.get_file_as_string(path)
	var slice := FileAccess.get_file_as_string("res://scripts/vardhelm/vardhelm_vertical_slice.gd")
	var v2_ui := slice.substr(slice.find("func _present_v2_load_result"))
	t.check(not v2_ui.contains("\"Jogo") and not v2_ui.contains("\"Falha") and v2_ui.contains("localization.tr_key"), "apresentação V2 do slice sem texto hardcoded (usa localization.tr_key)")


# 8–9. inventário de saves (somente leitura)
func _test_inventory(t) -> void:
	t.section("C9 — detecção de saves (legado × V2)")
	var legacy := _path("legacy.json")
	var v2 := _path("v2.json")
	t.check(SaveV2PersistenceInventory.inspect(legacy, v2)["scenario"] == SaveV2PersistenceInventory.SCENARIO_NONE, "nenhum save")
	var legacy_text := JSON.stringify({"version": 2, "language": "pt-BR", "world": {"flags": {}, "values": {}, "memories": []}, "quests": {"active": {}, "completed": {}, "objective_progress": {}}})
	_write(legacy, legacy_text)
	var only_legacy := SaveV2PersistenceInventory.inspect(legacy, v2)
	t.check(only_legacy["scenario"] == SaveV2PersistenceInventory.SCENARIO_LEGACY_ONLY and only_legacy["legacy"]["status"] == SaveV2PersistenceInventory.LEGACY_PRESENT, "A. só save antigo detectado")
	SaveV2Service.new(v2).save_game_state(GameState.new())
	var both := SaveV2PersistenceInventory.inspect(legacy, v2)
	t.check(both["scenario"] == SaveV2PersistenceInventory.SCENARIO_BOTH and both["v2"]["status"] == SaveV2PersistenceInventory.V2_VALID and both["distinct_paths"], "B. antigo + V2 coexistem, em caminhos distintos")
	t.check(FileAccess.get_file_as_string(legacy) == legacy_text, "inventário não altera o save antigo")
	var v2_only := SaveV2PersistenceInventory.inspect(_path("absent_legacy.json"), v2)
	t.check(v2_only["scenario"] == SaveV2PersistenceInventory.SCENARIO_V2_ONLY, "só V2")
	var confused := _path("confused.json")
	_write(confused, FileAccess.get_file_as_string(v2))
	t.check(SaveV2PersistenceInventory.classify_legacy(confused)["status"] == SaveV2PersistenceInventory.LEGACY_IS_V2_ENVELOPE, "envelope V2 no caminho legado: identificado, não confundido com legado")
	_write(_path("broken_legacy.json"), "{não é json")
	t.check(SaveV2PersistenceInventory.classify_legacy(_path("broken_legacy.json"))["status"] == SaveV2PersistenceInventory.LEGACY_UNRECOGNIZED, "save antigo ilegível: não reconhecido")
	_write(v2, FileAccess.get_file_as_string(v2).replace("\"current\"", "\"x\"").replace("\"shadow\"", "\"y\""))
	var invalid := SaveV2PersistenceInventory.classify_v2(v2)
	t.check(invalid["status"] == SaveV2PersistenceInventory.V2_INVALID and invalid["code"] == SaveV2Errors.INVALID_CHECKSUM, "V2 adulterado: inválido (%s)" % str(invalid))
	var source := FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_persistence_inventory.gd")
	t.check(not source.contains("FileAccess.WRITE") and not source.contains("remove_absolute") and not source.contains("rename_absolute") and not source.contains("save_game_state"), "inventário somente leitura")


# 2. instrumentação por sandbox
func _test_instrumentation(t) -> void:
	t.section("C9 — instrumentação do load")
	var saved := GameState.new()
	saved.quests.start_quest("quest.vardhelm.first_echo")
	var service := SaveV2Service.new(_path("timing.json"))
	service.save_game_state(saved)
	var main: RuntimeRestoreTargets = OP.build_targets(t.root, _nodes)
	main.quest_state.start_quest("vardhelm_first_echo")
	main.quest_state.set_objective_complete("vardhelm_first_echo", "observe")
	var sandbox = OP.FakeSandbox.new(t.root, "ok")
	_sandboxes.append(sandbox)
	var result := SaveV2RuntimeLoadCoordinator.new(SaveV2OperationalConfig.create(true, _path("timing.json"))).load_into_runtime(main, sandbox)
	var keys := ["rehearsal", "sandbox1_file_validation", "sandbox1_create", "sandbox1_restore", "sandbox1_discard", "snapshot", "rollback_rehearsal", "sandbox2_create", "sandbox2_restore", "sandbox2_discard", "apply", "post_restore", "total"]
	var missing: Array = []
	for key in keys:
		if not result.timings_ms.has(key):
			missing.append(key)
	t.check(result.is_success() and missing.is_empty(), "tempos por etapa e por sandbox (%s)" % str(missing))
	var parts := float(result.timings_ms["sandbox1_file_validation"]) + float(result.timings_ms["sandbox1_create"]) + float(result.timings_ms["sandbox1_restore"]) + float(result.timings_ms["sandbox1_discard"])
	t.check(parts <= float(result.timings_ms["rehearsal"]) + 0.01, "partes do sandbox 1 cabem no rehearsal")
