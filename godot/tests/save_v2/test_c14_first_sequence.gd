extends RefCounted

## Bloco C14 — primeira sequência narrativa completa de Vardhelm (headless, determinístico).
##   começo → Durn → escolha → Eco (descoberta) → consequência/memória → Vardhelm reage
##   → Durn reage → painel selado (investigação) → encerramento (silêncio) → gancho (Durn:
##   "Então não fui só eu.") — com Save/Load em cada etapa (A–E).
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c14.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const AFTER_PANEL_PATH := "res://data/dialogue/vardhelm_after_panel.json"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const AFTER_PANEL := "vardhelm_after_panel"
const FORBIDDEN := ["eco", "memória", "lembr", "aethel", "aetheris", "asterion", "cinzento", "origem", "cosmo", "significa", "agora você", "próximo objetivo", "você descobriu"]


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


func _press(slice: VardhelmVerticalSlice, index: int) -> void:
	(_buttons(slice)[index] as Button).pressed.emit()


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
			_press(slice, choice)
		guard += 1
	return lines


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _ambient(slice: VardhelmVerticalSlice) -> VardhelmAmbientLife:
	return slice.get_node("AmbientLife") as VardhelmAmbientLife


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


## Estado narrativo inteiro, como o jogador o vive (sem posição).
func _story(slice: VardhelmVerticalSlice) -> Dictionary:
	var observations := {}
	for id in OBSERVATIONS:
		observations[id] = [_observation(slice, id).revealed, _observation(slice, id).memory_registered]
	var active: Array = slice.quest_controller.states.active.keys()
	active.sort()
	var completed: Array = slice.quest_controller.states.completed.keys()
	completed.sort()
	# Memórias são um conjunto: o Load as reescreve na ordem canônica.
	var memories: Array = slice.narrative_controller.world_state.memories.duplicate()
	memories.sort()
	var worker := slice.get_node("AmbientLife/AmbientWorkers/worker_bench_01")
	return {
		"objective": slice.objective_label.text, "banner": slice.completion_banner.visible,
		"echo": [slice.echo.revealed, slice.echo.interaction_enabled],
		"quests": [active, completed],
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
		"memories": memories,
		"environment": _ambient(slice).environment_states.keys(),
		"world_reacted": [_ambient(slice).is_after_echo_world_applied(), String(worker.get_meta("routine", ""))],
		"observations": observations,
	}


func _volumes(slice: VardhelmVerticalSlice) -> Array:
	var out: Array = []
	for name in ["VardhelmHum", "VardhelmSteam", "VardhelmMachinery"]:
		out.append(snappedf((slice.get_node("VardhelmAudio/%s" % name) as AudioStreamPlayer).volume_db, 0.01))
	return out


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_texts(t)
	_test_sequence(t)
	_test_save_load(t)
	_test_closing_and_load(t)
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


func _test_texts(t) -> void:
	t.section("C14 — fala final de Durn: curta, sem escolha, sem explicar")
	var catalog: Dictionary = JSON_LOADER.read_dictionary(LOCALE_PATH)
	var dialogue: DialogueData = JSON_LOADER.load_dialogue(AFTER_PANEL_PATH)
	var ids: Array = []
	var found: Array = []
	var choices := 0
	for entry: DialogueEntry in dialogue.entries:
		ids.append(entry.entry_id)
		choices += entry.choices.size()
		var text := String(catalog.get(entry.text, "?")).to_lower()
		for word in FORBIDDEN:
			if text.contains(word):
				found.append("%s:%s" % [entry.entry_id, word])
	t.check(dialogue.is_valid() and ids == ["heard", "not_alone", "quiet"] and choices == 0, "3 falas curtas, nenhuma escolha nova (%s)" % str(ids))
	t.check(found.is_empty(), "nenhuma explicação, nenhum tom de tutorial (%s)" % str(found))
	t.check(GameIdCatalog.canonical_id(GameIdCatalog.KIND_DIALOGUE, AFTER_PANEL) == "dialogue.vardhelm.after_panel", "ID canônico no GameIdCatalog (persistível)")


