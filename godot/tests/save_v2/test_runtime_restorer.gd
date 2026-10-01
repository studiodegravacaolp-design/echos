extends RefCounted

## Bloco C3 — GameStateRuntimeRestorer: diagnóstico e sandbox com alvos de
## runtime reais (WorldState, QuestState, Player Node3D, NPCController), sem a
## cena de Vardhelm. Itens 1–20, 22 e 23.

const NPC_SCENE_PATH := "res://scenes/npc/npc.tscn"

var _nodes: Array[Node] = []


func _full_state() -> GameState:
	var state := GameState.new()
	state.player.position = Vector3(2.25, 0.5, -3.75)
	state.player.rotation = Vector3(0.0, 1.2, 0.0)
	# Flags espelho como o recorder as grava (consequências e observações).
	for flag in ["vardhelm_heard_echo", "vardhelm_first_echo_complete", "observation_maintenance_board_seen", "observation_tool_rack_seen"]:
		state.world.set_flag(flag)
	state.world.set_value("counter", 2)
	state.world.apply_consequence("consequence.vardhelm.heard_echo", "dialogue", "dialogue.vardhelm.intro")
	state.world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first")
	state.world.discover_observation("observation.vardhelm.maintenance_board")
	state.world.discover_observation("observation.vardhelm.tool_rack")
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.quests.set_objective_complete("quest.vardhelm.first_echo", "observe")
	state.quests.complete_quest("quest.vardhelm.first_echo")
	state.memory.resolve_echo("echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.maintenance_board", "observation", "observation.vardhelm.maintenance_board")
	state.memory.register_memory("memory.vardhelm.tool_rack", "observation", "observation.vardhelm.tool_rack")
	state.npcs.set_interaction_enabled("npc.vardhelm.durn", false)
	state.dialogue.mark_completed("dialogue.vardhelm.intro")
	state.dialogue.record_choice("dialogue.vardhelm.intro", "start", "learn")
	return state


## Sandbox descartável: WorldState/QuestState novos, Player e NPC reais.
func _sandbox(t) -> RuntimeRestoreTargets:
	var targets := RuntimeRestoreTargets.new()
	targets.is_sandbox = true
	targets.scenario_id = "scenario.vardhelm"
	var player := Node3D.new()
	player.name = "SandboxPlayer"
	t.root.add_child(player)
	_nodes.append(player)
	targets.player = player
	targets.world_state = WorldState.new()
	targets.quest_state = QuestState.new()
	var npc := (load(NPC_SCENE_PATH) as PackedScene).instantiate() as NPCController
	npc.npc_id = "vardhelm.durn"
	_nodes.append(npc)
	targets.npcs = {"npc.vardhelm.durn": npc}
	return targets


func _targets_json(targets: RuntimeRestoreTargets) -> String:
	var npc := targets.npcs.get("npc.vardhelm.durn") as NPCController
	return JSON.stringify([targets.world_state.flags, targets.world_state.values, Array(targets.world_state.memories),
		targets.quest_state.active, targets.quest_state.completed, targets.quest_state.objective_progress,
		targets.player.global_position, targets.player.global_rotation, npc.interaction_enabled if npc != null else null], "", true)


func run(t) -> void:
	_test_empty_plan(t)
	_test_matrix(t)
	_test_diagnostic_no_mutation(t)
	_test_sandbox_apply(t)
	_test_unsupported(t)
	_test_partial_and_refusals(t)
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()


# 1. plano vazio
func _test_empty_plan(t) -> void:
	t.section("C3 — plano de um GameState vazio")
	var plan := GameStateRuntimeRestorer.new().diagnose(GameState.new())
	var sources: Array[String] = []
	for item in plan.items:
		sources.append(String(item["source_path"]))
	t.check(Array(sources) == ["state_version", "player.location.scenario_id", "player.location.position", "player.location.rotation", "npcs (sem registro)", "(derivado) environment_states", "progression"], "GameState vazio: só itens estruturais (%s)" % ", ".join(sources))
	t.check(plan.counts()["unsupported"] == 0, "nenhum unsupported")
	t.check(plan.find("progression")["status"] == "not_implemented", "progression = not_implemented")


