extends RefCounted

## Bloco C23 — rua do Distrito das Fundições (headless, determinístico).
## Dados, cena (portão sul aberto, rua instanciada), generalizações opcionais do AmbientLife,
## observações/EventBus/GameState e Save/Load V2 na rua. Andar pelo portão com física real
## fica no playtest do C23.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const LEVEL_VALIDATOR := preload("res://scripts/level/level_validator.gd")
const LEVEL_PATH := "res://level_data/vardhelm_foundry_street_01.json"
const LIFE_PATH := "res://data/vardhelm/foundry_street_life.json"
const YARD_LIFE_PATH := "res://data/vardhelm/foundry_district_life.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c23.json"
const OBSERVATIONS := ["foundry_street_gate", "foundry_street_shift_board", "foundry_street_ore_wagons", "foundry_street_sharpening"]
const FORBIDDEN := ["eco", "memória", "lembr", "aethel", "aetheris", "asterion", "cinzento", "origem", "cosmo", "significa", "véu", "experimento", "elyra", "kael", "lurí", "édor", "agora você", "você descobriu"]
const STREET_SPOT := Vector3(-6.0, -11.65, 40.5)
const YARD_SPOT := Vector3(-3.0, -11.65, 20.0)

var _events: Array = []


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _new_game(t) -> VardhelmVerticalSlice:
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	game.player.set_physics_process(false)
	_events.clear()
	game.shadow_events.subscribe(func(event: GameEvent) -> void: _events.append(event))
	return game


func _key(t, physical: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.ctrl_pressed = true
	event.pressed = true
	t.root.push_input(event)


func _types(from: int = 0) -> Array:
	return _events.slice(from).map(func(e: GameEvent): return e.event_type)


func _street(game: VardhelmVerticalSlice) -> VardhelmAmbientLife:
	return game.foundry_district.life_named("StreetLife")


func _observation(game: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return _street(game).get_node("EnvironmentalObservations/%s" % id) as EnvironmentalObservation


func _talk(game: VardhelmVerticalSlice, choice: int) -> void:
	game._npc_interactable.interact(game.player)
	var guard := 0
	while game.dialogue_controller.is_active() and guard < 20:
		var buttons: Array = game.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			game.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[choice] as Button).pressed.emit()
		guard += 1


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_data(t)
	_test_scene(t)
	_test_life(t)
	_test_integration(t)
	_test_save_load(t)
	_isolate(t)
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _test_data(t) -> void:
	t.section("C23 — dados da rua (LevelBuilder, AmbientLife, IDs, textos)")
	var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	var validation: Dictionary = LEVEL_VALIDATOR.validate(level)
	t.check(validation["ok"], "nível da rua válido no LevelValidator %s" % str(validation["errors"]))
	t.check((level["lights"] as Array).is_empty() and not level.has("environment"), "a rua não traz luz direcional nem ambiente próprios")
	var life: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LIFE_PATH))
	var ids: Array = (life["observations"] as Array).map(func(o): return o["id"])
	t.check((life["workers"] as Array).size() == 12 and ids == OBSERVATIONS, "vida da rua: 12 trabalhadores e 4 observações (%s)" % str(ids))
	t.check((life["observations"] as Array).all(func(o): return not o.has("memory_id")) and (life["workers"] as Array).all(func(w): return not w.has("dialogue")), "observações sem memória; trabalhadores anônimos, sem diálogo")
	var canonical := OBSERVATIONS.map(func(id): return GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id))
	t.check(canonical.all(func(id): return String(id).begins_with("observation.vardhelm.foundry_street_") and GameIdCatalog.is_known(GameIdCatalog.KIND_OBSERVATION, id)), "IDs canônicos novos: %s" % str(canonical))
	t.check(GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_SCENARIO] == [GameIdCatalog.SCENARIO_VARDHELM] and GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_NPC] == [GameIdCatalog.NPC_DURN] and (GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_QUEST] as Array).all(func(q): return not String(q).contains("street")), "nenhum cenário, NPC ou quest da rua (a rua é parte de scenario.vardhelm; as quests do C25 são da investigação)")
	var locale: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOCALE_PATH))
	var texts: Array = []
	for id in OBSERVATIONS:
		texts.append(String(locale.get("observation.%s.title" % id, "")))
		texts.append(String(locale.get("observation.%s.text" % id, "")))
	texts.append(String(locale.get("observation.foundry_street_gate.after_echo", "")))
	var offending: Array = []
	for text in texts:
		for word in FORBIDDEN:
			if (text as String).to_lower().contains(word):
				offending.append("%s ← %s" % [word, text])
	t.check(texts.all(func(s): return not (s as String).is_empty() and (s as String).length() <= 110) and offending.is_empty(), "textos presentes, curtos (≤ 110 caracteres) e sem revelar o lore (%s)" % str(offending))
	var yard: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(YARD_LIFE_PATH))
	t.check((yard["workers"] as Array).size() == 6 and (yard["observations"] as Array).size() == 3 and (yard["workers"] as Array).all(func(w): return not w.has("face_movement") and not w.has("facing_degrees")), "vida do pátio intacta (6 trabalhadores, 3 observações, sem as opções novas)")


