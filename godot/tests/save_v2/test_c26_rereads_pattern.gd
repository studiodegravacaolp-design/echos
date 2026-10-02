extends RefCounted

## Bloco C26 — Releituras e padrão (headless, determinístico).
##   comparação dos horários (C25) → de volta à Forja: o quadro de manutenção (linha raspada,
##   "...58") e o painel (reforço mais novo), em qualquer ordem → "O reforço": quem reforçou o
##   painel e onde ficam os registros. Mudança de interpretação, nunca do mundo.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c26.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const HOURS := preload("res://scripts/vardhelm/vardhelm_hours_investigation.gd")
const REREADS := preload("res://scripts/vardhelm/vardhelm_rereads_investigation.gd")
const THOSE_HOURS := "vardhelm_those_hours"
const REINFORCEMENT := "vardhelm_the_reinforcement"
const SHIFT_BOARD := "foundry_street_shift_board"
const C26_KEYS := ["observation.maintenance_board.reread", "observation.sealed_panel.reread", "dialogue.vardhelm.the_mark.not_me", "quest.vardhelm.the_reinforcement.title", "quest.vardhelm.the_reinforcement.objective.trace"]
## Lore e nomes reservados (matriz C22.1, H5, H9) — nada disso pode aparecer no C26.
const FORBIDDEN_LORE := ["aethel", "aetheris", "asterion", "cinzento", "experimento", "véu", "kael", "lurídeo", "édor", "árvore", "elyra", "arconte", "cosmo"]
## Suspeita não vira fato: ninguém afirma quem apagou, o que foi selado ou por quê.
const FORBIDDEN_CONCLUSION := ["apagou", "apagaram", "esconde", "escond", "selaram", "por causa", "porque", "significa", "a resposta", "galpão", "17h41"]


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


## Conversa até o fim; nas escolhas, escolhe `choice` (índice) sempre que houver.
func _talk(slice: VardhelmVerticalSlice, choice: int = 0) -> Array:
	var lines: Array = []
	slice._npc_interactable.interact(slice.player)
	var guard := 0
	while slice.dialogue_controller.is_active() and guard < 20:
		lines.append(slice.dialogue_box.text_label.text)
		if _buttons(slice).is_empty():
			slice.dialogue_box.continue_button.pressed.emit()
		else:
			(_buttons(slice)[choice] as Button).pressed.emit()
		guard += 1
	return lines


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _board(slice: VardhelmVerticalSlice) -> EnvironmentalObservation:
	return _observation(slice, "maintenance_board")


func _panel(slice: VardhelmVerticalSlice) -> EnvironmentalObservation:
	return _observation(slice, "sealed_panel")


func _shift_board(slice: VardhelmVerticalSlice) -> EnvironmentalObservation:
	return slice.foundry_district.life_named("StreetLife").get_node("EnvironmentalObservations/%s" % SHIFT_BOARD) as EnvironmentalObservation


func _examine(slice: VardhelmVerticalSlice, observation: EnvironmentalObservation) -> String:
	observation.interact(slice.player)
	return slice.observation_text.text


func _tr(slice: VardhelmVerticalSlice, key: String) -> String:
	return slice.localization.tr_key(key)


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
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append([event.event_type, event.payload.duplicate()]))
	return [game, spy]


func _types(from: int = 0) -> Array:
	return _events.slice(from).map(func(e): return e[0])


## Eventos de quest do C26 (tipo:quest[:objetivo]) a partir de `from`.
func _quest_events(from: int = 0) -> Array:
	var out: Array = []
	for e in _events.slice(from):
		var quest := String(e[1].get("quest_id", ""))
		if quest.contains("those_hours") or quest.contains("reinforcement"):
			out.append("%s:%s%s" % [e[0], quest.trim_prefix("quest.vardhelm."), (":" + String(e[1]["objective_id"])) if e[1].has("objective_id") else ""])
	return out


## Primeira conversa (0 = "Sentir o quê?", 1 = "Não senti nada.") → Eco → Durn → painel →
## gancho → os horários (Durn conta ou a folha). Sem comparar ainda.
func _play_to_hours(game: VardhelmVerticalSlice, intro_choice: int, examine_board_early := false) -> void:
	_talk(game, intro_choice)
	if examine_board_early:
		_examine(game, _board(game))
	game.echo.interact(game.player)
	_talk(game, 0)
	_panel(game).interact(game.player)
	_talk(game)
	_talk(game, 0)
	if intro_choice == 1:
		_examine(game, _observation(game, "durn_notes"))


