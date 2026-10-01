extends RefCounted

## Bloco C7 — SaveV2RuntimeLoadCoordinator isolado (sem a cena de Vardhelm).
## "Jogo principal" de teste = alvos reais NÃO sandbox (Player na árvore,
## WorldState, QuestState, NPC, DialogueRuntimeState) com derivações simples.
## O fluxo real (Ctrl+L) está em test_save_v2_operational_load_vardhelm.gd.

const TEST_DIR := "user://save_v2_tests"
const FIXED_CLOCK := 1700000000


class FakeDerivations extends RuntimeStateDerivationContract:
	var dialogue_open := false

	func is_dialogue_session_open() -> bool:
		return dialogue_open

	var quests: QuestState
	var world: WorldState
	var echo: EchoMemoryInteractable

	func echo_ids() -> Array[String]:
		var ids: Array[String] = [GameIdCatalog.ECHO_FIRST]
		return ids

	func derive_echo_state() -> bool:
		var completed := world.has_flag("vardhelm_first_echo_complete") or quests.is_completed("vardhelm_first_echo")
		var active := quests.active.has("vardhelm_first_echo") or quests.objective_progress.has("vardhelm_first_echo")
		echo.revealed = completed
		echo.interaction_enabled = active and not completed
		return true

	func describe_echo(echo_id: String) -> Dictionary:
		return {"revealed": echo.revealed, "interaction_enabled": echo.interaction_enabled} if echo_id == GameIdCatalog.ECHO_FIRST else {}

	func derive_quest_presentation() -> bool:
		return true

	func describe_quest_presentation(quest_id: String) -> Dictionary:
		if quest_id != "quest.vardhelm.first_echo":
			return {}
		return {"completion_presented": quests.is_completed(GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id))}

	func derive_environment_state() -> bool:
		return true


static func build_targets(parent: Node, nodes: Array[Node], with_derivations: bool = true) -> RuntimeRestoreTargets:
	var targets := RuntimeRestoreTargets.new()
	targets.scenario_id = GameIdCatalog.SCENARIO_VARDHELM
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
	if with_derivations:
		var fake := FakeDerivations.new()
		fake.quests = targets.quest_state
		fake.world = targets.world_state
		fake.echo = EchoMemoryInteractable.new()
		nodes.append(fake.echo)
		targets.derivations = fake
	return targets


## mode: "ok" ou "no_derivations". Cada spawn() cria um sandbox novo.
class FakeSandbox extends SaveV2DiagnosticSandbox:
	var parent: Node
	var mode := "ok"
	var created := 0
	var spawned: Array = []
	var nodes: Array[Node] = []
	var _discarded := false

	func _init(tree_parent: Node, sandbox_mode: String = "ok") -> void:
		parent = tree_parent
		mode = sandbox_mode

	func create_targets() -> RuntimeRestoreTargets:
		created += 1
		var script: GDScript = load("res://tests/save_v2/test_save_v2_operational_load.gd")
		var targets: RuntimeRestoreTargets = script.build_targets(parent, nodes, mode != "no_derivations")
		targets.is_sandbox = true
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

	func spawn() -> SaveV2DiagnosticSandbox:
		var next := FakeSandbox.new(parent, "ok")
		spawned.append(next)
		return next


