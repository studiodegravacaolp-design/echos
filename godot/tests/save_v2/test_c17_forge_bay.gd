extends RefCounted

## Bloco C17 — baia oeste da Forja 01 (cenário). Verifica o que o cenário novo NÃO pode
## quebrar: dados válidos, colisão igual à geometria visível, entrada aberta e fechada
## para fora, posições de C13–C16 intactas, laranja concentrado na forja, desempenho.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const LEVEL_DATA := "res://level_data/vardhelm_forge_01.json"
const LOADER := preload("res://scripts/level/level_data_loader.gd")
const VALIDATOR := preload("res://scripts/level/level_validator.gd")


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func run(t) -> void:
	_test_data(t)
	_test_scene(t)
	_isolate(t)


func _test_data(t) -> void:
	t.section("C17 — dados do nível (LevelBuilder/LevelValidator)")
	var parsed := LOADER.parse(LOADER.read_file(LEVEL_DATA))
	t.check(parsed["ok"], "JSON do nível lido")
	var data: Dictionary = parsed["data"]
	var validation := VALIDATOR.validate(data)
	t.check(validation["ok"], "LevelValidator aprova o nível (%s)" % str(validation["errors"]))
	var bad := data.duplicate(true)
	bad["room"]["walls"]["south"]["openings"] = [{"from": 3.0, "to": 1.0}]
	bad["material_palette"]["wall"]["shader"] = "res://nao_existe.gdshader"
	t.check(VALIDATOR.validate(bad)["errors"].size() >= 2, "o validador recusa abertura invertida e shader inexistente")
	var old_style := {"width": 20.0, "depth": 14.0, "floor_thickness": 0.5, "wall_height": 4.0, "wall_thickness": 0.5}
	var legacy := data.duplicate(true)
	legacy["room"] = old_style
	t.check(VALIDATOR.validate(legacy)["ok"], "sala sem 'walls' (formato antigo) continua válida")
	t.check(not JSON.stringify(data).contains("test_prefab") and not FileAccess.file_exists("res://assets/vardhelm/prefabs/test_prefab_pillar.tscn"), "prefab magenta de teste removido (dados e arquivo)")
	t.check(not bool(data["environment"]["ssao"]["enabled"]), "SSAO desligado: dobrava o tempo de quadro na GPU integrada (16,7 → 35 ms)")
	t.check(data["spawns"] == [{"name": "PlayerSpawn", "type": "player", "position": [0.0, 0.25, 3.0]}, {"name": "NPCSpawn", "type": "npc", "position": [-4.0, 0.25, -2.0]}], "spawns do jogador e de Durn inalterados")
	t.check(data["camera"] == {"projection": "orthogonal", "size": 24.0, "position": [10.0, 9.0, 12.0], "rotation_degrees": [-35.0, 40.0, 0.0]}, "câmera do nível inalterada")


