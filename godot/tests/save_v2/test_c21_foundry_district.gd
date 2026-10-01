extends RefCounted

## Bloco C21 — Distrito das Fundições (pátio sob a Forja 01), headless e determinístico.
## Dados, cena, integração (dica, observações, EventBus, GameState), reação derivada e
## Save/Load V2. A passagem pela talha, a névoa por área e o andar pelo pátio com física
## real ficam no playtest do C21.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const LEVEL_VALIDATOR := preload("res://scripts/level/level_validator.gd")
const LEVEL_PATH := "res://level_data/vardhelm_foundry_district_01.json"
const LIFE_PATH := "res://data/vardhelm/foundry_district_life.json"
const FORGE_LIFE_PATH := "res://data/vardhelm/ambient_life.json"
const CONFIG_PATH := "res://data/vardhelm/foundry_district.json"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c21.json"
const OBSERVATIONS := ["foundry_coal_carts", "foundry_chain_pulley", "foundry_forge_door"]
const FORBIDDEN := ["eco", "memória", "lembr", "aethel", "aetheris", "asterion", "cinzento", "origem", "cosmo", "significa", "véu", "agora você", "você descobriu"]
const DISTRICT_SPOT := Vector3(1.5, -11.65, 17.0)
const FORGE_SPOT := Vector3(-1.5, 0.25, 1.75)

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


func _district(game: VardhelmVerticalSlice) -> VardhelmFoundryDistrict:
	return game.foundry_district


func _observation(game: VardhelmVerticalSlice, id: String) -> EnvironmentalObservation:
	return _district(game).observation_root().get_node(id) as EnvironmentalObservation


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
	_test_integration(t)
	_test_reaction(t)
	_test_save_load(t)
	_isolate(t)
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _test_data(t) -> void:
	t.section("C21 — dados do pátio (LevelBuilder, AmbientLife, IDs, textos)")
	var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEVEL_PATH))
	var validation: Dictionary = LEVEL_VALIDATOR.validate(level)
	t.check(validation["ok"], "nível do pátio válido no LevelValidator %s" % str(validation["errors"]))
	t.check((level["lights"] as Array).is_empty() and not level.has("environment"), "o pátio não traz luz direcional nem ambiente próprios (usa os da Forja)")
	var life: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LIFE_PATH))
	var observation_ids: Array = (life["observations"] as Array).map(func(o): return o["id"])
	t.check((life["workers"] as Array).size() == 6 and observation_ids == OBSERVATIONS, "vida do pátio: 6 trabalhadores e 3 observações (%s)" % str(observation_ids))
	t.check((life["observations"] as Array).all(func(o): return not o.has("memory_id")), "observações do pátio sem memória nova (só narrativa ambiental)")
	var canonical := OBSERVATIONS.map(func(id): return GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, id))
	t.check(canonical == ["observation.vardhelm.foundry_coal_carts", "observation.vardhelm.foundry_chain_pulley", "observation.vardhelm.foundry_forge_door"] and canonical.all(func(id): return GameIdCatalog.is_known(GameIdCatalog.KIND_OBSERVATION, id)), "IDs canônicos novos no catálogo: %s" % str(canonical))
	t.check(GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_SCENARIO] == [GameIdCatalog.SCENARIO_VARDHELM] and GameIdCatalog.KNOWN_IDS[GameIdCatalog.KIND_NPC] == [GameIdCatalog.NPC_DURN], "nenhum cenário, NPC ou evento novo: o pátio é parte de scenario.vardhelm")
	var locale: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LOCALE_PATH))
	var texts: Array = []
	for id in OBSERVATIONS:
		texts.append(String(locale.get("observation.%s.title" % id, "")))
		texts.append(String(locale.get("observation.%s.text" % id, "")))
	texts.append(String(locale.get("observation.foundry_forge_door.after_echo", "")))
	texts.append(String(locale.get("ui.hoist.down", "")))
	texts.append(String(locale.get("ui.hoist.up", "")))
	var offending: Array = []
	for text in texts:
		for word in FORBIDDEN:
			if (text as String).to_lower().contains(word):
				offending.append("%s ← %s" % [word, text])
	t.check(texts.all(func(s): return not (s as String).is_empty()) and offending.is_empty(), "textos do pátio presentes e sem explicar o mundo (%s)" % str(offending))
	var forge_life: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FORGE_LIFE_PATH))
	t.check((forge_life["observations"] as Array).size() == 3 and (forge_life["workers"] as Array).size() == 7, "dados da Forja 01 intactos (3 observações, 7 trabalhadores)")


