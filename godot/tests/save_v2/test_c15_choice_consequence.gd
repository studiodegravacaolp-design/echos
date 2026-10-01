extends RefCounted

## Bloco C15 — primeira escolha com consequência perceptível (headless, determinístico).
##   escolha "Não senti nada." (dialogue.vardhelm.intro / start / leave)
##   → consequência consequence.vardhelm.felt_nothing (fonte: a primeira conversa)
##   → estado de ambiente envstate.vardhelm.durn_alone
##   → depois do Eco, Durn não espera o jogador: vai sozinho até onde o Eco aconteceu.
##   "Sentir o quê?" (learn) mantém tudo como antes: Durn espera no lugar de sempre.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c15.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const ALONE_SPOT := Vector3(1.1, 0.25, -3.4)
const LEARN := 0
const LEAVE := 1


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


func _talk(slice: VardhelmVerticalSlice, choice: int = 0) -> Array:
	var lines: Array = []
	slice._npc_interactable.interact(slice.player)
	var guard := 0
	while slice.dialogue_controller.is_active() and guard < 20:
		lines.append(slice.dialogue_box.text_label.text)
		var buttons := _buttons(slice)
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


func _durn_count(slice: VardhelmVerticalSlice) -> int:
	return slice.get_children().filter(func(c): return c is NPCController).size()


