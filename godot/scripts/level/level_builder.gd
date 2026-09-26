@tool
class_name LevelBuilder
extends Node3D

# Builder genérico orientado por dados. Não conhece Vardhelm, MachineBlock,
# Catwalk ou qualquer outro conteúdo específico — tudo vem de level_data_path.

const LevelDataLoader = preload("res://scripts/level/level_data_loader.gd")
const LevelValidator = preload("res://scripts/level/level_validator.gd")

const WORLD_ENVIRONMENT_NODE_NAME := "WorldEnvironment"
const MANAGED_META_KEY := "level_builder_managed"


@export_tool_button("Build Level") var build_button := build_level
@export_tool_button("Check Sync With JSON") var check_sync_button := check_sync

@export_file("*.json") var level_data_path: String = "res://level_data/vardhelm_forge_01.json"


func build_level() -> void:
	var raw_text := LevelDataLoader.read_file(level_data_path)

	if raw_text.is_empty():
		push_error("LevelBuilder: build abortado, não foi possível ler o arquivo de dados.")
		return

	var parsed := LevelDataLoader.parse(raw_text)

	if not parsed["ok"]:
		push_error("LevelBuilder: build abortado. " + parsed["error"])
		return

	var level_data: Dictionary = parsed["data"]
	var validation := LevelValidator.validate(level_data)

	if not validation["ok"]:
		push_error("LevelBuilder: build abortado, JSON não atende ao schema atual:")
		for message in validation["errors"]:
			push_error(" - " + message)
		return

	var prefab_paths := LevelDataLoader.extract_prefab_scene_paths(level_data)
	var preflight_errors := preflight_check_prefabs(prefab_paths)

	if not preflight_errors.is_empty():
		push_error("LevelBuilder: build abortado, falha no preflight de prefabs:")
		for message in preflight_errors:
			push_error(" - " + message)
		return

	clear_generated()

	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	set_scene_owner(generated)

	var materials := build_material_palette(level_data["material_palette"])

	build_room(generated, level_data["room"], materials)
	var props_root := build_props(generated, level_data["props"], materials)
	build_generation_rules(props_root, level_data.get("generation_rules", []), materials)
	build_spawns(generated, level_data["spawns"])
	apply_camera(level_data["camera"])
	apply_lights(level_data["lights"])
	apply_environment(level_data.get("environment", {}))

	generated.set_meta("source_data_path", level_data_path)
	generated.set_meta("source_data_hash", LevelDataLoader.compute_combined_hash(raw_text, prefab_paths))

	print("LevelBuilder: nível gerado a partir de: ", level_data_path)


func check_sync() -> void:
	var generated := get_node_or_null("Generated")

	if generated == null:
		push_warning("LevelBuilder: nenhum nó 'Generated' encontrado. Rode 'Build Level' primeiro.")
		return

	if not generated.has_meta("source_data_hash"):
		push_warning(
			"LevelBuilder: 'Generated' não possui hash salvo (gerado por versão antiga?). "
			+ "Rode 'Build Level' novamente."
		)
		return

	var raw_text := LevelDataLoader.read_file(level_data_path)

	if raw_text.is_empty():
		push_error("LevelBuilder: não foi possível ler o arquivo de dados para comparar.")
		return

	var parsed := LevelDataLoader.parse(raw_text)

	if not parsed["ok"]:
		push_error("LevelBuilder: não foi possível comparar, JSON atual é inválido. " + parsed["error"])
		return

	var level_data: Dictionary = parsed["data"]
	var prefab_paths := LevelDataLoader.extract_prefab_scene_paths(level_data)
	var current_hash := LevelDataLoader.compute_combined_hash(raw_text, prefab_paths)
	var saved_hash: String = generated.get_meta("source_data_hash")

	if current_hash == saved_hash:
		print("LevelBuilder: cena SINCRONIZADA com ", level_data_path)
	else:
		push_warning(
			"LevelBuilder: cena DESSINCRONIZADA. O JSON mudou desde o último 'Build Level'. "
			+ "Rode o build novamente e salve a cena."
		)