func _test_scene(t) -> void:
	t.section("C21 — cena: o pátio instanciado sob a Forja 01")
	var game := _new_game(t)
	var level := game.get_node_or_null("VP02_FoundryDistrict") as Node3D
	t.check(level != null and level.position.is_equal_approx(Vector3(0, -11.9, 19.5)), "nível do pátio sob a Forja 01 (chão a y −11,9, na cidade abaixo do patamar)")
	var district := _district(game)
	t.check(district != null and district.life != null and district.life.data_path == LIFE_PATH, "controlador e vida do pátio (VardhelmAmbientLife com o arquivo do pátio)")
	var workers := district.life.get_node("AmbientWorkers").get_children()
	t.check(workers.size() == 6 and workers.all(func(w): return w.find_children("*", "AnimatableBody3D", true, false).size() == 1 and w.get_meta("routine", "") == "default"), "6 trabalhadores com corpo leve (C17.3) e rotina de trabalho")
	var forge_workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	var forge_observations := game.get_node("AmbientLife/EnvironmentalObservations").get_children()
	t.check(forge_workers.size() == 7 and forge_observations.size() == 4, "Forja 01 intacta: 7 trabalhadores, 4 observações")
	# C23: a rua acrescentou uma terceira raiz; o que o C21 garante é a da Forja e a do pátio.
	var roots := game.observation_roots()
	t.check(roots.has(game.get_node("AmbientLife/EnvironmentalObservations")) and roots.has(district.observation_root()) and district.observation_root().get_child_count() == 3, "raízes de observação da Forja e do pátio presentes, 3 no pátio")
	var level_camera := level.get_node("Camera3D") as Camera3D
	t.check(not level_camera.current and game.player.camera.current, "a câmera do jogador continua sendo a atual")
	var environments := game.find_children("*", "WorldEnvironment", true, false)
	var suns := game.find_children("*", "DirectionalLight3D", true, false)
	t.check(environments.size() == 1 and suns.size() == 1, "um só WorldEnvironment e uma só luz direcional (os da Forja)")
	var bodies := level.find_children("*", "StaticBody3D", true, false)
	var mismatched := bodies.filter(func(b): return b.find_children("*", "MeshInstance3D", false, false).size() != 1 or b.find_children("*", "CollisionShape3D", false, false).size() != 1)
	t.check(bodies.size() > 40 and mismatched.is_empty(), "colisão = geometria: %d corpos, cada um com a própria malha" % bodies.size())
	var lights := district.find_children("*", "OmniLight3D", false, false)
	# C23: os lampiões da rua entram no mesmo controlador; os 3 primeiros da config são os do pátio.
	var config_lamps: Array = district.config.get("lamps", [])
	t.check(lights.size() == config_lamps.size() and config_lamps.size() >= 3 and lights.all(func(l): return not l.shadow_enabled), "lampiões de querosene da config (%d, os 3 primeiros no pátio), sem sombra" % lights.size())
	var emitters := district.find_children("*", "CPUParticles3D", false, false).map(func(p): return String(p.name))
	t.check(emitters.has("ForgeVentSmoke") and emitters.has("WestFoundrySteam") and emitters.size() == (district.config.get("smoke", []) as Array).size() + 1, "fumaça do respiro, vapor e poeira de carvão do pátio presentes (%s)" % str(emitters))


func _test_integration(t) -> void:
	t.section("C21 — integração: talha, dica, observações, EventBus")
	var game := _new_game(t)
	var district := _district(game)
	t.check(district.hoist_top.interaction_priority == 0 and district.hoist_top.collision_layer == 2 and district.hoist_top.position.is_equal_approx(Vector3(0, 0.9, 9.5)), "talha no patamar: Interactable comum (camada 2, prioridade 0)")
	game._on_candidate_changed(district.hoist_top)
	var down := game.interaction_hint_label.text
	game._on_candidate_changed(district.hoist_bottom)
	var up := game.interaction_hint_label.text
	t.check(down == "E  •  Descer ao pátio" and up == "E  •  Subir à Forja 01" and game.interaction_hint.visible, "dica da talha pelo ciclo do C18: \"%s\" / \"%s\"" % [down, up])
	game._on_candidate_changed(null)
	t.check(game.hint_lifecycle.is_close_pending(), "sair da talha fecha a dica pelo ciclo do C18 (atraso)")
	t.check(district.hoist_top.destination.is_equal_approx(Vector3(0, -11.65, 12.75)) and district.hoist_bottom.destination.is_equal_approx(Vector3(0, 0.25, 9.2)), "destinos: pátio (frente da gaiola) e patamar da Forja 01")
	var before := _events.size()
	for id in OBSERVATIONS:
		var observation := _observation(game, id)
		t.check(observation.interact(game.player) and game.observation_text.text == game.localization.tr_key("observation.%s.text" % id) and game.narrative_controller.world_state.has_flag("observation_%s_seen" % id), "%s: E examina; painel com o texto; flag de observação" % id)
	var discovered := _events.slice(before).filter(func(e: GameEvent): return e.event_type == "observation_discovered").map(func(e: GameEvent): return e.payload.get("observation_id", ""))
	t.check(discovered == ["observation.vardhelm.foundry_coal_carts", "observation.vardhelm.foundry_chain_pulley", "observation.vardhelm.foundry_forge_door"] and _types(before).count("memory_recovered") == 0, "EventBus: observation_discovered com ID canônico, sem memória (%s)" % str(discovered))
	var projected := GameStateProjector.project(game.narrative_controller.world_state, game.quest_controller.states, game.player, game.dialogue_controller.persistent_state)
	t.check(projected.state.world.observations.size() == 3 and projected.quarantined.is_empty(), "GameState: 3 observações do pátio, nada em quarentena")
	t.check(game.shadow_state.game_state.world.observations.size() == 3, "sombra (A3) acompanhou as 3 observações")