func _test_scene(t) -> void:
	t.section("C17 — cena: colisão = geometria; entrada; C13–C16 intactos")
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	var generated := game.get_node("VP01_Vardhelm/Generated")
	# Toda parede: colisão exatamente do tamanho e na posição da malha.
	var mismatched: Array = []
	var walls: Array = []
	for body in generated.get_children():
		if body is StaticBody3D and String(body.name).contains("Wall"):
			walls.append(body)
			var mesh := (body.get_node("Mesh") as MeshInstance3D).mesh as BoxMesh
			var shape := (body.get_node("Collision") as CollisionShape3D).shape as BoxShape3D
			if mesh == null or shape == null or not mesh.size.is_equal_approx(shape.size):
				mismatched.append(String(body.name))
	t.check(walls.size() >= 4 and mismatched.is_empty(), "%d trechos de parede; colisão = malha em todos (%s)" % [walls.size(), str(mismatched)])
	var south: Array = walls.filter(func(w): return String(w.name).begins_with("SouthWall"))
	var east: Array = walls.filter(func(w): return String(w.name).begins_with("EastWall"))
	var low := func(list: Array) -> bool: return list.all(func(w): return ((w.get_node("Mesh") as MeshInstance3D).mesh as BoxMesh).size.y <= 1.11)
	t.check(not south.is_empty() and not east.is_empty() and low.call(south) and low.call(east), "paredes sul e leste em corte: parapeitos de 1,1 m, com colisão de 1,1 m (sem parede invisível)")
	var blocking := south.filter(func(w):
		var size := ((w.get_node("Mesh") as MeshInstance3D).mesh as BoxMesh).size
		var x: float = w.position.x
		return x - size.x / 2.0 < 2.19 and x + size.x / 2.0 > -2.19)
	t.check(blocking.is_empty(), "abertura real no sul entre os postes do portão (x −2,2…2,2)")
	var props := generated.get_node("Props")
	var landing := ["EntryLanding", "EntryRail_W", "EntryRail_E", "EntryRail_S"].filter(func(n): return props.get_node_or_null(n) is StaticBody3D)
	t.check(landing.size() == 4, "patamar da entrada com piso e guarda-corpos com colisão (fechado para fora)")
	var high: Array = walls.filter(func(w): return String(w.name).begins_with("NorthWall") or String(w.name).begins_with("WestWall"))
	var openings := high.filter(func(w): return w.position.y > 3.0 and ((w.get_node("Mesh") as MeshInstance3D).mesh as BoxMesh).size.y < 1.0)
	t.check(openings.size() >= 5, "janelas altas nas paredes norte e oeste (%d vergas)" % openings.size())
	# C13–C16: nomes e posições das dependências.
	var dressing := game.get_node("VardhelmSetDressing")
	var lamp := dressing.get_node_or_null("WorkLight_00") as OmniLight3D
	var fixture := dressing.get_node_or_null("WorkLightFixture_00") as Node3D
	t.check(lamp != null and fixture != null and lamp.position.is_equal_approx(Vector3(-6.2, 2.55, 2.0)) and fixture.position.is_equal_approx(Vector3(-6.2, 2.7, 2.0)) and lamp.light_color.is_equal_approx(Color("#FF8A3D")) and is_equal_approx(lamp.light_energy, 0.35), "WorkLight_00 e luminária: mesmos nomes, posição, cor e energia (C13/C14)")
	# C26: a âncora de interação do quadro desceu ao chão (como a de Durn) — ver BLOCK_C26 §6.
	var observations := {"maintenance_board": Vector3(-5.7, 0.25, -3.9), "sealed_panel": Vector3(-6.7, 1.3, 1.8), "tool_rack": Vector3(-3.5, 1.1, 3.1), "durn_notes": Vector3(-4.0, 0.02, -2.0)}
	var moved: Array = []
	for id in observations:
		var node := game.get_node("AmbientLife/EnvironmentalObservations/%s" % id) as Node3D
		if node == null or not node.global_position.is_equal_approx(observations[id]):
			moved.append(id)
	t.check(moved.is_empty() and game.echo.global_position.is_equal_approx(Vector3(2.5, 1.0, -3.0)) and game.npc.global_position.is_equal_approx(Vector3(-4.0, 0.25, -2.0)), "observações, Eco e Durn nas mesmas posições (%s)" % str(moved))
	t.check(game.get_node("AmbientLife/EnvironmentalStoryProps/sealed_panel").position.is_equal_approx(Vector3(-6.7, 1.3, 1.8)) and props.get_node_or_null("PanelBulkhead") is StaticBody3D, "painel selado no mesmo ponto, agora dentro de um anteparo")
	# Laranja: só a forja brilha forte; faixas, anéis e tampa deixaram de brilhar.
	var glowing: Array = []
	for mesh in dressing.find_children("*", "MeshInstance3D", true, false):
		var material := ((mesh as MeshInstance3D).mesh.surface_get_material(0) if (mesh as MeshInstance3D).mesh != null else null) as StandardMaterial3D
		var owner_name := String(mesh.get_parent().name)
		if material != null and material.emission_enabled and material.emission_energy_multiplier > 1.0 and not owner_name.begins_with("Forge") and not owner_name.begins_with("WorkLightFixture"):
			glowing.append("%s(%.1f)" % [owner_name, material.emission_energy_multiplier])
	t.check(glowing.is_empty(), "fora a forja (e as luminárias do C13), nada brilha forte (%s)" % str(glowing))
	var forge := dressing.get_node("ForgeLight") as OmniLight3D
	t.check(forge.light_color.is_equal_approx(Color("#FF7900")) and forge.light_energy > 1.5, "a forja é a fonte quente principal (#FF7900)")
	t.check(game.get_node("VardhelmAudio/VardhelmHum") != null and game.echo.get_node("Light") != null, "áudio e luz do Eco presentes (não tocados)")
	_test_density(t, game, props)
	_test_finish(t, game, props)
	_isolate(t)


