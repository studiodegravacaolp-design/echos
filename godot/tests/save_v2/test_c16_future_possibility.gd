extends RefCounted

## Bloco C16 — uma escolha muda uma possibilidade futura (headless, determinístico).
##   "Não senti nada." (C15: consequence.vardhelm.felt_nothing → Durn sai sozinho no Eco)
##   → no lugar de sempre de Durn fica o que ele fazia: a folha (observation.vardhelm.durn_notes)
##   passa a poder ser examinada. Em "Sentir o quê?" Durn nunca sai: não há folha.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c16.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const NOTES := "durn_notes"
const NOTES_ID := "observation.vardhelm.durn_notes"
const LEARN := 0
const LEAVE := 1
const FORBIDDEN := ["eco", "memória", "lembr", "aethel", "aetheris", "asterion", "cinzento", "véu", "origem", "cosmo", "escolha", "desbloque", "consequência"]


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


func _talk(slice: VardhelmVerticalSlice, choice: int = 0) -> Array:
	var lines: Array = []
	slice._npc_interactable.interact(slice.player)
	var guard := 0
	while slice.dialogue_controller.is_active() and guard < 20:
		lines.append(slice.dialogue_box.text_label.text)
		var buttons: Array = slice.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			slice.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[choice] as Button).pressed.emit()
		guard += 1
	return lines


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
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event))
	return [game, spy]


func _types(from: int = 0) -> Array:
	return _events.slice(from).map(func(e: GameEvent): return e.event_type)


func _ambient(slice: VardhelmVerticalSlice) -> VardhelmAmbientLife:
	return slice.get_node("AmbientLife") as VardhelmAmbientLife


func _notes(slice: VardhelmVerticalSlice) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % NOTES) as EnvironmentalObservation


## A possibilidade futura, como o jogador a encontra.
func _possibility(slice: VardhelmVerticalSlice) -> Dictionary:
	var notes := _notes(slice)
	var marker := notes.get_node("Marker") as Node3D
	return {
		"available": notes.interaction_enabled, "visible": marker.visible, "revealed": notes.revealed,
		"seen_flag": slice.narrative_controller.world_state.has_flag("observation_durn_notes_seen"),
		"durn_away": slice.is_durn_away_from_home(),
		"notes_nodes": slice.get_node("AmbientLife/EnvironmentalObservations").get_children().filter(func(c): return c.name == NOTES).size(),
		"durns": slice.get_children().filter(func(c): return c is NPCController).size(),
	}


## A caminhada de Durn é um tween; no headless, avança até o fim.
func _finish_walk(slice: VardhelmVerticalSlice) -> void:
	if slice._durn_walk != null and slice._durn_walk.is_valid():
		slice._durn_walk.custom_step(10.0)


func _examine(slice: VardhelmVerticalSlice) -> bool:
	return _notes(slice).interact(slice.player)


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_data(t)
	_test_paths(t)
	_test_events(t)
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
	t.section("C16 — a possibilidade: uma observação existente, IDs estáveis, texto contido")
	t.check(GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, NOTES) == NOTES_ID, "ID estável: %s" % NOTES_ID)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vardhelm/ambient_life.json"))
	var defs: Array = (data["conditional_observations"] as Array).filter(func(o): return o["id"] == NOTES)
	var spawn: Array = [-4.0, -2.0]
	t.check((data["observations"] as Array).size() == 3 and defs.size() == 1 and bool(defs[0]["starts_unavailable"]) and not defs[0].has("memory_id") and [float(defs[0]["position"][0]), float(defs[0]["position"][2])] == spawn, "uma observação condicional (tipo existente, lista separada: as 3 de sempre intactas), indisponível até a condição, sem memória nova, no lugar de sempre de Durn")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/localization/pt-BR.json"))
	var text := (String(catalog.get("observation.durn_notes.title", "")) + " " + String(catalog.get("observation.durn_notes.text", ""))).to_lower()
	var found: Array = FORBIDDEN.filter(func(w): return text.contains(w))
	t.check(not text.strip_edges().is_empty() and found.is_empty(), "texto observacional, sem explicar nem falar de sistema (%s)" % str(found))


func _test_paths(t) -> void:
	t.section("C16 — caminho A × caminho B: a mesma situação, possibilidades diferentes")
	# Caminho A: "Sentir o quê?"
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	t.check(not _possibility(game)["available"] and not _possibility(game)["visible"], "antes da escolha: nenhuma folha (indisponível e invisível)")
	_talk(game, LEARN)
	game.echo.interact(game.player)
	_finish_walk(game)
	var a := _possibility(game)
	t.check(not a["available"] and not a["visible"] and not a["durn_away"], "caminho A depois do Eco: Durn no lugar de sempre, nenhuma folha %s" % str(a))
	t.check(not _examine(game) and not _notes(game).revealed, "caminho A: não há o que examinar ali (o E continua sendo para Durn)")
	# Caminho B: "Não senti nada."
	pair = _new_game(t)
	game = pair[0]
	_talk(game, LEAVE)
	t.check(not _possibility(game)["available"], "caminho B antes do Eco: ainda nenhuma folha (Durn continua ali)")
	game.echo.interact(game.player)
	_finish_walk(game)
	var b := _possibility(game)
	t.check(b["available"] and b["visible"] and b["durn_away"] and not b["revealed"], "caminho B depois do Eco: Durn sai e a folha fica no lugar dele %s" % str(b))
	var memories_before := game.narrative_controller.world_state.memories.size()
	t.check(_examine(game) and game.observation_panel.visible and game.observation_title.text == "Folha dobrada" and game.observation_text.text.begins_with("Uma folha dobrada, caída onde Durn costumava ficar."), "examinar: \"%s\"" % game.observation_text.text)
	t.check(_notes(game).revealed and game.narrative_controller.world_state.has_flag("observation_durn_notes_seen") and game.narrative_controller.world_state.memories.size() == memories_before, "observação registrada (flag do sistema de observações); nenhuma memória nova")
	t.check(a != b, "diferença real entre os caminhos")
	t.check(game.quest_controller.states.completed.size() == 1 and not game.quest_controller.states.active.has("vardhelm_sealed_panel"), "a folha não mexe nas quests (C12/C14 seguem iguais)")


