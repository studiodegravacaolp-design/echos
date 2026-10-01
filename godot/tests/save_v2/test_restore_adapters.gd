extends RefCounted

## Bloco C4 — adapters de restauração, isolados (sem a cena de Vardhelm).
## Alvos de runtime reais (WorldState, QuestState, Player, NPC, observações e
## Eco); desde o C5 as derivações chegam por um RuntimeStateDerivationContract
## de teste (FakeDerivations) — o real (VardhelmRuntimeStateProvider) é
## exercitado em test_restore_adapters_vardhelm.gd / test_runtime_contracts_vardhelm.gd.


## Contrato de derivação de teste sobre nós reais. `echo_mode`: "ok" (regra de
## derivação da experiência), "broken" (deriva sem efeito) ou "none" (indisponível).
class FakeDerivations extends RuntimeStateDerivationContract:
	var observations := {}
	var echo: EchoMemoryInteractable
	var world: WorldState
	var quests: QuestState
	var echo_mode := "ok"
	var presentation_available := true
	var calls := {"echo": 0, "quest": 0, "environment": 0}

	func observation_ids() -> Array[String]:
		var ids: Array[String] = []
		for id in observations:
			ids.append(String(id))
		return ids

	func derive_observation_state(observation_id: String, discovered: bool) -> bool:
		var node := observations.get(observation_id) as EnvironmentalObservation
		if node == null:
			return false
		node.revealed = discovered
		node.memory_registered = discovered and not node.memory_id.is_empty()
		return true

	func describe_observation(observation_id: String) -> Dictionary:
		var node := observations.get(observation_id) as EnvironmentalObservation
		return {} if node == null else {"revealed": node.revealed, "fragment_registered": node.memory_registered}

	func echo_ids() -> Array[String]:
		var ids: Array[String] = []
		if echo != null:
			ids.append("echo.vardhelm.first")
		return ids

	func derive_echo_state() -> bool:
		if echo_mode == "none":
			return false
		calls["echo"] += 1
		if echo_mode == "ok":
			var completed := world.has_flag("vardhelm_first_echo_complete") or quests.is_completed("vardhelm_first_echo")
			var active := quests.active.has("vardhelm_first_echo") or quests.objective_progress.has("vardhelm_first_echo")
			echo.revealed = completed
			echo.interaction_enabled = active and not completed
		return true

	func describe_echo(echo_id: String) -> Dictionary:
		if echo == null or echo_id != "echo.vardhelm.first":
			return {}
		return {"revealed": echo.revealed, "interaction_enabled": echo.interaction_enabled}

	func derive_quest_presentation() -> bool:
		if not presentation_available:
			return false
		calls["quest"] += 1
		return true

	func describe_quest_presentation(quest_id: String) -> Dictionary:
		return {"completion_presented": quests.is_completed(GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id))}

	func derive_environment_state() -> bool:
		if not presentation_available:
			return false
		calls["environment"] += 1
		return true

const NPC_SCENE_PATH := "res://scenes/npc/npc.tscn"
const OBSERVATION_DEFS := {
	"observation.vardhelm.maintenance_board": ["maintenance_board", "vardhelm_memory_maintenance_board"],
	"observation.vardhelm.sealed_panel": ["sealed_panel", "vardhelm_memory_sealed_panel"],
	"observation.vardhelm.tool_rack": ["tool_rack", "vardhelm_memory_tool_rack"],
}

var _nodes: Array[Node] = []
var _calls := {}


func _state(with_echo: bool = true) -> GameState:
	var state := GameState.new()
	state.player.position = Vector3(1.0, 0.5, -2.0)
	state.world.set_flag("vardhelm_heard_echo")
	state.world.apply_consequence("consequence.vardhelm.heard_echo", "dialogue", "dialogue.vardhelm.intro")
	state.world.set_flag("observation_maintenance_board_seen")
	state.world.discover_observation("observation.vardhelm.maintenance_board")
	state.memory.register_memory("memory.vardhelm.maintenance_board", "observation", "observation.vardhelm.maintenance_board")
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.dialogue.mark_completed("dialogue.vardhelm.intro")
	state.dialogue.record_choice("dialogue.vardhelm.intro", "start", "learn")
	if with_echo:
		state.world.set_flag("vardhelm_first_echo_complete")
		state.world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first")
		state.quests.set_objective_complete("quest.vardhelm.first_echo", "observe")
		state.quests.complete_quest("quest.vardhelm.first_echo")
		state.memory.resolve_echo("echo.vardhelm.first")
		state.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	return state


