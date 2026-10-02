extends RefCounted

## Bloco C25 — Os horários (headless, determinístico).
##   gancho de Durn → os horários (caminho "Sentir o quê?": Durn conta; caminho
##   "Não senti nada.": a folha) → comparação no quadro de turnos da rua → próximo objetivo.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c25.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const HOURS := preload("res://scripts/vardhelm/vardhelm_hours_investigation.gd")
const THE_HOURS := "vardhelm_the_hours"
const THOSE_HOURS := "vardhelm_those_hours"
const SHIFT_BOARD := "foundry_street_shift_board"
## Lore e nomes reservados (matriz C22.1, H5, H9) — nada disso pode aparecer no C25.
const FORBIDDEN_LORE := ["aethel", "aetheris", "asterion", "cinzento", "experimento", "véu", "kael", "lurídeo", "édor", "árvore", "elyra", "arconte", "cosmo"]
## Durn não explica: nada de conclusão, tutorial ou resposta pronta.
const FORBIDDEN_TONE := ["significa", "descobri", "sempre acontece", "por causa", "a resposta", "você descobriu", "próximo objetivo"]

const DURN_HOURS_LINES := ["...Eu comecei a anotar.", "Hoje cedo, o painel. 5h58. Depois de novo, 13h58.", "E o último... quando você estava lá. 17h41.", "Não sei. Só sei que repetiu."]
const DURN_NOTES_LINES := ["...Você disse que não sentiu nada.", "Está na folha. Onde eu ficava."]


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


## Eventos de quest de C25 (tipo:quest[:objetivo]) a partir de `from`.
func _hours_events(from: int = 0) -> Array:
	var out: Array = []
	for e in _events.slice(from):
		var quest := String(e[1].get("quest_id", ""))
		if quest.contains("hours"):
			out.append("%s:%s%s" % [e[0], quest.trim_prefix("quest.vardhelm."), (":" + String(e[1]["objective_id"])) if e[1].has("objective_id") else ""])
	return out


## Primeira conversa (escolha 0 = "Sentir o quê?", 1 = "Não senti nada.") → Eco → Durn →
## painel → gancho. Depois disso a etapa dos horários está aberta.
func _play_to_hook(game: VardhelmVerticalSlice, intro_choice: int) -> void:
	_talk(game, intro_choice)
	game.echo.interact(game.player)
	_talk(game, 0)
	_observation(game, "sealed_panel").interact(game.player)
	_talk(game)


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
		"quests": [active, completed, (slice.quest_controller.states.objective_progress.get(THE_HOURS, {}) as Dictionary).duplicate(true)],
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
		"memories": memories,
		"flags": flags,
		"notes_available": (slice.get_node("AmbientLife") as VardhelmAmbientLife).is_observation_available("durn_notes"),
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_data(t)
	var finals := {}
	finals["a"] = _test_route_a(t)
	finals["b"] = _test_route_b(t)
	_test_convergence(t, finals)
	_test_save_load_a(t)
	_test_save_load_b(t)
	_test_old_save(t)
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
	t.section("C25 — dados: conversas, quests, textos, IDs canônicos")
	var hours_dialogue := JsonDataLoader.load_dialogue(HOURS.THE_HOURS_DIALOGUE_PATH)
	var notes_dialogue := JsonDataLoader.load_dialogue(HOURS.THE_NOTES_DIALOGUE_PATH)
	var the_hours := JsonDataLoader.load_quest(HOURS.THE_HOURS_QUEST_PATH)
	var those_hours := JsonDataLoader.load_quest(HOURS.THOSE_HOURS_QUEST_PATH)
	t.check(hours_dialogue.is_valid() and notes_dialogue.is_valid() and the_hours.objective_keys == ["hours", "compare"] and those_hours.objective_keys == ["mark", "panel"], "2 conversas e 2 quests válidas (horários: hours → compare; depois, no C26: mark + panel)")
	var ids := {
		GameIdCatalog.KIND_DIALOGUE: ["vardhelm_the_hours", "vardhelm_the_notes"],
		GameIdCatalog.KIND_QUEST: [THE_HOURS, THOSE_HOURS],
	}
	var unknown: Array = []
	for kind in ids:
		for id in ids[kind]:
			if not GameIdCatalog.is_known(kind, id):
				unknown.append(id)
	t.check(unknown.is_empty(), "IDs canônicos no GameIdCatalog (persistíveis, sem quarentena) %s" % str(unknown))
	# 10. nenhum lore profundo; Durn não explica.
	var catalog: Dictionary = JsonDataLoader.read_dictionary(LOCALE_PATH)
	var c25_keys: Array = catalog.keys().filter(func(k): return String(k).contains("the_hours") or String(k).contains("the_notes") or String(k).contains("those_hours") or String(k).ends_with(".hours"))
	var lore_found: Array = []
	var tone_found: Array = []
	for key in c25_keys:
		var text := String(catalog[key]).to_lower()
		for word in FORBIDDEN_LORE:
			if text.contains(word):
				lore_found.append("%s:%s" % [key, word])
		for word in FORBIDDEN_TONE:
			if text.contains(word):
				tone_found.append("%s:%s" % [key, word])
	t.check(c25_keys.size() == 16 and lore_found.is_empty(), "10. nenhum lore profundo nos %d textos do C25 (Véu, Aethel, Asterion, Elyra…) %s" % [c25_keys.size(), str(lore_found)])
	t.check(tone_found.is_empty(), "Durn não explica: nenhuma conclusão nem tom de tutorial %s" % str(tone_found))
	var long: Array = c25_keys.filter(func(k): return String(k).begins_with("observation.") and String(catalog[k]).length() > 110)
	t.check(long.is_empty(), "textos de observação concisos (até 110 caracteres; janela atual mantida) %s" % str(long))
	# 9. Elyra ausente de todo o texto do jogo.
	var elyra: Array = catalog.keys().filter(func(k): return String(k).to_lower().contains("elyra") or String(catalog[k]).to_lower().contains("elyra"))
	t.check(elyra.is_empty(), "9. Elyra ausente de todo o texto de runtime %s" % str(elyra))


