extends RefCounted

## Bloco C2 — Dual save / dual load em modo sombra, com Ctrl+S / Ctrl+L REAIS
## (InputEventKey empurrado pela viewport até o _unhandled_input do slice).
##
## O SaveService antigo continua operacional e grava seu arquivo real; ele é
## salvo antes e restaurado depois do teste. O Save V2 usa um caminho isolado.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const TEST_DIR := "user://save_v2_tests"
const OLD_SAVE_PATH := "user://echoes_of_the_soul_save.json"

var _old_save_backup: Variant = null


## O input é entregue pela viewport a TODAS as experiências vivas na árvore.
## Antes de cada cenário, remove da árvore as instâncias anteriores (inclusive
## as das outras suítes, ainda aguardando o fim do frame para serem liberadas).
func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _boot(t) -> VardhelmVerticalSlice:
	_isolate(t)
	var slice := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(slice)
	# C10.5: V2 é o padrão; esta suíte testa explicitamente o caminho LEGADO (+ sombra C2).
	slice.save_v2_operational_config = SaveV2OperationalConfig.create(false, SaveV2Service.DEFAULT_PATH, false)
	return slice


func _key(t, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	t.root.push_input(event)


func _ctrl_s(t) -> void:
	_key(t, KEY_S)


func _ctrl_l(t) -> void:
	_key(t, KEY_L)


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


## Tudo o que o jogador/jogo observa: estado de runtime, UI e transform.
func _gameplay_json(slice: VardhelmVerticalSlice) -> String:
	var world := slice.narrative_controller.world_state
	var quests := slice.quest_controller.states
	return JSON.stringify([
		world.flags, world.values, Array(world.memories),
		quests.active, quests.completed, quests.objective_progress,
		slice.echo.revealed, slice.echo.interaction_enabled,
		slice.objective_label.text, slice.status_label.text, slice.completion_banner.visible,
		slice.player.global_position, slice.player.global_rotation,
	], "", true)


func _service(path_name: String) -> SaveV2Service:
	var service := SaveV2Service.new("%s/%s.json" % [TEST_DIR, path_name])
	var now := [5000]
	service.clock = func() -> int:
		now[0] += 1
		return now[0]
	return service


## Fluxo: Durn -> escolha -> diálogo -> Primeiro Eco -> Ctrl+S -> observação -> Ctrl+L.
func _run(t, with_v2: bool, service_name: String) -> Dictionary:
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	var slice := _boot(t)
	var recorded := RecordedEvents.new()
	recorded.attach(slice.shadow_events)
	if with_v2:
		slice.shadow_save_v2.service = _service(service_name)
	else:
		slice.shadow_save_v2 = null
	slice.player.global_position = Vector3(0.75, 0.25, 2.5)
	slice._npc_interactable.interact(slice.player)
	_press_choice(slice, 0)
	slice.dialogue_box.continue_button.pressed.emit()
	slice.dialogue_box.continue_button.pressed.emit()
	slice.echo.interact(slice.player)
	var shadow_at_save := JSON.stringify(slice.shadow_state.snapshot(), "", true)
	_ctrl_s(t)
	var after_save := _gameplay_json(slice)
	var old_save_written := FileAccess.file_exists(OLD_SAVE_PATH)
	var events_after_save := recorded.types()
	(slice.get_node("AmbientLife/EnvironmentalObservations/maintenance_board") as EnvironmentalObservation).interact(slice.player)
	var before_load_count := recorded.count()
	_ctrl_l(t)
	var after_load := _gameplay_json(slice)
	return {
		"slice": slice, "recorded": recorded, "shadow_at_save": shadow_at_save,
		"after_save": after_save, "after_load": after_load, "old_save_written": old_save_written,
		"events_after_save": events_after_save, "load_events": recorded.types().slice(before_load_count),
	}


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	if FileAccess.file_exists(OLD_SAVE_PATH):
		_old_save_backup = FileAccess.get_file_as_string(OLD_SAVE_PATH)
	var control := _run(t, false, "control")
	var dual := _run(t, true, "dual")
	_test_gameplay_unchanged(t, control, dual)
	_test_dual_save(t, dual)
	_test_dual_load(t, dual)
	_test_shadow_not_replaced(t, dual)
	(control["slice"] as Node).queue_free()
	(dual["slice"] as Node).queue_free()
	_test_v2_failures(t)
	_test_boot_writes_nothing(t)
	_restore_old_save()
	_cleanup()


func _test_gameplay_unchanged(t, control: Dictionary, dual: Dictionary) -> void:
	t.section("C2 — gameplay idêntico com e sem Save V2")
	t.check(control["old_save_written"] and dual["old_save_written"], "Ctrl+S grava o save antigo nos dois casos (SaveService operacional)")
	t.check(control["after_save"] == dual["after_save"], "após Ctrl+S: runtime, UI e transform idênticos ao controle sem V2")
	t.check(control["after_load"] == dual["after_load"], "após Ctrl+L: runtime, UI e transform idênticos ao controle sem V2")
	var slice: VardhelmVerticalSlice = dual["slice"]
	t.check(slice.status_label.text == "Jogo salvo.", "status continua o do fluxo antigo (load antigo retorna vazio pelo bug conhecido)")


func _test_dual_save(t, dual: Dictionary) -> void:
	t.section("C2 — Ctrl+S: dual save")
	var slice: VardhelmVerticalSlice = dual["slice"]
	var coordinator := slice.shadow_save_v2
	var report := coordinator.last_save_report
	t.check(report.get("operation") == "save" and report["v2"]["ok"], "Save V2 executado depois do save antigo (%s)" % str(report.get("v2")))
	t.check(coordinator.service.has_save(), "arquivo V2 criado no caminho próprio")
	t.check(coordinator.service.path != OLD_SAVE_PATH and not FileAccess.file_exists(SaveV2Service.DEFAULT_PATH), "V2 não usa o arquivo do SaveService nem o caminho padrão (teste isolado)")
	var events_after_save: Array[String] = dual["events_after_save"]
	t.check(events_after_save.count("game_saved") == 1 and events_after_save.back() == "game_saved", "game_saved publicado uma vez, após o sucesso do V2")
	var recorded: RecordedEvents = dual["recorded"]
	t.check(recorded.matching("game_saved", {"slot_id": "shadow"}).size() == 1, "game_saved {slot_id: shadow}")
	var loaded := coordinator.service.load_game_state()
	t.check(loaded.ok and JSON.stringify(loaded.state.to_dict(), "", true) == dual["shadow_at_save"], "arquivo V2 contém exatamente o GameState sombra do momento do Ctrl+S")


func _test_dual_load(t, dual: Dictionary) -> void:
	t.section("C2 — Ctrl+L: dual load + comparação")
	var slice: VardhelmVerticalSlice = dual["slice"]
	var report := slice.shadow_save_v2.last_load_report
	t.check(report.get("operation") == "load" and report["v2"]["ok"], "Load V2 executado depois do load antigo (%s)" % str(report.get("v2")))
	t.check(report["legacy_loaded"] == false, "relatório registra o resultado do load antigo (vazio: bug conhecido de save_service.gd:44)")
	var load_events: Array[String] = dual["load_events"]
	t.check(JSON.stringify(load_events) == JSON.stringify(["game_loaded"]), "Ctrl+L publica somente game_loaded (após sucesso do V2)")
	var vs_runtime: Dictionary = report["vs_runtime"]
	var vs_shadow: Dictionary = report["vs_shadow"]
	print("   info V2 × runtime: ", vs_runtime["summary"])
	print("   info V2 × sombra:  ", vs_shadow["summary"])
	t.check(vs_runtime["differences"].is_empty() and vs_runtime["missing_in_left"].is_empty(), "V2 × runtime pós-load antigo: nenhuma diferença de valor")
	var runtime_only_dialogue := true
	for path in vs_runtime["missing_in_right"]:
		if not String(path).begins_with("dialogue."):
			runtime_only_dialogue = false
	t.check(runtime_only_dialogue, "V2 × runtime: só o DialogueState falta no runtime (invisível ao projetor)")
	var missing_in_v2: Array = vs_shadow["missing_in_left"]
	t.check(missing_in_v2.has("world.observations.observation.vardhelm.maintenance_board") and missing_in_v2.has("memory.memories.memory.vardhelm.maintenance_board") and missing_in_v2.has("world.flags.observation_maintenance_board_seen"), "V2 × sombra: detecta a observação feita depois do save (a sombra não é ressincronizada)")
	t.check(vs_shadow["differences"].is_empty(), "V2 × sombra: nenhuma outra diferença")
	t.check(vs_runtime["unexpected_ids"].is_empty() and vs_shadow["unexpected_ids"].is_empty(), "nenhum ID inesperado")
	t.check(JSON.parse_string(JSON.stringify(report)) is Dictionary, "relatório é JSON-safe")


func _test_shadow_not_replaced(t, dual: Dictionary) -> void:
	t.section("C2 — V2 não restaura nada")
	var slice: VardhelmVerticalSlice = dual["slice"]
	var state := slice.shadow_state.game_state
	t.check(state.world.is_observation_discovered("observation.vardhelm.maintenance_board"), "GameState sombra mantém a observação posterior ao save (não foi substituído pelo V2)")
	t.check(slice.narrative_controller.world_state.memories.size() == 2, "WorldState não recebeu dados do V2 (memories do runtime inalteradas)")
	t.check(slice.player.global_position == Vector3(0.75, 0.25, 2.5), "Player não foi reposicionado pelo V2")


func _test_v2_failures(t) -> void:
	t.section("C2 — falha do V2 não afeta o fluxo antigo")
	var blocker := FileAccess.open(TEST_DIR + "/blocker", FileAccess.WRITE)
	blocker.store_string("x")
	blocker.close()
	var slice := _boot(t)
	var recorded := RecordedEvents.new()
	recorded.attach(slice.shadow_events)
	slice.shadow_save_v2.service = SaveV2Service.new(TEST_DIR + "/blocker/impossivel.json")
	_ctrl_s(t)
	t.check(slice.status_label.text == "Jogo salvo." and FileAccess.file_exists(OLD_SAVE_PATH), "save antigo concluído mesmo com o V2 falhando")
	t.check(not slice.shadow_save_v2.last_save_report["v2"]["ok"] and slice.shadow_save_v2.last_save_report["v2"]["code"] == SaveV2Errors.IO_ERROR, "falha do V2 fica no relatório (IO_ERROR)")
	t.check(recorded.count("game_saved") == 0, "game_saved NÃO publicado quando o V2 falha")
	_ctrl_l(t)
	t.check(slice.shadow_save_v2.last_load_report["v2"]["code"] == SaveV2Errors.FILE_NOT_FOUND and recorded.count("game_loaded") == 0, "load V2 sem arquivo: FILE_NOT_FOUND e nenhum game_loaded")

	slice.shadow_save_v2.service = _service("corrupt")
	_ctrl_s(t)
	var file := FileAccess.open(slice.shadow_save_v2.service.path, FileAccess.WRITE)
	file.store_string("{corrompido")
	file.close()
	var before := _gameplay_json(slice)
	var before_events := recorded.count("game_loaded")
	_ctrl_l(t)
	t.check(slice.shadow_save_v2.last_load_report["v2"]["code"] == SaveV2Errors.CORRUPTED_DATA, "save V2 corrompido: CORRUPTED_DATA no relatório")
	t.check(recorded.count("game_loaded") == before_events, "game_loaded NÃO publicado quando o V2 falha")
	t.check(_gameplay_json(slice) == before, "load antigo segue igual com o V2 corrompido")
	slice.queue_free()
	DirAccess.remove_absolute(TEST_DIR + "/blocker")


func _test_boot_writes_nothing(t) -> void:
	t.section("C2 — nada é gravado sem Ctrl+S")
	var slice := _boot(t)
	t.check(slice.shadow_save_v2 != null and slice.shadow_save_v2.service.path == SaveV2Service.DEFAULT_PATH, "experiência cria o coordenador com o caminho próprio do V2")
	t.check(not FileAccess.file_exists(SaveV2Service.DEFAULT_PATH), "boot não grava Save V2")
	t.check(slice.shadow_save_v2.last_save_report.is_empty() and slice.shadow_save_v2.last_load_report.is_empty(), "sem relatórios antes do input")
	var coordinator_object: Variant = slice.shadow_save_v2
	t.check(coordinator_object is RefCounted and not (coordinator_object is Node), "coordenador é objeto de runtime (não Node/Autoload)")
	slice.queue_free()


func _restore_old_save() -> void:
	if FileAccess.file_exists(OLD_SAVE_PATH):
		DirAccess.remove_absolute(OLD_SAVE_PATH)
	if _old_save_backup != null:
		var file := FileAccess.open(OLD_SAVE_PATH, FileAccess.WRITE)
		file.store_string(String(_old_save_backup))
		file.close()


func _cleanup() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)