## C17.2 — acabamento: sem rótulos de protótipo, pessoas em vez de cápsulas, máquinas
## legíveis, e nada decorativo na frente do Eco ou do painel na câmera do jogador.
func _test_finish(t, game: VardhelmVerticalSlice, props: Node) -> void:
	t.section("C17.2 — identidade e acabamento")
	var dressing := game.get_node("VardhelmSetDressing")
	var floating: Array = dressing.find_children("*", "Label3D", true, false).filter(func(l): return (l as Label3D).billboard != BaseMaterial3D.BILLBOARD_DISABLED)
	var texts: Array = dressing.find_children("*", "Label3D", true, false).map(func(l): return (l as Label3D).text)
	t.check(floating.is_empty() and not texts.has("SETOR INDUSTRIAL") and texts == ["FORJA 01"], "sem rótulos flutuantes; só a placa \"FORJA 01\" fixa no portão %s" % str(texts))
	var workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	var shaped := workers.filter(func(w):
		var s = w.get_node_or_null("Silhouette")
		return s != null and s.get_node_or_null("Head") != null and s.get_node_or_null("Body") != null and s.get_node_or_null("Leg_L") != null and s.get_node_or_null("Arm_R") != null)
	t.check(shaped.size() == workers.size() and workers.size() == 7, "os 7 trabalhadores têm silhueta humana (cabeça, tronco, braços, pernas)")
	var durn_shape := game.npc.get_node_or_null("Silhouette")
	var durn_body := durn_shape.get_node_or_null("Body") as MeshInstance3D if durn_shape != null else null
	t.check(durn_body != null and (durn_body.mesh as CapsuleMesh).height > 1.0 and not (game.npc.get_node("Visual") as MeshInstance3D).visible and game.npc.get_node_or_null("Nameplate") != null, "Durn distinto: casaco longo, mais alto, placa DURN; a cápsula antiga só ficou oculta")
	t.check(game.npc.get_node("CollisionShape3D") != null and game._npc_interactable.interaction_enabled and game._npc_interactable.interaction_priority == VardhelmVerticalSlice.NPC_INTERACTION_PRIORITY, "colisão, interação e prioridade de Durn inalteradas")
	var machines := ["MachineB_Dress", "MachineA_Dress", "ToolRackDress"].filter(func(g): return props.get_node_or_null(g) != null)
	var colliders: Array = []
	for g in machines:
		for body in props.get_node(g).find_children("*", "StaticBody3D", true, false):
			colliders.append(String(body.name))
	t.check(machines.size() == 3 and colliders == ["Motor"], "máquinas A e B e o suporte de ferramentas vestidos; só o motor tem colisão %s" % str(colliders))
	var motor := props.get_node("MachineB_Dress/Motor") as Node3D
	t.check(motor.global_position.distance_to(Vector3(0, 0.3, 3.0)) > 5.0 and motor.global_position.distance_to(Vector3(2.5, 0.3, -3.0)) > 5.0, "motor longe do início, do Eco e dos caminhos")
	# Na câmera ortográfica do jogador, o deslocamento na tela independe da posição da
	# câmera: basta a orientação. Nada decorativo pode ficar NA FRENTE do Eco/painel.
	var basis := game.player.camera.global_transform.basis
	var targets := {"Eco": game.echo.global_position, "painel": Vector3(-6.7, 1.3, 1.8)}
	var groups := ["MachineB_Dress", "MachineA_Dress", "ToolRackDress", "ForgeStation_West", "AnvilStation", "WorkbenchStory", "MaintenanceNook", "TransportStack", "CraneLoad", "Foreground_Barrels", "Foreground_Sacks"]
	var blocking: Array = []
	for g in groups:
		for mesh in props.get_node(g).find_children("*", "MeshInstance3D", true, false):
			var box := (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).get_aabb()
			for label in targets:
				var target: Vector3 = targets[label]
				var center := box.get_center()
				var in_front := (center - target).dot(basis.z) > 0.3
				var dx := absf((center - target).dot(basis.x)) - box.size.length() * 0.5
				var dy := absf((center - target).dot(basis.y)) - box.size.length() * 0.5
				if in_front and dx < 0.35 and dy < 0.35:
					blocking.append("%s/%s → %s" % [g, mesh.get_parent().name, label])
	t.check(blocking.is_empty(), "nada decorativo cobre o Eco ou o painel na câmera do jogador %s" % str(blocking))
	var rack := game.get_node("AmbientLife/EnvironmentalStoryProps/tool_rack") as MeshInstance3D
	var station := game.get_node("AmbientLife/AmbientStations").get_child(0).get_node("StationBase") as Node3D
	t.check((rack.material_override as StandardMaterial3D).albedo_color.is_equal_approx(Color("#3F3022")) and station.position.y < 0.05, "suporte de ferramentas em madeira; bases das estações viraram estrados baixos")


