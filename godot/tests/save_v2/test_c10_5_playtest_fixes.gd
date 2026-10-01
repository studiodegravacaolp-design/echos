extends RefCounted

## Bloco C10.5 — correções do playtest humano:
##   1. Ctrl+L/Ctrl+S (padrão = V2) nunca chamam o SaveService legado; o jogo segue
##      respondendo depois do Load (sem pausa, sem execução dupla);
##   2. layout estrutural (DialogueBox / notificação) dentro da área visível;
##   3. sequência de Durn menos explicativa (só chaves de localização; IDs intactos).
## Flags no PADRÃO do jogo (ON); só o caminho do arquivo é redirecionado para o teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c10_5_v2.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const OBSERVATIONS := ["maintenance_board", "sealed_panel", "tool_rack"]
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const FORBIDDEN_IN_DURN := ["eco", "Eco", "memória", "fenômeno", "Aethel", "AETHERIS", "impossível", "lembr"]


## Espião: registra qualquer chamada ao SaveService legado.
class SpySaveService extends SaveService:
	var loads := 0
	var saves := 0

	func load_game(_world_state: WorldState, _quest_state: QuestState, _player: Node3D = null) -> Dictionary:
		loads += 1
		return {}

	func save_game(_world_state: WorldState, _quest_state: QuestState, _language: String, _player: Node3D = null) -> bool:
		saves += 1
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


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


## C12: conversa até o fim; em entradas com escolhas, escolhe a primeira (o Durn pós-Eco tem duas).
func _finish_dialogue(slice: VardhelmVerticalSlice) -> void:
	while slice.dialogue_controller.is_active():
		var has_choice := false
		for child in slice.dialogue_box.choices_box.get_children():
			if child is Button and not child.is_queued_for_deletion():
				has_choice = true
		if has_choice:
			_press_choice(slice, 0)
		else:
			slice.dialogue_box.continue_button.pressed.emit()


func _observation(slice: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return slice.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as EnvironmentalObservation


## Jogo com a configuração PADRÃO (V2 ON); só o arquivo vai para o diretório de teste.
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
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event.event_type), [GameEventCatalog.GAME_SAVED, GameEventCatalog.GAME_LOADED])
	return [game, spy]


func _talk(game: VardhelmVerticalSlice, choice: int = 0) -> void:
	game._npc_interactable.interact(game.player)
	_press_choice(game, choice)
	while game.dialogue_controller.is_active():
		game.dialogue_box.continue_button.pressed.emit()


