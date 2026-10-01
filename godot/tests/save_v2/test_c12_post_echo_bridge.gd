extends RefCounted

## Bloco C12 — continuidade narrativa pós-Primeiro Eco (headless, determinístico).
##   Eco → mundo reage → Durn reage uma vez (sem explicar o Eco) → pista (painel selado)
##   → nova investigação curta (quest vardhelm_sealed_panel).
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c12.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const AFTER_ECHO_PATH := "res://data/dialogue/vardhelm_after_echo.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const INTRO := "vardhelm_intro"
const AFTER := "vardhelm_after_echo"
const FIRST_QUEST := "vardhelm_first_echo"
const FOLLOWUP := "vardhelm_sealed_panel"
## Durn não explica o Eco, a memória, a cosmologia nem as figuras do mundo.
const FORBIDDEN := ["eco", "memória", "lembr", "aethel", "aetheris", "asterion", "cinzento", "fenômeno", "origem", "cosmo", "impossível"]


class SpySaveService extends SaveService:
	var calls := 0

	func load_game(_w: WorldState, _q: QuestState, _p: Node3D = null) -> Dictionary:
		calls += 1
		return {}

	func save_game(_w: WorldState, _q: QuestState, _l: String, _p: Node3D = null) -> bool:
		calls += 1
		return true


var _events: Array = []


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _key(t, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	t.root.push_input(event)


func _buttons(slice: VardhelmVerticalSlice) -> Array:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	return buttons


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	(_buttons(slice)[index] as Button).pressed.emit()


func _continue_to_end(slice: VardhelmVerticalSlice) -> void:
	var guard := 0
	while slice.dialogue_controller.is_active() and _buttons(slice).is_empty() and guard < 20:
		slice.dialogue_box.continue_button.pressed.emit()
		guard += 1


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _new_game(t) -> Array:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	var spy := SpySaveService.new()
	game.save_service = spy
	game.player.set_physics_process(false)
	game.player.global_position = SAVE_POSITION
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type))
	return [game, spy]


func _count(type: String) -> int:
	return _events.filter(func(e): return e == type).size()


func _session_id(game: VardhelmVerticalSlice) -> String:
	var session := game.dialogue_controller.current_session
	return session.dialogue.dialogue_id if session != null and session.dialogue != null else ""


func _entry_id(game: VardhelmVerticalSlice) -> String:
	var session := game.dialogue_controller.current_session
	return session.current_entry_id if session != null else ""


func _text(game: VardhelmVerticalSlice, key: String) -> String:
	return game.localization.tr_key(key)


## Conversa inicial (C10.5), escolha "learn" → quest do Eco ativa.
func _intro(game: VardhelmVerticalSlice) -> void:
	game._npc_interactable.interact(game.player)
	_press_choice(game, 0)
	_continue_to_end(game)


## Conversa pós-Eco completa: escolhas por índice em "start" e "noticed".
func _after_echo(game: VardhelmVerticalSlice, first: int, second: int) -> void:
	game._npc_interactable.interact(game.player)
	_press_choice(game, first)
	_press_choice(game, second)
	_continue_to_end(game)