## Sandbox com todos os alvos do C4. `echo_mode`: "ok", "broken" ou "none".
func _sandbox(t, echo_mode: String = "ok") -> RuntimeRestoreTargets:
	var targets := RuntimeRestoreTargets.new()
	targets.is_sandbox = true
	targets.scenario_id = "scenario.vardhelm"
	var player := Node3D.new()
	t.root.add_child(player)
	_nodes.append(player)
	targets.player = player
	targets.world_state = WorldState.new()
	targets.quest_state = QuestState.new()
	var npc := (load(NPC_SCENE_PATH) as PackedScene).instantiate() as NPCController
	npc.npc_id = "vardhelm.durn"
	_nodes.append(npc)
	targets.npcs = {"npc.vardhelm.durn": npc}
	var fake := FakeDerivations.new()
	for observation_id in OBSERVATION_DEFS:
		var node := EnvironmentalObservation.new()
		node.observation_id = OBSERVATION_DEFS[observation_id][0]
		node.memory_id = OBSERVATION_DEFS[observation_id][1]
		_nodes.append(node)
		fake.observations[observation_id] = node
	fake.echo = EchoMemoryInteractable.new()
	_nodes.append(fake.echo)
	fake.world = targets.world_state
	fake.quests = targets.quest_state
	fake.echo_mode = echo_mode
	_calls = fake.calls
	targets.derivations = fake
	return targets


func _fake(targets: RuntimeRestoreTargets) -> FakeDerivations:
	return targets.derivations as FakeDerivations


func _restorer() -> GameStateRuntimeRestorer:
	return GameStateRuntimeRestorer.new(RuntimeRestoreAdapterRegistry.create_default())


func _adapter_result(result: RestoreResult, adapter_id: String) -> Dictionary:
	for entry in result.adapter_results:
		if entry["adapter"] == adapter_id:
			return entry
	return {}


func run(t) -> void:
	_test_registry(t)
	_test_contract(t)
	_test_full_sandbox(t)
	_test_memory_cases(t)
	_test_observation_cases(t)
	_test_consequence_source(t)
	_test_echo_cases(t)
	_test_dialogue(t)
	_test_presentation_missing(t)
	_test_npc_and_unsupported(t)
	_test_no_mutation(t)
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()


# 1. registry
func _test_registry(t) -> void:
	t.section("C4 — registry")
	var registry := RuntimeRestoreAdapterRegistry.create_default()
	t.check(Array(registry.ids()) == ["consequence", "observation", "echo", "memory", "dialogue", "quest_presentation", "environment_presentation"], "registry padrão com os 7 adapters, em ordem (%s)" % str(registry.ids()))
	t.check(not registry.register(EchoRestoreAdapter.new()), "ID repetido recusado")
	t.check(not registry.register(null), "adapter nulo recusado")
	t.check(registry.adapters_for("presentation").size() == 2 and registry.adapters_for("player").is_empty(), "adapters por passo (player/quests não são reimplementados)")
	var registry_object: Variant = registry
	t.check(registry_object is RefCounted and not (registry_object is Node), "registry é objeto comum (não Autoload/singleton)")
	t.check(RuntimeRestoreAdapterRegistry.create_default() != registry, "cada restaurador escolhe seu registry")
	t.check(GameStateRuntimeRestorer.new().registry.all().is_empty(), "restaurador sem registry = comportamento do C3")


# 2. contrato
func _test_contract(t) -> void:
	t.section("C4 — contrato dos adapters")
	var state := _state()
	var targets := _sandbox(t)
	var plan := _restorer().diagnose(state)
	for adapter in RuntimeRestoreAdapterRegistry.create_default().all():
		t.check(not adapter.adapter_id().is_empty() and RestorePlan.STEPS.has(adapter.step()), "%s: id e passo válidos (%s)" % [adapter.adapter_id(), adapter.step()])
		var result: Variant = adapter.apply(state, plan, targets)
		t.check(result is RestoreAdapterResult, "%s: apply devolve RestoreAdapterResult" % adapter.adapter_id())
		var data: Dictionary = (result as RestoreAdapterResult).to_dict()
		for key in ["adapter", "step", "ok", "supported", "applied", "requires_adapter", "unsupported", "warnings", "errors"]:
			if not data.has(key):
				t.check(false, "%s: to_dict sem '%s'" % [adapter.adapter_id(), key])
	t.check(RestorePlan.STATUSES.has("adapter-supported"), "status adapter-supported disponível")


