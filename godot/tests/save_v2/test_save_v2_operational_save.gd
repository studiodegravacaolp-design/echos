extends RefCounted

## Bloco C8 — Save V2 operacional + ciclo Save/Load, isolados (sem a cena).
## Reaproveita os alvos/fakes do C7 (test_save_v2_operational_load.gd).
## O fluxo real (Ctrl+S/Ctrl+L) está em test_save_v2_operational_save_vardhelm.gd.

const OP := preload("res://tests/save_v2/test_save_v2_operational_load.gd")
const TEST_DIR := "user://save_v2_tests"
const FIXED_CLOCK := 1700000000

var _nodes: Array[Node] = []
var _sandboxes: Array = []


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_flag(t)
	_test_save(t)
	_test_shadow_sync(t)
	_test_duplicate(t)
	_test_cycle(t)
	_test_rejections(t)
	_test_dialogue_open(t)
	_test_events(t)
	_test_timings(t)
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


func _config(name: String, load_on: bool = true, save_on: bool = true) -> SaveV2OperationalConfig:
	return SaveV2OperationalConfig.create(load_on, _path(name), save_on)


func _saver(name: String, bus: GameEventBus = null) -> SaveV2RuntimeSaveCoordinator:
	var saver := SaveV2RuntimeSaveCoordinator.new(_config(name), bus)
	saver.service.clock = func() -> int: return FIXED_CLOCK
	return saver


func _loader(name: String, bus: GameEventBus = null) -> SaveV2RuntimeLoadCoordinator:
	return SaveV2RuntimeLoadCoordinator.new(_config(name), null, bus)


func _sandbox(t) -> SaveV2DiagnosticSandbox:
	var sandbox = OP.FakeSandbox.new(t.root, "ok")
	_sandboxes.append(sandbox)
	return sandbox


## Runtime "estado A": quest ativa, heard_echo, diálogo learn, posição/rotação não padrão.
func _runtime_a(t) -> RuntimeRestoreTargets:
	var targets: RuntimeRestoreTargets = OP.build_targets(t.root, _nodes)
	targets.player.global_position = Vector3(3.25, 0.5, -7.125)
	targets.player.global_rotation = Vector3(0.0, 1.25, 0.0)
	targets.world_state.set_flag("vardhelm_heard_echo", true)
	targets.world_state.add_memory("vardhelm_heard_echo")
	targets.quest_state.start_quest("vardhelm_first_echo")
	targets.dialogue_state.mark_completed("vardhelm_intro")
	targets.dialogue_state.record_choice("vardhelm_intro", "start", "learn")
	targets.derivations.derive_echo_state()
	return targets


## Leva o runtime ao "estado B" (Eco resolvido, quest concluída, outra posição e escolha).
func _to_b(targets: RuntimeRestoreTargets) -> void:
	targets.player.global_position = Vector3(9.0, 0.0, 9.0)
	targets.world_state.set_flag("vardhelm_first_echo_complete", true)
	targets.world_state.add_memory("vardhelm_first_echo_complete")
	targets.quest_state.active.erase("vardhelm_first_echo")
	targets.quest_state.completed["vardhelm_first_echo"] = true
	targets.quest_state.objective_progress["vardhelm_first_echo"] = {"observe": true}
	targets.dialogue_state.record_choice("vardhelm_intro", "start", "leave")
	(targets.npcs[GameIdCatalog.NPC_DURN] as NPCController).set_interaction_enabled(false)
	targets.derivations.derive_echo_state()


func _json(targets: RuntimeRestoreTargets) -> String:
	return JSON.stringify([SaveV2RuntimeSnapshot.raw_of(targets), targets.player.global_position, targets.player.global_rotation, SaveV2RuntimeSnapshot.describe(targets)], "", true)


func _file_state(name: String) -> Dictionary:
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_path(name)))
	return envelope["state"]