func preflight_check_prefabs(prefab_paths: Array) -> Array:
	var errors: Array[String] = []

	# prefab_paths já vem deduplicado por LevelDataLoader.extract_prefab_scene_paths
	# (props + generation_rules), então cada arquivo único é checado UMA vez,
	# mesmo que seja referenciado por dezenas de props ou por uma regra com
	# muitas instâncias.
	for scene_path in prefab_paths:
		if not ResourceLoader.exists(scene_path):
			errors.append("Prefab não encontrado em '%s'." % scene_path)
			continue

		var resource := ResourceLoader.load(scene_path)

		if resource == null or not (resource is PackedScene):
			errors.append("Recurso em '%s' não é um PackedScene." % scene_path)
			continue

		var packed_scene: PackedScene = resource

		if not packed_scene.can_instantiate():
			errors.append("PackedScene em '%s' não pode ser instanciada." % scene_path)
			continue

		var instance := packed_scene.instantiate()

		if instance == null:
			errors.append("Falha ao instanciar '%s'." % scene_path)
			continue

		if not (instance is Node3D):
			errors.append(
				"A raiz de '%s' precisa ser Node3D (encontrado: %s)." % [scene_path, instance.get_class()]
			)

		instance.free()

	return errors


func build_material_palette(palette_data: Dictionary) -> Dictionary:
	var materials := {}

	for material_name in palette_data.keys():
		var entry: Dictionary = palette_data[material_name]
		var material := create_material(
			Color(entry["color"]),
			float(entry["metallic"]),
			float(entry["roughness"])
		)

		if entry.has("emission"):
			apply_emission(material, entry["emission"])

		materials[material_name] = material

	return materials


func build_room(parent: Node3D, room: Dictionary, materials: Dictionary) -> void:
	var width: float = float(room["width"])
	var depth: float = float(room["depth"])
	var floor_thickness: float = float(room["floor_thickness"])
	var wall_height: float = float(room["wall_height"])
	var wall_thickness: float = float(room["wall_thickness"])

	create_prop_body(
		parent,
		"Floor",
		Vector3(width, floor_thickness, depth),
		Vector3(0.0, -floor_thickness / 2.0, 0.0),
		materials["floor"]
	)

	var half_width := width / 2.0
	var half_depth := depth / 2.0
	var wall_y := wall_height / 2.0

	create_prop_body(
		parent, "NorthWall",
		Vector3(width, wall_height, wall_thickness),
		Vector3(0.0, wall_y, -half_depth),
		materials["wall"]
	)

	create_prop_body(
		parent, "SouthWall",
		Vector3(width, wall_height, wall_thickness),
		Vector3(0.0, wall_y, half_depth),
		materials["wall"]
	)

	create_prop_body(
		parent, "WestWall",
		Vector3(wall_thickness, wall_height, depth),
		Vector3(-half_width, wall_y, 0.0),
		materials["wall"]
	)

	create_prop_body(
		parent, "EastWall",
		Vector3(wall_thickness, wall_height, depth),
		Vector3(half_width, wall_y, 0.0),
		materials["wall"]
	)


func build_props(parent: Node3D, props: Array, materials: Dictionary) -> Node3D:
	var props_root := Node3D.new()
	props_root.name = "Props"
	parent.add_child(props_root)
	set_scene_owner(props_root)

	for prop in props:
		var prop_dict: Dictionary = prop

		if prop_dict.get("type", "primitive") == "prefab":
			create_prefab_instance(props_root, prop_dict)
			continue

		var size := array_to_vector3(prop_dict["size"])
		var prop_position := array_to_vector3(prop_dict["position"])
		var material: StandardMaterial3D = materials[prop_dict["material"]]
		var shape: String = prop_dict.get("shape", "box")

		create_prop_body(props_root, prop_dict["name"], size, prop_position, material, shape)

	return props_root


func create_prefab_instance(parent: Node3D, prop_dict: Dictionary) -> void:
	var scene_path: String = prop_dict["scene"]
	var packed_scene: PackedScene = ResourceLoader.load(scene_path)
	var instance := packed_scene.instantiate() as Node3D

	instance.name = prop_dict["name"]

	parent.add_child(instance)
	set_scene_owner(instance)

	instance.position = array_to_vector3(prop_dict["position"])
	instance.rotation_degrees = array_to_vector3(prop_dict.get("rotation_degrees", [0.0, 0.0, 0.0]))
	instance.scale = array_to_vector3(prop_dict.get("scale", [1.0, 1.0, 1.0]))