# 3–10, 14, 15 — sandbox completo
func _test_full_sandbox(t) -> void:
	t.section("C4 — sandbox com adapters")
	var state := _state()
	var original := JSON.stringify(state.to_dict(), "", true)
	var targets := _sandbox(t)
	var result := _restorer().apply_to_sandbox(state, targets)
	t.check(result.success and not result.partial_failure, "restauração com adapters concluída (%s)" % str(result.errors))
	t.check(Array(result.completed_steps) == RestorePlan.STEPS, "15. ordem: %s" % " → ".join(PackedStringArray(result.completed_steps)))
	var order: Array = []
	for entry in result.adapter_results:
		order.append(entry["adapter"])
	t.check(order == ["consequence", "observation", "echo", "memory", "dialogue", "quest_presentation", "environment_presentation"], "adapters executados na ordem dos passos")
	t.check(JSON.stringify(state.to_dict(), "", true) == original, "GameState de origem preservado")
	var echo := _fake(targets).echo
	t.check(echo.revealed and not echo.interaction_enabled and _calls["echo"] == 1, "6. Eco resolvido reconstruído pela derivação (revealed, interação desligada)")
	var node := _fake(targets).observations["observation.vardhelm.maintenance_board"] as EnvironmentalObservation
	t.check(node.revealed and node.memory_registered, "4. nó da observação: revealed + memory_registered")
	t.check(not (_fake(targets).observations["observation.vardhelm.tool_rack"] as EnvironmentalObservation).revealed, "observação ausente do GameState fica no padrão (não inventada)")
	t.check(_calls["quest"] == 1 and _calls["environment"] == 1, "8/9. derivações de apresentação acionadas uma vez")
	var projected := GameStateProjector.project(targets.world_state, targets.quest_state, targets.player).state
	t.check(projected.world.is_consequence_applied("consequence.vardhelm.first_echo_complete") and not projected.memory.has_memory("consequence.vardhelm.first_echo_complete"), "caso 1: consequence continua consequence")
	t.check(projected.memory.memories.get("memory.vardhelm.first_echo", {}) == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "caso 1: memory continua memória (origem echo)")
	t.check(projected.memory.is_fragment("memory.vardhelm.maintenance_board"), "caso 2: fragmento permanece fragmento")
	t.check(not Array(targets.world_state.memories).has("vardhelm_first_echo_memory") and not Array(targets.world_state.memories).has("vardhelm_memory_maintenance_board"), "3. nenhuma memória gravada em WorldState.memories")
	var counts := result.plan.counts()
	# C5: o diálogo passou a ter destino (DialogueRuntimeState) -> 10 adapter-supported, 0 requires_adapter.
	t.check(counts["adapter-supported"] == 10 and counts["requires_adapter"] == 0 and counts["not_implemented"] == 1 and counts["unsupported"] == 0, "12. plano: 10 adapter-supported (C5: + diálogo), 0 requires_adapter, 1 not_implemented (%s)" % str(counts))
	var diff := result.differences
	var missing_ok := true
	for path in diff["missing_in_right"]:
		if not String(path).begins_with("dialogue."):
			missing_ok = false
	t.check(diff["differences"].is_empty() and diff["missing_in_left"].is_empty() and missing_ok, "14. runtime restaurado × GameState: só o diálogo falta (sandbox sem destino de diálogo) (%s)" % diff["summary"])
	# Interagir de novo com a observação restaurada não produz fragmento de novo.
	var emitted := [0]
	node.memory_fragment_discovered.connect(func(_a, _b, _c, _d): emitted[0] += 1)
	node.interact(Node3D.new())
	t.check(emitted[0] == 0, "4. nó restaurado não emite o fragmento outra vez (mesmo comportamento pós-interação)")


func _test_memory_cases(t) -> void:
	t.section("C4 — memória")
	var state := _state()
	state.memory.register_memory("memory.vardhelm.tool_rack", "observation", "observation.vardhelm.tool_rack")
	var plan := _restorer().diagnose(state)
	t.check(plan.find("memory.memories.memory.vardhelm.first_echo")["status"] == "adapter-supported", "3. memória do Primeiro Eco: adapter-supported (Eco derivável)")
	t.check(plan.find("memory.memories.memory.vardhelm.maintenance_board")["status"] == "adapter-supported", "3. fragmento com observação restaurável: adapter-supported")
	t.check(plan.find("memory.memories.memory.vardhelm.tool_rack")["status"] == "requires_adapter", "fragmento SEM a observação de origem: requires_adapter (observação não é inventada)")
	var orphan := GameState.new()
	orphan.memory.resolve_echo("echo.vardhelm.first")
	orphan.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	var orphan_plan := _restorer().diagnose(orphan)
	t.check(orphan_plan.find("memory.memories.memory.vardhelm.first_echo")["status"] == "requires_adapter" and orphan_plan.find("memory.echoes.echo.vardhelm.first")["status"] == "requires_adapter", "Eco/memória sem consequência nem quest: requires_adapter")
	var targets := _sandbox(t)
	var result := _restorer().apply_to_sandbox(orphan, targets)
	t.check(result.success and not _fake(targets).echo.revealed, "Eco sem base de derivação não é forçado no runtime")