func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	var active: Array = slice.quest_controller.states.active.keys()
	active.sort()
	var completed: Array = slice.quest_controller.states.completed.keys()
	completed.sort()
	return {
		"echo": [slice.echo.revealed, slice.echo.interaction_enabled, (slice.echo.get_node("Visual") as MeshInstance3D).visible],
		"banner": slice.completion_banner.visible, "objective": slice.objective_label.text,
		"environment": env, "observations": observations, "npc": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
		"quests": [active, completed],
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_data(t)
	_test_before_and_after(t)
	_test_save_load(t)
	_test_legacy_quest_only(t)
	_isolate(t)
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	if backup != null:
		var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
		file.store_string(String(backup))
		file.close()
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _test_data(t) -> void:
	t.section("C12 — dados: diálogo pós-Eco só com chaves, sem explicar o Eco")
	var catalog: Dictionary = JSON_LOADER.read_dictionary(LOCALE_PATH)
	var dialogue: DialogueData = JSON_LOADER.load_dialogue(AFTER_ECHO_PATH)
	var keys: Array = []
	var ids: Array = []
	for entry: DialogueEntry in dialogue.entries:
		ids.append(entry.entry_id)
		keys.append(entry.text)
		for choice: DialogueChoice in entry.choices:
			keys.append(choice.text_key)
			t.check(choice.consequences.is_empty(), "escolha %s sem consequência (não duplica/alter a consequência do Eco)" % choice.choice_id)
	keys.append_array(["quest.vardhelm.sealed_panel.title", "quest.vardhelm.sealed_panel.objective.listen", "quest.vardhelm.sealed_panel.done"])
	var missing := keys.filter(func(k): return not catalog.has(k))
	t.check(dialogue.is_valid() and ids == ["start", "noticed", "dont_know", "clue", "closing"] and missing.is_empty(), "entradas %s; todos os textos em data/localization (faltando: %s)" % [str(ids), str(missing)])
	var found: Array = []
	for key in keys:
		var text := String(catalog.get(key, "")).to_lower()
		for word in FORBIDDEN:
			if text.contains(word):
				found.append("%s:%s" % [key, word])
	t.check(found.is_empty(), "nenhuma fala explica Eco/memória/Aethel/Asterion/Homem Cinzento/origem/cosmologia (%s)" % str(found))
	t.check(GameIdCatalog.canonical_id(GameIdCatalog.KIND_DIALOGUE, AFTER) == "dialogue.vardhelm.after_echo" and GameIdCatalog.canonical_id(GameIdCatalog.KIND_QUEST, FOLLOWUP) == "quest.vardhelm.sealed_panel", "IDs canônicos no GameIdCatalog (persistíveis pelo Save V2)")


func _test_before_and_after(t) -> void:
	t.section("C12 — Durn antes/depois do Eco; reação única; pista; nova investigação")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == INTRO and game.dialogue_box.text_label.text == "...Você também sentiu isso?", "antes do Eco: Durn abre a conversa inicial (inalterada)")
	_press_choice(game, 0)
	_continue_to_end(game)
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == INTRO, "Eco ainda não resolvido: Durn continua na conversa inicial (sem reação pós-Eco)")
	_press_choice(game, 0)
	_continue_to_end(game)
	t.check(not game.quest_controller.states.active.has(FOLLOWUP) and _count("quest_started") == 1, "antes do Eco: nenhuma nova investigação")

	game.echo.interact(game.player)
	t.check(game.completion_banner.visible and game.quest_controller.states.is_completed(FIRST_QUEST), "Eco resolvido: mundo reage (banner, quest concluída)")
	var before := _events.size()
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == AFTER and _entry_id(game) == "start" and game.dialogue_box.text_label.text == _text(game, "dialogue.vardhelm.after_echo.start") and game.dialogue_box.speaker_label.text == "Durn", "Primeiro Eco desbloqueia a reação: Durn abre a conversa pós-Eco (\"%s\")" % game.dialogue_box.text_label.text)
	_press_choice(game, 1)
	t.check(_entry_id(game) == "noticed", "escolha \"%s\" → Durn percebe" % _text(game, "dialogue.vardhelm.after_echo.choice.unsure"))
	_press_choice(game, 0)
	t.check(game.dialogue_box.text_label.text == "Não.", "\"Você sabe o que era?\" → \"Não.\" (Durn não explica)")
	game.dialogue_box.continue_button.pressed.emit()
	t.check(_entry_id(game) == "clue" and game.dialogue_box.text_label.text.contains("painel selado"), "pista concreta: o painel selado")
	_continue_to_end(game)
	var bridge := _events.slice(before)
	t.check(not game.dialogue_controller.is_active() and game.dialogue_controller.persistent_state.is_completed(AFTER), "conversa pós-Eco concluída e registrada no DialogueRuntimeState")
	t.check(game.dialogue_controller.persistent_state.last_choice(AFTER, "start") == "unsure" and game.dialogue_controller.persistent_state.last_choice(AFTER, "noticed") == "ask", "escolhas registradas (start=unsure, noticed=ask)")
	t.check(game.quest_controller.states.active.has(FOLLOWUP) and game.objective_label.text == _text(game, "quest.vardhelm.sealed_panel.objective.listen") and not game.completion_banner.visible, "nova investigação: objetivo \"%s\"" % game.objective_label.text)
	t.check(bridge.count("dialogue_completed") == 1 and bridge.count("quest_started") == 1 and bridge.count("consequence_applied") == 0 and bridge.count("memory_recovered") == 0, "eventos da conversa pós-Eco sem duplicação (%s)" % str(bridge))

	# Não repete: da segunda vez em diante, só o lembrete da pista.
	before = _events.size()
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == AFTER and _entry_id(game) == "clue" and _buttons(game).is_empty(), "conversa pós-Eco não se repete: Durn só lembra a pista (entrada clue, sem escolhas)")
	_continue_to_end(game)
	t.check(not game.dialogue_controller.is_active() and game.dialogue_controller.persistent_state.last_choice(AFTER, "start") == "unsure", "lembrete não altera as escolhas")
	var reminder := _events.slice(before)
	t.check(reminder.count("quest_started") == 0 and reminder.count("quest_completed") == 0 and reminder.count("consequence_applied") == 0, "lembrete não reinicia a investigação (%s)" % str(reminder))

	# Pista → investigação: examinar o painel selado.
	before = _events.size()
	_observation(game, "sealed_panel").interact(game.player)
	t.check(game.observation_text.text == _text(game, "observation.sealed_panel.after_echo"), "painel selado: \"%s\"" % game.observation_text.text)
	t.check(game.quest_controller.states.is_completed(FOLLOWUP) and game.objective_label.text == _text(game, "quest.vardhelm.sealed_panel.done"), "investigação concluída: \"%s\"" % game.objective_label.text)
	_observation(game, "sealed_panel").interact(game.player)
	var panel := _events.slice(before)
	t.check(panel.count("quest_completed") == 1 and panel.count("consequence_applied") == 0, "examinar de novo não conclui outra vez (%s)" % str(panel))
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == "vardhelm_after_panel" and _entry_id(game) == "heard", "depois da investigação Durn não repete a pista (C14: fala final)")
	_continue_to_end(game)
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and game.quest_controller.states.completed.size() == 2 and _count("quest_completed") == 2 and _count("echo_triggered") == 1, "nenhuma consequência/quest duplicada (2 quests concluídas, 1 Eco)")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_save_load(t) -> void:
	t.section("C12 — Save/Load V2 em cada ponto da ponte")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_intro(game)
	game.echo.interact(game.player)
	# 1) Save logo depois do Eco (Durn ainda não reagiu) → conversar → Load → Durn reage de novo.
	_key(t, KEY_S)
	var state_e := _functional(game)
	t.check(game.last_v2_save_result.is_success() and game.last_v2_save_result.shadow_divergence.is_empty(), "Save depois do Eco (antes de Durn): sombra acompanhava o runtime")
	_after_echo(game, 0, 1)
	t.check(game.quest_controller.states.active.has(FOLLOWUP), "conversa pós-Eco → investigação ativa")
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_e) and game.player.global_position == SAVE_POSITION, "Load: volta ao ponto depois do Eco (sem investigação, conversa pós-Eco não registrada)")
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == AFTER and _entry_id(game) == "start", "após o Load Durn reage de novo (o estado salvo é anterior à conversa)")
	_press_choice(game, 1)
	_press_choice(game, 1)
	_continue_to_end(game)

	# 2) Save com a investigação ativa → alterar escolha/mundo → Load.
	_key(t, KEY_S)
	var state_f := _functional(game)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V2_FILE))["state"]
	t.check(saved["dialogue"]["completed"].has("dialogue.vardhelm.after_echo") and String(saved["quests"].get("quest.vardhelm.sealed_panel", {}).get("status", "")) == "active" and not FileAccess.get_file_as_string(V2_FILE).contains("painel selado"), "Save V2 grava IDs canônicos (diálogo concluído, quest ativa), sem texto")
	game.dialogue_controller.persistent_state.record_choice(AFTER, "start", "found")
	_observation(game, "sealed_panel").interact(game.player)
	t.check(game.quest_controller.states.is_completed(FOLLOWUP), "investigação concluída antes do Load")
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_f), "Load: investigação ativa de novo, objetivo \"%s\"" % game.objective_label.text)
	t.check(game.dialogue_controller.persistent_state.last_choice(AFTER, "start") == "unsure" and game.dialogue_controller.persistent_state.last_choice(AFTER, "noticed") == "felt" and not game.dialogue_controller.is_active(), "escolhas pós-Eco restauradas (unsure/felt), conversa não reaberta")
	game._npc_interactable.interact(game.player)
	t.check(_entry_id(game) == "clue", "após o Load a conversa pós-Eco continua não repetindo (lembrete)")
	_continue_to_end(game)

	# 3) Save com a investigação concluída → Load repetido.
	var before := _events.size()
	_observation(game, "sealed_panel").interact(game.player)
	t.check(_events.slice(before).count("quest_completed") == 1, "investigação concluída uma vez depois do Load (resync)")
	_key(t, KEY_S)
	var state_g := _functional(game)
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "Save com a investigação concluída: sombra sem divergência")
	game.player.global_position = MOVED_POSITION
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), state_g) and game.objective_label.text == _text(game, "quest.vardhelm.sealed_panel.done") and not game.completion_banner.visible, "Load repetido: investigação concluída, sem banner antigo")
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == "vardhelm_after_panel" and _entry_id(game) == "heard", "Durn após o Load da investigação concluída: fala final (C14), não a pista")
	_continue_to_end(game)

	var world := game.narrative_controller.world_state
	var projected: GameState = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and game.quest_controller.states.completed.size() == 2 and projected.world.observations.size() == 1, "nenhuma consequência, memória, quest ou observação duplicada após os Loads")
	t.check(_count("game_saved") == 3 and _count("game_loaded") == 4 and _count("echo_triggered") == 1, "EventBus: game_saved %d / game_loaded %d / echo_triggered %d (sem duplicação)" % [_count("game_saved"), _count("game_loaded"), _count("echo_triggered")])
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


## Save salvo antes do C12 (quest do Eco concluída, sem a conversa pós-Eco) carrega e Durn reage.
func _test_legacy_quest_only(t) -> void:
	t.section("C12 — Eco concluído sem a flag de mundo: condição persistente pela quest")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	game.quest_controller.states.complete_quest(FIRST_QUEST)
	t.check(not game.narrative_controller.world_state.has_flag("vardhelm_first_echo_complete") and game._first_echo_resolved(), "quest do Eco concluída basta para Durn reagir")
	game._npc_interactable.interact(game.player)
	t.check(_session_id(game) == AFTER, "Durn abre a conversa pós-Eco")
	_press_choice(game, 0)
	_press_choice(game, 0)
	_continue_to_end(game)