func build_generation_rules(parent: Node3D, rules: Array, materials: Dictionary) -> void:
	for rule in rules:
		var rule_dict: Dictionary = rule

		var rule_root := Node3D.new()
		rule_root.name = rule_dict["name"]
		parent.add_child(rule_root)
		set_scene_owner(rule_root)

		if rule_dict["rule"] == "linear":
			build_linear_rule(rule_root, rule_dict, materials)
		else:
			build_grid_rule(rule_root, rule_dict, materials)


func build_linear_rule(parent: Node3D, rule: Dictionary, materials: Dictionary) -> void:
	var rule_name: String = rule["name"]
	var base_position := array_to_vector3(rule["position"])
	var step := array_to_vector3(rule["step"])
	var count: int = int(rule["count"])
	var padding := maxi(2, str(count - 1).length())

	for index in count:
		var instance_position := base_position + step * index
		var instance_name := "%s_%s" % [rule_name, pad_index(index, padding)]

		create_rule_instance(parent, rule["template"], instance_name, instance_position, materials)


func build_grid_rule(parent: Node3D, rule: Dictionary, materials: Dictionary) -> void:
	var rule_name: String = rule["name"]
	var base_position := array_to_vector3(rule["position"])
	var step_x := array_to_vector3(rule["step_x"])
	var step_z := array_to_vector3(rule["step_z"])
	var columns: int = int(rule["columns"])
	var rows: int = int(rule["rows"])
	var row_padding := maxi(2, str(rows - 1).length())
	var column_padding := maxi(2, str(columns - 1).length())

	for row in rows:
		for column in columns:
			var instance_position := base_position + step_x * column + step_z * row
			var instance_name := "%s_%s_%s" % [
				rule_name, pad_index(row, row_padding), pad_index(column, column_padding)
			]

			create_rule_instance(parent, rule["template"], instance_name, instance_position, materials)


func create_rule_instance(
	parent: Node3D,
	template: Dictionary,
	instance_name: String,
	instance_position: Vector3,
	materials: Dictionary
) -> void:
	if template.get("type", "primitive") == "prefab":
		var prefab_prop := {
			"name": instance_name,
			"scene": template["scene"],
			"position": [instance_position.x, instance_position.y, instance_position.z],
			"rotation_degrees": template.get("rotation_degrees", [0.0, 0.0, 0.0]),
			"scale": template.get("scale", [1.0, 1.0, 1.0]),
		}
		create_prefab_instance(parent, prefab_prop)
	else:
		var size := array_to_vector3(template["size"])
		var material: StandardMaterial3D = materials[template["material"]]
		var shape: String = template.get("shape", "box")

		create_prop_body(parent, instance_name, size, instance_position, material, shape)


func pad_index(value: int, width: int) -> String:
	var text := str(value)

	while text.length() < width:
		text = "0" + text

	return text


func build_spawns(parent: Node3D, spawns: Array) -> void:
	var spawns_root := Node3D.new()
	spawns_root.name = "Spawns"
	parent.add_child(spawns_root)
	set_scene_owner(spawns_root)

	for spawn in spawns:
		var spawn_dict: Dictionary = spawn
		var marker := Marker3D.new()
		marker.name = spawn_dict["name"]
		marker.position = array_to_vector3(spawn_dict["position"])
		marker.set_meta("spawn_type", spawn_dict["type"])

		spawns_root.add_child(marker)
		set_scene_owner(marker)


func apply_camera(camera_data: Dictionary) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D

	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
		set_scene_owner(camera)

	camera.projection = (
		Camera3D.PROJECTION_ORTHOGONAL
		if camera_data["projection"] == "orthogonal"
		else Camera3D.PROJECTION_PERSPECTIVE
	)

	if camera_data.has("size"):
		camera.size = float(camera_data["size"])

	camera.position = array_to_vector3(camera_data["position"])
	camera.rotation_degrees = array_to_vector3(camera_data["rotation_degrees"])
	camera.current = true


func apply_lights(lights: Array) -> void:
	var lights_root := get_node_or_null("Lights") as Node3D

	if lights_root == null:
		lights_root = Node3D.new()
		lights_root.name = "Lights"
		add_child(lights_root)
		set_scene_owner(lights_root)
	else:
		for child in lights_root.get_children():
			lights_root.remove_child(child)
			child.queue_free()

	for i in lights.size():
		var light_data: Dictionary = lights[i]
		var light := DirectionalLight3D.new()
		light.name = "Light_%d" % i
		light.rotation_degrees = array_to_vector3(light_data["rotation_degrees"])
		light.shadow_enabled = bool(light_data["shadows"])

		lights_root.add_child(light)
		set_scene_owner(light)