func _play_to_compare(game: VardhelmVerticalSlice, intro_choice: int, examine_board_early := false) -> void:
	_play_to_hours(game, intro_choice, examine_board_early)
	_examine(game, _shift_board(game))


## Estado narrativo inteiro, como o jogador o vive (sem posição).
func _story(slice: VardhelmVerticalSlice) -> Dictionary:
	var active: Array = slice.quest_controller.states.active.keys()
	active.sort()
	var completed: Array = slice.quest_controller.states.completed.keys()
	completed.sort()
	var memories: Array = slice.narrative_controller.world_state.memories.duplicate()
	memories.sort()
	var flags: Array = slice.narrative_controller.world_state.flags.keys()
	flags.sort()
	return {
		"objective": slice.objective_label.text,
		"quests": [active, completed, (slice.quest_controller.states.objective_progress.get(THOSE_HOURS, {}) as Dictionary).duplicate(true)],
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
		"memories": memories,
		"flags": flags,
		"observations": [_board(slice).revealed, _board(slice).memory_registered, _panel(slice).revealed, _panel(slice).memory_registered],
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_data(t)
	_test_reread_flow(t)
	_test_seen_before(t)
	_test_free_order(t)
	_test_durn(t)
	_test_save_load(t)
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
	t.section("C26 — dados: quests, conversa, textos, IDs canônicos")
	var those := JsonDataLoader.load_quest("res://data/quests/vardhelm_those_hours.json")
	var reinforcement := JsonDataLoader.load_quest(REREADS.REINFORCEMENT_QUEST_PATH)
	var mark := JsonDataLoader.load_dialogue(REREADS.THE_MARK_DIALOGUE_PATH)
	t.check(those.objective_keys == ["mark", "panel"] and reinforcement.objective_keys == ["trace"] and mark.is_valid() and mark.entries.size() == 1 and mark.entries[0].choices.is_empty(), "\"Nesses horários\": duas evidências (mark, panel); \"O reforço\": trace; Durn: uma fala, sem escolha")
	t.check(GameIdCatalog.is_known(GameIdCatalog.KIND_QUEST, REINFORCEMENT) and GameIdCatalog.is_known(GameIdCatalog.KIND_DIALOGUE, "vardhelm_the_mark"), "IDs canônicos no GameIdCatalog (persistíveis, sem quarentena)")
	var catalog: Dictionary = JsonDataLoader.read_dictionary(LOCALE_PATH)
	var lore_found: Array = []
	var conclusion_found: Array = []
	for key in C26_KEYS:
		var text := String(catalog.get(key, "?")).to_lower()
		for word in FORBIDDEN_LORE:
			if text.contains(word):
				lore_found.append("%s:%s" % [key, word])
		for word in FORBIDDEN_CONCLUSION:
			if text.contains(word):
				conclusion_found.append("%s:%s" % [key, word])
	t.check(C26_KEYS.all(func(k): return catalog.has(k)) and lore_found.is_empty(), "20. nenhum lore profundo nos 5 textos do C26 %s" % str(lore_found))
	# 6. a releitura sugere, não conclui.
	t.check(conclusion_found.is_empty(), "6. sem conclusão excessiva: ninguém afirma quem apagou, o que foi selado ou por quê; o Galpão não é nomeado %s" % str(conclusion_found))
	t.check(C26_KEYS.filter(func(k): return String(k).begins_with("observation.")).all(func(k): return String(catalog[k]).length() <= 110), "textos de releitura curtos (até 110 caracteres; janela atual mantida)")
	# 7. 17h41 continua fora do padrão: nada no C26 o explica, e a comparação do C25 não mudou.
	t.check(String(catalog["observation.foundry_street_shift_board.hours"]).ends_with("O sublinhado, não.") and C26_KEYS.all(func(k): return not String(catalog[k]).contains("17h41") and not String(catalog[k]).contains("17h")), "7. o terceiro horário continua irregular (sem falsa correspondência)")
	t.check(catalog.keys().all(func(k): return not String(k).to_lower().contains("elyra") and not String(catalog[k]).to_lower().contains("elyra")), "21. Elyra ausente de todo o texto de runtime")


## Caminho principal: comparação → quadro → painel → "O reforço".
func _test_reread_flow(t) -> void:
	t.section("C26 — releituras: o quadro e o painel ganham sentido novo")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_hours(game, 0)
	# 1. horários conhecidos, ainda sem comparar: o quadro continua com o olhar de depois do Eco.
	var before := _examine(game, _board(game))
	t.check(before == _tr(game, "observation.maintenance_board.after_echo") and not game.rereads.can_reread(), "1. antes da comparação: o quadro como antes (\"marca quase apagada\")")
	_examine(game, _shift_board(game))
	t.check(game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY) and game.quest_controller.states.active.has(THOSE_HOURS), "objetivo anterior (C25): \"%s\"" % game.objective_label.text)
	# 2/5. depois da comparação, o mesmo quadro: a linha raspada, "...58".
	var from := _events.size()
	var memories_before := game.narrative_controller.world_state.memories.size()
	var reread := _examine(game, _board(game))
	t.check(reread == _tr(game, REREADS.BOARD_REREAD_KEY), "2. o quadro relido: \"%s\"" % reread)
	t.check(reread.contains("raspada") and reread.contains("...58") and not reread.to_lower().contains("painel"), "5. a marca apagada: uma linha raspada, o fim de um horário — sem dizer de quê")
	# 12. uma evidência só não basta.
	t.check(game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY) and game.quest_controller.states.active.has(THOSE_HOURS) and not game.quest_controller.states.active.has(REINFORCEMENT), "12. só a linha raspada: o objetivo ainda não muda")
	t.check(_quest_events(from) == ["quest_progressed:those_hours:mark"] and _types(from).count("observation_discovered") == 0 and game.narrative_controller.world_state.memories.size() == memories_before, "18/19. um evento real (quest_progressed), sem nova descoberta nem memória %s" % str(_quest_events(from)))
	# 8/9. o painel: relido, ainda fechado.
	from = _events.size()
	var panel := _examine(game, _panel(game))
	t.check(panel == _tr(game, REREADS.PANEL_REREAD_KEY) and panel.begins_with("O painel continua fechado."), "8/9. o painel relido, ainda fechado: \"%s\"" % panel)
	var states: Array = (game.get_node("AmbientLife") as VardhelmAmbientLife).environment_states.keys()
	t.check(states.all(func(s): return ["echo_awakened", "durn_alone", "maintenance_remembered", "sealed_panel_remembered", "tools_remembered"].has(String(s))) and _types(from).count("world_state_changed") == 0 and _quest_events(from).all(func(e): return not String(e).contains("sealed_panel")), "8. nada muda no mundo: nenhum estado novo, nenhuma reação, a etapa do painel (C12) não reabre")
	# 12/13. com as duas evidências: "O reforço".
	t.check(game.quest_controller.states.is_completed(THOSE_HOURS) and game.quest_controller.states.active.has(REINFORCEMENT), "12. com as duas evidências, \"Nesses horários\" se conclui e começa \"O reforço\"")
	t.check(game.objective_label.text == _tr(game, REREADS.OBJECTIVE_TRACE_KEY) and game.objective_label.text.contains("registros") and not game.objective_label.text.to_lower().contains("galpão") and not game.objective_label.text.to_lower().contains("elyra"), "13. novo objetivo prepara o Galpão sem nomeá-lo: \"%s\"" % game.objective_label.text)
	t.check(_quest_events(from) == ["quest_progressed:those_hours:panel", "quest_completed:those_hours", "quest_started:the_reinforcement"], "18. eventos da evidência suficiente, uma vez cada %s" % str(_quest_events(from)))
	# 18. reexaminar não reemite nada.
	from = _events.size()
	_examine(game, _board(game))
	_examine(game, _panel(game))
	_examine(game, _shift_board(game))
	t.check(_events.size() == from and _examine(game, _board(game)) == _tr(game, REREADS.BOARD_REREAD_KEY), "18. reexaminar quadro, painel e quadro de turnos não reemite nada; a releitura fica")
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_memory_maintenance_board") <= 1 and world.memories.count("vardhelm_memory_sealed_panel") <= 1 and _board(game).memory_registered, "19. o fragmento do quadro existe uma vez (o da primeira leitura); nenhuma memória nova")
	var c26_flags: Array = world.flags.keys().filter(func(k): return String(k).contains("mark") or String(k).contains("reread") or String(k).contains("reinforce"))
	t.check(c26_flags.is_empty(), "17. nenhuma flag nova: a evidência vive na quest %s" % str(c26_flags))
	# 21/22. Elyra e combate ausentes.
	t.check(game.find_children("*Elyra*", "", true, false).is_empty() and game.find_children("*", "NPCController", true, false).size() == 1, "21. Elyra ausente: nenhum NPC além de Durn")
	var combat: Array = game.find_children("*Enemy*", "", true, false) + game.find_children("*Combat*", "", true, false) + game.find_children("*Creature*", "", true, false)
	t.check(combat.is_empty() and GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_QUEST].all(func(q): return not String(q).contains("combat")), "22. nenhum combate nem criatura")
	var projected: Dictionary = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())
	var state: GameState = projected["state"]
	t.check((projected["quarantined"] as Array).is_empty() and state.quests.get_status("quest.vardhelm.those_hours") == GameQuestState.STATUS_COMPLETED and state.quests.get_status("quest.vardhelm.the_reinforcement") == GameQuestState.STATUS_ACTIVE, "GameState: quests do C26 com ID canônico, sem quarentena")


