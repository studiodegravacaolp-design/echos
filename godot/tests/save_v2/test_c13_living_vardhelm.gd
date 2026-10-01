extends RefCounted

## Bloco C13 — Vardhelm reage ao Primeiro Eco (headless, determinístico).
## Três reações sutis e persistentes, DERIVADAS de echo_awakened (flag
## vardhelm_first_echo_complete): luz sobre o painel selado fria e falhando,
## trabalhador da oficina fora da rotina (parado perto do painel), máquinas mais baixas.
## Configuração PADRÃO do jogo (V2); só o arquivo vai para o diretório de teste.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c13.json"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"
const DATA_PATH := "res://data/vardhelm/ambient_life.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const SAVE_POSITION := Vector3(-1.5, 0.25, 1.75)
const MOVED_POSITION := Vector3(4.0, 0.25, -3.0)
const WORKER := "worker_bench_01"
const WORKER_HOME := Vector3(-2.4, 0.0, 2.0)
const EMBER := Color("#FF8A3D")
const COLD := Color("#BFE3EA")


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


func _finish(slice: VardhelmVerticalSlice) -> void:
	var guard := 0
	while slice.dialogue_controller.is_active() and guard < 20:
		var buttons := _buttons(slice)
		if buttons.is_empty():
			slice.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[0] as Button).pressed.emit()
		guard += 1


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


func _ambient(game: VardhelmVerticalSlice) -> VardhelmAmbientLife:
	return game.get_node("AmbientLife") as VardhelmAmbientLife


func _worker(game: VardhelmVerticalSlice) -> Node3D:
	return game.get_node("AmbientLife/AmbientWorkers/%s" % WORKER) as Node3D


func _observation_tool_rack(game: VardhelmVerticalSlice) -> EnvironmentalObservation:
	return game.get_node("AmbientLife/EnvironmentalObservations/tool_rack") as EnvironmentalObservation


func _lamp(game: VardhelmVerticalSlice) -> OmniLight3D:
	return game.get_node("VardhelmSetDressing/WorkLight_00") as OmniLight3D


func _fixture(game: VardhelmVerticalSlice) -> MeshInstance3D:
	return game.get_node("VardhelmSetDressing/WorkLightFixture_00").get_child(0) as MeshInstance3D


func _machinery(game: VardhelmVerticalSlice) -> AudioStreamPlayer:
	return game.get_node("VardhelmAudio/VardhelmMachinery") as AudioStreamPlayer


## O que o jogador percebe do mundo (as três reações + o estado de ambiente).
func _world(game: VardhelmVerticalSlice) -> Dictionary:
	var worker := _worker(game)
	return {
		"environment": _ambient(game).environment_states.keys(),
		"routine": String(worker.get_meta("routine", "")),
		"worker_at_home": worker.position.is_equal_approx(WORKER_HOME),
		"lamp_color": _lamp(game).light_color.to_html(false),
		"lamp_energy": snappedf(_lamp(game).light_energy, 0.001),
		"lamp_range": snappedf(_lamp(game).omni_range, 0.01),
		"fixture_cold": _fixture(game).material_override != null,
		"flicker": _ambient(game).is_after_echo_world_applied(),
		"machinery_db": snappedf(_machinery(game).volume_db, 0.01),
	}


func _before_echo_world() -> Dictionary:
	return {"environment": [], "routine": "default", "worker_at_home": true, "lamp_color": EMBER.to_html(false), "lamp_energy": 0.35, "lamp_range": 2.4, "fixture_cold": false, "flicker": false, "machinery_db": -20.0}


