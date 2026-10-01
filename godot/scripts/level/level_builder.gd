@tool
class_name LevelBuilder
extends Node3D

# Builder genérico orientado por dados. Não conhece Vardhelm, MachineBlock,
# Catwalk ou qualquer outro conteúdo específico — tudo vem de level_data_path.

const LevelDataLoader = preload("res://scripts/level/level_data_loader.gd")
const LevelValidator = preload("res://scripts/level/level_validator.gd")

const WORLD_ENVIRONMENT_NODE_NAME := "WorldEnvironment"
const MANAGED_META_KEY := "level_builder_managed"
const TONEMAP_MODES := {
	"linear": Environment.TONE_MAPPER_LINEAR,
	"reinhard": Environment.TONE_MAPPER_REINHARDT,
	"filmic": Environment.TONE_MAPPER_FILMIC,
	"aces": Environment.TONE_MAPPER_ACES,
}


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

		# Opcional: material por shader (.gdshader), com parâmetros do JSON.
		if entry.has("shader"):
			materials[material_name] = create_shader_material(entry["shader"], entry.get("shader_params", {}))
			continue

		var material := create_material(
			Color(entry["color"]),
			float(entry["metallic"]),
			float(entry["roughness"])
		)

		if entry.has("emission"):
			apply_emission(material, entry["emission"])

		materials[material_name] = material

	return materials