## 3/4. Objetos examinados antes (até antes do Eco) × nunca examinados.
func _test_seen_before(t) -> void:
	t.section("C26 — quem já tinha olhado e quem nunca olhou")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_compare(game, 0, true)
	t.check(_board(game).revealed and _board(game).memory_registered, "o quadro foi examinado antes do Primeiro Eco (fragmento registrado)")
	var fragments := game.narrative_controller.world_state.memories.count("vardhelm_memory_maintenance_board")
	var reread := _examine(game, _board(game))
	t.check(reread == _tr(game, REREADS.BOARD_REREAD_KEY) and game.quest_controller.states.is_objective_complete(THOSE_HOURS, "mark"), "3. já examinado antes: a releitura aparece ao examinar de novo e conta como evidência")
	t.check(game.narrative_controller.world_state.memories.count("vardhelm_memory_maintenance_board") == fragments, "19. o fragmento da primeira leitura não se repete")
	var pair2 := _new_game(t)
	var fresh: VardhelmVerticalSlice = pair2[0]
	_play_to_compare(fresh, 0)
	t.check(not _board(fresh).revealed, "o quadro nunca foi examinado até a comparação")
	var from := _events.size()
	var first := _examine(fresh, _board(fresh))
	t.check(first == _tr(fresh, REREADS.BOARD_REREAD_KEY) and _types(from).count("observation_discovered") == 1 and fresh.quest_controller.states.is_objective_complete(THOSE_HOURS, "mark"), "4. nunca examinado: a primeira leitura já é a de quem sabe o que procurar; descoberta e evidência, uma vez cada")