# matriz (2–15)
func _test_matrix(t) -> void:
	t.section("C3 — matriz de restauração")
	var plan := GameStateRuntimeRestorer.new().diagnose(_full_state())
	var expect := {
		"player.location.scenario_id": ["verify", "supported"],
		"player.location.position": ["restore", "supported"],
		"player.location.rotation": ["restore", "supported"],
		"world.flags.vardhelm_heard_echo": ["restore", "supported"],
		"world.values.counter": ["restore", "supported"],
		"world.consequences.consequence.vardhelm.first_echo_complete": ["restore", "supported"],
		"world.consequences.consequence.vardhelm.first_echo_complete.source": ["not_applied", "requires_adapter"],
		"world.observations.observation.vardhelm.maintenance_board": ["restore", "supported"],
		"world.observations.observation.vardhelm.maintenance_board.node": ["not_applied", "requires_adapter"],
		"quests.quest.vardhelm.first_echo.status": ["restore", "supported"],
		"quests.quest.vardhelm.first_echo.objectives.observe": ["restore", "supported"],
		"quests.quest.vardhelm.first_echo.presentation": ["not_applied", "requires_adapter"],
		"memory.echoes.echo.vardhelm.first": ["not_applied", "requires_adapter"],
		"memory.memories.memory.vardhelm.first_echo": ["not_applied", "requires_adapter"],
		"memory.memories.memory.vardhelm.tool_rack": ["not_applied", "requires_adapter"],
		"npcs.npc.vardhelm.durn.interaction_enabled": ["restore", "supported"],
		"dialogue.completed.dialogue.vardhelm.intro": ["not_applied", "requires_adapter"],
		"dialogue.choices.dialogue.vardhelm.intro.start": ["not_applied", "requires_adapter"],
		"progression": ["not_applied", "not_implemented"],
	}
	for source in expect:
		var item := plan.find(source)
		t.check(not item.is_empty() and item["action"] == expect[source][0] and item["status"] == expect[source][1], "%s -> %s / %s" % [source, expect[source][0], expect[source][1]])
	for item in plan.items:
		t.check(not String(item["destination"]).is_empty() and RestorePlan.STATUSES.has(item["status"]), "%s tem destino e status explícitos" % item["source_path"])
	var consequence := plan.find("world.consequences.consequence.vardhelm.first_echo_complete")
	t.check(String(consequence["destination"]).contains("WorldState.memories[vardhelm_first_echo_complete]"), "consequência -> representação existente do runtime (flag + memories legado)")
	print("   info plano completo: ", plan.counts())


# 16. diagnóstico sem mutação · 20. GameState preservado
func _test_diagnostic_no_mutation(t) -> void:
	t.section("C3 — diagnóstico não muta nada")
	var state := _full_state()
	var before := JSON.stringify(state.to_dict(), "", true)
	var targets := _sandbox(t)
	var targets_before := _targets_json(targets)
	GameStateRuntimeRestorer.new().diagnose(state)
	t.check(JSON.stringify(state.to_dict(), "", true) == before, "16. GameState intacto após diagnose")
	t.check(_targets_json(targets) == targets_before, "16. runtime (alvos) intacto após diagnose")


