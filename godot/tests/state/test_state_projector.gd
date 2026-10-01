extends RefCounted

## Testes do projetor somente leitura (runtime atual -> GameState).
## Usa as classes reais de runtime (WorldState, QuestState) sem cena.


func _runtime_after_first_echo() -> Array:
	# Reproduz o estado de runtime observado no A0 após Durn + Primeiro Eco +
	# observação do quadro de manutenção.
	var world := WorldState.new()
	world.set_flag("vardhelm_heard_echo", true)
	world.add_memory("vardhelm_heard_echo")
	world.set_flag("vardhelm_first_echo_complete", true)
	world.add_memory("vardhelm_first_echo_complete")
	world.set_flag("observation_maintenance_board_seen", true)
	world.set_value("observation.maintenance_board.seen", true)
	var quests := QuestState.new()
	quests.start_quest("vardhelm_first_echo")
	quests.set_objective_complete("vardhelm_first_echo", "observe")
	quests.complete_quest("vardhelm_first_echo")
	return [world, quests]


func run(t) -> void:
	_test_projection(t)
	_test_projection_is_read_only(t)
	_test_projection_without_player(t)


func _test_projection(t) -> void:
	t.section("Projetor: runtime -> GameState")
	var runtime := _runtime_after_first_echo()
	var result := GameStateProjector.project_values(runtime[0], runtime[1], Vector3(2.0, 0.25, -1.5), Vector3(0.0, 1.25, 0.0))
	var state := result.state
	t.check(state.player.position == Vector3(2.0, 0.25, -1.5), "posição convertida")
	t.check(state.player.rotation == Vector3(0.0, 1.25, 0.0), "rotação convertida")
	t.check(state.quests.get_status("quest.vardhelm.first_echo") == "completed", "quest convertida para ID canônico")
	t.check(state.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "consequência separada")
	t.check(not state.memory.has_memory("vardhelm_first_echo_complete"), "consequência não aparece como memória")
	t.check(state.world.is_observation_discovered("observation.vardhelm.maintenance_board"), "observação convertida")
	t.check(state.memory.has_memory("memory.vardhelm.first_echo"), "Primeiro Eco registrado como memória")
	t.check(state.memory.is_fragment("memory.vardhelm.maintenance_board"), "fragmento da observação registrado")
	t.check(not result.has_quarantine(), "nenhum ID do slice atual cai em quarentena")
	t.check(state.validate().is_empty(), "GameState projetado é válido")


func _test_projection_is_read_only(t) -> void:
	t.section("Projetor não altera a origem")
	var runtime := _runtime_after_first_echo()
	var world: WorldState = runtime[0]
	var quests: QuestState = runtime[1]
	world.add_memory("mystery_memory")
	var before := JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress], "", true)
	var result := GameStateProjector.project_values(world, quests, Vector3.ONE, Vector3.ZERO)
	var after := JSON.stringify([world.flags, world.values, Array(world.memories), quests.active, quests.completed, quests.objective_progress], "", true)
	t.check(before == after, "WorldState e QuestState de runtime intactos")
	t.check(world.memories.size() == 3, "WorldState.memories intacto (Array[String] tipado preservado)")
	t.check(result.quarantined.get("world.memories", []).has("mystery_memory"), "ID desconhecido do runtime preservado em quarentena")


func _test_projection_without_player(t) -> void:
	t.section("Projetor sem Player")
	var result := GameStateProjector.project(WorldState.new(), QuestState.new())
	t.check(result.state.player.position == Vector3.ZERO, "sem Player: posição padrão")
	t.check(result.warnings.size() > 0, "ausência de Player registrada como aviso")
	t.check(result.state.validate().is_empty(), "GameState válido")
