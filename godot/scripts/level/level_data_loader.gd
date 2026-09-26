extends RefCounted


static func read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("LevelDataLoader: arquivo não encontrado: " + path)
		return ""

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("LevelDataLoader: não foi possível abrir: " + path)
		return ""

	var text := file.get_as_text()
	file.close()
	return text


static func parse(json_text: String) -> Dictionary:
	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		return {
			"ok": false,
			"data": {},
			"error": "Erro no JSON. Linha %d: %s" % [json.get_error_line(), json.get_error_message()]
		}

	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"data": {},
			"error": "O JSON precisa possuir um objeto principal (Dictionary)."
		}

	return {"ok": true, "data": data, "error": ""}


static func compute_hash(json_text: String) -> String:
	return json_text.sha256_text()


static func extract_prefab_scene_paths(level_data: Dictionary) -> Array:
	var paths := {}

	for prop in level_data.get("props", []):
		if typeof(prop) != TYPE_DICTIONARY:
			continue

		var scene_path = prop.get("scene", null)

		if prop.get("type", "primitive") == "prefab" and typeof(scene_path) == TYPE_STRING:
			paths[scene_path] = true

	for rule in level_data.get("generation_rules", []):
		if typeof(rule) != TYPE_DICTIONARY:
			continue

		var template = rule.get("template", null)

		if typeof(template) != TYPE_DICTIONARY:
			continue

		var scene_path = template.get("scene", null)

		if template.get("type", "primitive") == "prefab" and typeof(scene_path) == TYPE_STRING:
			paths[scene_path] = true

	var sorted_paths := paths.keys()
	sorted_paths.sort()
	return sorted_paths


static func compute_combined_hash(json_text: String, prefab_paths: Array) -> String:
	var unique_paths := {}

	for path in prefab_paths:
		unique_paths[path] = true

	var sorted_paths := unique_paths.keys()
	sorted_paths.sort()

	var combined := compute_hash(json_text)

	for path in sorted_paths:
		combined += "\n" + path + ":" + FileAccess.get_sha256(path)

	return combined.sha256_text()