func _functional(slice: VardhelmVerticalSlice) -> Dictionary:
	var ambient := slice.get_node("AmbientLife") as VardhelmAmbientLife
	var env: Array = ambient.environment_states.keys()
	env.sort()
	var observations := {}
	for id in OBSERVATIONS:
		var node := _observation(slice, id)
		observations[id] = [node.revealed, node.memory_registered]
	return {
		"echo": [slice.echo.revealed, slice.echo.interaction_enabled, (slice.echo.get_node("Visual") as MeshInstance3D).visible],
		"banner": slice.completion_banner.visible, "objective": slice.objective_label.text,
		"environment_states": env, "observations": observations, "npc": slice.npc.interaction_enabled,
		"dialogue": slice.dialogue_controller.persistent_state.to_dict(),
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_load_input(t)
	_test_flows(t)
	_test_layout(t)
	_test_durn_sequence(t)
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


# B, C
func _test_load_input(t) -> void:
	t.section("C10.5 — Ctrl+L / Ctrl+S (padrão V2) não chamam o SaveService legado")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	t.check(game.save_v2_operational_config.enabled and game.save_v2_operational_config.save_enabled, "configuração padrão do jogo: Load/Save V2 ligados")
	var load_events := InputMap.action_get_events("load_game")
	t.check(load_events.size() == 1 and (load_events[0] as InputEventKey).ctrl_pressed and (load_events[0] as InputEventKey).physical_keycode == KEY_L, "Ctrl+L registrado uma única vez no InputMap (load_game)")
	var old_before: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_talk(game)
	_key(t, KEY_S)
	t.check(game.last_v2_save_result != null and game.last_v2_save_result.is_success() and spy.saves == 0 and (FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null) == old_before, "Ctrl+S → Save V2; SaveService.save_game NÃO chamado; save antigo não criado nem alterado")
	game.player.global_position = MOVED_POSITION
	_events.clear()
	_key(t, KEY_L)
	var first := game.last_v2_load_result
	t.check(first != null and first.is_success() and spy.loads == 0, "Ctrl+L → Load V2 (%s); SaveService.load_game NÃO chamado" % (first.describe() if first != null else "sem resultado"))
	t.check(_events == ["game_loaded"], "execução única: um só game_loaded (%s)" % str(_events))
	t.check(not t.paused and game.is_processing_unhandled_input() and game.can_process() and game.player.global_position == SAVE_POSITION, "jogo segue respondendo: árvore não pausada, input ativo, estado carregado")
	_key(t, KEY_S)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result != first and game.last_v2_load_result.is_success() and spy.loads == 0 and spy.saves == 0, "novos Ctrl+S/Ctrl+L continuam funcionando, sempre pelo V2")
	# Controle: com as flags desligadas EXPLICITAMENTE o legado é quem responde (o espião vê).
	game.save_v2_operational_config = SaveV2OperationalConfig.create(false, V2_FILE, false)
	game.shadow_save_v2 = null
	_key(t, KEY_L)
	t.check(spy.loads == 1, "controle: flags OFF explícitas → caminho legado (o espião detecta a chamada)")
	var source := FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_load_coordinator.gd") + FileAccess.get_file_as_string("res://scripts/save_v2/save_v2_runtime_save_coordinator.gd")
	t.check(not source.contains("save_service.") and not source.contains("load_game("), "coordenadores V2 não referenciam o SaveService legado")


# D–H
func _test_flows(t) -> void:
	t.section("C10.5 — fluxos com o padrão V2")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_talk(game)
	_key(t, KEY_S)
	var before_echo := {"functional": _functional(game), "position": game.player.global_position}
	game.echo.interact(game.player)
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), before_echo["functional"]) and game.player.global_position == before_echo["position"], "D/E. Save antes do Eco → Eco → Load: estado anterior restaurado")
	game.echo.interact(game.player)
	_key(t, KEY_S)
	var after_echo := _functional(game)
	game.player.global_position = MOVED_POSITION
	game.npc.set_interaction_enabled(false)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_functional(game), after_echo), "F. Save depois do Eco → alterar → Load: estado pós-Eco")
	game._npc_interactable.interact(game.player)
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.status == SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE and game.status_label.text == "Termine a conversa antes de carregar o jogo." and game.dialogue_box.visible, "G. Load durante diálogo: rejeitado com a mensagem existente; diálogo aberto")
	_press_choice(game, 1)
	_finish_dialogue(game)
	_key(t, KEY_S)
	game.dialogue_controller.persistent_state.record_choice("vardhelm_after_echo", "start", "found")
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and game.dialogue_controller.persistent_state.last_choice("vardhelm_after_echo", "start") == "unsure" and game.dialogue_controller.persistent_state.last_choice("vardhelm_intro", "start") == "learn" and not game.dialogue_controller.is_active(), "H. Load depois de uma escolha concluída: última escolha (C12: conversa pós-Eco, unsure) restaurada, diálogo não reaberto")
	t.check(spy.loads == 0 and spy.saves == 0, "nenhuma chamada ao SaveService legado em todo o fluxo")