## Caminho "Sentir o quê?": Durn conta.
func _test_route_a(t) -> Dictionary:
	t.section("C25 — caminho \"Sentir o quê?\": Durn conta os horários")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, 0)
	game.echo.interact(game.player)
	_talk(game, 0)
	# Antes do gancho, o quadro de turnos é só rotina (nada a comparar).
	var before_hook := _examine(game, _board(game))
	t.check(before_hook == _tr(game, "observation.foundry_street_shift_board.text") and not game.hours.is_started(), "antes do gancho: quadro de turnos com o texto do C23; etapa fechada")
	_observation(game, "sealed_panel").interact(game.player)
	var hook := _talk(game)
	t.check(hook == ["...Você ouviu, não ouviu?", "Então não fui só eu.", "..."], "gancho do C14 intacto")
	t.check(game.quest_controller.states.active.has(THE_HOURS) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_ASK_DURN_KEY), "o gancho abre \"Os horários\": \"%s\"" % game.objective_label.text)
	# 3. a folha não existe neste caminho (Durn nunca saiu do lugar).
	t.check(not (game.get_node("AmbientLife") as VardhelmAmbientLife).is_observation_available("durn_notes") and not game.is_durn_away_from_home(), "3. sem folha neste caminho: Durn está no lugar de sempre")
	var board_early := _examine(game, _board(game))
	t.check(board_early == _tr(game, "observation.foundry_street_shift_board.text") and not game.hours.knows_hours(), "sem os horários, o quadro de turnos não diz nada de novo")
	# 1. Durn conta.
	var from := _events.size()
	var lines := _talk(game, 0)
	t.check(lines == DURN_HOURS_LINES, "1. Durn conta: %s" % " / ".join(lines))
	t.check(game.quest_controller.states.is_objective_complete(THE_HOURS, "hours") and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_COMPARE_KEY), "horários conhecidos → \"%s\"" % game.objective_label.text)
	t.check(game.dialogue_controller.persistent_state.last_choice("vardhelm_the_hours", "last") == "why", "a pergunta do jogador fica registrada (DialogueRuntimeState)")
	t.check(_hours_events(from) == ["quest_progressed:the_hours:hours"], "16. um evento real: quest_progressed (%s)" % str(_hours_events(from)))
	var again := _talk(game, 0)
	t.check(again == ["Não sei. Só sei que repetiu."], "depois, Durn só retoma (não repete a conversa) %s" % str(again))
	t.check(game.quest_controller.states.active.has(THE_HOURS) and not game.hours.compared(), "conversar de novo não avança nada")
	# 6. comparação com a rotina da cidade.
	from = _events.size()
	var compared := _examine(game, _board(game))
	t.check(compared == _tr(game, HOURS.SHIFT_BOARD_HOURS_TEXT_KEY), "6. o quadro de turnos, lido com os horários: \"%s\"" % compared)
	t.check(game.quest_controller.states.is_completed(THE_HOURS) and game.quest_controller.states.active.has(THOSE_HOURS), "a relação percebida conclui \"Os horários\" e abre \"Nesses horários\"")
	# 7. objetivo seguinte, sem apontar o Galpão.
	t.check(game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY) and not game.objective_label.text.to_lower().contains("galpão") and not game.objective_label.text.to_lower().contains("registro"), "7. novo objetivo: \"%s\"" % game.objective_label.text)
	t.check(_hours_events(from) == ["quest_progressed:the_hours:compare", "quest_completed:the_hours", "quest_started:those_hours"], "16. eventos da comparação, uma vez cada %s" % str(_hours_events(from)))
	from = _events.size()
	_examine(game, _board(game))
	_talk(game, 0)
	t.check(_hours_events(from).is_empty() and _types(from).count("observation_discovered") == 0, "15. examinar e conversar de novo não reemitem nada %s" % str(_types(from)))
	# 8. o painel continua fechado (C26: relido depois da comparação, ainda fechado).
	var panel := _examine(game, _observation(game, "sealed_panel"))
	t.check(panel == _tr(game, "observation.sealed_panel.reread") and panel.contains("continua fechado"), "8. o painel continua fechado (H1): \"%s\"" % panel)
	_test_no_new_things(t, game)
	return _story(game)