## 11. Ordem parcialmente livre.
func _test_free_order(t) -> void:
	t.section("C26 — ordem parcialmente livre")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_compare(game, 1)
	_examine(game, _panel(game))
	t.check(game.quest_controller.states.is_objective_complete(THOSE_HOURS, "panel") and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY), "11. painel primeiro (caminho \"Não senti nada.\"): evidência guardada, objetivo ainda não muda")
	_examine(game, _board(game))
	t.check(game.quest_controller.states.active.has(REINFORCEMENT) and game.objective_label.text == _tr(game, REREADS.OBJECTIVE_TRACE_KEY), "11. depois o quadro: mesmo resultado da outra ordem")
	# Antes da comparação as releituras não existem (a pergunta ainda não foi feita).
	var pair2 := _new_game(t)
	var early: VardhelmVerticalSlice = pair2[0]
	_play_to_hours(early, 0)
	var panel := _examine(early, _panel(early))
	t.check(panel == _tr(early, "observation.sealed_panel.after_echo") and not early.quest_controller.states.active.has(THOSE_HOURS), "antes da comparação, o painel como antes; nada a guardar")


## 10. Durn não conduz.
func _test_durn(t) -> void:
	t.section("C26 — Durn não conduz esta etapa")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_compare(game, 0)
	t.check(_talk(game, 0) == ["Não sei. Só sei que repetiu."], "antes da linha raspada, Durn só retoma o que disse")
	_examine(game, _board(game))
	var from := _events.size()
	var lines := _talk(game, 0)
	t.check(lines == ["...Raspado? Não fui eu."] and _quest_events(from).is_empty(), "10. depois da linha raspada: uma reação curta, nenhuma etapa nova (%s)" % str(lines))
	_examine(game, _panel(game))
	t.check(_talk(game, 0) == ["...Raspado? Não fui eu."] and game.quest_controller.states.active.keys() == [REINFORCEMENT], "10. depois, a mesma reação; quem conduz é a investigação")
	var pair2 := _new_game(t)
	var denied: VardhelmVerticalSlice = pair2[0]
	_play_to_compare(denied, 1)
	_examine(denied, _board(denied))
	t.check(_talk(denied, 0) == ["..."], "10. no caminho \"Não senti nada.\", Durn continua em silêncio")