func _test_observation_cases(t) -> void:
	t.section("C4 — observações")
	var empty := GameState.new()
	var targets := _sandbox(t)
	var result := _restorer().apply_to_sandbox(empty, targets)
	var any_revealed := false
	for id in _fake(targets).observations:
		if (_fake(targets).observations[id] as EnvironmentalObservation).revealed:
			any_revealed = true
	t.check(result.success and not any_revealed and targets.world_state.flags.is_empty() and targets.world_state.values.is_empty(), "caso 3: sem world.observations nada é inventado")
	var no_mirror := _state()
	no_mirror.world.flags.erase("observation_maintenance_board_seen")
	var mirror_targets := _sandbox(t)
	var mirror := _restorer().apply_to_sandbox(no_mirror, mirror_targets)
	t.check(mirror.success and (_fake(mirror_targets).observations["observation.vardhelm.maintenance_board"] as EnvironmentalObservation).revealed, "caso 4: observação sem flag espelho é reconstruída (representação segura: flag + value + nó)")
	t.check(Array(mirror.differences["missing_in_left"]) == ["world.flags.observation_maintenance_board_seen"], "caso 4: a flag adicionada aparece como diferença explícita (não mascarada)")
	var partial_nodes := _sandbox(t)
	_fake(partial_nodes).observations.erase("observation.vardhelm.maintenance_board")
	var no_node := _restorer().apply_to_sandbox(_state(), partial_nodes)
	var observation_result := _adapter_result(no_node, "observation")
	t.check(no_node.success and Array(observation_result["requires_adapter"]).has("world.observations.observation.vardhelm.maintenance_board.node"), "nó ausente no sandbox: requires_adapter com aviso")


# 5. consequência
func _test_consequence_source(t) -> void:
	t.section("C4 — consequências")
	var state := _state()
	var plan := _restorer().diagnose(state)
	t.check(plan.find("world.consequences.consequence.vardhelm.first_echo_complete.source")["status"] == "adapter-supported", "fonte canônica: adapter-supported")
	var odd := _state()
	odd.world.consequences["consequence.vardhelm.heard_echo"]["source_type"] = "quest"
	odd.world.consequences["consequence.vardhelm.heard_echo"]["source_id"] = "quest.vardhelm.first_echo"
	var odd_plan := _restorer().diagnose(odd)
	t.check(odd_plan.find("world.consequences.consequence.vardhelm.heard_echo.source")["status"] == "requires_adapter", "fonte divergente do catálogo: requires_adapter (explícito)")
	var targets := _sandbox(t)
	_restorer().apply_to_sandbox(state, targets)
	t.check(targets.world_state.memories.count("vardhelm_first_echo_complete") == 1 and targets.world_state.has_flag("vardhelm_first_echo_complete"), "consequência reconhecida pelo runtime exatamente uma vez (sem duplicar)")


# 6 e 13. Eco
func _test_echo_cases(t) -> void:
	t.section("C4 — Eco")
	var active_targets := _sandbox(t)
	var active := _restorer().apply_to_sandbox(_state(false), active_targets)
	var echo := _fake(active_targets).echo
	t.check(active.success and not echo.revealed and echo.interaction_enabled, "Eco não resolvido com quest ativa: oculto e interativo")
	var none_targets := _sandbox(t)
	_restorer().apply_to_sandbox(GameState.new(), none_targets)
	var idle := _fake(none_targets).echo
	t.check(not idle.revealed and not idle.interaction_enabled, "Eco sem quest: oculto e não interativo")
	var missing_targets := _sandbox(t, "none")
	var missing := _restorer().apply_to_sandbox(_state(), missing_targets)
	t.check(missing.success and Array(_adapter_result(missing, "echo")["requires_adapter"]).has("memory.echoes.echo.vardhelm.first"), "sem derivação disponível: requires_adapter (não falha)")
	var broken_targets := _sandbox(t, "broken")
	var broken := _restorer().apply_to_sandbox(_state(), broken_targets)
	t.check(not broken.success and broken.partial_failure, "13. derivação que não reproduz o Eco: partial_failure")
	t.check(broken.completed_steps.back() == "quests" and broken.errors[0].begins_with("echo:"), "falha no passo echo, passos anteriores listados")
	t.check(broken.warnings.any(func(w): return String(w).contains("descartar o sandbox")), "resultado parcial não é tratado como restauração completa")