# I
func _test_layout(t) -> void:
	t.section("C10.5 — layout estrutural (redimensionamento)")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var box := game.dialogue_box
	t.check(box.anchor_left == 0.0 and box.anchor_right == 1.0 and box.anchor_top == 1.0 and box.anchor_bottom == 1.0 and box.offset_left == 24.0 and box.offset_right == -24.0 and box.offset_bottom == -36.0 and box.grow_vertical == Control.GROW_DIRECTION_BEGIN, "DialogueBox: ancorada embaixo, 24 px nas laterais, 36 px embaixo, cresce para cima")
	var note := game.memory_notification_panel
	t.check(note.anchor_left == 0.5 and note.anchor_right == 0.5 and note.anchor_top == 1.0 and note.offset_left == -280.0 and note.offset_right == 280.0, "notificação de memória: ancorada no centro-inferior (560 px)")
	game._npc_interactable.interact(game.player)
	game.memory_notification_panel.visible = true
	var visible_rect: Rect2 = t.root.get_visible_rect()
	var outside: Array = []
	for pair_item in [["objetivo", game.objective_panel], ["dialogo", box], ["observacao", game.observation_panel], ["notificacao", note], ["banner", game.completion_banner], ["hint", game.interaction_hint]]:
		var control: Control = pair_item[1]
		if not visible_rect.encloses(control.get_global_rect()):
			outside.append("%s %s" % [pair_item[0], control.get_global_rect()])
	t.check(outside.is_empty(), "todos os elementos dentro da área visível %s (%s)" % [visible_rect, str(outside)])
	var project := FileAccess.get_file_as_string("res://project.godot")
	t.check(project.contains("window/stretch/mode=\"canvas_items\"") and project.contains("window/stretch/aspect=\"expand\""), "stretch canvas_items + aspect expand (estrutura mantida)")


# J
func _test_durn_sequence(t) -> void:
	t.section("C10.5 — sequência de Durn")
	var catalog: Dictionary = JSON_LOADER.read_dictionary(LOCALE_PATH)
	var localization := LocalizationService.new()
	localization.register_catalog("pt-BR", catalog)
	var dialogue: DialogueData = JSON_LOADER.load_dialogue(DIALOGUE_PATH)
	var ids: Array = []
	var not_keys: Array = []
	for entry: DialogueEntry in dialogue.entries:
		ids.append(entry.entry_id)
		if not catalog.has(entry.text):
			not_keys.append(entry.entry_id)
	t.check(ids == ["start", "memory", "end"] and dialogue.get_entry("start").choices.map(func(c): return c.choice_id) == ["learn", "leave"] and dialogue.get_entry("start").choices[0].consequences == ["vardhelm_heard_echo"], "IDs de entrada/escolha e consequência inalterados (DialogueState compatível)")
	t.check(not_keys.is_empty(), "todas as falas vêm de chaves de localização (nenhum texto solto nos dados)")
	for path in [["learn", 0, ["...Você também sentiu isso?", "...Nada. Deve ter sido nada.", "Se acontecer de novo... procure por mim."]], ["leave", 1, ["...Você também sentiu isso?", "Se acontecer de novo... procure por mim."]]]:
		var controller := DialogueController.new()
		var shown: Array = []
		controller.entry_changed.connect(func(entry: DialogueEntry) -> void: shown.append(localization.tr_key(entry.text)))
		controller.start_dialogue(dialogue, "start")
		controller.select_choice(dialogue.get_entry("start").choices[path[1]].choice_id)
		while controller.is_active():
			controller.advance()
		t.check(shown == path[2] and controller.persistent_state.last_choice("vardhelm_intro", "start") == path[0], "caminho %s: %s" % [path[0], " → ".join(PackedStringArray(shown))])
		controller.free()
	var durn_lines: Array = [catalog["dialogue.vardhelm.greeting"], catalog["dialogue.vardhelm.pause"], catalog["dialogue.vardhelm.farewell"], catalog["dialogue.vardhelm.choice.memory"], catalog["dialogue.vardhelm.choice.leave"]]
	var explicit: Array = []
	for line in durn_lines:
		for token in FORBIDDEN_IN_DURN:
			if String(line).contains(token):
				explicit.append("%s:%s" % [line, token])
	t.check(explicit.is_empty(), "Durn não nomeia nem explica o fenômeno (%s)" % str(explicit))
	t.check(localization.tr_key("npc.vardhelm.elder.name") == "Durn", "falante continua Durn")
	localization.free()