## 14–18. Save/Load.
func _test_save_load(t) -> void:
	t.section("C26 — Save/Load em cada ponto")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_talk(game, 0)
	_examine(game, _board(game))
	game.echo.interact(game.player)
	_talk(game, 0)
	_panel(game).interact(game.player)
	_talk(game)
	# 14. Save antes de conhecer os horários → Load → descobre os horários.
	_key(t, KEY_S)
	var before_hours := _story(game)
	_talk(game, 0)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), before_hours) and _examine(game, _board(game)) == _tr(game, "observation.maintenance_board.after_echo"), "14. Save antes dos horários → Load: quadro como antes")
	_talk(game, 0)
	_examine(game, _shift_board(game))
	t.check(game.rereads.can_reread() and _examine(game, _board(game)) == _tr(game, REREADS.BOARD_REREAD_KEY), "depois do Load, horários e comparação: a releitura aparece")
	# 15/16. Save depois da primeira releitura → painel → Load.
	_key(t, KEY_S)
	var after_mark := _story(game)
	_examine(game, _panel(game))
	game.player.global_position = MOVED_POSITION
	var from := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), after_mark) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY), "15/16. Save depois da linha raspada → Load: evidência guardada, painel por reler")
	t.check(_examine(game, _board(game)) == _tr(game, REREADS.BOARD_REREAD_KEY) and _types(from) == ["game_loaded"], "16. depois do Load, o quadro continua relido; o Load só emitiu game_loaded")
	from = _events.size()
	_examine(game, _panel(game))
	t.check(_quest_events(from) == ["quest_progressed:those_hours:panel", "quest_completed:those_hours", "quest_started:the_reinforcement"], "16. o painel relido depois do Load completa a evidência, uma vez")
	# 17. Save final → Load ×3.
	_key(t, KEY_S)
	var final_state := _story(game)
	from = _events.size()
	_key(t, KEY_L)
	_key(t, KEY_L)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), final_state) and game.objective_label.text == _tr(game, REREADS.OBJECTIVE_TRACE_KEY) and _types(from) == ["game_loaded", "game_loaded", "game_loaded"], "17. Load ×3: \"O reforço\" ativo; só game_loaded")
	var world := game.narrative_controller.world_state
	var memory: GameState = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]
	var memory_ids: Array = memory.memory.memories.keys()
	t.check(memory_ids.count("memory.vardhelm.maintenance_board") == 1 and memory_ids.count("memory.vardhelm.sealed_panel") == 1 and world.memories.count("vardhelm_first_echo_complete") == 1 and game.quest_controller.states.completed.size() == 4 and game.quest_controller.states.active.size() == 1, "18/19. nada duplicado: fragmentos uma vez (GameState), 4 quests concluídas, 1 ativa %s" % str(memory_ids))
	t.check(_talk(game, 0) == ["...Raspado? Não fui eu."] and game.dialogue_controller.persistent_state.is_completed("vardhelm_the_hours"), "18. Durn depois do Load: a reação curta; a conversa dos horários não se repete")
	var text := FileAccess.get_file_as_string(V2_FILE).to_lower()
	t.check(text.contains("quest.vardhelm.the_reinforcement") and not text.contains("reread") and not text.contains("raspada") and not text.contains("objective.trace"), "persistido: só as quests; textos de releitura e objetivo são derivados")
	t.check(game.last_v2_save_result.shadow_divergence.is_empty() and spy.calls == 0, "sombra sem divergência; SaveService legado nunca chamado")