func _test_reaction(t) -> void:
	t.section("C21 — reação derivada do Primeiro Eco (C13) no pátio")
	var game := _new_game(t)
	var district := _district(game)
	t.check(not district.after_echo_applied and district.smoke_ratio("ForgeVentSmoke") == 1.0 and district.smoke_ratio("WestFoundrySteam") == 1.0, "antes do Eco: respiro da Forja 01 com fumaça normal")
	_observation(game, "foundry_forge_door").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.foundry_forge_door.text"), "porta da fundição antes do Eco: o barulho da Forja 01 desce até o pátio")
	_talk(game, 0)
	game.echo.interact(game.player)
	district.refresh()
	t.check(district.after_echo_applied and is_equal_approx(district.smoke_ratio("ForgeVentSmoke"), 0.35) and district.smoke_ratio("WestFoundrySteam") == 1.0, "depois do Eco: só o respiro da Forja 01 solta menos fumaça (%.2f)" % district.smoke_ratio("ForgeVentSmoke"))
	_observation(game, "foundry_forge_door").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.foundry_forge_door.after_echo"), "porta da fundição depois do Eco: o barulho chega mais baixo")
	_observation(game, "foundry_coal_carts").interact(game.player)
	t.check(game.observation_text.text == game.localization.tr_key("observation.foundry_coal_carts.text"), "o resto do pátio não muda (carrinhos com o mesmo texto)")


func _test_save_load(t) -> void:
	t.section("C21 — Save/Load V2 no pátio")
	var game := _new_game(t)
	var district := _district(game)
	game.player.global_position = DISTRICT_SPOT
	game.player.rotation.y = deg_to_rad(33.0)
	_observation(game, "foundry_coal_carts").interact(game.player)
	_key(t, KEY_S)
	var saved := FileAccess.get_file_as_string(V2_FILE)
	t.check(game.last_v2_save_result != null and game.last_v2_save_result.is_success() and saved.contains("observation.vardhelm.foundry_coal_carts"), "Save V2 no pátio: observação salva pelo ID canônico")
	var lower := saved.to_lower()
	t.check(not lower.contains("hoist") and not lower.contains("fog") and not lower.contains("district") and not lower.contains("riding"), "nada transitório do pátio no save (talha, névoa, área)")
	# Muda tudo: volta à Forja, gira, examina outra observação do pátio.
	game.player.global_position = FORGE_SPOT
	game.player.rotation.y = 0.0
	_observation(game, "foundry_chain_pulley").interact(game.player)
	var before := _events.size()
	_key(t, KEY_L)
	t.check(game.last_v2_load_result != null and game.last_v2_load_result.is_success() and game.player.global_position.distance_to(DISTRICT_SPOT) < 0.05 and absf(angle_difference(game.player.rotation.y, deg_to_rad(33.0))) < 0.01, "Load V2: jogador de volta ao pátio, na posição e rotação salvas")
	t.check(_observation(game, "foundry_coal_carts").revealed and not _observation(game, "foundry_chain_pulley").revealed and not game.narrative_controller.world_state.has_flag("observation_foundry_chain_pulley_seen"), "observações do pátio restauradas (a examinada depois do Save volta a não vista)")
	t.check(_types(before) == ["game_loaded"], "o Load não reemite eventos de gameplay (%s)" % str(_types(before)))
	t.check(game.get_children().filter(func(c): return c is VardhelmFoundryDistrict).size() == 1 and district.life.get_node("AmbientWorkers").get_child_count() == 6 and district.observation_root().get_child_count() == 3, "nada duplicado depois do Load (um pátio, 6 trabalhadores, 3 observações)")
	# Reação derivada volta com o Load: save antes do Eco × depois do Eco.
	_talk(game, 0)
	game.echo.interact(game.player)
	district.refresh()
	t.check(is_equal_approx(district.smoke_ratio("ForgeVentSmoke"), 0.35), "Eco depois do Save: respiro com menos fumaça")
	_key(t, KEY_L)
	t.check(not district.after_echo_applied and district.smoke_ratio("ForgeVentSmoke") == 1.0, "Load do save de antes do Eco: fumaça normal de novo (re-derivada)")
	_talk(game, 0)
	game.echo.interact(game.player)
	_key(t, KEY_S)
	_key(t, KEY_L)
	t.check(district.after_echo_applied and is_equal_approx(district.smoke_ratio("ForgeVentSmoke"), 0.35), "Save/Load depois do Eco: a reação do pátio persiste pela causa (flag), não pelo visual")
