extends RefCounted

## Testes da migração preparatória (formato atual do SaveService -> GameState).
## Cobre os itens 9, 10, 11 e 13 da especificação do Bloco A2.


## Payload no formato real gravado hoje pelo SaveService (A0 §14), após o
## fluxo completo: diálogo com Durn (learn), Primeiro Eco e uma observação.
func _current_save_payload() -> Dictionary:
	return {
		"version": 2,
		"language": "pt-BR",
		"world": {
			"flags": {
				"vardhelm_heard_echo": true,
				"vardhelm_first_echo_complete": true,
				"observation_maintenance_board_seen": true,
			},
			"values": {"observation.maintenance_board.seen": true},
			"memories": ["vardhelm_heard_echo", "vardhelm_first_echo_complete"],
		},
		"quests": {
			"active": {},
			"completed": {"vardhelm_first_echo": true},
			"objective_progress": {"vardhelm_first_echo": {"observe": true}},
		},
		"player": {"position": [1.5, 0.25, -2.0], "rotation": [0.0, 0.75, 0.0]},
	}


func run(t) -> void:
	_test_consequence_separated_from_memory(t)
	_test_observation_separated_from_consequence(t)
	_test_first_echo_registers_memory(t)
	_test_unknown_ids_quarantined(t)
	_test_full_payload(t)
	_test_input_not_mutated(t)
	_test_json_text_payload(t)
	_test_invalid_payloads(t)


# 9. consequência separada de memória
func _test_consequence_separated_from_memory(t) -> void:
	t.section("9. Consequência separada de memória")
	var result := GameStateMigrator.migrate_legacy_payload({
		"world": {"flags": {}, "values": {}, "memories": ["vardhelm_heard_echo", "vardhelm_memory_tool_rack"]},
	})
	var state := result.state
	t.check(state.world.is_consequence_applied("consequence.vardhelm.heard_echo"), "ID de consequência em memories -> world.consequences")
	t.check(not state.memory.has_memory("consequence.vardhelm.heard_echo") and not state.memory.has_memory("vardhelm_heard_echo"), "consequência NÃO vira memória")
	t.check(state.world.get_consequence("consequence.vardhelm.heard_echo").get("source_type") == "dialogue", "fonte da consequência vem do catálogo (diálogo)")
	t.check(state.memory.has_memory("memory.vardhelm.tool_rack"), "ID de memória em memories -> memory.memories")
	t.check(not state.world.is_consequence_applied("memory.vardhelm.tool_rack"), "memória NÃO vira consequência")
	t.check(state.memory.is_fragment("memory.vardhelm.tool_rack"), "memória de observação é fragmento")
	t.check(state.world.observations.is_empty(), "registrar memória não inventa observação")


# 10. observação separada de consequência
func _test_observation_separated_from_consequence(t) -> void:
	t.section("10. Observação separada de consequência")
	var result := GameStateMigrator.migrate_legacy_payload({
		"world": {
			"flags": {"observation_sealed_panel_seen": true},
			"values": {"observation.sealed_panel.seen": true},
			"memories": [],
		},
	})
	var state := result.state
	t.check(state.world.is_observation_discovered("observation.vardhelm.sealed_panel"), "flag/value legado -> world.observations")
	t.check(state.world.consequences.is_empty(), "observação NÃO gera consequência")
	t.check(state.world.has_flag("observation_sealed_panel_seen"), "flag legada preservada como espelho de compatibilidade")
	t.check(not state.world.values.has("observation.sealed_panel.seen"), "value duplicado representado em observations, não em values")
	t.check(state.memory.has_memory("memory.vardhelm.sealed_panel") and state.memory.is_fragment("memory.vardhelm.sealed_panel"), "observação descoberta produz fragmento (decisão #1)")
	t.check(state.memory.echoes.is_empty(), "fragmento não resolve Eco")


# 11. Primeiro Eco gera registro de memória
func _test_first_echo_registers_memory(t) -> void:
	t.section("11. Primeiro Eco gera memória")
	var by_consequence := GameStateMigrator.migrate_legacy_payload({
		"world": {"flags": {"vardhelm_first_echo_complete": true}, "values": {}, "memories": ["vardhelm_first_echo_complete"]},
	}).state
	t.check(by_consequence.memory.is_echo_resolved("echo.vardhelm.first"), "consequência do Eco -> echo resolved")
	t.check(by_consequence.memory.has_memory("memory.vardhelm.first_echo"), "memory.vardhelm.first_echo registrada (decisão #2)")
	t.check(by_consequence.memory.memories["memory.vardhelm.first_echo"] == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "origem = echo.vardhelm.first")
	t.check(by_consequence.world.get_consequence("consequence.vardhelm.first_echo_complete").get("source_id") == "echo.vardhelm.first", "fonte da consequência = Eco (decisão #4)")

	var by_quest := GameStateMigrator.migrate_legacy_payload({
		"quests": {"active": {}, "completed": {"vardhelm_first_echo": true}, "objective_progress": {}},
	}).state
	t.check(by_quest.memory.is_echo_resolved("echo.vardhelm.first"), "quest concluída -> echo resolved (regra do slice)")
	t.check(by_quest.memory.has_memory("memory.vardhelm.first_echo"), "memória do Eco registrada")
	t.check(not by_quest.world.is_consequence_applied("consequence.vardhelm.first_echo_complete"), "quest NÃO aplica a consequência de novo (decisão #4)")

	var none := GameStateMigrator.migrate_legacy_payload({"quests": {"active": {"vardhelm_first_echo": true}}}).state
	t.check(not none.memory.is_echo_resolved("echo.vardhelm.first") and none.memory.memories.is_empty(), "quest só ativa: Eco não resolvido, sem memória")