## Caminho "Não senti nada.": Durn aponta a folha.
func _test_route_b(t) -> Dictionary:
	t.section("C25 — caminho \"Não senti nada.\": a folha de Durn")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, 1)
	game.echo.interact(game.player)
	var notes := _observation(game, "durn_notes")
	# 3. C16 preservado: a folha aparece quando Durn sai; antes do gancho, o texto de sempre.
	var early := _examine(game, notes)
	# Durn ainda está caminhando (tween ao vivo); quem decide que ele saiu é o estado derivado.
	t.check((game.get_node("AmbientLife") as VardhelmAmbientLife).is_durn_alone_after_echo() and early == _tr(game, "observation.durn_notes.text"), "3. antes do gancho: a folha do C16, texto de sempre")
	_talk(game, 0)
	_observation(game, "sealed_panel").interact(game.player)
	_talk(game)
	t.check(game.quest_controller.states.active.has(THE_HOURS) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_READ_NOTES_KEY), "o gancho abre \"Os horários\": \"%s\"" % game.objective_label.text)
	# 2. Durn não conta: aponta a folha (distância preservada).
	var lines := _talk(game, 0)
	t.check(lines == DURN_NOTES_LINES and not game.hours.knows_hours(), "2. Durn não conta: %s" % " / ".join(lines))
	t.check(_talk(game, 0) == ["Está na folha. Onde eu ficava."], "de novo: só aponta a folha")
	var from := _events.size()
	var read := _examine(game, notes)
	t.check(read == _tr(game, HOURS.NOTES_HOURS_TEXT_KEY) and game.hours.knows_hours(), "2. a folha, lida agora: \"%s\"" % read)
	t.check(game.objective_label.text == _tr(game, HOURS.OBJECTIVE_COMPARE_KEY) and _hours_events(from) == ["quest_progressed:the_hours:hours"] and _types(from).count("observation_discovered") == 0, "mesmo objetivo do outro caminho; folha já descoberta não reemite descoberta %s" % str(_types(from)))
	t.check(_talk(game, 0) == ["..."], "depois de lida, Durn não tem mais o que dizer (silêncio do C14)")
	var compared := _examine(game, _board(game))
	t.check(compared == _tr(game, HOURS.SHIFT_BOARD_HOURS_TEXT_KEY) and game.quest_controller.states.active.has(THOSE_HOURS), "6. mesma comparação no quadro de turnos")
	_test_no_new_things(t, game)
	return _story(game)