class FailingAdapter extends RestoreAdapter:
	func adapter_id() -> String:
		return "failing_probe"

	func step() -> String:
		return "echo"

	func apply(_state: GameState, _plan: RestorePlan, _targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
		var result := new_result()
		result.errors.append("falha injetada pelo teste")
		return result


## Só no jogo principal e uma única vez: deixa um resto no runtime depois do apply.
class StrayAdapter extends RestoreAdapter:
	var armed := true

	func adapter_id() -> String:
		return "stray_probe"

	func step() -> String:
		return "progression"

	func apply(_state: GameState, _plan: RestorePlan, targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
		if armed and not targets.is_sandbox:
			armed = false
			targets.world_state.set_flag("stray_after_apply", true)
		return new_result()


var _nodes: Array[Node] = []
var _sandboxes: Array = []


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_flag(t)
	_test_success(t)
	_test_snapshot(t)
	_test_rehearsal_failures(t)
	_test_apply_failure(t)
	_test_post_restore_mismatch(t)
	_test_rollback_failure(t)
	_test_guards(t)
	_test_idempotence(t)
	_test_no_events(t)
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


func _main(t) -> RuntimeRestoreTargets:
	var main := build_targets(t.root, _nodes)
	# Runtime principal "avançado": outro estado que o do arquivo.
	main.player.global_position = Vector3(9.0, 0.0, 9.0)
	main.world_state.set_flag("vardhelm_heard_echo", true)
	main.world_state.add_memory("vardhelm_heard_echo")
	main.world_state.set_flag("vardhelm_first_echo_complete", true)
	main.world_state.add_memory("vardhelm_first_echo_complete")
	main.quest_state.completed["vardhelm_first_echo"] = true
	main.quest_state.objective_progress["vardhelm_first_echo"] = {"observe": true}
	main.dialogue_state.mark_completed("vardhelm_intro")
	main.dialogue_state.record_choice("vardhelm_intro", "start", "leave")
	(main.npcs[GameIdCatalog.NPC_DURN] as NPCController).set_interaction_enabled(false)
	main.derivations.derive_echo_state()
	return main


func _saved_state() -> GameState:
	var state := GameState.new()
	state.player.position = Vector3(3.25, 0.5, -7.125)
	state.player.rotation = Vector3(0.0, 1.25, 0.0)
	state.world.set_flag("vardhelm_heard_echo")
	state.world.apply_consequence(GameIdCatalog.CONSEQUENCE_HEARD_ECHO, "dialogue", GameIdCatalog.DIALOGUE_INTRO)
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.dialogue.mark_completed(GameIdCatalog.DIALOGUE_INTRO)
	state.dialogue.record_choice(GameIdCatalog.DIALOGUE_INTRO, "start", "learn")
	return state


func _write_save(name: String, state: GameState) -> void:
	var service := SaveV2Service.new(_path(name))
	service.clock = func() -> int: return FIXED_CLOCK
	service.save_game_state(state)


func _sandbox(t, mode: String = "ok") -> FakeSandbox:
	var sandbox := FakeSandbox.new(t.root, mode)
	_sandboxes.append(sandbox)
	return sandbox


func _coordinator(name: String, registry: RuntimeRestoreAdapterRegistry = null) -> SaveV2RuntimeLoadCoordinator:
	return SaveV2RuntimeLoadCoordinator.new(SaveV2OperationalConfig.create(true, _path(name)), registry)


func _json(targets: RuntimeRestoreTargets) -> String:
	return JSON.stringify([SaveV2RuntimeSnapshot.raw_of(targets), targets.player.global_position, targets.player.global_rotation, SaveV2RuntimeSnapshot.describe(targets)], "", true)


func _projection_equals(targets: RuntimeRestoreTargets, state: GameState) -> bool:
	var projected := GameStateProjector.project(targets.world_state, targets.quest_state, targets.player, targets.dialogue_state).state
	return GameStateComparator.compare(state, projected).is_equal()


# 1–3. flag
func _test_flag(t) -> void:
	t.section("C7 — feature flag")
	var config := SaveV2OperationalConfig.new()
	# C10.5: V2 virou o padrão (decisão pós-playtest); create() explícito continua OFF.
	t.check(config.enabled and SaveV2OperationalConfig.DEFAULT_ENABLED == true and not SaveV2OperationalConfig.create().enabled, "SAVE_V2_OPERATIONAL_LOAD_ENABLED padrão ON (C10.5); create() explícito OFF")
	t.check(config.path == SaveV2Service.DEFAULT_PATH and config.path != SaveService.SAVE_PATH, "lê o Save V2 que o Ctrl+S já grava (C2), nunca o save antigo")
	var config_object: Variant = config
	t.check(config_object is RefCounted and not (config_object is Node), "flag em objeto local (sem Autoload)")
	_write_save("flag.json", _saved_state())
	var main := _main(t)
	var before := _json(main)
	var sandbox := _sandbox(t)
	var result := SaveV2RuntimeLoadCoordinator.new(SaveV2OperationalConfig.create(false, _path("flag.json"))).load_into_runtime(main, sandbox)
	t.check(result.status == SaveV2RuntimeLoadResult.DISABLED and sandbox.created == 0 and _json(main) == before, "2. flag OFF: DISABLED, nada lido, nada tocado")


# 3, 5–7. caminho habilitado
func _test_success(t) -> void:
	t.section("C7 — Load V2 operacional (sucesso)")
	var saved := _saved_state()
	_write_save("success.json", saved)
	var main := _main(t)
	var sandbox := _sandbox(t)
	var result := _coordinator("success.json").load_into_runtime(main, sandbox)
	t.check(result.is_success(), "3. SUCCESS (%s)" % result.describe())
	t.check(Array(result.steps) == ["flag", "rehearsal", "snapshot", "rollback_rehearsal", "apply", "post_restore"], "5–7. ordem: %s" % " → ".join(PackedStringArray(result.steps)))
	t.check(result.rehearsal.get("status") == "SUCCESS" and result.rehearsal.get("checksum_verified") == true, "rehearsal C6 completo (checksum validado) antes do jogo principal")
	t.check(sandbox.created == 1 and sandbox.is_discarded() and sandbox.spawned.size() == 1 and sandbox.spawned[0].is_discarded(), "sandboxes de rehearsal e de rollback descartados")
	t.check(_projection_equals(main, saved), "7. runtime principal == GameState salvo (0 diferenças persistentes)")
	t.check(result.post_restore.get("persistent_equal") == true and result.post_restore.get("functional_equal") == true, "7. validação pós-restore: persistente + funcional")
	t.check(main.player.global_position == saved.player.position and main.player.global_rotation.is_equal_approx(saved.player.rotation), "posição exata e rotação")
	t.check(main.dialogue_state.last_choice("vardhelm_intro", "start") == "learn" and (main.npcs[GameIdCatalog.NPC_DURN] as NPCController).interaction_enabled, "diálogo e NPC restaurados")
	t.check(not main.world_state.has_flag("vardhelm_first_echo_complete") and main.quest_state.active.has("vardhelm_first_echo") and main.quest_state.completed.is_empty(), "estado mais avançado revertido para o salvo")
	t.check(not main.operational_load_authorized, "autorização operacional revogada ao terminar")
	t.check(result.state != null and GameStateComparator.compare(result.state, saved).is_equal(), "resultado traz o GameState carregado")


# 4. snapshot
func _test_snapshot(t) -> void:
	t.section("C7 — snapshot transitório")
	var main := _main(t)
	var snapshot := SaveV2RuntimeSnapshot.capture(main)
	t.check(snapshot.quarantined.is_empty() and snapshot.state.validate().is_empty(), "snapshot representável como GameState")
	t.check(snapshot.state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and snapshot.state.dialogue.get_choice(GameIdCatalog.DIALOGUE_INTRO, "start") == "leave" and not snapshot.state.npcs.is_interaction_enabled(GameIdCatalog.NPC_DURN), "cobre world, consequences, quests, dialogue, NPC")
	t.check(snapshot.player_position == main.player.global_position and snapshot.state.player.scenario_id == GameIdCatalog.SCENARIO_VARDHELM, "cobre player (posição, rotação, cenário)")
	t.check(snapshot.differences(main).is_empty(), "runtime == snapshot logo após a captura")
	var source := _code_only(FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_snapshot.gd"))
	t.check(not source.contains("FileAccess") and not source.contains("user://") and not source.contains("SaveV2Service"), "snapshot nunca é gravado (sem arquivo, sem user://)")
	var odd := _main(t)
	odd.world_state.add_memory("memoria_desconhecida")
	var before := _json(odd)
	_write_save("odd.json", _saved_state())
	var rejected := _coordinator("odd.json").load_into_runtime(odd, _sandbox(t))
	t.check(rejected.status == SaveV2RuntimeLoadResult.RESTORE_REJECTED and rejected.code == SaveV2RuntimeLoadResult.CODE_SNAPSHOT_NOT_REVERSIBLE and _json(odd) == before, "runtime não representável: rollback impossível -> recusado sem tocar em nada")


# 22–26, 33–34. falhas antes do apply: runtime intocado
func _test_rehearsal_failures(t) -> void:
	t.section("C7 — falhas antes do apply (runtime intocado)")
	_write_save("tampered.json", _saved_state())
	var text := FileAccess.get_file_as_string(_path("tampered.json")).replace("\"learn\"", "\"leave\"")
	var file := FileAccess.open(_path("tampered.json"), FileAccess.WRITE)
	file.store_string(text)
	file.close()
	_expect_untouched(t, "tampered.json", null, "ok", SaveV2RuntimeLoadResult.VALIDATION_FAILURE, SaveV2Errors.INVALID_CHECKSUM, "22. checksum corrompido")
	_expect_untouched(t, "missing.json", null, "ok", SaveV2RuntimeLoadResult.LOAD_FAILURE, SaveV2Errors.FILE_NOT_FOUND, "arquivo inexistente")
	var envelope := SaveV2Envelope.create(_saved_state().to_dict(), SaveV2Envelope.make_metadata("shadow", FIXED_CLOCK, FIXED_CLOCK))
	envelope["state"]["quests"] = "inválido"
	envelope[SaveV2Checksum.FIELD] = SaveV2Checksum.compute(envelope)
	var invalid := FileAccess.open(_path("invalid.json"), FileAccess.WRITE)
	invalid.store_string(SaveV2Serializer.to_file_text(envelope))
	invalid.close()
	_expect_untouched(t, "invalid.json", null, "ok", SaveV2RuntimeLoadResult.VALIDATION_FAILURE, SaveV2Errors.INVALID_STATE, "23. save inválido")
	var unknown := _saved_state()
	unknown.quests.start_quest("quest.outro.desconhecida")
	_write_save("unknown.json", unknown)
	_expect_untouched(t, "unknown.json", null, "ok", SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_UNKNOWN_ID, "24. ID desconhecido")
	_write_save("ok.json", _saved_state())
	var registry := RuntimeRestoreAdapterRegistry.create_default()
	registry.register(FailingAdapter.new())
	_expect_untouched(t, "ok.json", registry, "ok", SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_ADAPTER_FAILURE, "25. falha de adapter (no rehearsal)")
	_expect_untouched(t, "ok.json", null, "no_derivations", SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_DERIVATION_FAILURE, "26. falha de derivação (no rehearsal)")


func _expect_untouched(t, file_name: String, registry: RuntimeRestoreAdapterRegistry, mode: String, status: String, code: String, label: String) -> void:
	var main := _main(t)
	var before := _json(main)
	var result := _coordinator(file_name, registry).load_into_runtime(main, _sandbox(t, mode))
	t.check(result.status == status and result.code == code, "%s: %s/%s (%s)" % [label, status, code, result.describe()])
	t.check(_json(main) == before and not result.snapshot_taken and not result.main_touched and result.rollback_status.is_empty(), "%s: jogo principal intocado, sem snapshot, sem rollback" % label)


# 8, 9, 27, 35. falha no apply -> rollback
func _test_apply_failure(t) -> void:
	t.section("C7 — falha no apply -> rollback")
	_write_save("apply.json", _saved_state())
	var main := _main(t)
	var before := _json(main)
	var coordinator := _coordinator("apply.json")
	coordinator.fault_injection_apply_step = "echo"
	var result := coordinator.load_into_runtime(main, _sandbox(t))
	t.check(result.status == SaveV2RuntimeLoadResult.APPLY_FAILURE and result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS, "27. APPLY_FAILURE + ROLLBACK_SUCCESS (%s)" % result.describe())
	t.check(result.snapshot_taken and result.main_touched, "o apply chegou a escrever no jogo principal (snapshot tirado antes)")
	t.check(_json(main) == before, "9/35. rollback: runtime == snapshot (0 diferenças)")
	t.check(result.state == null and not result.is_success(), "sem falso sucesso")
	t.check(not main.operational_load_authorized, "autorização revogada após rollback")


func _test_post_restore_mismatch(t) -> void:
	t.section("C7 — divergência pós-restore -> rollback")
	_write_save("stray.json", _saved_state())
	var registry := RuntimeRestoreAdapterRegistry.create_default()
	registry.register(StrayAdapter.new())
	var main := _main(t)
	var before := _json(main)
	var result := _coordinator("stray.json", registry).load_into_runtime(main, _sandbox(t))
	t.check(result.status == SaveV2RuntimeLoadResult.POST_RESTORE_MISMATCH and result.code == SaveV2RuntimeLoadResult.CODE_PERSISTENT_MISMATCH and result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS, "POST_RESTORE_MISMATCH detectado + rollback (%s)" % result.describe())
	t.check(_json(main) == before and not main.world_state.has_flag("stray_after_apply"), "runtime == snapshot após rollback")


# 10, 28. rollback falha
func _test_rollback_failure(t) -> void:
	t.section("C7 — falha do rollback")
	_write_save("rollback.json", _saved_state())
	var main := _main(t)
	var coordinator := _coordinator("rollback.json")
	coordinator.fault_injection_apply_step = "echo"
	coordinator.fault_injection_rollback_step = "quests"
	var result := coordinator.load_into_runtime(main, _sandbox(t))
	t.check(result.status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE and result.rollback_status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE, "28. ROLLBACK_FAILURE (%s)" % result.describe())
	t.check(result.original_failure.get("status") == SaveV2RuntimeLoadResult.APPLY_FAILURE and not result.rollback_details.is_empty(), "falha original + falha do rollback registradas")
	t.check(not result.is_success() and result.state == null, "sem falso sucesso")
	var source := _code_only(FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_load_coordinator.gd"))
	t.check(not source.contains("SaveService") and not source.contains("load_game("), "sem fallback para o load antigo")


func _test_guards(t) -> void:
	t.section("C7 — guardas do restaurador")
	var main := build_targets(t.root, _nodes)
	var restorer := GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default())
	var before := _json(main)
	var unauthorized := restorer.apply_to_runtime(_saved_state(), main)
	t.check(not unauthorized.success and unauthorized.applied.is_empty() and _json(main) == before, "apply_to_runtime sem autorização: recusado")
	t.check(not restorer.apply_to_sandbox(_saved_state(), main).success, "apply_to_sandbox continua recusando o jogo principal")
	var sandbox_targets := build_targets(t.root, _nodes)
	sandbox_targets.is_sandbox = true
	sandbox_targets.operational_load_authorized = true
	t.check(not restorer.apply_to_runtime(_saved_state(), sandbox_targets).success, "apply_to_runtime recusa alvo sandbox")
	var bad := _coordinator("ok.json").load_into_runtime(sandbox_targets, _sandbox(t))
	t.check(bad.status == SaveV2RuntimeLoadResult.RESTORE_REJECTED and bad.code == SaveV2RuntimeLoadResult.CODE_INVALID_MAIN_TARGET, "coordenador recusa alvo principal declarado sandbox")


# 31, 32. idempotência e duplicação
func _test_idempotence(t) -> void:
	t.section("C7 — idempotência e duplicação")
	_write_save("twice.json", _saved_state())
	var main := _main(t)
	var first := _coordinator("twice.json").load_into_runtime(main, _sandbox(t))
	var after_first := _json(main)
	var second := _coordinator("twice.json").load_into_runtime(main, _sandbox(t))
	t.check(first.is_success() and second.is_success() and _json(main) == after_first, "32. Load V2 repetido: mesmo estado")
	t.check(main.world_state.memories.count("vardhelm_heard_echo") == 1 and Array(main.world_state.memories).size() == 1 and main.quest_state.active.size() == 1 and (main.dialogue_state.choices["vardhelm_intro"] as Dictionary).size() == 1, "31. sem duplicação de consequência, memória, quest ou escolha")


func _test_no_events(t) -> void:
	t.section("C7 — sem eventos novos")
	var events: Array = []
	for type in ["restore_started", "restore_completed", "restore_failed"]:
		if GameEventCatalog.is_known_type(type):
			events.append(type)
	t.check(events.is_empty(), "restore_* fora do EventCatalog")
	var source := _code_only(FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_load_coordinator.gd"))
	# C8: o coordenador publica somente game_loaded (existente), após SUCCESS.
	t.check(not source.contains("restore_started") and not source.contains("restore_failed") and not source.contains("restore_completed") and not source.contains("GAME_SAVED"), "coordenador de load não cria eventos novos (só game_loaded após SUCCESS)")


func _code_only(source: String) -> String:
	var lines: PackedStringArray = []
	for line in source.split("\n"):
		var code := line.strip_edges()
		if not code.begins_with("#"):
			lines.append(code)
	return "\n".join(lines)