# 13. IDs desconhecidos vão para quarentena
func _test_unknown_ids_quarantined(t) -> void:
	t.section("13. IDs desconhecidos -> quarentena")
	var result := GameStateMigrator.migrate_legacy_payload({
		"world": {
			"flags": {"mystery_flag": true, "observation_unknown_spot_seen": true, "bad_flag": "sim"},
			"values": {"observation.unknown_spot.seen": true, "nested": {"a": 1}},
			"memories": ["mystery_memory", 42],
		},
		"quests": {"active": {"quest_ghost": true}, "completed": {}, "objective_progress": {}},
		"extra_root": {"x": 1},
	})
	var q := result.quarantined
	t.check(result.has_quarantine(), "quarentena não vazia")
	t.check(q.has("world.memories") and q["world.memories"].has("mystery_memory"), "memória desconhecida em quarentena")
	t.check(q["world.memories"].has(42), "entrada não-String em quarentena")
	t.check(q.has("quests.active.quest_ghost"), "quest desconhecida em quarentena")
	t.check(q.has("world.values.observation.unknown_spot.seen"), "value de observação desconhecida em quarentena")
	t.check(q.has("world.values.nested"), "value não escalar em quarentena")
	t.check(q.has("world.flags.bad_flag"), "flag não booleana em quarentena")
	t.check(q.has("extra_root"), "campo raiz desconhecido em quarentena")
	t.check(result.state.world.has_flag("mystery_flag"), "flag desconhecida preservada (flags mantêm nomes atuais)")
	t.check(result.state.world.has_flag("observation_unknown_spot_seen"), "flag de observação desconhecida preservada")
	t.check(not result.warnings.is_empty(), "avisos registrados")
	t.check(result.state.validate().is_empty(), "GameState resultante continua válido")


func _test_full_payload(t) -> void:
	t.section("Payload completo do save atual")
	var result := GameStateMigrator.migrate_legacy_payload(_current_save_payload())
	var state := result.state
	t.check(result.source_version == 2, "versão de origem registrada (2)")
	t.check(result.excluded.get("language") == "pt-BR", "language excluído do GameState e preservado no resultado")
	t.check(not result.has_quarantine(), "nada em quarentena no fluxo real conhecido")
	t.check(state.player.position == Vector3(1.5, 0.25, -2.0) and state.player.rotation == Vector3(0.0, 0.75, 0.0), "posição e rotação exatas")
	t.check(state.player.scenario_id == "scenario.vardhelm", "scenario_id inferido")
	t.check(state.quests.get_status("quest.vardhelm.first_echo") == "completed", "quest concluída")
	t.check(state.quests.is_objective_complete("quest.vardhelm.first_echo", "observe"), "objetivo observe")
	t.check(state.world.consequences.size() == 2, "2 consequências")
	t.check(state.world.observations.size() == 1, "1 observação")
	t.check(state.memory.memories.size() == 2, "2 memórias: Primeiro Eco + fragmento do quadro")
	t.check(state.memory.is_echo_resolved("echo.vardhelm.first"), "Primeiro Eco resolvido")
	t.check(state.dialogue.completed.is_empty() and state.dialogue.choices.is_empty(), "DialogueState não inferido")
	t.check(state.npcs.to_dict().is_empty(), "sem registros de NPC")
	t.check(state.validate().is_empty(), "GameState migrado é válido")


func _test_input_not_mutated(t) -> void:
	t.section("Migração não altera a entrada")
	var payload := _current_save_payload()
	var before := JSON.stringify(payload, "", true)
	GameStateMigrator.migrate_legacy_payload(payload)
	t.check(JSON.stringify(payload, "", true) == before, "payload de entrada intacto")


func _test_json_text_payload(t) -> void:
	t.section("Payload vindo de texto JSON (caminho do bug de load)")
	var parsed: Variant = JSON.parse_string(JSON.stringify(_current_save_payload()))
	var result := GameStateMigrator.migrate_legacy_payload(parsed)
	t.check(result.source_version == 2, "version float 2.0 aceita como 2")
	t.check(result.state.memory.memories.size() == 2, "memories (Array não tipado do JSON) convertido sem erro")
	t.check(result.state.validate().is_empty(), "resultado válido")


func _test_invalid_payloads(t) -> void:
	t.section("Entradas inválidas")
	var not_dict := GameStateMigrator.migrate_legacy_payload("texto")
	t.check(not_dict.has_quarantine() and not_dict.state.validate().is_empty(), "não-Dictionary: quarentena + GameState padrão válido")
	var bad_player := GameStateMigrator.migrate_legacy_payload({"player": {"position": [1, "a", 3], "rotation": [0, 0, 0]}})
	t.check(bad_player.quarantined.has("player.position"), "posição inválida em quarentena")
	t.check(bad_player.state.player.position == Vector3.ZERO, "posição inválida não é aplicada")