func _intro(game: VardhelmVerticalSlice) -> void:
	game._npc_interactable.interact(game.player)
	(_buttons(game)[0] as Button).pressed.emit()
	_finish(game)


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var backup: Variant = FileAccess.get_file_as_string(OLD_SAVE_PATH) if FileAccess.file_exists(OLD_SAVE_PATH) else null
	_test_data(t)
	_test_reaction(t)
	_test_persistence(t)
	_test_continuity(t)
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
	t.section("C13 — dados: três reações, só no AmbientLife existente, sem texto novo")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	var after: Dictionary = data.get("after_echo", {})
	var routines := (data["workers"] as Array).filter(func(w): return (w as Dictionary).has("after_echo_route"))
	t.check(after.get("environment_state") == "echo_awakened" and routines.size() == 1 and after.has("flicker_light") and after.has("quiet_audio"), "no máximo 3 reações: 1 luz, 1 rotina de trabalhador, 1 som — ligadas a echo_awakened")
	var consequences := (data["narrative_consequences"] as Array).filter(func(c): return c["environment_state"] == "echo_awakened")
	t.check(consequences.size() == 1 and consequences[0]["world_flag"] == "vardhelm_first_echo_complete", "estado persistente reutilizado: flag vardhelm_first_echo_complete → echo_awakened (nenhum estado novo)")
	var locale := FileAccess.get_file_as_string(LOCALE_PATH).to_lower()
	t.check(not locale.contains("mudou") and not locale.contains("alterou o mundo"), "nenhum texto avisa que o mundo mudou")


func _test_reaction(t) -> void:
	t.section("C13 — antes/depois do Eco: o mundo reage sem avisar")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	t.check(t.same_json(_world(game), _before_echo_world()), "antes do Eco (estado A): lâmpada quente e estável, trabalhador na bancada, máquinas -20 dB %s" % str(_world(game)))
	_intro(game)
	t.check(t.same_json(_world(game), _before_echo_world()), "conversar com Durn não muda o mundo")
	var before := _events.size()
	game.echo.interact(game.player)
	var world := _world(game)
	t.check(world["environment"] == ["echo_awakened"] and world["routine"] == "after_echo" and world["lamp_color"] == COLD.to_html(false) and world["fixture_cold"] and world["lamp_range"] == 3.6 and world["flicker"] and world["machinery_db"] == -30.0, "depois do Eco (estado B): lâmpada sobre o painel fria e falhando, trabalhador sai da rotina, máquinas -30 dB %s" % str(world))
	var echo_events := _events.slice(before)
	t.check(echo_events.count("consequence_applied") == 1 and echo_events.count("echo_triggered") == 1, "o Eco aplica a consequência uma vez (%s)" % str(echo_events))
	t.check(not game.status_label.text.to_lower().contains("mudou") and not game.observation_panel.visible, "nenhum aviso de que o mundo mudou (status \"%s\")" % game.status_label.text)
	# Re-derivar (como o Load faz) não acumula nem reinicia nada.
	var routine_tween: Tween = _ambient(game)._worker_routines.get(StringName(WORKER))
	var flicker := _ambient(game)._flicker_tween
	game._refresh_persistent_world_state()
	game._refresh_persistent_world_state()
	t.check(t.same_json(_world(game), world) and _ambient(game)._worker_routines.get(StringName(WORKER)) == routine_tween and _ambient(game)._flicker_tween == flicker, "re-aplicar é idempotente (sem -40 dB, sem reiniciar rotina ou piscar)")
	t.check(game.completion_banner.get_parent() == game.objective_panel.get_parent() and game.completion_banner.get_index() == 2, "banner do Eco no HudTop, abaixo do objetivo e do status (não cobre o objetivo)")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_persistence(t) -> void:
	t.section("C13 — Save/Load: estado A e estado B")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	var spy: SpySaveService = pair[1]
	_intro(game)
	_key(t, KEY_S)
	game.echo.interact(game.player)
	var state_b := _world(game)
	game.player.global_position = MOVED_POSITION
	var before := _events.size()
	_key(t, KEY_L)
	var load_events := _events.slice(before)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_world(game), _before_echo_world()), "Save antes do Eco → Eco → Load: estado A volta (lâmpada, trabalhador em casa, som) %s" % str(_world(game)))
	t.check(load_events.count("consequence_applied") == 0 and load_events.count("echo_triggered") == 0 and load_events.count("game_loaded") == 1, "Load não reaplica a reação como se o Eco tivesse acontecido (%s)" % str(load_events))
	game.echo.interact(game.player)
	t.check(t.same_json(_world(game), state_b), "Eco de novo após o Load: estado B (resync)")
	_key(t, KEY_S)
	t.check(game.last_v2_save_result.is_success() and game.last_v2_save_result.shadow_divergence.is_empty(), "Save depois do Eco: sombra sem divergência")
	# Alterar o mundo (como o jogador) e carregar: estado B volta, sem acumular.
	# (Zerar à mão o estado derivado deixa o runtime incoerente com a flag; o Load
	# recusa com SNAPSHOT_NOT_REVERSIBLE — proteção existente, não é o que o jogador faz.)
	game.player.global_position = MOVED_POSITION
	game.npc.set_interaction_enabled(false)
	_observation_tool_rack(game).interact(game.player)
	before = _events.size()
	_key(t, KEY_L)
	_key(t, KEY_L)
	load_events = _events.slice(before)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_world(game), state_b), "Save depois do Eco → Load (repetido): estado B continua, -30 dB (não -40) %s" % str(_world(game)))
	t.check(load_events.count("consequence_applied") == 0 and load_events.count("echo_triggered") == 0 and load_events.count("observation_discovered") == 0 and load_events.count("memory_recovered") == 0 and load_events.count("game_loaded") == 2, "dois Loads: nenhuma consequência, memória, observação ou Eco reemitidos (%s)" % str(load_events))
	var world := game.narrative_controller.world_state
	t.check(world.memories.count("vardhelm_first_echo_complete") == 1 and game.quest_controller.states.completed.size() == 1, "nenhuma consequência/quest duplicada")
	t.check(spy.calls == 0, "SaveService legado nunca chamado")


