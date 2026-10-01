extends RefCounted

## Testes dos contratos de dados puros (GameState e sub-estados).
## Cobre os itens 1–8, 12, 14 e 15 da especificação do Bloco A2.

const STATE_SCRIPT_PATHS := [
	"res://scripts/state/game_state.gd",
	"res://scripts/state/game_player_state.gd",
	"res://scripts/state/game_world_state.gd",
	"res://scripts/state/game_quest_state.gd",
	"res://scripts/state/game_dialogue_state.gd",
	"res://scripts/state/game_memory_state.gd",
	"res://scripts/state/game_npc_state.gd",
	"res://scripts/state/game_state_serde.gd",
	"res://scripts/state/id_catalog.gd",
	"res://scripts/state/game_state_migrator.gd",
	"res://scripts/state/game_state_migration_result.gd",
]

const FORBIDDEN_TOKENS := [
	"Node3D", "CharacterBody3D", "Control", "SceneTree", "Timer",
	"Input", "Audio", "get_tree", "Tween", "Camera", "Label",
]


func run(t) -> void:
	_test_default_game_state(t)
	_test_player_state(t)
	_test_vector3_roundtrip(t)
	_test_world_state(t)
	_test_quest_state(t)
	_test_dialogue_state(t)
	_test_memory_state(t)
	_test_npc_state(t)
	_test_game_state_roundtrip(t)
	_test_validation_rejects_bad_data(t)
	_test_no_node_dependency(t)


# 1. GameState default
func _test_default_game_state(t) -> void:
	t.section("1. GameState default")
	var state := GameState.new()
	var data := state.to_dict()
	t.check(state.state_version == 1, "state_version = 1")
	t.check(data.keys().size() == 7, "raiz tem exatamente state_version + 6 seções")
	for key in ["player", "world", "quests", "dialogue", "memory", "npcs"]:
		t.check(data.has(key), "seção '%s' presente" % key)
	for key in ["progression", "language", "audio", "ui", "camera", "input", "session", "checksum", "slot", "metadata"]:
		t.check(not data.has(key), "'%s' fora do GameState" % key)
	t.check(state.player.scenario_id == "scenario.vardhelm", "scenario_id inicial = scenario.vardhelm")
	t.check(state.validate().is_empty(), "GameState padrão é válido")


# 2. PlayerState serialization
func _test_player_state(t) -> void:
	t.section("2. PlayerState serialization")
	var player := GamePlayerState.new()
	player.position = Vector3(1.5, 0.25, -3.0)
	player.rotation = Vector3(0.0, 0.5, 0.0)
	var data := player.to_dict()
	t.check(data.keys() == ["location"], "somente 'location' na raiz do player")
	var location: Dictionary = data["location"]
	t.check(location.keys().size() == 3, "location tem scenario_id, position, rotation")
	t.check(typeof(location["position"]) == TYPE_ARRAY and location["position"] == [1.5, 0.25, -3.0], "position serializada como [x, y, z]")
	t.check(typeof(location["rotation"]) == TYPE_ARRAY and location["rotation"] == [0.0, 0.5, 0.0], "rotation serializada como [x, y, z]")
	for forbidden in ["hp", "ep", "xp", "level", "attributes", "equipment", "inventory", "party", "skills"]:
		t.check(not data.has(forbidden) and not location.has(forbidden), "sem '%s'" % forbidden)
	var restored := GamePlayerState.from_dict(t.json_roundtrip(data))
	t.check(restored.position == player.position and restored.rotation == player.rotation, "roundtrip JSON preserva posição/rotação exatas")
	t.check(restored.scenario_id == "scenario.vardhelm", "roundtrip preserva scenario_id")
	t.check(player.validate().is_empty(), "PlayerState válido")