## O que importa para a consequência (decisão, consequência, estado, onde Durn está).
func _choice_state(slice: VardhelmVerticalSlice) -> Dictionary:
	var world := slice.narrative_controller.world_state
	var env: Array = _ambient(slice).environment_states.keys()
	env.sort()
	return {
		"decision": slice.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start"),
		"felt_nothing": [world.has_flag("vardhelm_felt_nothing"), world.memories.count("vardhelm_felt_nothing")],
		"environment": env,
		"durn_at": [snappedf(slice.npc.global_position.x, 0.01), snappedf(slice.npc.global_position.z, 0.01)],
		"durns": _durn_count(slice),
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_ids(t)
	_test_both_branches(t)
	_test_events(t)
	_test_save_load(t)
	_test_c14_on_this_branch(t)
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


func _test_ids(t) -> void:
	t.section("C15 — IDs estáveis, uma escolha, uma consequência")
	t.check(GameIdCatalog.canonical_id(GameIdCatalog.KIND_CONSEQUENCE, "vardhelm_felt_nothing") == "consequence.vardhelm.felt_nothing" and GameIdCatalog.canonical_id(GameIdCatalog.KIND_ENVSTATE, "durn_alone") == "envstate.vardhelm.durn_alone", "IDs canônicos: consequence.vardhelm.felt_nothing → envstate.vardhelm.durn_alone")
	t.check(GameIdCatalog.CONSEQUENCE_SOURCES.get("consequence.vardhelm.felt_nothing", {}) == {"source_type": "dialogue", "source_id": "dialogue.vardhelm.intro"}, "fonte da consequência: a primeira conversa (dialogue.vardhelm.intro)")
	var intro: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/vardhelm_intro.json"))
	var choices: Array = intro["entries"][0]["choices"]
	t.check(choices.size() == 2 and choices[0]["consequences"] == ["vardhelm_heard_echo"] and choices[1]["choice_id"] == "leave" and choices[1]["consequences"] == ["vardhelm_felt_nothing"], "a escolha existente \"leave\" ganhou a consequência; \"learn\" continua igual; nenhuma escolha nova")
	var locale := FileAccess.get_file_as_string("res://data/localization/pt-BR.json")
	t.check(not locale.contains("felt_nothing") and not locale.contains("durn_alone"), "nenhum texto novo para o jogador (nada explica a consequência)")


func _test_both_branches(t) -> void:
	t.section("C15 — os dois caminhos: antes da escolha, escolha, depois do Eco")
	# "Não senti nada."
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var home := game.npc.global_position
	t.check(not game.is_durn_away_from_home() and _ambient(game).environment_states.is_empty(), "antes da escolha (estado A): Durn no lugar de sempre")
	var lines := _talk(game, LEAVE)
	t.check(lines == ["...Você também sentiu isso?", "Se acontecer de novo... procure por mim."], "conversa inicial inalterada no caminho \"Não senti nada.\" %s" % str(lines))
	var state := _choice_state(game)
	t.check(state["decision"] == "leave" and state["felt_nothing"] == [true, 1] and state["environment"] == ["durn_alone"], "decisão registrada e consequência aplicada (flag + estado durn_alone) %s" % str(state))
	t.check(not game.is_durn_away_from_home(), "a consequência não aparece de imediato: Durn continua no lugar (espera o Eco)")
	game.echo.interact(game.player)
	t.check(_ambient(game).is_durn_alone_after_echo() and game._durn_walk != null and game._durn_walk.is_valid(), "o Eco acontece: Durn sai andando sozinho (ao vivo)")
	game._durn_walk.custom_step(10.0)
	t.check(game.npc.global_position.is_equal_approx(ALONE_SPOT) and game.is_durn_away_from_home() and _durn_count(game) == 1, "Durn para onde o Eco aconteceu (%s); continua um só Durn" % str(game.npc.global_position))
	t.check(game._npc_interactable.interaction_enabled and game._npc_interactable.global_position.distance_to(ALONE_SPOT) < 0.01, "a conversa acontece onde ele está (interação acompanha o NPC)")
	# Mesma prioridade (Durn = observações = 2): vence o mais próximo. De qualquer ponto
	# junto ao painel o painel vence; de qualquer ponto junto a Durn, Durn vence.
	var panel := (game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as Node3D).global_position
	var rack := (game.get_node("AmbientLife/EnvironmentalObservations/tool_rack") as Node3D).global_position
	var flat := func(v: Vector3) -> Vector2: return Vector2(v.x, v.z)
	var conflicts: Array = []
	for step in 16:
		var angle := TAU * step / 16.0
		for radius in [0.6, 1.0]:
			var near_panel: Vector2 = flat.call(panel) + Vector2(cos(angle), sin(angle)) * radius
			if near_panel.distance_to(flat.call(ALONE_SPOT)) <= near_panel.distance_to(flat.call(panel)) + 0.5:
				conflicts.append("painel@%.1f,%.1f" % [near_panel.x, near_panel.y])
		var near_durn: Vector2 = flat.call(ALONE_SPOT) + Vector2(cos(angle), sin(angle)) * 1.2
		for other in [panel, rack]:
			if near_durn.distance_to(flat.call(other)) <= 1.2 + 0.5:
				conflicts.append("durn@%.1f,%.1f" % [near_durn.x, near_durn.y])
	t.check(conflicts.is_empty(), "sem disputa de interação: junto ao painel o E examina o painel; junto a Durn, fala com ele (margem 0,5 m) %s" % str(conflicts))
	# "Sentir o quê?"
	pair = _new_game(t)
	game = pair[0]
	_talk(game, LEARN)
	game.echo.interact(game.player)
	state = _choice_state(game)
	t.check(state["decision"] == "learn" and state["felt_nothing"] == [false, 0] and not _ambient(game).is_durn_alone_after_echo() and not game.is_durn_away_from_home() and game.npc.global_position.is_equal_approx(home), "caminho \"Sentir o quê?\": nada muda — Durn espera no lugar de sempre, como antes do C15")


func _test_events(t) -> void:
	t.section("C15 — EventBus: escolha → consequência → mundo")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, LEAVE)
	var chain: Array = []
	for e: GameEvent in _events:
		if e.event_type == "dialogue_choice_selected" or e.event_type == "consequence_applied" or e.event_type == "world_state_changed":
			chain.append([e.event_type, e.payload.get("choice_id", e.payload.get("consequence_id", e.payload.get("state_id", "")))])
	t.check(chain == [["dialogue_choice_selected", "leave"], ["consequence_applied", "consequence.vardhelm.felt_nothing"], ["world_state_changed", "envstate.vardhelm.durn_alone"]], "ordem rastreável, uma vez cada: %s" % str(chain))
	var applied: Array = _events.filter(func(e: GameEvent): return e.event_type == "consequence_applied")
	t.check(applied.size() == 1 and applied[0].payload.get("source_type") == "dialogue" and applied[0].payload.get("source_id") == "dialogue.vardhelm.intro", "consequence_applied com a fonte (dialogue.vardhelm.intro)")
	var before := _events.size()
	game.echo.interact(game.player)
	var echo_types := _types(before)
	t.check(echo_types.count("consequence_applied") == 1 and echo_types.count("world_state_changed") == 1, "no Eco: só a consequência do Eco; a da escolha não se repete (%s)" % str(echo_types))
	t.check(game.shadow_state.game_state.world.consequences.has("consequence.vardhelm.felt_nothing") and game.shadow_state.diagnostics.is_empty(), "GameState sombra registrou a consequência, sem ID fora do catálogo")