func _test_events(t) -> void:
	t.section("C16 — EventBus: escolha → consequência → mundo → possibilidade")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	_finish_walk(game)
	_examine(game)
	_examine(game)
	var chain: Array = []
	for e: GameEvent in _events:
		match e.event_type:
			"dialogue_choice_selected":
				chain.append("escolha:%s" % e.payload["choice_id"])
			"consequence_applied":
				chain.append("consequência:%s" % e.payload["consequence_id"])
			"world_state_changed":
				chain.append("mundo:%s" % e.payload["state_id"])
			"observation_discovered":
				chain.append("observação:%s" % e.payload["observation_id"])
	t.check(chain == ["escolha:leave", "consequência:consequence.vardhelm.felt_nothing", "mundo:envstate.vardhelm.durn_alone", "consequência:consequence.vardhelm.first_echo_complete", "mundo:envstate.vardhelm.echo_awakened", "observação:%s" % NOTES_ID], "rastreável, uma vez cada (reexame não repete): %s" % str(chain))
	t.check(game.shadow_state.game_state.world.observations.has(NOTES_ID) and game.shadow_state.diagnostics.is_empty(), "GameState sombra registrou a observação, sem ID fora do catálogo")


func _test_save_load(t) -> void:
	t.section("C16 — Save/Load: a possibilidade persiste, o save de antes da escolha a desfaz")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	# 1. antes da escolha (Save A)
	_key(t, KEY_S)
	var state_a := _possibility(game)
	# 2–5. escolha → consequência → a possibilidade → examinar
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	_finish_walk(game)
	_examine(game)
	var state_b := _possibility(game)
	t.check(state_b["available"] and state_b["revealed"], "caminho B: folha disponível e examinada")
	# 6. Save; 7. alterar; 8. Load
	_key(t, KEY_S)
	var saved := FileAccess.get_file_as_string(V2_FILE)
	t.check(saved.contains(NOTES_ID) and saved.contains("consequence.vardhelm.felt_nothing") and not saved.contains("\"available\"") and not saved.contains("durn_alone"), "Save V2: observação e consequência por ID canônico; disponibilidade não salva (derivada)")
	game.player.global_position = MOVED_POSITION
	game.npc.global_position = MOVED_POSITION
	_ambient(game).set_observation_available(NOTES, false)
	var before := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_possibility(game), state_b), "Load: a folha continua lá, examinada, e Durn fora do lugar de sempre %s" % str(_possibility(game)))
	# 9–10. voltar à interação
	t.check(_examine(game) and game.observation_text.text.begins_with("Uma folha dobrada"), "voltar à folha depois do Load: mesma possibilidade")
	# 11–13. Save + Load de novo: idempotência
	_key(t, KEY_S)
	_key(t, KEY_L)
	_key(t, KEY_L)
	var types := _types(before)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_possibility(game), state_b), "Save + Load repetidos: mesmo resultado")
	t.check(types.count("observation_discovered") == 0 and types.count("consequence_applied") == 0 and types.count("world_state_changed") == 0 and types.count("game_loaded") == 3, "nada reemitido por Loads nem pelo reexame (%s)" % str(types))
	t.check(_possibility(game)["notes_nodes"] == 1 and _possibility(game)["durns"] == 1, "nenhuma folha nem Durn duplicado")
	# Save de ANTES da escolha: a possibilidade volta ao estado anterior.
	var file := FileAccess.open(V2_FILE, FileAccess.WRITE)
	file.close()
	pair = _new_game(t)
	game = pair[0]
	_key(t, KEY_S)
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	_finish_walk(game)
	_examine(game)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_possibility(game), state_a) and not game.narrative_controller.world_state.has_flag("vardhelm_felt_nothing"), "Load do save de antes da escolha: sem folha, não examinada, Durn no lugar %s" % str(_possibility(game)))
	# Caminho A: depois de um Load continua sem folha.
	_talk(game, LEARN)
	game.echo.interact(game.player)
	_finish_walk(game)
	_key(t, KEY_S)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and not _possibility(game)["available"] and not _possibility(game)["durn_away"], "caminho A salvo e carregado: continua sem folha, Durn no lugar")
	t.check(spy.calls == 0 and pair[1].calls == 0, "SaveService legado nunca chamado")
