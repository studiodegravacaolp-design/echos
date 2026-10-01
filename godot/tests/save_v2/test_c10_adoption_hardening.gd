extends RefCounted

## Bloco C10 — endurecimento da adoção (sem a cena): decisão de migração OPT-IN,
## severidade/distinção das mensagens, localização do falante (Durn), flags OFF e
## instrumentação. O fluxo real está em test_c10_adoption_hardening_vardhelm.gd.

const OP := preload("res://tests/save_v2/test_save_v2_operational_load.gd")
const TEST_DIR := "user://save_v2_tests"
const DIALOGUE_BOX_SCENE := "res://scenes/ui/dialogue_box.tscn"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const LOCALE_PATH := "res://data/localization/pt-BR.json"

var _nodes: Array[Node] = []
var _sandboxes: Array = []


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_migration_policy(t)
	_test_messages(t)
	_test_durn(t)
	_test_flags(t)
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


func _scan(root: String, token: String) -> Array:
	var hits: Array = []
	var dir := DirAccess.open(root)
	if dir == null:
		return hits
	for file_name in dir.get_files():
		if file_name.ends_with(".gd") and FileAccess.get_file_as_string("%s/%s" % [root, file_name]).contains(token):
			hits.append(file_name)
	for sub in dir.get_directories():
		hits.append_array(_scan("%s/%s" % [root, sub], token))
	return hits


# 1. política de migração
func _test_migration_policy(t) -> void:
	t.section("C10 — política de migração OPT-IN")
	var policy := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../docs/architecture/SAVE_MIGRATION_POLICY.md"))
	t.check(policy.contains("OPTION B — OPT-IN MIGRATION") and policy.contains("DECIDIDO"), "decisão registrada: OPTION B — OPT-IN MIGRATION")
	t.check(policy.contains("Nenhuma migração automática") and policy.contains("não implementada"), "documenta: sem migração automática; conversão não implementada")
	var migrators: Array = []
	for entry in ProjectSettings.get_global_class_list():
		if String(entry["class"]).contains("Migrator"):
			migrators.append(String(entry["class"]))
	t.check(migrators == ["GameStateMigrator"], "nenhum migrator novo (só o GameStateMigrator do A2): %s" % str(migrators))
	t.check(_scan("res://scripts/save_v2", "migrate_legacy_payload").is_empty() and _scan("res://scripts/vardhelm", "migrate_legacy_payload").is_empty(), "nenhuma conversão de save antigo no Save V2 / experiência")


# 3–9. mensagens distintas, severidade, sem código técnico
func _test_messages(t) -> void:
	t.section("C10 — mensagens")
	var catalog: Dictionary = JSON_LOADER.read_dictionary(LOCALE_PATH)
	var required := {
		"SAVE SUCCESS": SaveV2PlayerMessages.KEY_SAVED,
		"SAVE FAILURE": SaveV2PlayerMessages.KEY_SAVE_WRITE_FAILED,
		"LOAD SUCCESS": SaveV2PlayerMessages.KEY_LOADED,
		"LOAD FAILURE": SaveV2PlayerMessages.KEY_LOAD_INVALID,
		"LOAD REJECTED DIALOGUE": SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE,
		"ROLLBACK FAILURE": SaveV2PlayerMessages.KEY_LOAD_UNSAFE,
	}
	var texts := {}
	for label in required:
		texts[String(catalog.get(required[label], ""))] = label
	t.check(texts.size() == required.size() and not texts.has(""), "6 mensagens distintas e localizadas (%s)" % str(texts.keys()))
	t.check(SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_SAVED) == "success" and SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_LOADED) == "success", "sucesso destacado como sucesso")
	t.check(SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_LOAD_REJECTED_DIALOGUE) == "warning", "recusa por diálogo: aviso")
	t.check(SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_LOAD_UNSAFE) == "error" and SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_SAVE_WRITE_FAILED) == "error" and SaveV2PlayerMessages.severity_of(SaveV2PlayerMessages.KEY_LOAD_INVALID) == "error", "falhas: erro")
	var leaked: Array = []
	for key in SaveV2PlayerMessages.ALL_KEYS:
		var text := String(catalog.get(key, ""))
		for token in ["FAILURE", "REJECTED", "ROLLBACK", "MISMATCH", "CHECKSUM", "ERROR", "_"]:
			if text.contains(token):
				leaked.append("%s:%s" % [key, token])
	t.check(leaked.is_empty(), "nenhum código técnico nas mensagens (%s)" % str(leaked))