# 2–13, 17, 18, 20, 22, 23
func _test_sandbox_apply(t) -> void:
	t.section("C3 — sandbox: aplicar e comparar")
	var state := _full_state()
	var original := JSON.stringify(state.to_dict(), "", true)
	var targets := _sandbox(t)
	var restorer := GameStateRuntimeRestorer.new()
	var before := restorer.compare_with_runtime(state, targets)
	t.check(not before["missing_in_right"].is_empty(), "18. antes: runtime vazio diverge do GameState (%s)" % before["summary"])
	var result := restorer.apply_to_sandbox(state, targets)
	t.check(result.success and not result.partial_failure and result.errors.is_empty(), "17. restauração em sandbox concluída (%s)" % str(result.errors))
	t.check(Array(result.completed_steps) == RestorePlan.STEPS, "ordem de dependência respeitada (%s)" % str(result.completed_steps))
	t.check(JSON.stringify(state.to_dict(), "", true) == original, "20. GameState original preservado")
	# Player
	t.check(targets.player.global_position == state.player.position, "3. posição X/Y/Z exata")
	t.check(targets.player.global_rotation.is_equal_approx(state.player.rotation), "4. rotação X/Y/Z equivalente")
	t.check(result.applied.any(func(item): return item["source_path"] == "player.location.scenario_id"), "2. cenário verificado (scenario.vardhelm)")
	# World
	var world := targets.world_state
	t.check(world.has_flag("vardhelm_heard_echo") and world.has_flag("observation_maintenance_board_seen"), "5. flags restauradas")
	t.check(world.get_value("counter") == 2.0, "6. values restaurados")
	t.check(Array(world.memories) == ["vardhelm_heard_echo", "vardhelm_first_echo_complete"], "7. consequências na representação do runtime (flag + WorldState.memories legado)")
	t.check(world.has_flag("observation_tool_rack_seen") and world.get_value("observation.tool_rack.seen") == true, "8. observação restaurada como flag + value (representação do slice)")
	t.check(not Array(world.memories).has("vardhelm_memory_tool_rack") and not Array(world.memories).has("vardhelm_first_echo_memory"), "memórias não foram injetadas no WorldState (sem armazenamento inventado)")
	# Quests
	t.check(targets.quest_state.is_completed("vardhelm_first_echo") and not targets.quest_state.active.has("vardhelm_first_echo"), "9. status da quest restaurado")
	t.check(targets.quest_state.is_objective_complete("vardhelm_first_echo", "observe"), "10. objetivos restaurados")
	# NPC
	t.check(not (targets.npcs["npc.vardhelm.durn"] as NPCController).interaction_enabled, "13. npc.vardhelm.durn interaction_enabled restaurado")
	# 22/23 — projeção do runtime restaurado × GameState
	var after := result.differences
	print("   info depois: ", after["summary"])
	t.check(after["differences"].is_empty() and after["missing_in_left"].is_empty() and after["unexpected_ids"].is_empty(), "18/23. depois: nenhuma diferença de valor, nada extra no runtime")
	var only_expected := true
	for path in after["missing_in_right"]:
		var p := String(path)
		if not (p.begins_with("dialogue.") or p.begins_with("npcs.")):
			only_expected = false
	t.check(only_expected, "22. projeção do runtime restaurado == GameState, exceto dialogue (sem adapter) e npcs (projetor não lê NPC)")
	var projected := GameStateProjector.project(world, targets.quest_state, targets.player).state
	t.check(projected.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and not projected.memory.has_memory("consequence.vardhelm.first_echo_complete"), "7. first_echo_complete continua consequência, não memória")
	t.check(projected.memory.memories.get("memory.vardhelm.first_echo", {}) == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "11. memória do Primeiro Eco reproduzida (origem echo)")
	t.check(projected.memory.is_fragment("memory.vardhelm.maintenance_board") and projected.memory.is_fragment("memory.vardhelm.tool_rack"), "12. fragmentos reproduzidos com origem observation (sem composição)")
	t.check(result.requires_adapter.size() > 0 and result.not_implemented.size() == 1, "15. requires_adapter e not_implemented reportados no resultado")
	t.check(JSON.parse_string(JSON.stringify(result.to_dict())) is Dictionary, "RestoreResult é JSON-safe")

	# GameState sem a flag espelho de uma observação: o restaurador escreve a
	# representação completa do runtime (flag + value) e a comparação REPORTA a
	# flag extra — não a esconde.
	var no_mirror := _full_state()
	no_mirror.world.flags.erase("observation_tool_rack_seen")
	var mirror_targets := _sandbox(t)
	var mirror_result := GameStateRuntimeRestorer.new().apply_to_sandbox(no_mirror, mirror_targets)
	t.check(mirror_result.success and Array(mirror_result.differences["missing_in_left"]) == ["world.flags.observation_tool_rack_seen"], "flag espelho ausente no GameState aparece como diferença explícita")