## 8–10, 17–18: nada além do previsto.
func _test_no_new_things(t, game: VardhelmVerticalSlice) -> void:
	var ambient := game.get_node("AmbientLife") as VardhelmAmbientLife
	var states: Array = ambient.environment_states.keys()
	t.check(states.all(func(s): return ["echo_awakened", "durn_alone", "maintenance_remembered", "sealed_panel_remembered", "tools_remembered"].has(String(s))), "8. nenhum estado novo no mundo (painel não abre, não quebra) %s" % str(states))
	var npcs: Array = game.find_children("*", "NPCController", true, false)
	var named: Array = game.find_children("*Elyra*", "", true, false)
	t.check(npcs.size() == 1 and named.is_empty(), "9. Elyra ausente: nenhum NPC além de Durn, nenhum nó com o nome")
	var world := game.narrative_controller.world_state
	var c25_flags: Array = world.flags.keys().filter(func(k): return String(k).contains("hour") or String(k).contains("compar") or String(k).contains("shift"))
	t.check(c25_flags == ["observation_foundry_street_shift_board_seen"], "17. nenhuma flag nova: o progresso vive nas quests %s" % str(c25_flags))
	t.check(not world.memories.any(func(m): return String(m).contains("hour")), "memória: os horários não viram memória (decisão C25)")
	var projected: Dictionary = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())
	var state: GameState = projected["state"]
	t.check((projected["quarantined"] as Array).is_empty() and state.quests.get_status("quest.vardhelm.the_hours") == GameQuestState.STATUS_COMPLETED and state.quests.get_status("quest.vardhelm.those_hours") == GameQuestState.STATUS_ACTIVE, "17. GameState: quests do C25 com ID canônico, sem quarentena")


func _test_convergence(t, finals: Dictionary) -> void:
	t.section("C25 — os caminhos convergem na informação, não no relacionamento")
	var a: Dictionary = finals["a"]
	var b: Dictionary = finals["b"]
	t.check(a["objective"] == b["objective"] and a["quests"] == b["quests"], "4. mesmo ponto da investigação nos dois caminhos: \"%s\"" % a["objective"])
	t.check(a["flags"].has("vardhelm_heard_echo") and not a["flags"].has("vardhelm_felt_nothing") and b["flags"].has("vardhelm_felt_nothing") and not b["flags"].has("vardhelm_heard_echo"), "5. a consequência da primeira escolha continua (heard_echo × felt_nothing)")
	t.check(a["dialogue"]["completed"].has("vardhelm_the_hours") and not a["dialogue"]["completed"].has("vardhelm_the_notes") and b["dialogue"]["completed"].has("vardhelm_the_notes") and not b["dialogue"]["completed"].has("vardhelm_the_hours"), "5. relacionamento diferente: num caminho Durn contou; no outro, só apontou a folha")
	t.check(not a["notes_available"] and b["notes_available"], "5. a folha só existe no caminho \"Não senti nada.\"")