func apply_environment(environment_data: Dictionary) -> void:
	var world_environment := get_node_or_null(WORLD_ENVIRONMENT_NODE_NAME) as WorldEnvironment

	if environment_data.is_empty():
		if world_environment != null and world_environment.has_meta(MANAGED_META_KEY):
			remove_child(world_environment)
			world_environment.queue_free()

		return

	if world_environment == null:
		world_environment = WorldEnvironment.new()
		world_environment.name = WORLD_ENVIRONMENT_NODE_NAME
		add_child(world_environment)
		set_scene_owner(world_environment)
		world_environment.set_meta(MANAGED_META_KEY, true)
	elif not world_environment.has_meta(MANAGED_META_KEY):
		push_warning(
			"LevelBuilder: já existe um nó 'WorldEnvironment' não gerenciado pelo LevelBuilder. "
			+ "Ele não será modificado nem removido."
		)
		return

	var environment := world_environment.environment

	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment

	if environment_data.has("background_color"):
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(environment_data["background_color"])

	if environment_data.has("ambient_light_color") or environment_data.has("ambient_light_energy"):
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

		if environment_data.has("ambient_light_color"):
			environment.ambient_light_color = Color(environment_data["ambient_light_color"])

		if environment_data.has("ambient_light_energy"):
			environment.ambient_light_energy = float(environment_data["ambient_light_energy"])

	if environment_data.has("exposure"):
		environment.tonemap_exposure = float(environment_data["exposure"])

	if environment_data.has("glow"):
		var glow_data: Dictionary = environment_data["glow"]

		if glow_data.has("enabled"):
			environment.glow_enabled = bool(glow_data["enabled"])

		if glow_data.has("intensity"):
			environment.glow_intensity = float(glow_data["intensity"])


func create_prop_body(
	parent: Node3D,
	object_name: String,
	size: Vector3,
	object_position: Vector3,
	material: StandardMaterial3D,
	shape: String = "box"
) -> StaticBody3D:

	var body := StaticBody3D.new()
	body.name = object_name
	body.position = object_position

	parent.add_child(body)
	set_scene_owner(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = create_mesh_for_shape(shape, size)
	mesh_instance.material_override = material

	body.add_child(mesh_instance)
	set_scene_owner(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = create_collision_shape_for_shape(shape, size)

	body.add_child(collision)
	set_scene_owner(collision)

	return body


func create_mesh_for_shape(shape: String, size: Vector3) -> Mesh:
	match shape:
		"cylinder":
			var mesh := CylinderMesh.new()
			mesh.top_radius = size.x / 2.0
			mesh.bottom_radius = size.x / 2.0
			mesh.height = size.y
			return mesh

		"sphere":
			var mesh := SphereMesh.new()
			mesh.radius = size.x / 2.0
			mesh.height = size.x
			return mesh

		_:
			var mesh := BoxMesh.new()
			mesh.size = size
			return mesh


func create_collision_shape_for_shape(shape: String, size: Vector3) -> Shape3D:
	match shape:
		"cylinder":
			var collision_shape := CylinderShape3D.new()
			collision_shape.radius = size.x / 2.0
			collision_shape.height = size.y
			return collision_shape

		"sphere":
			var collision_shape := SphereShape3D.new()
			collision_shape.radius = size.x / 2.0
			return collision_shape

		_:
			var collision_shape := BoxShape3D.new()
			collision_shape.size = size
			return collision_shape


func create_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func apply_emission(material: StandardMaterial3D, emission_data: Dictionary) -> void:
	material.emission_enabled = true
	material.emission = Color(emission_data["color"])
	material.emission_energy_multiplier = float(emission_data["energy"])


func array_to_vector3(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func clear_generated() -> void:
	var old_generated := get_node_or_null("Generated")

	if old_generated != null:
		remove_child(old_generated)
		old_generated.queue_free()


func set_scene_owner(node: Node) -> void:
	var scene_root := get_tree().edited_scene_root

	if scene_root != null:
		node.owner = scene_root