func _test_sequence(t) -> void:
	t.section("C14 — a sequência completa, do começo ao gancho")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	# COMEÇO
	t.check(game.objective_label.text == "Fale com Durn para descobrir o que está acontecendo." and game.status_label.text.contains("WASD") and not game.echo.interaction_enabled, "começo: objetivo aponta Durn; controles no status; Eco ainda fechado")
	var workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	# C17.1: mais trabalhadores no cenário; o que importa aqui é todos na rotina antes do Eco.
	t.check(workers.size() >= 4 and workers.all(func(w): return w.get_meta("routine", "") == "default"), "rotina ao redor: %d trabalhadores na rotina de trabalho" % workers.size())
	# DURN + ESCOLHA
	var intro := _talk(game, 0)
	t.check(intro[0] == "...Você também sentiu isso?" and intro.back() == "Se acontecer de novo... procure por mim.", "primeira conversa aprovada, terminando com \"procure por mim\" (%s)" % str(intro))
	t.check(game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn" and game.narrative_controller.world_state.has_flag("vardhelm_heard_echo"), "escolha registrada e com consequência (vardhelm_heard_echo)")
	t.check(not game.status_label.text.contains("vardhelm_") and not game.status_label.text.contains("Memória registrada:"), "status sem ID técnico (\"%s\")" % game.status_label.text)
	t.check(game.quest_controller.states.active.has("vardhelm_first_echo") and game.echo.interaction_enabled and game.objective_label.text == "Investigue o fenômeno no setor industrial.", "quest iniciada; o Eco pode ser encontrado")
	# DESCOBERTA + CONSEQUÊNCIA + MEMÓRIA + REAÇÃO
	game.echo.interact(game.player)
	t.check(game.memory_panel.visible and game.narrative_controller.world_state.memories.has("vardhelm_first_echo_complete") and game.quest_controller.states.is_completed("vardhelm_first_echo"), "Eco: memória, consequência, quest concluída")
	t.check(_ambient(game).is_after_echo_world_applied() and _ambient(game).environment_states.has("echo_awakened"), "Vardhelm reage (C13 preservado)")
	# Exploração pós-Eco: as observações têm o texto de depois do Eco.
	_observation(game, "tool_rack").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.tool_rack.after_echo"), "exploração pós-Eco: observação com o olhar de depois")
	# DURN REAGE
	var after_echo := _talk(game, 1)
	t.check(after_echo[0] == "...Você voltou." and after_echo.any(func(l): return String(l).contains("painel selado")), "Durn reage e aponta o painel (C12 preservado)")
	t.check(game.quest_controller.states.active.has("vardhelm_sealed_panel"), "investigação curta aberta")
	# INVESTIGAÇÃO + ENCERRAMENTO
	var before := _events.size()
	_observation(game, "sealed_panel").interact(game.player)
	t.check(game.objective_label.text == "✓ O painel selado — ainda fechado." and game.observation_text.text == game.localization.tr_key("observation.sealed_panel.after_echo"), "painel examinado: \"%s\" — continua fechado" % game.objective_label.text)
	t.check(_ambient(game).is_closing_silence_active(), "encerramento: Vardhelm entra em silêncio por alguns segundos (luz do painel se apaga)")
	var panel_events := _events.slice(before)
	t.check(panel_events.count("quest_completed") == 1 and panel_events.count("consequence_applied") == 0, "conclusão emitida uma vez (%s)" % str(panel_events))
	_observation(game, "sealed_panel").interact(game.player)
	t.check(_events.slice(before).count("quest_completed") == 1, "examinar de novo não conclui nem reabre o encerramento")
	# GANCHO
	var final_talk := _talk(game)
	t.check(final_talk == ["...Você ouviu, não ouviu?", "Então não fui só eu.", "..."], "gancho: Durn — \"%s\"" % " / ".join(final_talk))
	t.check(game.dialogue_controller.persistent_state.is_completed(AFTER_PANEL), "fala final registrada (DialogueRuntimeState)")
	# C25: o gancho não se repete; ao voltar, Durn passa aos horários (antes: silêncio).
	var again := _talk(game)
	t.check(again[0] == "...Eu comecei a anotar." and not again.has("Então não fui só eu."), "depois, Durn não repete o gancho (C25: passa aos horários) %s" % str(again))
	# ESTADO FINAL
	var story := _story(game)
	t.check(story["quests"] == [["vardhelm_the_hours"], ["vardhelm_first_echo", "vardhelm_sealed_panel"]] and story["world_reacted"] == [true, "after_echo"], "estado final: as duas etapas concluídas (C25: os horários abertos), mundo pós-Eco")
	t.check(game.narrative_controller.world_state.memories.count("vardhelm_first_echo_complete") == 1 and _count("echo_triggered") == 1 and _count("quest_completed") == 2 and _count("quest_started") == 3, "nada duplicado ao longo da sequência (C25: + o início dos horários)")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_save_load(t) -> void:
	t.section("C14 — Save/Load em cada etapa (A–E)")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_talk(game, 0)
	# A. Save antes do Eco → Eco → Load: estado anterior.
	_key(t, KEY_S)
	var state_a := _story(game)
	game.echo.interact(game.player)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), state_a), "A. Save antes do Eco → Eco → Load: de volta ao antes do Eco")
	game.echo.interact(game.player)
	# B. Save depois do Eco → Durn → Load: Durn reage de novo, do começo.
	_key(t, KEY_S)
	var state_b := _story(game)
	_talk(game, 0)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), state_b), "B. Save depois do Eco → conversa → Load: estado anterior à conversa")
	var lines := _talk(game, 1)
	t.check(lines[0] == "...Você voltou." and game.dialogue_controller.persistent_state.last_choice("vardhelm_after_echo", "start") == "unsure", "B. diálogo correto depois do Load (conversa pós-Eco inteira, uma vez)")
	# C. Save durante a investigação → Load: investigação continua.
	_key(t, KEY_S)
	var state_c := _story(game)
	_observation(game, "sealed_panel").interact(game.player)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), state_c) and game.objective_label.text == "Procure o painel selado no fundo do setor.", "C. Save durante a investigação → Load: investigação ativa de novo")
	t.check(not _ambient(game).is_closing_silence_active(), "C. o Load interrompe o encerramento que estava tocando")
	# D. Save depois do painel → Load: painel concluído; a fala final ainda não foi dita.
	_observation(game, "sealed_panel").interact(game.player)
	_key(t, KEY_S)
	var state_d := _story(game)
	_talk(game)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), state_d) and game.objective_label.text == "✓ O painel selado — ainda fechado.", "D. Save depois do painel → Load: painel concluído")
	t.check(not _ambient(game).is_closing_silence_active(), "D. o Load não toca o encerramento de novo")
	t.check(_talk(game)[0] == "...Você ouviu, não ouviu?", "D. depois do Load Durn diz a fala final (ela era posterior ao save)")
	# E. Save final → Load repetido.
	_key(t, KEY_S)
	var state_e := _story(game)
	var before := _events.size()
	_key(t, KEY_L)
	_key(t, KEY_L)
	_key(t, KEY_L)
	var load_events := _events.slice(before)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_story(game), state_e) and _talk(game)[0] == "...Eu comecei a anotar.", "E. Load repetido (3×): mesmo estado final; Durn não repete o gancho (C25: os horários)")
	t.check(load_events.count("game_loaded") == 3 and load_events.count("consequence_applied") == 0 and load_events.count("quest_completed") == 0 and load_events.count("dialogue_completed") == 0 and load_events.count("echo_triggered") == 0 and load_events.count("memory_recovered") == 0 and load_events.count("observation_discovered") == 0, "Loads não reemitem diálogo, quest, consequência, Eco, memória nem observação (%s)" % str(load_events))
	var world := game.narrative_controller.world_state
	var projected: GameState = SaveV2RuntimeSnapshot.project(VardhelmRuntimeStateProvider.new(game).build_targets())["state"]
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and world.memories.count("vardhelm_heard_echo") == 1 and game.quest_controller.states.completed.size() == 2 and projected.world.observations.size() == 1 and projected.dialogue.to_dict().get("completed", []).size() == 4, "nenhuma duplicação: memórias, quests, observação, 4 diálogos concluídos (C25: + os horários)")
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "sombra sem divergência no save final")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_closing_and_load(t) -> void:
	t.section("C14 — encerramento: transitório, nunca reaplicado pelo Load")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, 0)
	game.echo.interact(game.player)
	_talk(game, 0)
	var resting := _volumes(game)
	t.check(resting == [-6.0, -16.0, -30.0], "som de repouso pós-Eco: zumbido -6, vapor -16, máquinas -30 %s" % str(resting))
	# C14.1: o silêncio alcança TODAS as fontes de ambiente do jogo, fundo o bastante para
	# o zumbido contínuo (a fonte mais alta, ~-16 dBFS no arquivo) não mascarar a quebra.
	var closing: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vardhelm/ambient_life.json"))["after_echo"]["closing_silence"]
	var ambient_players: Array = game.find_children("*", "AudioStreamPlayer", true, false).map(func(p): return "VardhelmAudio/%s" % p.name)
	ambient_players.sort()
	var silenced: Array = (closing["audio"] as Array).duplicate()
	silenced.sort()
	t.check(silenced == ambient_players and float(closing["silent_db"]) == -70.0, "C14.2: o silêncio cobre todas as fontes de ambiente %s com piso %.0f dB" % [str(ambient_players), float(closing["silent_db"])])
	t.check(float(closing["fade_out"]) == 1.4 and float(closing["hold"]) == 4.0 and float(closing["fade_in"]) == 3.0, "C14.1: duração do encerramento inalterada (1,4 + 4 + 3 s)")
	_key(t, KEY_S)
	_observation(game, "sealed_panel").interact(game.player)
	t.check(_ambient(game).is_closing_silence_active(), "encerramento tocando")
	_ambient(game).play_closing_silence()
	t.check(_ambient(game).is_closing_silence_active(), "chamar de novo não empilha outro encerramento")
	# Load no meio do silêncio: volta para antes do painel com o som de repouso e a luz piscando.
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and not _ambient(game).is_closing_silence_active() and _volumes(game) == resting and _ambient(game).is_after_echo_world_applied(), "Load no meio do encerramento: som e luz no estado derivado %s" % str(_volumes(game)))
	t.check(game.quest_controller.states.active.has("vardhelm_sealed_panel"), "investigação ativa de novo; o encerramento volta a acontecer ao examinar")
	_observation(game, "sealed_panel").interact(game.player)
	t.check(_ambient(game).is_closing_silence_active(), "encerramento ao concluir de novo depois do Load")