func _test_scene(t) -> void:
	t.section("C23 — cena: rua pelo portão sul aberto")
	var game := _new_game(t)
	var street_level := game.get_node_or_null("VP03_FoundryStreet") as Node3D
	t.check(street_level != null and street_level.position.is_equal_approx(Vector3(0, -11.9, 39.5)), "nível da rua ao sul do pátio, no mesmo chão (y −11,9)")
	var yard_props := game.get_node("VP02_FoundryDistrict/Generated/Props")
	var bars := yard_props.get_node_or_null("SouthGate_Bars")
	var leaves := [yard_props.get_node_or_null("SouthGate_Leaf_0"), yard_props.get_node_or_null("SouthGate_Leaf_1")]
	t.check(bars == null and leaves.all(func(l): return l != null and l.find_children("*", "StaticBody3D", true, false).size() == 8), "portão sul ABERTO: grade fechada removida; duas folhas abertas com colisão (8 corpos cada)")
	var leaf_x: Array = leaves.map(func(l): return absf((l as Node3D).global_position.x))
	t.check(leaf_x.all(func(x): return is_equal_approx(x, 3.1)), "folhas encostadas nos postes (x ±3,1): vão livre de 5,85 m entre elas")
	var bodies := street_level.find_children("*", "StaticBody3D", true, false)
	var mismatched := bodies.filter(func(b): return b.find_children("*", "MeshInstance3D", false, false).size() != 1 or b.find_children("*", "CollisionShape3D", false, false).size() != 1)
	t.check(bodies.size() > 15 and mismatched.is_empty(), "colisão = geometria na rua: %d corpos, cada um com a própria malha" % bodies.size())
	var far: Array = street_level.get_node("Generated/Props").get_children().filter(func(n): return String(n.name).begins_with("Bg_"))
	t.check(far.all(func(n): return n.find_children("*", "CollisionObject3D", true, false).is_empty()), "cenário distante sem colisão (%d peças)" % far.size())
	t.check(not (street_level.get_node("Camera3D") as Camera3D).current and game.player.camera.current, "a câmera do jogador continua sendo a atual")
	t.check(game.find_children("*", "WorldEnvironment", true, false).size() == 1 and game.find_children("*", "DirectionalLight3D", true, false).size() == 1, "um só WorldEnvironment e uma só luz direcional")
	var district := game.foundry_district
	t.check(district.lives.size() == 2 and _street(game) != null and district.observation_roots().size() == 2 and game.observation_roots().size() == 3, "vidas do distrito: pátio + rua; raízes de observação: Forja, pátio e rua")
	var lights := district.find_children("*", "OmniLight3D", false, false)
	t.check(lights.size() == 6 and lights.all(func(l): return not l.shadow_enabled), "6 lampiões no distrito (3 no pátio + 3 na rua), sem sombra")
	t.check(district.find_children("*", "CPUParticles3D", false, false).size() == 5 and district._animations.size() == 3, "5 emissores de partícula no distrito; 3 animações de cenário (carga da talha, pedal, trem)")


func _test_life(t) -> void:
	t.section("C23 — vida da rua e generalizações opcionais do AmbientLife")
	var game := _new_game(t)
	var workers := _street(game).get_node("AmbientWorkers").get_children()
	t.check(workers.size() == 12 and workers.all(func(w): return w.find_children("*", "AnimatableBody3D", true, false).size() == 1), "12 trabalhadores na rua, cada um com corpo leve (C17.3)")
	var pair := _street(game).get_node("AmbientWorkers/worker_street_pair_01") as Node3D
	t.check(is_equal_approx(pair.rotation_degrees.y, -121.0), "facing_degrees: a dupla parada se olha (%.0f°)" % pair.rotation_degrees.y)
	var cart := _street(game).get_node("AmbientWorkers/worker_street_cart_01") as Node3D
	var carried := cart.get_node("Carry") as Node3D
	t.check(carried.position.is_equal_approx(Vector3(0, 0.45, -0.85)), "carry_offset: o carrinho de mão vai baixo, à frente (%s)" % carried.position)
	var walker := _street(game).get_node("AmbientWorkers/worker_street_walker_01") as Node3D
	var before: float = walker.rotation.y
	_street(game)._face_towards(walker, walker.position + Vector3(1, 0, 0))
	var east: float = walker.rotation.y
	_street(game)._face_towards(walker, walker.position + Vector3(0, 0, 1))
	t.check(is_equal_approx(east, -PI / 2.0) and is_equal_approx(absf(walker.rotation.y), PI), "face_movement: vira para o próximo ponto (leste −90°, sul 180°)")
	walker.rotation.y = before
	var forge_workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	var yard_workers := game.foundry_district.life.get_node("AmbientWorkers").get_children()
	t.check((forge_workers + yard_workers).all(func(w): return is_zero_approx((w as Node3D).rotation.y) and not ((w.get_meta("definition", {}) as Dictionary).get("face_movement", false))), "Forja e pátio inalterados: ninguém usa as opções novas (rotação 0)")


