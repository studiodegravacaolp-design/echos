extends RefCounted

# Valida o Dictionary já parseado do JSON de nível contra o schema esperado
# pelo LevelBuilder. Não conhece nada sobre Vardhelm ou qualquer outro nível
# específico — só a forma genérica dos dados.

const REQUIRED_ROOT_KEYS := [
	"level_name", "room", "props", "spawns", "camera", "lights", "material_palette"
]

const REQUIRED_ROOM_KEYS := [
	"width", "depth", "floor_thickness", "wall_height", "wall_thickness"
]

# A geometria genérica de sala sempre usa estes dois materiais por convenção.
const REQUIRED_ROOM_MATERIALS := ["floor", "wall"]

const VALID_PROP_SHAPES := ["box", "cylinder", "sphere"]

const VALID_PROP_TYPES := ["primitive", "prefab", "group"]

const VALID_RULE_TYPES := ["linear", "grid"]

const VALID_WALL_SIDES := ["north", "south", "west", "east"]

const VALID_TONEMAPS := ["linear", "reinhard", "filmic", "aces"]

# Limite defensivo por regra — evita JSON malformado gerar milhares de nós
# de uma vez no editor. Ver relatório da etapa de planejamento para o racional.
const MAX_RULE_INSTANCES := 500


static func validate(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []

	for key in REQUIRED_ROOT_KEYS:
		if not data.has(key):
			errors.append("Chave obrigatória ausente no nível raiz: '%s'." % key)

	var material_names: Array = []

	if data.has("material_palette"):
		_validate_material_palette(data["material_palette"], errors)
		material_names = _material_names(data["material_palette"])

	if data.has("room"):
		_validate_room(data["room"], material_names, errors)

	if data.has("props"):
		_validate_props(data["props"], material_names, errors)

	if data.has("spawns"):
		_validate_spawns(data["spawns"], errors)

	if data.has("camera"):
		_validate_camera(data["camera"], errors)

	if data.has("lights"):
		_validate_lights(data["lights"], errors)

	if data.has("environment"):
		_validate_environment(data["environment"], errors)

	if data.has("generation_rules"):
		_validate_generation_rules(data["generation_rules"], material_names, errors)

	_validate_global_name_uniqueness(data, errors)

	return {"ok": errors.is_empty(), "errors": errors}


static func _material_names(palette) -> Array:
	if typeof(palette) != TYPE_DICTIONARY:
		return []
	return palette.keys()


static func _validate_material_palette(palette, errors: Array[String]) -> void:
	if typeof(palette) != TYPE_DICTIONARY:
		errors.append("'material_palette' precisa ser um objeto.")
		return

	for material_name in palette.keys():
		var entry = palette[material_name]

		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("material_palette.%s precisa ser um objeto." % material_name)
			continue

		# Material por shader: só o caminho do .gdshader (e parâmetros opcionais).
		if entry.has("shader"):
			var shader_path = entry["shader"]
			if typeof(shader_path) != TYPE_STRING or not String(shader_path).ends_with(".gdshader"):
				errors.append("material_palette.%s.shader precisa apontar para um arquivo '.gdshader'." % material_name)
			elif not ResourceLoader.exists(shader_path):
				errors.append("material_palette.%s.shader não encontrado em '%s'." % [material_name, shader_path])
			if entry.has("shader_params") and typeof(entry["shader_params"]) != TYPE_DICTIONARY:
				errors.append("material_palette.%s.shader_params precisa ser um objeto." % material_name)
			continue

		if not entry.has("color") or typeof(entry["color"]) != TYPE_STRING:
			errors.append(
				"material_palette.%s.color ausente ou inválido (esperado string hex)." % material_name
			)

		if not _is_number(entry.get("metallic", null)):
			errors.append("material_palette.%s.metallic ausente ou não numérico." % material_name)

		if not _is_number(entry.get("roughness", null)):
			errors.append("material_palette.%s.roughness ausente ou não numérico." % material_name)

		if entry.has("emission"):
			_validate_emission(entry["emission"], material_name, errors)


static func _validate_emission(emission, material_name: String, errors: Array[String]) -> void:
	if typeof(emission) != TYPE_DICTIONARY:
		errors.append("material_palette.%s.emission precisa ser um objeto." % material_name)
		return

	if not emission.has("color") or typeof(emission["color"]) != TYPE_STRING:
		errors.append(
			"material_palette.%s.emission.color ausente ou inválido (esperado string hex)." % material_name
		)

	if not _is_number(emission.get("energy", null)):
		errors.append("material_palette.%s.emission.energy ausente ou não numérico." % material_name)


static func _validate_room(room, material_names: Array, errors: Array[String]) -> void:
	if typeof(room) != TYPE_DICTIONARY:
		errors.append("'room' precisa ser um objeto.")
		return

	for key in REQUIRED_ROOM_KEYS:
		if not room.has(key):
			errors.append("room.%s ausente." % key)
		elif not _is_number(room[key]):
			errors.append("room.%s precisa ser numérico." % key)

	for required_material in REQUIRED_ROOM_MATERIALS:
		if not material_names.has(required_material):
			errors.append(
				"material_palette precisa conter '%s' (usado pela construção genérica da sala)."
				% required_material
			)

	if room.has("walls"):
		_validate_walls(room, material_names, errors)


# room.walls (opcional): por lado, altura, material e aberturas dentro do comprimento.
static func _validate_walls(room: Dictionary, material_names: Array, errors: Array[String]) -> void:
	var walls = room["walls"]

	if typeof(walls) != TYPE_DICTIONARY:
		errors.append("room.walls precisa ser um objeto.")
		return

	for side in walls.keys():
		var label := "room.walls.%s" % side

		if not VALID_WALL_SIDES.has(side):
			errors.append("%s: lado inválido. Valores aceitos: %s." % [label, VALID_WALL_SIDES])
			continue

		var config = walls[side]

		if typeof(config) != TYPE_DICTIONARY:
			errors.append("%s precisa ser um objeto." % label)
			continue

		var height := float(room.get("wall_height", 0.0))

		if config.has("height"):
			if not _is_number(config["height"]) or float(config["height"]) <= 0.0:
				errors.append("%s.height precisa ser um número maior que 0." % label)
			else:
				height = float(config["height"])

		if config.has("material") and not material_names.has(config["material"]):
			errors.append("%s.material '%s' não existe em material_palette." % [label, str(config["material"])])

		var half_length := float(room.get("width" if side in ["north", "south"] else "depth", 0.0)) / 2.0
		var openings = config.get("openings", [])

		if typeof(openings) != TYPE_ARRAY:
			errors.append("%s.openings precisa ser uma lista." % label)
			continue

		var previous_to := -half_length

		for i in openings.size():
			var opening = openings[i]
			var opening_label := "%s.openings[%d]" % [label, i]

			if typeof(opening) != TYPE_DICTIONARY or not _is_number(opening.get("from", null)) or not _is_number(opening.get("to", null)):
				errors.append("%s precisa ter 'from' e 'to' numéricos." % opening_label)
				continue

			var from := float(opening["from"])
			var to := float(opening["to"])
			var bottom := float(opening.get("bottom", 0.0))
			var top := float(opening.get("top", height))

			if from < -half_length or to > half_length or from >= to:
				errors.append("%s: [from, to] precisa estar dentro da parede e crescente." % opening_label)
			if from < previous_to:
				errors.append("%s: aberturas precisam estar em ordem e sem sobreposição." % opening_label)
			if bottom < 0.0 or top > height or bottom >= top:
				errors.append("%s: [bottom, top] precisa estar dentro da altura da parede." % opening_label)
			previous_to = to


static func _validate_props(props, material_names: Array, errors: Array[String]) -> void:
	if typeof(props) != TYPE_ARRAY:
		errors.append("'props' precisa ser uma lista.")
		return

	for i in props.size():
		var prop = props[i]

		if typeof(prop) != TYPE_DICTIONARY:
			errors.append("props[%d] precisa ser um objeto." % i)
			continue

		if not prop.has("name") or typeof(prop["name"]) != TYPE_STRING or prop["name"].is_empty():
			errors.append("props[%d].name ausente ou inválido." % i)

		if not _is_vector3_array(prop.get("position", null)):
			errors.append("props[%d].position precisa ser um array [x, y, z] numérico." % i)

		var prop_type = prop.get("type", "primitive")

		if not VALID_PROP_TYPES.has(prop_type):
			errors.append(
				"props[%d].type inválido: '%s'. Valores aceitos: %s." % [i, str(prop_type), VALID_PROP_TYPES]
			)
			continue

		if prop_type == "group":
			_validate_group_prop(prop, i, material_names, errors)
		elif prop_type == "prefab":
			_validate_prefab_prop(prop, i, errors)
		else:
			_validate_primitive_prop(prop, i, material_names, errors)


static func _validate_primitive_prop(prop: Dictionary, i: int, material_names: Array, errors: Array[String]) -> void:
	_validate_primitive_fields(prop, "props[%d]" % i, material_names, errors)


static func _validate_prefab_prop(prop: Dictionary, i: int, errors: Array[String]) -> void:
	_validate_prefab_fields(prop, "props[%d]" % i, errors)


# Campos compartilhados entre props[].type=="primitive" e
# generation_rules[].template.type=="primitive". "label" identifica a origem
# nas mensagens de erro (ex.: "props[2]" ou "generation_rules[0].template").
static func _validate_primitive_fields(
	fields: Dictionary, label: String, material_names: Array, errors: Array[String]
) -> void:
	if not _is_vector3_array(fields.get("size", null)):
		errors.append("%s.size precisa ser um array [x, y, z] numérico." % label)

	var material_name = fields.get("material", null)

	if typeof(material_name) != TYPE_STRING or material_name.is_empty():
		errors.append("%s.material ausente ou inválido." % label)
	elif not material_names.has(material_name):
		errors.append("%s.material '%s' não existe em material_palette." % [label, material_name])

	if fields.has("shape"):
		var shape_value = fields["shape"]

		if typeof(shape_value) != TYPE_STRING or not VALID_PROP_SHAPES.has(shape_value):
			errors.append(
				"%s.shape inválido: '%s'. Valores aceitos: %s."
				% [label, str(shape_value), VALID_PROP_SHAPES]
			)

	if fields.has("scene"):
		errors.append("%s é do tipo 'primitive' mas contém 'scene' (campo exclusivo de prefab)." % label)

	if fields.has("collision") and typeof(fields["collision"]) != TYPE_BOOL:
		errors.append("%s.collision precisa ser booleano." % label)

	if fields.has("rotation_degrees") and not _is_vector3_array(fields["rotation_degrees"]):
		errors.append("%s.rotation_degrees precisa ser um array [x, y, z] numérico." % label)


# Campos compartilhados entre props[].type=="prefab" e
# generation_rules[].template.type=="prefab".
static func _validate_prefab_fields(fields: Dictionary, label: String, errors: Array[String]) -> void:
	var scene_path = fields.get("scene", null)

	if typeof(scene_path) != TYPE_STRING or scene_path.is_empty():
		errors.append("%s.scene ausente ou inválido (esperado string não vazia)." % label)
	elif not scene_path.ends_with(".tscn"):
		errors.append("%s.scene precisa apontar para um arquivo '.tscn'." % label)

	if fields.has("rotation_degrees") and not _is_vector3_array(fields["rotation_degrees"]):
		errors.append("%s.rotation_degrees precisa ser um array [x, y, z] numérico." % label)

	if fields.has("scale") and not _is_vector3_array(fields["scale"]):
		errors.append("%s.scale precisa ser um array [x, y, z] numérico." % label)

	for forbidden_key in ["size", "shape", "material"]:
		if fields.has(forbidden_key):
			errors.append(
				"%s é do tipo 'prefab' mas contém '%s' (campo exclusivo de primitive)."
				% [label, forbidden_key]
			)


static func _validate_spawns(spawns, errors: Array[String]) -> void:
	if typeof(spawns) != TYPE_ARRAY:
		errors.append("'spawns' precisa ser uma lista.")
		return

	for i in spawns.size():
		var spawn = spawns[i]

		if typeof(spawn) != TYPE_DICTIONARY:
			errors.append("spawns[%d] precisa ser um objeto." % i)
			continue

		if not spawn.has("name") or typeof(spawn["name"]) != TYPE_STRING or spawn["name"].is_empty():
			errors.append("spawns[%d].name ausente ou inválido." % i)

		if not spawn.has("type") or typeof(spawn["type"]) != TYPE_STRING or spawn["type"].is_empty():
			errors.append("spawns[%d].type ausente ou inválido." % i)

		if not _is_vector3_array(spawn.get("position", null)):
			errors.append("spawns[%d].position precisa ser um array [x, y, z] numérico." % i)


static func _validate_camera(camera, errors: Array[String]) -> void:
	if typeof(camera) != TYPE_DICTIONARY:
		errors.append("'camera' precisa ser um objeto.")
		return

	var projection = camera.get("projection", null)

	if projection != "orthogonal" and projection != "perspective":
		errors.append("camera.projection precisa ser 'orthogonal' ou 'perspective'.")

	if projection == "orthogonal" and not _is_number(camera.get("size", null)):
		errors.append("camera.size ausente ou não numérico (obrigatório para projeção orthogonal).")

	if not _is_vector3_array(camera.get("position", null)):
		errors.append("camera.position precisa ser um array [x, y, z] numérico.")

	if not _is_vector3_array(camera.get("rotation_degrees", null)):
		errors.append("camera.rotation_degrees precisa ser um array [x, y, z] numérico.")


static func _validate_lights(lights, errors: Array[String]) -> void:
	if typeof(lights) != TYPE_ARRAY:
		errors.append("'lights' precisa ser uma lista.")
		return

	for i in lights.size():
		var light = lights[i]

		if typeof(light) != TYPE_DICTIONARY:
			errors.append("lights[%d] precisa ser um objeto." % i)
			continue

		if light.get("type", "") != "directional":
			errors.append(
				"lights[%d].type precisa ser 'directional' (único tipo suportado no LevelBuilder v1)." % i
			)

		if not _is_vector3_array(light.get("rotation_degrees", null)):
			errors.append("lights[%d].rotation_degrees precisa ser um array [x, y, z] numérico." % i)

		if typeof(light.get("shadows", null)) != TYPE_BOOL:
			errors.append("lights[%d].shadows ausente ou não booleano." % i)

		if light.has("color") and typeof(light["color"]) != TYPE_STRING:
			errors.append("lights[%d].color precisa ser uma string hex." % i)

		if light.has("energy") and not _is_number(light["energy"]):
			errors.append("lights[%d].energy precisa ser numérico." % i)


static func _validate_environment(environment, errors: Array[String]) -> void:
	if typeof(environment) != TYPE_DICTIONARY:
		errors.append("'environment' precisa ser um objeto.")
		return

	if environment.has("background_color") and typeof(environment["background_color"]) != TYPE_STRING:
		errors.append("environment.background_color precisa ser uma string hex.")

	if environment.has("ambient_light_color") and typeof(environment["ambient_light_color"]) != TYPE_STRING:
		errors.append("environment.ambient_light_color precisa ser uma string hex.")

	if environment.has("ambient_light_energy") and not _is_number(environment["ambient_light_energy"]):
		errors.append("environment.ambient_light_energy precisa ser numérico.")

	if environment.has("exposure") and not _is_number(environment["exposure"]):
		errors.append("environment.exposure precisa ser numérico.")

	if environment.has("glow"):
		_validate_glow(environment["glow"], errors)

	if environment.has("tonemap") and not VALID_TONEMAPS.has(environment["tonemap"]):
		errors.append("environment.tonemap inválido. Valores aceitos: %s." % [VALID_TONEMAPS])

	for section in ["fog", "ssao"]:
		if not environment.has(section):
			continue
		var data = environment[section]
		if typeof(data) != TYPE_DICTIONARY:
			errors.append("environment.%s precisa ser um objeto." % section)
			continue
		for key in data.keys():
			var value = data[key]
			if key == "enabled":
				if typeof(value) != TYPE_BOOL:
					errors.append("environment.%s.enabled precisa ser booleano." % section)
			elif key == "color":
				if typeof(value) != TYPE_STRING:
					errors.append("environment.%s.color precisa ser uma string hex." % section)
			elif not _is_number(value):
				errors.append("environment.%s.%s precisa ser numérico." % [section, key])


static func _validate_glow(glow, errors: Array[String]) -> void:
	if typeof(glow) != TYPE_DICTIONARY:
		errors.append("environment.glow precisa ser um objeto.")
		return

	if glow.has("enabled") and typeof(glow["enabled"]) != TYPE_BOOL:
		errors.append("environment.glow.enabled precisa ser booleano.")

	if glow.has("intensity") and not _is_number(glow["intensity"]):
		errors.append("environment.glow.intensity precisa ser numérico.")


static func _validate_generation_rules(rules, material_names: Array, errors: Array[String]) -> void:
	if typeof(rules) != TYPE_ARRAY:
		errors.append("'generation_rules' precisa ser uma lista.")
		return

	for i in rules.size():
		var rule = rules[i]

		if typeof(rule) != TYPE_DICTIONARY:
			errors.append("generation_rules[%d] precisa ser um objeto." % i)
			continue

		if not rule.has("name") or typeof(rule["name"]) != TYPE_STRING or rule["name"].is_empty():
			errors.append("generation_rules[%d].name ausente ou inválido." % i)

		if not _is_vector3_array(rule.get("position", null)):
			errors.append("generation_rules[%d].position precisa ser um array [x, y, z] numérico." % i)

		var rule_type = rule.get("rule", null)

		if not VALID_RULE_TYPES.has(rule_type):
			errors.append(
				"generation_rules[%d].rule inválido: '%s'. Valores aceitos: %s."
				% [i, str(rule_type), VALID_RULE_TYPES]
			)
		elif rule_type == "linear":
			_validate_linear_rule(rule, i, errors)
		else:
			_validate_grid_rule(rule, i, errors)

		if not rule.has("template"):
			errors.append("generation_rules[%d].template ausente." % i)
		elif typeof(rule["template"]) != TYPE_DICTIONARY:
			errors.append("generation_rules[%d].template precisa ser um objeto." % i)
		else:
			_validate_rule_template(rule["template"], i, material_names, errors)


static func _validate_linear_rule(rule: Dictionary, i: int, errors: Array[String]) -> void:
	var count = rule.get("count", null)

	if not _is_number(count):
		errors.append("generation_rules[%d].count ausente ou não numérico." % i)
	elif not _is_whole_number(count):
		errors.append("generation_rules[%d].count precisa ser um número inteiro exato." % i)
	elif int(count) <= 0:
		errors.append("generation_rules[%d].count precisa ser maior que 0." % i)
	elif int(count) > MAX_RULE_INSTANCES:
		errors.append(
			"generation_rules[%d].count (%d) excede o limite de %d instâncias por regra."
			% [i, int(count), MAX_RULE_INSTANCES]
		)

	if not _is_vector3_array(rule.get("step", null)):
		errors.append("generation_rules[%d].step precisa ser um array [x, y, z] numérico." % i)


static func _validate_grid_rule(rule: Dictionary, i: int, errors: Array[String]) -> void:
	var columns = rule.get("columns", null)
	var rows = rule.get("rows", null)

	var columns_ok := _is_number(columns) and _is_whole_number(columns) and int(columns) > 0
	var rows_ok := _is_number(rows) and _is_whole_number(rows) and int(rows) > 0

	if not _is_number(columns):
		errors.append("generation_rules[%d].columns ausente ou não numérico." % i)
	elif not _is_whole_number(columns):
		errors.append("generation_rules[%d].columns precisa ser um número inteiro exato." % i)
	elif int(columns) <= 0:
		errors.append("generation_rules[%d].columns precisa ser maior que 0." % i)

	if not _is_number(rows):
		errors.append("generation_rules[%d].rows ausente ou não numérico." % i)
	elif not _is_whole_number(rows):
		errors.append("generation_rules[%d].rows precisa ser um número inteiro exato." % i)
	elif int(rows) <= 0:
		errors.append("generation_rules[%d].rows precisa ser maior que 0." % i)

	if columns_ok and rows_ok and int(columns) * int(rows) > MAX_RULE_INSTANCES:
		errors.append(
			"generation_rules[%d]: columns * rows (%d) excede o limite de %d instâncias por regra."
			% [i, int(columns) * int(rows), MAX_RULE_INSTANCES]
		)

	if not _is_vector3_array(rule.get("step_x", null)):
		errors.append("generation_rules[%d].step_x precisa ser um array [x, y, z] numérico." % i)

	if not _is_vector3_array(rule.get("step_z", null)):
		errors.append("generation_rules[%d].step_z precisa ser um array [x, y, z] numérico." % i)


static func _validate_rule_template(
	template: Dictionary, i: int, material_names: Array, errors: Array[String]
) -> void:
	var label := "generation_rules[%d].template" % i

	if template.has("name"):
		errors.append("%s não pode conter 'name' (calculado pela regra)." % label)

	if template.has("position"):
		errors.append("%s não pode conter 'position' (calculado pela regra)." % label)

	var template_type = template.get("type", null)

	if not VALID_PROP_TYPES.has(template_type):
		errors.append(
			"%s.type inválido: '%s'. Valores aceitos: %s." % [label, str(template_type), VALID_PROP_TYPES]
		)
		return

	if template_type == "prefab":
		_validate_prefab_fields(template, label, errors)
	else:
		_validate_primitive_fields(template, label, material_names, errors)


# Constrói um conjunto global de nomes (props[] + generation_rules[].name) e
# rejeita qualquer duplicata — todos acabam como nós irmãos dentro de
# Generated/Props, então precisam ser únicos nesse nível.
static func _validate_global_name_uniqueness(data: Dictionary, errors: Array[String]) -> void:
	var occurrences := {}

	var props = data.get("props", [])

	if typeof(props) == TYPE_ARRAY:
		for i in props.size():
			var prop = props[i]

			if typeof(prop) == TYPE_DICTIONARY and typeof(prop.get("name", null)) == TYPE_STRING:
				var name: String = prop["name"]

				if not occurrences.has(name):
					occurrences[name] = []

				occurrences[name].append("props[%d]" % i)

	var rules = data.get("generation_rules", [])

	if typeof(rules) == TYPE_ARRAY:
		for i in rules.size():
			var rule = rules[i]

			if typeof(rule) == TYPE_DICTIONARY and typeof(rule.get("name", null)) == TYPE_STRING:
				var name: String = rule["name"]

				if not occurrences.has(name):
					occurrences[name] = []

				occurrences[name].append("generation_rules[%d]" % i)

	for name in occurrences.keys():
		var locations: Array = occurrences[name]

		if locations.size() > 1:
			errors.append(
				"Nome '%s' duplicado entre: %s. Nomes precisam ser únicos entre props e generation_rules."
				% [name, ", ".join(locations)]
			)


static func _is_whole_number(value) -> bool:
	return _is_number(value) and float(value) == floor(float(value))


static func _is_number(value) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT


static func _is_vector3_array(value) -> bool:
	if typeof(value) != TYPE_ARRAY or value.size() != 3:
		return false

	for component in value:
		if not _is_number(component):
			return false

	return true


# props[].type == "group": itens primitivos com posição local e nomes únicos no grupo.
static func _validate_group_prop(prop: Dictionary, i: int, material_names: Array, errors: Array[String]) -> void:
	var label := "props[%d]" % i

	if prop.has("rotation_degrees") and not _is_vector3_array(prop["rotation_degrees"]):
		errors.append("%s.rotation_degrees precisa ser um array [x, y, z] numérico." % label)

	var items = prop.get("items", null)

	if typeof(items) != TYPE_ARRAY or items.is_empty():
		errors.append("%s.items precisa ser uma lista não vazia." % label)
		return

	var names := {}

	for j in items.size():
		var item = items[j]
		var item_label := "%s.items[%d]" % [label, j]

		if typeof(item) != TYPE_DICTIONARY:
			errors.append("%s precisa ser um objeto." % item_label)
			continue

		var item_name = item.get("name", null)

		if typeof(item_name) != TYPE_STRING or item_name.is_empty():
			errors.append("%s.name ausente ou inválido." % item_label)
		elif names.has(item_name):
			errors.append("%s.name '%s' duplicado no grupo." % [item_label, item_name])
		else:
			names[item_name] = true

		if not _is_vector3_array(item.get("position", null)):
			errors.append("%s.position precisa ser um array [x, y, z] numérico." % item_label)

		if item.get("type", "primitive") != "primitive":
			errors.append("%s: grupos aceitam só primitivas." % item_label)

		_validate_primitive_fields(item, item_label, material_names, errors)