# 1–2
func _test_flag(t) -> void:
	t.section("C8 — flags")
	var config := SaveV2OperationalConfig.new()
	# C10.5: V2 virou o padrão (decisão pós-playtest); create() explícito continua OFF.
	t.check(config.save_enabled and config.enabled and SaveV2OperationalConfig.DEFAULT_SAVE_ENABLED == true and not SaveV2OperationalConfig.create().save_enabled, "SAVE_V2_OPERATIONAL_SAVE/LOAD_ENABLED padrão ON (C10.5); create() explícito OFF")
	t.check(SaveV2OperationalConfig.SLOT_ID == "current" and config.path == SaveV2Service.DEFAULT_PATH, "slot único, mesmo arquivo do Save V2 (C2)")
	var targets := _runtime_a(t)
	var off := SaveV2RuntimeSaveCoordinator.new(SaveV2OperationalConfig.create(false, _path("off.json"), false))
	var result := off.save_runtime(targets)
	t.check(result.status == SaveV2RuntimeSaveResult.DISABLED and not FileAccess.file_exists(_path("off.json")), "1. flag OFF: DISABLED, nada gravado")


# 3, 21–22
func _test_save(t) -> void:
	t.section("C8 — Save V2 operacional")
	var targets := _runtime_a(t)
	var before := _json(targets)
	var result := _saver("save.json").save_runtime(targets)
	t.check(result.is_success(), "2/3. SUCCESS (%s)" % result.describe())
	t.check(Array(result.steps) == ["flag", "project", "validate", "sync", "write", "checksum"], "etapas: %s" % " → ".join(PackedStringArray(result.steps)))
	var loaded := SaveV2Service.new(_path("save.json")).load_game_state()
	t.check(loaded.ok and loaded.envelope["metadata"]["slot_id"] == "current" and int(loaded.envelope["schema_version"]) == 2, "22. arquivo válido no formato C1 (envelope, schema 2, slot current)")
	var split := SaveV2Checksum.split_file_text(FileAccess.get_file_as_string(_path("save.json")))
	t.check(split["ok"] and String(split["checksum"]) == result.checksum and SaveV2Checksum.compute_from_text(String(split["covered"])) == result.checksum, "21. checksum literal válido")
	var projected: GameState = SaveV2RuntimeSnapshot.project(targets)["state"]
	t.check(GameStateComparator.compare(loaded.state, projected).is_equal(), "arquivo == projeção persistente do runtime")
	t.check(loaded.state.player.position == targets.player.global_position and loaded.state.dialogue.get_choice(GameIdCatalog.DIALOGUE_INTRO, "start") == "learn", "player e diálogo persistente gravados")
	t.check(_json(targets) == before, "save não altera o runtime")
	var source := _code_only(FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_save_coordinator.gd"))
	t.check(not source.contains("Sandbox") and not source.contains("SaveService") and not source.contains("user://echoes_of_the_soul_save.json"), "sem sandbox, sem SaveService, nunca o arquivo antigo")


# 23. sincronização da sombra
func _test_shadow_sync(t) -> void:
	t.section("C8 — GameState sombra sincronizado")
	var targets := _runtime_a(t)
	var recorder := GameStateShadowRecorder.new()
	recorder.game_state.quests.start_quest("quest.vardhelm.first_echo")
	recorder.game_state.world.set_flag("sombra_desatualizada")
	var result := _saver("sync.json").save_runtime(targets, recorder)
	t.check(result.is_success() and not result.shadow_divergence.is_empty(), "divergência da sombra detectada e registrada (%d caminhos)" % result.shadow_divergence.size())
	var projected: GameState = SaveV2RuntimeSnapshot.project(targets)["state"]
	t.check(GameStateComparator.compare(recorder.game_state, projected).is_equal() and recorder.game_state != result.state, "sombra == runtime após o save (cópia)")
	var again := _saver("sync.json").save_runtime(targets, recorder)
	t.check(again.shadow_divergence.is_empty(), "save seguinte: sombra já sincronizada")


# 20. save duplo
func _test_duplicate(t) -> void:
	t.section("C8 — save duplo")
	var targets := _runtime_a(t)
	_saver("twice.json").save_runtime(targets)
	var first := FileAccess.get_file_as_string(_path("twice.json"))
	_saver("twice.json").save_runtime(targets)
	t.check(FileAccess.get_file_as_string(_path("twice.json")) == first, "mesmo relógio: arquivo idêntico (envelope/state/checksum)")
	var later := SaveV2RuntimeSaveCoordinator.new(_config("twice.json"))
	later.service.clock = func() -> int: return FIXED_CLOCK + 60
	var result := later.save_runtime(targets)
	var loaded := SaveV2Service.new(_path("twice.json")).load_game_state()
	var original: Dictionary = JSON.parse_string(first)
	t.check(result.is_success() and t.same_json(loaded.envelope["state"], original["state"]) and result.checksum != String(original["checksum"]), "timestamp diferente: state idêntico (checksum muda só pela metadata)")
	t.check(targets.world_state.memories.count("vardhelm_heard_echo") == 1 and loaded.state.world.consequences.size() == 1 and (loaded.state.dialogue.choices[GameIdCatalog.DIALOGUE_INTRO] as Dictionary).size() == 1, "sem duplicação")


# 5–7. Save -> Load -> Save -> Load
func _test_cycle(t) -> void:
	t.section("C8 — ciclo Save → Load → Save → Load")
	var targets := _runtime_a(t)
	var state_a := _json(targets)
	t.check(_saver("cycle.json").save_runtime(targets).is_success(), "save do estado A")
	var file_a := FileAccess.get_file_as_string(_path("cycle.json"))
	_to_b(targets)
	t.check(_json(targets) != state_a, "runtime alterado para B")
	var loaded := _loader("cycle.json").load_into_runtime(targets, _sandbox(t))
	t.check(loaded.is_success() and _json(targets) == state_a, "5. Save → Load: estado A (%s)" % loaded.describe())
	var resaved := _saver("cycle.json").save_runtime(targets)
	t.check(resaved.is_success() and FileAccess.get_file_as_string(_path("cycle.json")) == file_a, "6. Load → Save: arquivo equivalente ao original")
	_to_b(targets)
	var reloaded := _loader("cycle.json").load_into_runtime(targets, _sandbox(t))
	t.check(reloaded.is_success() and _json(targets) == state_a, "7. Save → Load → Save → Load: estado A")


func _test_rejections(t) -> void:
	t.section("C8 — save recusado")
	var odd := _runtime_a(t)
	odd.world_state.add_memory("memoria_desconhecida")
	var result := _saver("odd.json").save_runtime(odd)
	t.check(result.status == SaveV2RuntimeSaveResult.SAVE_REJECTED and result.code == SaveV2RuntimeSaveResult.CODE_UNREPRESENTABLE_RUNTIME and not FileAccess.file_exists(_path("odd.json")), "runtime não representável: SAVE_REJECTED, nada gravado")
	var sandbox_targets := _runtime_a(t)
	sandbox_targets.is_sandbox = true
	t.check(_saver("sb.json").save_runtime(sandbox_targets).status == SaveV2RuntimeSaveResult.SAVE_REJECTED, "alvo sandbox: recusado")
	var directory := SaveV2RuntimeSaveCoordinator.new(SaveV2OperationalConfig.create(true, TEST_DIR, true))
	var failed := directory.save_runtime(_runtime_a(t))
	t.check(failed.status == SaveV2RuntimeSaveResult.WRITE_FAILURE and failed.code == SaveV2Errors.IO_ERROR, "falha de escrita: WRITE_FAILURE/IO_ERROR (%s)" % failed.describe())


# 10–12. diálogo aberto
func _test_dialogue_open(t) -> void:
	t.section("C8 — diálogo aberto")
	var targets := _runtime_a(t)
	_saver("dialogue.json").save_runtime(targets)
	_to_b(targets)
	targets.derivations.set("dialogue_open", true)
	var before := _json(targets)
	var sandbox = _sandbox(t)
	var bus := GameEventBus.new()
	var rejected := _loader("dialogue.json", bus).load_into_runtime(targets, sandbox)
	t.check(rejected.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE, "12. Load com diálogo aberto: LOAD_REJECTED_TRANSIENT_DIALOGUE")
	t.check(_json(targets) == before and sandbox.created == 0 and not rejected.snapshot_taken and bus.published_count() == 0, "nada tocado, sem rehearsal, sem evento")
	var saved := _saver("dialogue_open.json").save_runtime(targets)
	t.check(saved.is_success() and saved.dialogue_session_open, "11. Save com diálogo aberto: permitido, só o persistente")
	var text := FileAccess.get_file_as_string(_path("dialogue_open.json"))
	t.check(not text.contains("current_session") and not text.contains("current_entry") and not text.contains("dialogue_box") and _file_state("dialogue_open.json").keys().size() == GameState.new().to_dict().keys().size(), "10/11. nenhum estado transitório no arquivo")
	targets.derivations.set("dialogue_open", false)


# 30–31. eventos
func _test_events(t) -> void:
	t.section("C8 — eventos game_saved / game_loaded")
	var bus := GameEventBus.new()
	var types: Array = []
	bus.subscribe(func(event: GameEvent) -> void: types.append(event.event_type))
	var targets := _runtime_a(t)
	_saver("events.json", bus).save_runtime(targets)
	t.check(types == ["game_saved"], "save com SUCCESS: game_saved")
	types.clear()
	var directory := SaveV2RuntimeSaveCoordinator.new(SaveV2OperationalConfig.create(true, TEST_DIR, true), bus)
	directory.save_runtime(targets)
	t.check(types.is_empty(), "save que falhou: nenhum game_saved")
	_to_b(targets)
	var ok := _loader("events.json", bus).load_into_runtime(targets, _sandbox(t))
	t.check(ok.is_success() and ok.event_published and types == ["game_loaded"], "load com SUCCESS: game_loaded (após validação pós-restore)")
	types.clear()
	var failing := _loader("events.json", bus)
	failing.fault_injection_apply_step = "echo"
	var rolled := failing.load_into_runtime(targets, _sandbox(t))
	t.check(rolled.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS and not rolled.event_published and types.is_empty(), "load com rollback: nenhum game_loaded")
	var tampered := FileAccess.get_file_as_string(_path("events.json")).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(_path("events.json"), FileAccess.WRITE)
	file.store_string(tampered)
	file.close()
	var invalid := _loader("events.json", bus).load_into_runtime(targets, _sandbox(t))
	t.check(invalid.status == SaveV2RuntimeLoadResult.VALIDATION_FAILURE and types.is_empty(), "load inválido: nenhum game_loaded")
	var catalog: Array = GameEventCatalog.all_types()
	t.check(catalog.has("game_saved") and catalog.has("game_loaded") and not catalog.has("restore_started") and not catalog.has("restore_failed"), "nenhum evento novo no catálogo")


# 27–28. tempos
func _test_timings(t) -> void:
	t.section("C8 — medição")
	var targets := _runtime_a(t)
	_saver("timing.json").save_runtime(targets)
	var loaded := _loader("timing.json").load_into_runtime(targets, _sandbox(t))
	var keys := ["rehearsal", "snapshot", "rollback_rehearsal", "apply", "post_restore", "total"]
	t.check(keys.all(func(key): return loaded.timings_ms.has(key) and float(loaded.timings_ms[key]) >= 0.0), "tempos por etapa registrados (%s)" % str(loaded.timings_ms))
	var failing := _loader("timing.json")
	failing.fault_injection_apply_step = "echo"
	t.check(failing.load_into_runtime(targets, _sandbox(t)).timings_ms.has("rollback"), "tempo do rollback registrado")


func _code_only(source: String) -> String:
	var lines: PackedStringArray = []
	for line in source.split("\n"):
		var code := line.strip_edges()
		if not code.begins_with("#"):
			lines.append(code)
	return "\n".join(lines)