# 10. Durn
func _test_durn(t) -> void:
	t.section("C10 — falante do diálogo localizado (Durn)")
	var box := (load(DIALOGUE_BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	t.root.add_child(box)
	_nodes.append(box)
	var localization := LocalizationService.new()
	_nodes.append(localization)
	localization.register_catalog("pt-BR", JSON_LOADER.read_dictionary(LOCALE_PATH))
	var dialogue: DialogueData = JSON_LOADER.load_dialogue("res://data/dialogue/vardhelm_intro.json")
	var entry := dialogue.get_entry("start")
	box.show_entry(entry, localization)
	t.check(box.speaker_label.text == "Durn", "falante exibido = Durn (\"%s\")" % box.speaker_label.text)
	t.check(entry.speaker_id == "npc.vardhelm.elder.name", "dado do diálogo inalterado (speaker_id continua a chave)")
	t.check(GameIdCatalog.NPC_DURN == "npc.vardhelm.durn" and GameIdCatalog.canonical_id(GameIdCatalog.KIND_NPC, "vardhelm.durn") == "npc.vardhelm.durn", "ID canônico do NPC inalterado (npc.vardhelm.durn)")
	box.show_entry(entry, null)
	t.check(box.speaker_label.text == "npc.vardhelm.elder.name", "sem localizador: comportamento anterior preservado")


# 23. flags
func _test_flags(t) -> void:
	t.section("C10 — flags (padrão ON desde o C10.5)")
	var config := SaveV2OperationalConfig.new()
	t.check(config.enabled and config.save_enabled and SaveV2OperationalConfig.DEFAULT_ENABLED and SaveV2OperationalConfig.DEFAULT_SAVE_ENABLED, "SAVE_V2_OPERATIONAL_LOAD/SAVE_ENABLED = true por padrão (decisão C10.5)")
	var slice := FileAccess.get_file_as_string("res://scripts/vardhelm/vardhelm_vertical_slice.gd")
	t.check(slice.contains("var save_v2_operational_config: SaveV2OperationalConfig = SaveV2OperationalConfig.new()") and not slice.contains("get_cmdline_user_args"), "slice usa a configuração padrão (V2 ON); nenhum modo de teste permanente")


# 22. instrumentação
func _test_instrumentation(t) -> void:
	t.section("C10 — instrumentação continua")
	var saved := GameState.new()
	saved.quests.start_quest("quest.vardhelm.first_echo")
	SaveV2Service.new("%s/c10.json" % TEST_DIR).save_game_state(saved)
	var main: RuntimeRestoreTargets = OP.build_targets(t.root, _nodes)
	main.quest_state.start_quest("vardhelm_first_echo")
	var sandbox = OP.FakeSandbox.new(t.root, "ok")
	_sandboxes.append(sandbox)
	var result := SaveV2RuntimeLoadCoordinator.new(SaveV2OperationalConfig.create(true, "%s/c10.json" % TEST_DIR)).load_into_runtime(main, sandbox)
	t.check(result.is_success() and result.timings_ms.has("sandbox1_create") and result.timings_ms.has("sandbox2_create") and result.timings_ms.has("total"), "tempos por sandbox continuam registrados")
	t.check(sandbox.created == 1 and sandbox.spawned.size() == 1, "dois sandboxes continuam (rehearsal do arquivo + do rollback)")