# 7. diálogo
func _test_dialogue(t) -> void:
	t.section("C4 — diálogo")
	var state := _state()
	var plan := _restorer().diagnose(state)
	# C5: o plano classifica o diálogo como adapter-supported (destino DialogueRuntimeState);
	# este sandbox NÃO fornece destino de diálogo -> requires_adapter no resultado, com motivo.
	t.check(plan.find("dialogue.completed.dialogue.vardhelm.intro")["status"] == "adapter-supported", "caso 5 (C5): dialogue.completed = adapter-supported no plano")
	t.check(plan.find("dialogue.choices.dialogue.vardhelm.intro.start")["status"] == "adapter-supported", "dialogue.choices = adapter-supported no plano (C5)")
	var result := _restorer().apply_to_sandbox(state, _sandbox(t))
	var dialogue_result := _adapter_result(result, "dialogue")
	t.check(result.success and Array(dialogue_result["requires_adapter"]).size() == 2 and Array(dialogue_result["applied"]).is_empty(), "caso 5: sem destino no sandbox -> requires_adapter (não mascarado)")
	t.check(state.dialogue.is_completed("dialogue.vardhelm.intro") and state.dialogue.get_choice("dialogue.vardhelm.intro", "start") == "learn", "informação de diálogo não é descartada")
	t.check(result.warnings.any(func(w): return String(w).contains("dialogue: 2 registro(s) mantidos") and String(w).contains("preservada no GameState")), "adapter informa o motivo e que a informação segue no GameState")


func _test_presentation_missing(t) -> void:
	t.section("C4 — apresentação sem derivação disponível")
	var targets := _sandbox(t)
	_fake(targets).presentation_available = false
	var result := _restorer().apply_to_sandbox(_state(), targets)
	t.check(result.success and Array(_adapter_result(result, "quest_presentation")["requires_adapter"]).size() == 1 and Array(_adapter_result(result, "environment_presentation")["requires_adapter"]).size() == 1, "8/9. sem derivação: requires_adapter, sem falha")


# 10 e 11
func _test_npc_and_unsupported(t) -> void:
	t.section("C4 — NPC e unsupported")
	var state := _state()
	state.npcs.set_interaction_enabled("npc.vardhelm.durn", false)
	var targets := _sandbox(t)
	_restorer().apply_to_sandbox(state, targets)
	t.check(not (targets.npcs["npc.vardhelm.durn"] as NPCController).interaction_enabled, "10. NPC com estado persistido restaurado")
	var default_targets := _sandbox(t)
	(default_targets.npcs["npc.vardhelm.durn"] as NPCController).set_interaction_enabled(false)
	_restorer().apply_to_sandbox(_state(), default_targets)
	t.check((default_targets.npcs["npc.vardhelm.durn"] as NPCController).interaction_enabled, "10. NPC sem estado persistido volta ao padrão")
	var unknown := GameState.new()
	unknown.quests.start_quest("quest.outro.x")
	unknown.world.discover_observation("observation.outro.y")
	var plan := _restorer().diagnose(unknown)
	t.check(plan.counts()["unsupported"] == 2 and plan.find("world.observations.observation.outro.y.node").is_empty(), "11. unsupported continua unsupported (adapters não promovem IDs sem destino)")


# 16. sem mutação
func _test_no_mutation(t) -> void:
	t.section("C4 — sem mutação fora do sandbox")
	var state := _state()
	var main := _sandbox(t)
	main.is_sandbox = false
	var echo := _fake(main).echo
	var before := JSON.stringify([main.world_state.flags, Array(main.world_state.memories), main.quest_state.completed, echo.revealed, _calls], "", true)
	_restorer().diagnose(state)
	var refused := _restorer().apply_to_sandbox(state, main)
	t.check(not refused.success and refused.adapter_results.is_empty(), "alvo não-sandbox: nenhum adapter executado")
	t.check(JSON.stringify([main.world_state.flags, Array(main.world_state.memories), main.quest_state.completed, echo.revealed, _calls], "", true) == before, "16. diagnóstico + recusa não mutam nada (nem acionam derivações)")