# 14. unsupported
func _test_unsupported(t) -> void:
	t.section("C3 — campos sem destino")
	var state := GameState.new()
	state.quests.start_quest("quest.outro.misterio")
	state.world.apply_consequence("consequence.outro.x")
	state.world.discover_observation("observation.outro.y")
	state.npcs.set_interaction_enabled("npc.outro.z", false)
	var plan := GameStateRuntimeRestorer.new().diagnose(state)
	var unsupported: Array[String] = []
	for item in plan.by_status("unsupported"):
		unsupported.append(String(item["source_path"]))
	t.check(unsupported.has("quests.quest.outro.misterio") and unsupported.has("world.consequences.consequence.outro.x") and unsupported.has("world.observations.observation.outro.y") and unsupported.has("npcs.npc.outro.z.interaction_enabled"), "14. IDs sem destino no runtime classificados como unsupported (%s)" % ", ".join(unsupported))
	var targets := _sandbox(t)
	var result := GameStateRuntimeRestorer.new().apply_to_sandbox(state, targets)
	t.check(result.success and result.unsupported.size() == 4, "unsupported não é aplicado nem descartado em silêncio")
	t.check(targets.quest_state.active.is_empty() and targets.world_state.memories.is_empty(), "nada inventado para campos unsupported")
	t.check(result.warnings.any(func(w): return String(w).contains("npc.outro.z")), "NPC sem alvo gera aviso")


# 19. estado parcial · recusas sem mutação
func _test_partial_and_refusals(t) -> void:
	t.section("C3 — falha parcial e recusas")
	var state := _full_state()
	var targets := _sandbox(t)
	var restorer := GameStateRuntimeRestorer.new()
	restorer.fault_injection_step = "quests"
	var result := restorer.apply_to_sandbox(state, targets)
	t.check(not result.success and result.partial_failure, "19. falha no meio: partial_failure")
	t.check(Array(result.completed_steps) == ["scenario", "player", "world", "consequences", "observations"], "passos concluídos antes da falha registrados")
	t.check(result.warnings.any(func(w): return String(w).contains("descartar o sandbox")), "resultado manda descartar o sandbox")
	t.check(not result.differences.is_empty() and not result.differences["missing_in_right"].is_empty(), "comparação mostra o estado incompleto")

	var main := _sandbox(t)
	main.is_sandbox = false
	var before := _targets_json(main)
	var refused := GameStateRuntimeRestorer.new().apply_to_sandbox(state, main)
	t.check(not refused.success and not refused.partial_failure and refused.applied.is_empty() and refused.errors[0].contains("não é sandbox"), "alvo não-sandbox (jogo principal) é recusado")
	t.check(_targets_json(main) == before, "alvo recusado não é mutado")

	var incomplete := _sandbox(t)
	incomplete.quest_state = null
	var before_incomplete := JSON.stringify([incomplete.world_state.flags, incomplete.player.global_position], "", true)
	var preflight := GameStateRuntimeRestorer.new().apply_to_sandbox(state, incomplete)
	t.check(not preflight.success and not preflight.partial_failure and preflight.applied.is_empty(), "alvo incompleto: erro na pré-checagem, sem restauração parcial")
	t.check(JSON.stringify([incomplete.world_state.flags, incomplete.player.global_position], "", true) == before_incomplete, "pré-checagem não muta nada")

	var wrong := _sandbox(t)
	wrong.scenario_id = "scenario.outro"
	var mismatch := GameStateRuntimeRestorer.new().apply_to_sandbox(state, wrong)
	t.check(not mismatch.success and mismatch.completed_steps.is_empty() and mismatch.errors[0].contains("cenário"), "cenário diferente: falha no primeiro passo, nada aplicado")