## Save/Load em cada ponto (caminho "Sentir o quê?").
func _test_save_load_a(t) -> void:
	t.section("C25 — Save/Load em cada ponto (caminho \"Sentir o quê?\")")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_play_to_hook(game, 0)
	# 11. Save antes da pista → Durn conta → Load: de volta ao antes.
	_key(t, KEY_S)
	var before_clue := _story(game)
	_talk(game, 1)
	var from := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), before_clue) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_ASK_DURN_KEY), "11. Save antes da pista → Load: pista ainda não recebida")
	t.check(_talk(game, 1) == DURN_HOURS_LINES and game.dialogue_controller.persistent_state.last_choice("vardhelm_the_hours", "last") == "meaning", "11. depois do Load, Durn conta de novo, do começo (outra pergunta registrada)")
	# 12/13. Save depois da pista → comparação → Load: antes da comparação.
	_key(t, KEY_S)
	var after_clue := _story(game)
	_examine(game, _board(game))
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), after_clue) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_COMPARE_KEY), "12/13. Save depois da pista → Load: horários conhecidos, comparação por fazer")
	t.check(_talk(game, 0) == ["Não sei. Só sei que repetiu."], "13. depois do Load, Durn não repete a conversa")
	from = _events.size()
	t.check(_examine(game, _board(game)) == _tr(game, HOURS.SHIFT_BOARD_HOURS_TEXT_KEY) and _hours_events(from) == ["quest_progressed:the_hours:compare", "quest_completed:the_hours", "quest_started:those_hours"], "13. comparação feita depois do Load, uma vez")
	# 14. Save depois da comparação → mexe → Load ×3.
	_key(t, KEY_S)
	var after_compare := _story(game)
	game.player.global_position = MOVED_POSITION
	from = _events.size()
	_key(t, KEY_L)
	_key(t, KEY_L)
	_key(t, KEY_L)
	var load_types := _types(from)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), after_compare) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_FIND_OUT_KEY), "14. Save depois da comparação → Load ×3: novo objetivo ativo")
	t.check(load_types.count("game_loaded") == 3 and load_types.size() == 3, "15/16. Loads não reemitem quest, diálogo, observação nem consequência %s" % str(load_types))
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and game.quest_controller.states.completed.size() == 3 and game.quest_controller.states.active.size() == 1, "15. nenhuma duplicação: memórias, 3 quests concluídas, 1 ativa")
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "sombra (GameState) sem divergência no save")
	# 17/18. o arquivo só tem estado persistente.
	var text := FileAccess.get_file_as_string(V2_FILE)
	var file_text := text.to_lower()
	t.check(file_text.contains("quest.vardhelm.the_hours") and file_text.contains("quest.vardhelm.those_hours") and file_text.contains("dialogue.vardhelm.the_hours"), "17. persistido: as quests do C25 e a conversa concluída (IDs canônicos)")
	var derived := ["objective.ask_durn", "objective.compare", "objective.find_out", "shift_board.hours", "durn_notes.hours", "5h58", "dialogue_box", "durn_alone"]
	t.check(derived.all(func(w): return not file_text.contains(w)), "18. derivado/transitório fora do arquivo: textos de objetivo e de observação, caixa de diálogo, posição de Durn")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


## Save/Load no caminho "Não senti nada." (folha).
func _test_save_load_b(t) -> void:
	t.section("C25 — Save/Load em cada ponto (caminho \"Não senti nada.\")")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_hook(game, 1)
	_talk(game, 0)
	# Save antes de ler a folha → lê → Load.
	_key(t, KEY_S)
	var before_read := _story(game)
	_examine(game, _observation(game, "durn_notes"))
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), before_read) and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_READ_NOTES_KEY), "Save antes de ler a folha → Load: horários ainda desconhecidos")
	t.check(game.is_durn_away_from_home() and (game.get_node("AmbientLife") as VardhelmAmbientLife).is_observation_available("durn_notes"), "depois do Load: Durn longe do lugar de sempre, a folha continua lá (C15/C16)")
	t.check(_talk(game, 0) == ["Está na folha. Onde eu ficava."], "depois do Load: Durn só aponta a folha (a conversa já tinha acontecido)")
	# Lê → Save → Load: a leitura continua.
	_examine(game, _observation(game, "durn_notes"))
	_key(t, KEY_S)
	var after_read := _story(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), after_read) and _examine(game, _observation(game, "durn_notes")) == _tr(game, HOURS.NOTES_HOURS_TEXT_KEY), "Save depois de ler → Load: horários conhecidos, a folha mostra os horários")
	t.check(_talk(game, 0) == ["..."] and game.objective_label.text == _tr(game, HOURS.OBJECTIVE_COMPARE_KEY), "depois do Load: Durn em silêncio; comparação por fazer")


## Save de antes do C25 (gancho dito, etapa inexistente): abre ao voltar a Durn.
func _test_old_save(t) -> void:
	t.section("C25 — save de antes do C25: a etapa abre ao voltar a Durn")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_play_to_hook(game, 0)
	var states := game.quest_controller.states
	states.active.erase(THE_HOURS)
	states.objective_progress.erase(THE_HOURS)
	game.derive_quest_presentation()
	_key(t, KEY_S)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and not game.hours.is_started() and game.objective_label.text == _tr(game, "quest.vardhelm.sealed_panel.done"), "Load de um save sem a etapa: \"%s\"" % game.objective_label.text)
	var from := _events.size()
	var lines := _talk(game, 0)
	t.check(lines == DURN_HOURS_LINES and _hours_events(from) == ["quest_started:the_hours", "quest_progressed:the_hours:hours"], "ao voltar a Durn: a etapa abre e ele conta %s" % str(_hours_events(from)))
