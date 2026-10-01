extends RefCounted

## Bloco C6 — SaveV2DiagnosticCoordinator isolado (sem a cena de Vardhelm).
## Sandbox de teste com alvos reais (Player, WorldState, QuestState, NPC,
## DialogueRuntimeState) e derivações simples. O fluxo real está em
## test_save_v2_diagnostic_vardhelm.gd.

const TEST_DIR := "user://save_v2_tests"
const NPC_SCENE_PATH := "res://scenes/npc/npc.tscn"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const FIXED_CLOCK := 1700000000


class FakeDerivations extends RuntimeStateDerivationContract:
	var quests: QuestState

	func derive_quest_presentation() -> bool:
		return true

	func describe_quest_presentation(quest_id: String) -> Dictionary:
		return {"completion_presented": quests.is_completed(GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id))}

	func derive_environment_state() -> bool:
		return true


## mode: "ok", "no_derivations", "not_sandbox", "wrong_scenario", "null".
class FakeSandbox extends SaveV2DiagnosticSandbox:
	var parent: Node
	var mode := "ok"
	var created := 0
	var targets: RuntimeRestoreTargets = null
	var nodes: Array[Node] = []
	var _discarded := false

	func _init(tree_parent: Node, sandbox_mode: String = "ok") -> void:
		parent = tree_parent
		mode = sandbox_mode

	func create_targets() -> RuntimeRestoreTargets:
		created += 1
		if mode == "null":
			return null
		targets = RuntimeRestoreTargets.new()
		targets.is_sandbox = mode != "not_sandbox"
		targets.scenario_id = "scenario.outro" if mode == "wrong_scenario" else GameIdCatalog.SCENARIO_VARDHELM
		var player := Node3D.new()
		parent.add_child(player)
		nodes.append(player)
		targets.player = player
		targets.world_state = WorldState.new()
		targets.quest_state = QuestState.new()
		var npc := (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as NPCController
		npc.npc_id = "vardhelm.durn"
		nodes.append(npc)
		targets.npcs = {GameIdCatalog.NPC_DURN: npc}
		targets.dialogue_state = DialogueRuntimeState.new()
		targets.dialogue_definitions = {GameIdCatalog.DIALOGUE_INTRO: (load("res://scripts/data/json_data_loader.gd")).load_dialogue("res://data/dialogue/vardhelm_intro.json")}
		if mode != "no_derivations":
			var fake := FakeDerivations.new()
			fake.quests = targets.quest_state
			targets.derivations = fake
		return targets

	func discard() -> void:
		for node in nodes:
			if is_instance_valid(node):
				if node.get_parent() != null:
					node.get_parent().remove_child(node)
				node.queue_free()
		nodes.clear()
		_discarded = true

	func is_discarded() -> bool:
		return _discarded


class FailingAdapter extends RestoreAdapter:
	func adapter_id() -> String:
		return "failing_probe"

	func step() -> String:
		return "echo"

	func apply(_state: GameState, _plan: RestorePlan, _targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
		var result := new_result()
		result.errors.append("falha injetada pelo teste")
		return result


var _sandboxes: Array[FakeSandbox] = []


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_flag(t)
	_test_save_and_integrity(t)
	_test_load_success(t)
	_test_duplicate_and_idempotence(t)
	_test_failures(t)
	_test_no_events(t)
	for sandbox in _sandboxes:
		sandbox.discard()
	_clean()


func _path(name: String) -> String:
	return "%s/%s" % [TEST_DIR, name]


func _coordinator(name: String, registry: RuntimeRestoreAdapterRegistry = null) -> SaveV2DiagnosticCoordinator:
	var coordinator := SaveV2DiagnosticCoordinator.new(SaveV2DiagnosticConfig.create(true, _path(name)), registry)
	coordinator.service.clock = func() -> int: return FIXED_CLOCK
	return coordinator


func _sandbox(t, mode: String = "ok") -> FakeSandbox:
	var sandbox := FakeSandbox.new(t.root, mode)
	_sandboxes.append(sandbox)
	return sandbox


func _state() -> GameState:
	var state := GameState.new()
	state.player.position = Vector3(3.25, 0.5, -7.125)
	state.player.rotation = Vector3(0.0, 1.2345678901234567, 0.0)
	state.world.set_flag("vardhelm_heard_echo")
	state.world.apply_consequence(GameIdCatalog.CONSEQUENCE_HEARD_ECHO, "dialogue", GameIdCatalog.DIALOGUE_INTRO)
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.dialogue.mark_completed(GameIdCatalog.DIALOGUE_INTRO)
	state.dialogue.record_choice(GameIdCatalog.DIALOGUE_INTRO, "start", "learn")
	return state


func _write(name: String, text: String) -> void:
	var file := FileAccess.open(_path(name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _envelope_text(state_data: Dictionary, schema: int = SaveV2Envelope.SCHEMA_VERSION) -> String:
	var envelope := SaveV2Envelope.create(state_data, SaveV2Envelope.make_metadata("diagnostic", FIXED_CLOCK, FIXED_CLOCK))
	envelope["schema_version"] = schema
	envelope[SaveV2Checksum.FIELD] = SaveV2Checksum.compute(envelope)
	return SaveV2Serializer.to_file_text(envelope)


func _runtime_json(targets: RuntimeRestoreTargets) -> String:
	var projected := GameStateProjector.project(targets.world_state, targets.quest_state, targets.player, targets.dialogue_state).state
	return JSON.stringify([projected.to_dict(), targets.world_state.flags, Array(targets.world_state.memories), targets.dialogue_state.to_dict()], "", true)


# 1. feature flag
func _test_flag(t) -> void:
	t.section("C6 — feature flag")
	var config := SaveV2DiagnosticConfig.new()
	t.check(not config.enabled and SaveV2DiagnosticConfig.DEFAULT_ENABLED == false, "SAVE_V2_DIAGNOSTIC_ENABLED padrão OFF")
	var config_object: Variant = config
	t.check(config_object is RefCounted and not (config_object is Node), "flag em objeto local (não Autoload, sem ProjectSettings/ambiente)")
	t.check(SaveV2DiagnosticConfig.DEFAULT_PATH == "user://echoes_of_the_soul_save_v2_diagnostic.json" and SaveV2DiagnosticConfig.DEFAULT_PATH != SaveService.SAVE_PATH and SaveV2DiagnosticConfig.DEFAULT_PATH != SaveV2Service.DEFAULT_PATH, "arquivo próprio: nem o do SaveService nem o da sombra C2")
	var off := SaveV2DiagnosticCoordinator.new(SaveV2DiagnosticConfig.create(false, _path("off.json")))
	var sandbox := _sandbox(t)
	var saved := off.save(_state())
	var loaded := off.load_and_restore(sandbox)
	t.check(saved.status == SaveV2DiagnosticReport.DISABLED and loaded.status == SaveV2DiagnosticReport.DISABLED and saved.code == "FLAG_DISABLED", "flag OFF: save e load devolvem DISABLED")
	t.check(not FileAccess.file_exists(_path("off.json")) and sandbox.created == 0, "flag OFF: nenhum arquivo gravado, nenhum sandbox criado")
	t.check(not SaveV2DiagnosticCoordinator.new().is_enabled(), "coordenador sem configuração = desligado")


# 2–5, 16. save + integridade
func _test_save_and_integrity(t) -> void:
	t.section("C6 — V2 save + integridade")
	var coordinator := _coordinator("integrity.json")
	var report := coordinator.save(_state())
	t.check(report.is_success() and report.checksum_verified and FileAccess.file_exists(_path("integrity.json")), "V2 save diagnóstico gravado (%s)" % report.describe())
	var text := FileAccess.get_file_as_string(_path("integrity.json"))
	var split := SaveV2Checksum.split_file_text(text)
	t.check(split["ok"] and SaveV2Checksum.compute_from_text(String(split["covered"])) == String(split["checksum"]) and String(split["checksum"]) == report.checksum, "arquivo literal: checksum recalculado confere")
	var envelope: Dictionary = JSON.parse_string(text)
	t.check(envelope["format"] == SaveV2Envelope.FORMAT and int(envelope["schema_version"]) == 2 and envelope["metadata"]["slot_id"] == "diagnostic" and Array(envelope.keys()).size() == SaveV2Envelope.KEYS.size(), "envelope do C1 inalterado (format, schema 2, metadata, state, checksum)")
	t.check(text.begins_with("{\"checksum\":\"sha256:") and not text.contains("\n"), "serialização canônica do C1 (uma linha, checksum primeiro)")
	var loaded := _coordinator("integrity.json").load_and_restore(_sandbox(t))
	t.check(loaded.steps.find("checksum") >= 0 and loaded.steps.find("checksum") < loaded.steps.find("sandbox"), "checksum validado ANTES de criar o sandbox / restaurar (%s)" % str(loaded.steps))


# 3, 6–8. load com sucesso
func _test_load_success(t) -> void:
	t.section("C6 — V2 load diagnóstico (sandbox de teste)")
	var state := _state()
	var coordinator := _coordinator("success.json")
	coordinator.save(state)
	var sandbox := _sandbox(t)
	var report := _coordinator("success.json").load_and_restore(sandbox, state)
	t.check(report.is_success(), "SUCCESS (%s)" % report.describe())
	t.check(Array(report.steps) == ["flag", "load", "envelope", "checksum", "game_state", "plan", "sandbox", "restore", "verify", "comparison"], "etapas na ordem: %s" % " → ".join(PackedStringArray(report.steps)))
	t.check(report.plan_counts["requires_adapter"] == 0 and report.plan_counts["unsupported"] == 0, "RestorePlan validado (%s)" % str(report.plan_counts))
	t.check(report.sandbox == sandbox and not sandbox.is_discarded() and sandbox.created == 1, "sandbox mantido para inspeção em SUCCESS")
	var targets := sandbox.targets
	t.check(targets.player.global_position == state.player.position and targets.player.global_rotation.is_equal_approx(state.player.rotation), "posição exata e rotação restauradas")
	t.check(targets.dialogue_state.is_completed("vardhelm_intro") and targets.dialogue_state.last_choice("vardhelm_intro", "start") == "learn", "diálogo persistente restaurado")
	t.check(report.expected_comparison.get("loaded_equal") == true and report.expected_comparison.get("restored_equal") == true, "esperado == carregado == restaurado")
	var adapters: Array = []
	for entry in report.restore["adapter_results"]:
		adapters.append(entry["adapter"])
	t.check(adapters == ["consequence", "observation", "echo", "memory", "dialogue", "quest_presentation", "environment_presentation"], "adapters executados")


# 31–33. duplicação e idempotência
func _test_duplicate_and_idempotence(t) -> void:
	t.section("C6 — save duplicado e restore idempotente")
	var state := _state()
	var coordinator := _coordinator("twice.json")
	var first := coordinator.save(state)
	var first_text := FileAccess.get_file_as_string(_path("twice.json"))
	var second := coordinator.save(state)
	var second_text := FileAccess.get_file_as_string(_path("twice.json"))
	t.check(first.is_success() and second.is_success() and first_text == second_text and first.checksum == second.checksum, "mesmo GameState salvo duas vezes: arquivo idêntico")
	var a := _sandbox(t)
	var b := _sandbox(t)
	var ra := _coordinator("twice.json").load_and_restore(a, state)
	var rb := _coordinator("twice.json").load_and_restore(b, state)
	t.check(ra.is_success() and rb.is_success() and _runtime_json(a.targets) == _runtime_json(b.targets), "restore em sandboxes independentes: mesmo estado final")
	var world := a.targets.world_state
	t.check(world.memories.count("vardhelm_heard_echo") == 1 and a.targets.quest_state.active.size() == 1 and (a.targets.dialogue_state.choices["vardhelm_intro"] as Dictionary).size() == 1, "sem duplicação de consequência, quest ou escolha")
	var again := GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default()).apply_to_sandbox(ra.state, a.targets)
	t.check(again.success and _runtime_json(a.targets) == _runtime_json(b.targets), "restore repetido sobre o mesmo sandbox: idempotente")


# 23–30. failure policy
func _test_failures(t) -> void:
	t.section("C6 — failure policy")
	var main_world := WorldState.new()
	main_world.set_flag("main_only")
	var main_before := JSON.stringify(main_world.flags)

	var missing := _sandbox(t)
	var report := _coordinator("does_not_exist.json").load_and_restore(missing)
	_expect(t, report, missing, SaveV2DiagnosticReport.FAILURE, SaveV2Errors.FILE_NOT_FOUND, false, "1. arquivo inexistente")

	_coordinator("tampered.json").save(_state())
	_write("tampered.json", FileAccess.get_file_as_string(_path("tampered.json")).replace("\"learn\"", "\"leave\""))
	var tampered := _sandbox(t)
	_expect(t, _coordinator("tampered.json").load_and_restore(tampered), tampered, SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2Errors.INVALID_CHECKSUM, false, "2. checksum inválido")

	_write("broken.json", "{\"checksum\":\"sha256:")
	var broken := _sandbox(t)
	_expect(t, _coordinator("broken.json").load_and_restore(broken), broken, SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2Errors.CORRUPTED_DATA, false, "3. JSON corrompido")

	_write("future.json", _envelope_text(_state().to_dict(), 3))
	var future := _sandbox(t)
	_expect(t, _coordinator("future.json").load_and_restore(future), future, SaveV2DiagnosticReport.UNSUPPORTED_SCHEMA, SaveV2Errors.UNSUPPORTED_SCHEMA, false, "4. schema futuro")

	var invalid := _state().to_dict()
	invalid["quests"] = "não é seção"
	_write("invalid.json", _envelope_text(invalid))
	var invalid_box := _sandbox(t)
	_expect(t, _coordinator("invalid.json").load_and_restore(invalid_box), invalid_box, SaveV2DiagnosticReport.INVALID_SAVE, SaveV2Errors.INVALID_STATE, false, "5. GameState inválido")

	var unknown := _state()
	unknown.quests.start_quest("quest.outro.desconhecida")
	var unknown_coordinator := _coordinator("unknown.json")
	t.check(unknown_coordinator.save(unknown).is_success(), "GameState com ID desconhecido é gravável (formato válido)")
	var unknown_box := _sandbox(t)
	var unknown_report := unknown_coordinator.load_and_restore(unknown_box)
	_expect(t, unknown_report, unknown_box, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_UNKNOWN_ID, false, "6. ID desconhecido")
	t.check(unknown_report.details.has("quests.quest.outro.desconhecida"), "6. ID desconhecido listado no diagnóstico")

	_coordinator("ok.json").save(_state())
	var registry := RuntimeRestoreAdapterRegistry.create_default()
	registry.register(FailingAdapter.new())
	var adapter_box := _sandbox(t)
	var adapter_report := _coordinator("ok.json", registry).load_and_restore(adapter_box)
	_expect(t, adapter_report, adapter_box, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.CODE_ADAPTER_FAILURE, true, "7. falha de adapter")

	var derivation_box := _sandbox(t, "no_derivations")
	var derivation_report := _coordinator("ok.json").load_and_restore(derivation_box)
	_expect(t, derivation_report, derivation_box, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.CODE_DERIVATION_FAILURE, true, "8. falha de derivação (nunca best effort)")

	var not_sandbox := _sandbox(t, "not_sandbox")
	_expect(t, _coordinator("ok.json").load_and_restore(not_sandbox), not_sandbox, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_TARGET_NOT_SANDBOX, true, "9. restore rejeitado (alvo não sandbox)")
	var wrong := _sandbox(t, "wrong_scenario")
	var wrong_report := _coordinator("ok.json").load_and_restore(wrong)
	_expect(t, wrong_report, wrong, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_RESTORE_REFUSED, true, "9. restore rejeitado (cenário diferente)")
	t.check(wrong_report.restore.get("applied", [1]).is_empty(), "9. rejeição antes de qualquer escrita")
	var null_box := _sandbox(t, "null")
	_expect(t, _coordinator("ok.json").load_and_restore(null_box), null_box, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_SANDBOX_UNAVAILABLE, true, "sandbox indisponível")
	t.check(JSON.stringify(main_world.flags) == main_before, "nenhuma falha toca estado fora do sandbox")
	for status in [SaveV2DiagnosticReport.SUCCESS, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.FAILURE, SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2DiagnosticReport.INVALID_SAVE, SaveV2DiagnosticReport.UNSUPPORTED_SCHEMA, SaveV2DiagnosticReport.RESTORE_REJECTED]:
		if not SaveV2DiagnosticReport.STATUSES.has(status):
			t.check(false, "status ausente: %s" % status)
	t.check(SaveV2DiagnosticCoordinator.status_for(SaveV2Errors.INVALID_FORMAT) == SaveV2DiagnosticReport.INVALID_SAVE and SaveV2DiagnosticCoordinator.status_for(SaveV2Errors.IO_ERROR) == SaveV2DiagnosticReport.FAILURE, "mapeamento SaveV2Errors -> failure policy")


func _expect(t, report: SaveV2DiagnosticReport, sandbox: FakeSandbox, status: String, code: String, sandbox_expected: bool, label: String) -> void:
	t.check(report.status == status and report.code == code, "%s: %s/%s (%s)" % [label, status, code, report.describe()])
	if sandbox_expected:
		t.check(sandbox.created == 1 and sandbox.is_discarded() and report.sandbox_discarded and report.sandbox == null, "%s: sandbox descartado, nada parcial sobrevive" % label)
	else:
		t.check(sandbox.created == 0 and report.sandbox == null, "%s: falha antes de criar o sandbox (nada restaurado)" % label)


# 20. nenhum evento
func _test_no_events(t) -> void:
	t.section("C6 — sem eventos")
	var events: Array = []
	for type in ["restore_started", "restore_completed", "restore_failed"]:
		if GameEventCatalog.is_known_type(type):
			events.append(type)
	t.check(events.is_empty(), "restore_started/completed/failed não existem no EventCatalog (%s)" % str(events))
	var source := _code_only(FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_diagnostic_coordinator.gd"))
	t.check(not source.contains("GameEventBus") and not source.contains(".publish(") and not source.contains("SaveService"), "coordenador não usa EventBus nem SaveService")


func _clean() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


## Somente linhas de código (comentários ignorados).
func _code_only(source: String) -> String:
	var lines: PackedStringArray = []
	for line in source.split("\n"):
		var code := line.strip_edges()
		if not code.begins_with("#"):
			lines.append(code)
	return "\n".join(lines)