# 3. Vector3 -> Array -> Vector3
func _test_vector3_roundtrip(t) -> void:
	t.section("3. Vector3 -> Array -> Vector3")
	var original := Vector3(-8.5, 1.25, 5.75)
	var as_array := GameStateSerde.vector3_to_array(original)
	t.check(typeof(as_array) == TYPE_ARRAY and as_array.size() == 3, "Vector3 vira Array de 3")
	t.check(GameStateSerde.array_to_vector3(as_array) == original, "Array volta ao mesmo Vector3")
	var parsed: Variant = JSON.parse_string(JSON.stringify(as_array))
	t.check(GameStateSerde.array_to_vector3(parsed) == original, "passa por texto JSON sem perda")
	t.check(GameStateSerde.array_to_vector3([1, 2, 3]) == Vector3(1, 2, 3), "aceita inteiros e converte")
	t.check(GameStateSerde.array_to_vector3(["x", 2, 3], Vector3.ONE) == Vector3.ONE, "valor inválido cai no fallback")
	t.check(GameStateSerde.array_to_vector3([1, 2], Vector3.ONE) == Vector3.ONE, "tamanho errado cai no fallback")


# 4. WorldState serialization
func _test_world_state(t) -> void:
	t.section("4. WorldState serialization")
	var world := GameWorldState.new()
	world.set_flag("vardhelm_first_echo_complete", true)
	t.check(world.set_value("counter", 3), "value escalar aceito")
	t.check(not world.set_value("bad", [1, 2]), "value não escalar recusado")
	t.check(world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first"), "consequência aplicada")
	t.check(not world.apply_consequence("consequence.vardhelm.first_echo_complete", "quest", "quest.vardhelm.first_echo"), "segunda aplicação é recusada (idempotente)")
	t.check(world.get_consequence("consequence.vardhelm.first_echo_complete")["source_type"] == "echo", "primeira fonte (Eco) prevalece")
	t.check(world.discover_observation("observation.vardhelm.tool_rack"), "observação descoberta")
	var data := world.to_dict()
	t.check(data.keys().size() == 4, "exatamente flags, values, consequences, observations")
	t.check(not data.has("environment_states") and not data.has("memories"), "environment_states e memories fora do WorldState")
	t.check(data["consequences"]["consequence.vardhelm.first_echo_complete"]["applied"] == true, "consequência tem applied = true")
	t.check(data["observations"]["observation.vardhelm.tool_rack"] == {"discovered": true}, "observação = {discovered: true}")
	var restored := GameWorldState.from_dict(t.json_roundtrip(data))
	t.check(t.same_json(restored.to_dict(), data), "roundtrip JSON preserva o WorldState")
	t.check(restored.has_flag("vardhelm_first_echo_complete"), "flag preservada")
	t.check(world.validate().is_empty(), "WorldState válido")


# 5. QuestState serialization
func _test_quest_state(t) -> void:
	t.section("5. QuestState serialization")
	var quests := GameQuestState.new()
	t.check(quests.get_status("quest.vardhelm.first_echo") == "not_started", "quest ausente = not_started")
	t.check(quests.start_quest("quest.vardhelm.first_echo"), "start_quest")
	t.check(quests.set_objective_complete("quest.vardhelm.first_echo", "observe"), "objetivo marcado")
	t.check(not quests.set_objective_complete("quest.unknown", "observe"), "objetivo exige quest registrada")
	t.check(quests.complete_quest("quest.vardhelm.first_echo"), "complete_quest")
	t.check(not quests.start_quest("quest.vardhelm.first_echo"), "quest concluída não é reaberta")
	var data := quests.to_dict()
	t.check(data["quest.vardhelm.first_echo"] == {"status": "completed", "objectives": {"observe": true}}, "registro {status, objectives}")
	t.check(not JSON.stringify(data).contains("not_started"), "not_started nunca é serializado")
	t.check(not JSON.stringify(data).contains("reward"), "sem campo de recompensa")
	var restored := GameQuestState.from_dict(t.json_roundtrip(data))
	t.check(restored.get_status("quest.vardhelm.first_echo") == "completed", "roundtrip preserva status")
	t.check(restored.is_objective_complete("quest.vardhelm.first_echo", "observe"), "roundtrip preserva objetivo")
	t.check(quests.validate().is_empty(), "QuestState válido")


# 6. DialogueState serialization + 12. escolha salva como última escolha
func _test_dialogue_state(t) -> void:
	t.section("6/12. DialogueState + última escolha")
	var dialogue := GameDialogueState.new()
	t.check(dialogue.mark_completed("dialogue.vardhelm.intro"), "diálogo marcado como concluído")
	t.check(dialogue.record_choice("dialogue.vardhelm.intro", "start", "learn"), "primeira escolha registrada")
	t.check(dialogue.record_choice("dialogue.vardhelm.intro", "start", "leave"), "diálogo repetido: nova escolha")
	t.check(dialogue.get_choice("dialogue.vardhelm.intro", "start") == "leave", "persiste a ÚLTIMA escolha")
	var data := dialogue.to_dict()
	t.check(data == {"completed": {"dialogue.vardhelm.intro": true}, "choices": {"dialogue.vardhelm.intro": {"start": "leave"}}}, "no máximo uma escolha por ponto de decisão")
	for forbidden in ["current_entry", "current_dialogue_session", "history", "text", "speaker"]:
		t.check(not JSON.stringify(data).contains(forbidden), "sem '%s'" % forbidden)
	var restored := GameDialogueState.from_dict(t.json_roundtrip(data))
	t.check(t.same_json(restored.to_dict(), data), "roundtrip JSON preserva o DialogueState")
	t.check(dialogue.validate().is_empty(), "DialogueState válido")


# 7. MemoryState serialization
func _test_memory_state(t) -> void:
	t.section("7. MemoryState serialization")
	var memory := GameMemoryState.new()
	t.check(memory.resolve_echo("echo.vardhelm.first"), "Eco resolvido")
	t.check(memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first"), "memória de Eco registrada")
	t.check(memory.register_memory("memory.vardhelm.tool_rack", "observation", "observation.vardhelm.tool_rack"), "fragmento de observação registrado")
	t.check(not memory.register_memory("memory.vardhelm.x", "journal", "x"), "origem desconhecida recusada")
	t.check(memory.is_fragment("memory.vardhelm.tool_rack"), "origem observation = fragmento")
	t.check(not memory.is_fragment("memory.vardhelm.first_echo"), "memória de Eco não é fragmento")
	var data := memory.to_dict()
	t.check(data.keys().size() == 2, "exatamente echoes e memories")
	t.check(data["echoes"]["echo.vardhelm.first"] == {"status": "resolved"}, "Eco = {status: resolved}")
	t.check(data["memories"]["memory.vardhelm.first_echo"] == {"source_type": "echo", "source_id": "echo.vardhelm.first"}, "memória = {source_type, source_id}")
	for forbidden in ["category", "title", "journal", "order", "timestamp", "composed"]:
		t.check(not JSON.stringify(data).contains(forbidden), "sem '%s'" % forbidden)
	var restored := GameMemoryState.from_dict(t.json_roundtrip(data))
	t.check(t.same_json(restored.to_dict(), data), "roundtrip JSON preserva o MemoryState")
	t.check(memory.validate().is_empty(), "MemoryState válido")


# 8. NPCState serialization
func _test_npc_state(t) -> void:
	t.section("8. NPCState serialization")
	var npcs := GameNPCState.new()
	t.check(npcs.to_dict().is_empty(), "nenhum NPC com registro obrigatório")
	t.check(npcs.is_interaction_enabled("npc.vardhelm.durn"), "Durn sem registro = padrão (interação ativa)")
	npcs.set_interaction_enabled("npc.vardhelm.durn", false)
	t.check(npcs.to_dict() == {"npc.vardhelm.durn": {"interaction_enabled": false}}, "registro criado só ao diferir do padrão")
	var restored := GameNPCState.from_dict(t.json_roundtrip(npcs.to_dict()))
	t.check(not restored.is_interaction_enabled("npc.vardhelm.durn"), "roundtrip preserva o registro")
	npcs.set_interaction_enabled("npc.vardhelm.durn", true)
	t.check(not npcs.has_record("npc.vardhelm.durn"), "voltar ao padrão remove o registro")
	t.check(npcs.validate().is_empty(), "NPCState válido")


# 14. GameState pode ser reconstruído de Dictionary
func _test_game_state_roundtrip(t) -> void:
	t.section("14. GameState reconstruído de Dictionary")
	var state := GameState.new()
	state.player.position = Vector3(2.5, 0.25, -1.0)
	state.player.rotation = Vector3(0.0, 1.0, 0.0)
	state.world.set_flag("vardhelm_heard_echo")
	state.world.apply_consequence("consequence.vardhelm.heard_echo", "dialogue", "dialogue.vardhelm.intro")
	state.world.discover_observation("observation.vardhelm.sealed_panel")
	state.quests.start_quest("quest.vardhelm.first_echo")
	state.dialogue.mark_completed("dialogue.vardhelm.intro")
	state.dialogue.record_choice("dialogue.vardhelm.intro", "start", "learn")
	state.memory.register_memory("memory.vardhelm.sealed_panel", "observation", "observation.vardhelm.sealed_panel")
	state.npcs.set_interaction_enabled("npc.vardhelm.durn", false)
	var data := state.to_dict()
	var parsed: Dictionary = t.json_roundtrip(data)
	t.check(GameState.validate_dict(parsed).is_empty(), "Dictionary vindo de JSON é válido")
	var restored := GameState.from_dict(parsed)
	t.check(t.same_json(restored.to_dict(), data), "GameState reconstruído é idêntico")
	t.check(restored.state_version == 1, "state_version restaurado como int")
	t.check(restored.memory.memories is Dictionary and restored.world.flags is Dictionary, "coleções reconstruídas por conversão explícita")


func _test_validation_rejects_bad_data(t) -> void:
	t.section("Validação mínima de estrutura")
	var data := GameState.new().to_dict()
	data["progression"] = {}
	t.check(not GameState.validate_dict(data).is_empty(), "seção reservada 'progression' é rejeitada")
	data = GameState.new().to_dict()
	data["state_version"] = 2
	t.check(not GameState.validate_dict(data).is_empty(), "state_version não suportada é rejeitada")
	data = GameState.new().to_dict()
	data["language"] = "pt-BR"
	t.check(not GameState.validate_dict(data).is_empty(), "language no GameState é rejeitado")
	t.check(not GameWorldState.validate_dict({"flags": {"a": "sim"}, "values": {}, "consequences": {}, "observations": {}}).is_empty(), "flag não booleana é rejeitada (sem erro de script)")
	t.check(not GameWorldState.validate_dict({"flags": {}, "values": {}, "consequences": {"c": {"applied": "true"}}, "observations": {}}).is_empty(), "applied não booleano é rejeitado")
	t.check(not GameQuestState.validate_dict({"q": {"status": "failed", "objectives": {}}}).is_empty(), "status 'failed' é rejeitado")
	t.check(not GameMemoryState.validate_dict({"echoes": {"e": {"status": 1}}, "memories": {}}).is_empty(), "status de Eco inválido é rejeitado")
	t.check(not GamePlayerState.validate_dict({"location": {"scenario_id": "", "position": [0, 0], "rotation": [0, 0, 0]}}).is_empty(), "player malformado é rejeitado")
	var tolerant := GameState.from_dict({"state_version": "x", "world": {"flags": {"a": "sim"}}, "memory": {"echoes": {"e": {"status": 1}}}})
	t.check(tolerant.world.flags.is_empty() and tolerant.memory.echoes.is_empty(), "from_dict ignora entradas malformadas sem quebrar")


# 15. nenhum Node/SceneTree é necessário para criar os estados
func _test_no_node_dependency(t) -> void:
	t.section("15. Estados sem Node/SceneTree")
	var instances := [
		GameState.new(), GamePlayerState.new(), GameWorldState.new(), GameQuestState.new(),
		GameDialogueState.new(), GameMemoryState.new(), GameNPCState.new(),
	]
	for instance in instances:
		t.check(instance is RefCounted and not (instance is Node), "%s é RefCounted, não Node" % instance.get_script().get_global_name())
	for path in STATE_SCRIPT_PATHS:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			t.check(false, "%s legível" % path)
			continue
		var hits: Array[String] = []
		for line in file.get_as_text().split("\n"):
			var code := line.split("#")[0]
			for token in FORBIDDEN_TOKENS:
				if code.contains(token):
					hits.append(token)
		t.check(hits.is_empty(), "%s sem dependência de Node/UI/Input/Audio/SceneTree %s" % [path.get_file(), str(hits) if not hits.is_empty() else ""])