## C17.1 — densidade funcional: postos de trabalho como grupos de dados, sem atrapalhar
## a circulação nem as interações.
func _test_density(t, game: VardhelmVerticalSlice, props: Node) -> void:
	t.section("C17.1 — densidade industrial: postos, trabalhadores, circulação")
	var groups := ["ForgeStation_West", "AnvilStation", "WorkbenchStory", "MaintenanceNook", "TransportStack", "CraneLoad", "Foreground_Barrels", "Foreground_Sacks"]
	var missing := groups.filter(func(g): return props.get_node_or_null(g) == null)
	t.check(missing.is_empty(), "%d postos/pilhas montados pelo LevelBuilder a partir do JSON (%s)" % [groups.size(), str(missing)])
	# Colisores novos: só volumes maiores em cantos mortos, longe de tudo o que se usa.
	var colliders: Array = []
	for g in groups:
		for body in props.get_node(g).find_children("*", "StaticBody3D", true, false):
			colliders.append(body)
	var names := colliders.map(func(b): return String(b.name))
	names.sort()
	t.check(names == ["Barrel_1", "Barrel_2", "Barrel_3", "Crate_Low", "OpenCrate", "Pallet"], "só palete, caixas e barris têm colisão (o resto é visual) %s" % str(names))
	var keep_clear := {
		"Durn (lugar de sempre)": Vector3(-4.0, 0, -2.0), "Durn sozinho (C15)": Vector3(1.1, 0, -3.4), "Eco": Vector3(2.5, 0, -3.0),
		"frente do painel": Vector3(-6.2, 0, 2.6), "folha (C16)": Vector3(-4.0, 0, -2.0), "ferramentas": Vector3(-3.5, 0, 3.9),
		"quadro": Vector3(-5.2, 0, -2.8), "início": Vector3(0.0, 0, 3.0), "entrada": Vector3(0.0, 0, 6.6),
		"corredor forja × máquina": Vector3(-6.2, 0, -2.5),
	}
	var crowded: Array = []
	for label in keep_clear:
		var point: Vector3 = keep_clear[label]
		for body in colliders:
			var p: Vector3 = body.global_position
			if Vector2(p.x - point.x, p.z - point.z).length() < 1.5:
				crowded.append("%s ← %s" % [label, body.name])
	t.check(crowded.is_empty(), "nenhum colisor novo a menos de 1,5 m das interações, do início ou da entrada %s" % str(crowded))
	var workers := game.get_node("AmbientLife/AmbientWorkers").get_children()
	var hauler := game.get_node_or_null("AmbientLife/AmbientWorkers/worker_hauler_01")
	# C17.3: cada trabalhador ganhou um corpo leve (o jogador não o atravessa); nada de interação.
	var light_body := func(w) -> bool:
		var bodies: Array = w.find_children("*", "CollisionObject3D", true, false)
		return bodies.size() == 1 and bodies[0] is AnimatableBody3D and bodies[0].collision_layer == 1 and bodies[0].collision_mask == 0
	t.check(workers.size() == 7 and hauler != null and hauler.get_node_or_null("Carry") != null and workers.all(light_body), "7 trabalhadores no sistema existente (um carregando material); um corpo leve cada (C17.3), sem interação")
	var vent := props.get_node("EmberVent/Mesh") as MeshInstance3D
	var vent_material := vent.material_override as StandardMaterial3D
	t.check(vent_material != null and not vent_material.emission_enabled, "o respiro da entrada deixou de ser um bloco laranja")