func _test_integration(t) -> void:
	t.section("C23 — observações, EventBus, GameState, reação do Primeiro Eco")
	var game := _new_game(t)
	var before := _events.size()
	for id in OBSERVATIONS:
		var observation := _observation(game, id)
		t.check(observation.interact(game.player) and game.observation_text.text == game.localization.tr_key("observation.%s.text" % id) and game.narrative_controller.world_state.has_flag("observation_%s_seen" % id), "%s: E examina; painel com o texto; flag" % id)
	var discovered := _events.slice(before).filter(func(e: GameEvent): return e.event_type == "observation_discovered").map(func(e: GameEvent): return e.payload.get("observation_id", ""))
	t.check(discovered.size() == 4 and discovered.all(func(id): return String(id).begins_with("observation.vardhelm.foundry_street_")) and _types(before).count("memory_recovered") == 0, "EventBus: 4 observation_discovered com ID canônico, sem memória")
	for id in OBSERVATIONS:
		_observation(game, id).interact(game.player)
	t.check(_types(before).count("observation_discovered") == 4, "examinar de novo não duplica eventos (%d)" % _types(before).count("observation_discovered"))
	var projected := GameStateProjector.project(game.narrative_controller.world_state, game.quest_controller.states, game.player, game.dialogue_controller.persistent_state)
	t.check(projected.state.world.observations.size() == 4 and projected.quarantined.is_empty(), "GameState: 4 observações da rua, nada em quarentena")
	_talk(game, 0)
	game.echo.interact(game.player)
	_observation(game, "foundry_street_gate").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.foundry_street_gate.after_echo"), "depois do Primeiro Eco, o portão: \"%s\"" % game.observation_text.text)
	_observation(game, "foundry_street_ore_wagons").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.foundry_street_ore_wagons.text"), "o resto da rua não muda (normalidade primeiro)")


func _test_save_load(t) -> void:
	t.section("C23 — Save/Load V2 na rua")
	var game := _new_game(t)
	game.player.global_position = STREET_SPOT
	game.player.rotation.y = deg_to_rad(-57.0)
	_observation(game, "foundry_street_shift_board").interact(game.player)
	_key(t, KEY_S)
	var saved := FileAccess.get_file_as_string(V2_FILE)
	t.check(game.last_v2_save_result.is_success() and saved.contains("observation.vardhelm.foundry_street_shift_board"), "Save V2 na rua: observação salva pelo ID canônico")
	var lower := saved.to_lower()
	var transient := ["streetlife", "worker_street", "corridortrain", "craneload", "sharpening", "fog", "riding", "hoist", "district"]
	t.check(transient.all(func(w): return not lower.contains(w)), "nada transitório ou derivado no save (trabalhadores, animações, névoa, área, talha)")
	game.player.global_position = YARD_SPOT
	game.player.rotation.y = 0.0
	_observation(game, "foundry_street_sharpening").interact(game.player)
	var before := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result.is_success() and game.player.global_position.distance_to(STREET_SPOT) < 0.05 and absf(angle_difference(game.player.rotation.y, deg_to_rad(-57.0))) < 0.01, "Load V2: de volta à rua, na posição e rotação salvas")
	t.check(_observation(game, "foundry_street_shift_board").revealed and not _observation(game, "foundry_street_sharpening").revealed and not game.narrative_controller.world_state.has_flag("observation_foundry_street_sharpening_seen"), "observações da rua restauradas (a vista depois do Save volta a não vista)")
	t.check(_types(before) == ["game_loaded"], "o Load não reemite eventos de gameplay (%s)" % str(_types(before)))
	t.check(game.foundry_district.lives.size() == 2 and _street(game).get_node("AmbientWorkers").get_child_count() == 12 and _street(game).get_node("EnvironmentalObservations").get_child_count() == 4 and game.get_children().filter(func(c): return c is VardhelmFoundryDistrict).size() == 1, "nada duplicado depois do Load")