# Parâmetros: número -> float; string hex -> Color; [x, y] -> Vector2; [x, y, z] -> Vector3.
func create_shader_material(shader_path: String, params: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ResourceLoader.load(shader_path) as Shader

	for param_name in params.keys():
		var value = params[param_name]

		match typeof(value):
			TYPE_STRING:
				material.set_shader_parameter(param_name, Color(value))
			TYPE_ARRAY:
				if value.size() == 2:
					material.set_shader_parameter(param_name, Vector2(float(value[0]), float(value[1])))
				else:
					material.set_shader_parameter(param_name, array_to_vector3(value))
			_:
				material.set_shader_parameter(param_name, float(value))

	return material


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
	# Opcional por lado ("north", "south", "west", "east"): altura, material e aberturas.
	# A colisão é sempre a mesma caixa da malha (nada de parede invisível).
	var walls: Dictionary = room.get("walls", {})

	build_wall(parent, "NorthWall", true, width, wall_thickness, Vector3(0.0, 0.0, -half_depth), wall_height, walls.get("north", {}), materials)
	build_wall(parent, "SouthWall", true, width, wall_thickness, Vector3(0.0, 0.0, half_depth), wall_height, walls.get("south", {}), materials)
	build_wall(parent, "WestWall", false, depth, wall_thickness, Vector3(-half_width, 0.0, 0.0), wall_height, walls.get("west", {}), materials)
	build_wall(parent, "EastWall", false, depth, wall_thickness, Vector3(half_width, 0.0, 0.0), wall_height, walls.get("east", {}), materials)


# Parede ao longo de X (along_x) ou de Z. Sem aberturas: um único corpo com o nome de
# sempre. Com aberturas ({"from", "to"} ao longo da parede, e opcionalmente "bottom"/"top"
# para janelas): trechos cheios entre elas, peitoril abaixo e verga acima.
func build_wall(
	parent: Node3D,
	wall_name: String,
	along_x: bool,
	length: float,
	thickness: float,
	center: Vector3,
	default_height: float,
	config: Dictionary,
	materials: Dictionary
) -> void:
	var height := float(config.get("height", default_height))
	var material: Material = materials[config.get("material", "wall")]
	var openings: Array = config.get("openings", [])

	if openings.is_empty():
		create_wall_piece(parent, wall_name, along_x, center, -length / 2.0, length / 2.0, 0.0, height, thickness, material)
		return

	var sorted: Array = openings.duplicate()
	sorted.sort_custom(func(a, b): return float(a["from"]) < float(b["from"]))
	var pieces: Array = []
	var cursor := -length / 2.0

	for opening in sorted:
		var from := float(opening["from"])
		var to := float(opening["to"])
		var bottom := float(opening.get("bottom", 0.0))
		var top := float(opening.get("top", height))

		if from > cursor:
			pieces.append([cursor, from, 0.0, height])
		if bottom > 0.0:
			pieces.append([from, to, 0.0, bottom])
		if top < height:
			pieces.append([from, to, top, height])
		cursor = to

	if cursor < length / 2.0:
		pieces.append([cursor, length / 2.0, 0.0, height])

	for i in pieces.size():
		var piece: Array = pieces[i]
		create_wall_piece(parent, "%s_%s" % [wall_name, pad_index(i, 2)], along_x, center, piece[0], piece[1], piece[2], piece[3], thickness, material)


func create_wall_piece(
	parent: Node3D,
	piece_name: String,
	along_x: bool,
	center: Vector3,
	from: float,
	to: float,
	bottom: float,
	top: float,
	thickness: float,
	material: Material
) -> void:
	var span := to - from
	var mid := (from + to) / 2.0
	var size := Vector3(span, top - bottom, thickness) if along_x else Vector3(thickness, top - bottom, span)
	var piece_position := center + (Vector3(mid, 0.0, 0.0) if along_x else Vector3(0.0, 0.0, mid))
	piece_position.y = (top + bottom) / 2.0
	create_prop_body(parent, piece_name, size, piece_position, material)


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

		if prop_dict.get("type", "primitive") == "group":
			create_group(props_root, prop_dict, materials)
			continue

		var size := array_to_vector3(prop_dict["size"])
		var prop_position := array_to_vector3(prop_dict["position"])
		var material: Material = materials[prop_dict["material"]]
		var shape: String = prop_dict.get("shape", "box")

		create_primitive(props_root, prop_dict["name"], size, prop_position, material, shape, prop_dict)

	return props_root


# Grupo (opcional): um posto de trabalho ou pilha de material como uma unidade. Um nó com
# posição/rotação próprias e "items" primitivos em coordenadas LOCAIS (mesmos campos de
# uma primitiva: size, material, shape, rotation_degrees, collision).
func create_group(parent: Node3D, group_dict: Dictionary, materials: Dictionary) -> void:
	var group := Node3D.new()
	group.name = group_dict["name"]
	group.position = array_to_vector3(group_dict["position"])
	group.rotation_degrees = array_to_vector3(group_dict.get("rotation_degrees", [0.0, 0.0, 0.0]))
	parent.add_child(group)
	set_scene_owner(group)

	for item in group_dict["items"]:
		var item_dict: Dictionary = item
		var material: Material = materials[item_dict["material"]]
		create_primitive(
			group,
			item_dict["name"],
			array_to_vector3(item_dict["size"]),
			array_to_vector3(item_dict["position"]),
			material,
			item_dict.get("shape", "box"),
			item_dict
		)


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
		var material: Material = materials[template["material"]]
		var shape: String = template.get("shape", "box")

		create_primitive(parent, instance_name, size, instance_position, material, shape, template)


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

		if light_data.has("color"):
			light.light_color = Color(light_data["color"])

		if light_data.has("energy"):
			light.light_energy = float(light_data["energy"])

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

	# Opcionais: tonemap, névoa (profundidade + altura) e SSAO (sombras de contato).
	if environment_data.has("tonemap"):
		environment.tonemap_mode = TONEMAP_MODES[environment_data["tonemap"]]

	if environment_data.has("fog"):
		var fog_data: Dictionary = environment_data["fog"]
		environment.fog_enabled = bool(fog_data.get("enabled", true))

		if fog_data.has("color"):
			environment.fog_light_color = Color(fog_data["color"])
		if fog_data.has("density"):
			environment.fog_density = float(fog_data["density"])
		if fog_data.has("sky_affect"):
			environment.fog_sky_affect = float(fog_data["sky_affect"])
		if fog_data.has("height"):
			environment.fog_height = float(fog_data["height"])
		if fog_data.has("height_density"):
			environment.fog_height_density = float(fog_data["height_density"])

	if environment_data.has("ssao"):
		var ssao_data: Dictionary = environment_data["ssao"]
		environment.ssao_enabled = bool(ssao_data.get("enabled", true))

		if ssao_data.has("radius"):
			environment.ssao_radius = float(ssao_data["radius"])
		if ssao_data.has("intensity"):
			environment.ssao_intensity = float(ssao_data["intensity"])


# Primitiva de props/templates. Opcionais: "rotation_degrees" e "collision" (padrão true;
# false = só a malha, para o que o jogador não alcança: estruturas altas e fundo).
func create_primitive(
	parent: Node3D,
	object_name: String,
	size: Vector3,
	object_position: Vector3,
	material: Material,
	shape: String,
	fields: Dictionary
) -> void:
	var node: Node3D

	if bool(fields.get("collision", true)):
		node = create_prop_body(parent, object_name, size, object_position, material, shape)
	else:
		node = Node3D.new()
		node.name = object_name
		node.position = object_position
		parent.add_child(node)
		set_scene_owner(node)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Mesh"
		mesh_instance.mesh = create_mesh_for_shape(shape, size)
		mesh_instance.material_override = material
		node.add_child(mesh_instance)
		set_scene_owner(mesh_instance)

	if fields.has("rotation_degrees"):
		node.rotation_degrees = array_to_vector3(fields["rotation_degrees"])


func create_prop_body(
	parent: Node3D,
	object_name: String,
	size: Vector3,
	object_position: Vector3,
	material: Material,
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