func _test_save_load(t) -> void:
	t.section("C15 — Save/Load: decisão e consequência persistem, sem duplicar")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	# Save ANTES da escolha: o Load desfaz a decisão e a consequência.
	_key(t, KEY_S)
	var state_a := _choice_state(game)
	# 1. escolher; 2. observar consequência
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_choice_state(game), state_a) and not game.is_durn_away_from_home(), "Load de antes da escolha: sem decisão, sem consequência, Durn no lugar")
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	game._durn_walk.custom_step(10.0)
	var state_b := _choice_state(game)
	t.check(game.npc.global_position.is_equal_approx(ALONE_SPOT), "consequência visível: Durn onde o Eco aconteceu (%s)" % str(game.npc.global_position))
	# 3. Save; 4. alterar; 5. Load; 6. confirmar
	_key(t, KEY_S)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V2_FILE))["state"]
	t.check(saved["world"]["consequences"].has("consequence.vardhelm.felt_nothing") and saved["dialogue"]["choices"]["dialogue.vardhelm.intro"]["start"] == "leave" and not FileAccess.get_file_as_string(V2_FILE).contains("durn_alone"), "Save V2: decisão e consequência por ID canônico; estado de ambiente e posição NÃO salvos (derivados)")
	game.player.global_position = MOVED_POSITION
	game.npc.global_position = MOVED_POSITION
	game.npc.set_interaction_enabled(false)
	var before := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_choice_state(game), state_b) and game.npc.interaction_enabled, "Load: decisão, consequência e Durn onde o Eco aconteceu de novo (já no lugar, sem caminhar)")
	t.check(game._durn_walk == null, "o Load não reencena a caminhada (efeito transitório não reexecutado)")
	# 7. Save de novo; 8. Load de novo; 9. idempotência
	_key(t, KEY_S)
	_key(t, KEY_L)
	_key(t, KEY_L)
	var load_types := _types(before)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_choice_state(game), state_b), "Save + Load repetidos: mesmo resultado %s" % str(_choice_state(game)))
	t.check(load_types.count("consequence_applied") == 0 and load_types.count("dialogue_choice_selected") == 0 and load_types.count("world_state_changed") == 0 and load_types.count("game_loaded") == 3, "Loads não reemitem escolha, consequência nem estado (%s)" % str(load_types))
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_felt_nothing") == 1 and world.memories.count("vardhelm_first_echo_complete") == 1 and _durn_count(game) == 1, "nada duplicado: consequência 1×, Eco 1×, um só Durn")
	t.check(game.last_v2_save_result.shadow_divergence.is_empty(), "sombra sem divergência")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_c14_on_this_branch(t) -> void:
	t.section("C15 — a sequência do C14 continua inteira no caminho \"Não senti nada.\"")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_talk(game, LEAVE)
	game.echo.interact(game.player)
	game._durn_walk.custom_step(10.0)
	var after_echo := _talk(game, 0)
	t.check(after_echo[0] == "...Você voltou." and after_echo.any(func(l): return String(l).contains("painel selado")), "Durn (agora onde o Eco aconteceu) reage ao Eco e aponta o painel — falas do C12 inalteradas")
	(game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as EnvironmentalObservation).interact(game.player)
	t.check(game.quest_controller.states.is_completed("vardhelm_sealed_panel") and _ambient(game).is_closing_silence_active(), "painel examinado: investigação concluída e o silêncio do C14")
	t.check(_talk(game) == ["...Você ouviu, não ouviu?", "Então não fui só eu.", "..."], "gancho do C14 inalterado")
	t.check(game.is_durn_away_from_home() and _ambient(game).is_after_echo_world_applied(), "Durn continua onde o Eco aconteceu; as reações do C13 continuam")