func _test_continuity(t) -> void:
	t.section("C13 — continuidade: quest, Durn, painel (fechado), status")
	var pair := _new_game(t)
	var game: VardhelmVerticalSlice = pair[0]
	_intro(game)
	game.echo.interact(game.player)
	t.check(game.status_label.text == VardhelmVerticalSlice.ECHO_DONE_STATUS, "logo após o Eco o status de conclusão aparece (como antes)")
	game._npc_interactable.interact(game.player)
	t.check(game.dialogue_controller.current_session.dialogue.dialogue_id == "vardhelm_after_echo" and game.dialogue_box.text_label.text == "...Você voltou.", "Durn: conversa pós-Eco do C12, inalterada")
	_finish(game)
	t.check(game.quest_controller.states.active.has("vardhelm_sealed_panel") and game.status_label.text != VardhelmVerticalSlice.ECHO_DONE_STATUS, "investigação ativa; status do Eco não fica preso (\"%s\")" % game.status_label.text)
	var panel := game.get_node("AmbientLife/EnvironmentalObservations/sealed_panel") as EnvironmentalObservation
	panel.interact(game.player)
	t.check(game.quest_controller.states.is_completed("vardhelm_sealed_panel") and game.observation_text.text == game.localization.tr_key("observation.sealed_panel.after_echo"), "painel examinado: mesmo texto do C12, investigação concluída")
	var prop := game.get_node("AmbientLife/EnvironmentalStoryProps/sealed_panel") as MeshInstance3D
	t.check(prop.visible and prop.mesh is BoxMesh and panel.interaction_enabled and _ambient(game).environment_states.keys() == ["echo_awakened"], "painel continua FECHADO: mesma placa, nenhum estado de abertura, sem passagem")
	t.check(_world(game)["flicker"] and _world(game)["routine"] == "after_echo", "reação do mundo continua depois da investigação")
	_key(t, KEY_S)
	var saved := _world(game)
	game.player.global_position = MOVED_POSITION
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and t.same_json(_world(game), saved) and game.quest_controller.states.is_completed("vardhelm_sealed_panel") and game.status_label.text != VardhelmVerticalSlice.ECHO_DONE_STATUS, "Load com tudo concluído: mundo pós-Eco, investigação concluída, status do Eco não volta")
	game._npc_interactable.interact(game.player)
	t.check(game.dialogue_controller.current_session.dialogue.dialogue_id == "vardhelm_after_panel", "Durn depois do painel: fala final do C14 (não repete a pista)")
	_finish(game)
