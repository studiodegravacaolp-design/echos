extends Node3D
class_name VardhelmAmbientLife

const DATA_PATH := "res://data/vardhelm/ambient_life.json"
var environment_states: Dictionary = {}
const ENVIRONMENTAL_OBSERVATION := preload("res://scripts/interaction/environmental_observation.gd")
var _worker_defs: Array = []
var _stations: Array = []
var _story_defs: Array = []
var _observation_defs: Array = []
var _memory_response_defs: Array = []
var _narrative_consequence_defs: Array = []
var _presentation: Dictionary = {
    "show_station_labels": false,
    "show_story_prop_labels": false,
    "show_worker_labels": false,
    "show_observation_labels": false
}

func _ready() -> void:
	_load_data()
	_build_stations()
	_build_story_props()
	_build_observations()
	_build_workers()

func _load_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("VardhelmAmbientLife: não foi possível abrir %s" % DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("VardhelmAmbientLife: JSON inválido")
		return
	_worker_defs = parsed.get("workers", [])
	_stations = parsed.get("stations", [])
	_story_defs = parsed.get("story_props", [])
	_observation_defs = parsed.get("observations", [])
	_memory_response_defs = parsed.get("memory_responses", [])
	_narrative_consequence_defs = parsed.get("narrative_consequences", [])
	var presentation_raw = parsed.get("presentation", {})
	if typeof(presentation_raw) == TYPE_DICTIONARY:
		for key in _presentation.keys():
			if presentation_raw.has(key):
				_presentation[key] = bool(presentation_raw[key])

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

func _box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

func _build_stations() -> void:
	var root := Node3D.new()
	root.name = "AmbientStations"
	add_child(root)
	for definition in _stations:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var marker := Node3D.new()
		marker.name = str(definition.get("id", "Station"))
		var p = definition.get("position", [0,0,0])
		marker.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		root.add_child(marker)
		_box(marker, "StationBase", Vector3(0,0.12,0), Vector3(1.8,0.24,0.9), _mat(Color("#343434")))
		var label := Label3D.new()
		label.text = str(definition.get("label", "ATIVIDADE"))
		label.font_size = 28
		label.outline_size = 8
		label.position = Vector3(0,1.25,0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.visible = bool(_presentation.get("show_station_labels", false))
		marker.add_child(label)

func _build_story_props() -> void:
	var root := Node3D.new()
	root.name = "EnvironmentalStoryProps"
	add_child(root)
	for definition in _story_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var p = definition.get("position", [0,0,0])
		var s = definition.get("size", [1,1,0.1])
		var prop := _box(root, str(definition.get("id","StoryProp")),
			Vector3(float(p[0]),float(p[1]),float(p[2])),
			Vector3(float(s[0]),float(s[1]),float(s[2])), _mat(Color("#454545")))
		var label := Label3D.new()
		label.name = "Label"
		label.text = str(definition.get("label",""))
		label.font_size = 20
		label.outline_size = 6
		label.position = Vector3(0,float(s[1])*0.65,0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.visible = bool(_presentation.get("show_story_prop_labels", false))
		prop.add_child(label)


func _build_observations() -> void:
	var root := Node3D.new()
	root.name = "EnvironmentalObservations"
	add_child(root)
	for definition in _observation_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var observation := ENVIRONMENTAL_OBSERVATION.new()
		observation.name = str(definition.get("id", "Observation"))
		observation.observation_id = str(definition.get("id", ""))
		observation.memory_id = str(definition.get("memory_id", ""))
		observation.memory_category = str(definition.get("memory_category", ""))
		observation.memory_title_key = str(definition.get("memory_title_key", ""))
		observation.memory_text_key = str(definition.get("memory_text_key", ""))
		observation.title_key = str(definition.get("title_key", ""))
		observation.text_key = str(definition.get("text_key", ""))
		observation.after_echo_text_key = str(definition.get("after_echo_text_key", ""))
		observation.seen_flag = str(definition.get("seen_flag", ""))
		var p = definition.get("position", [0,0,0])
		observation.position = Vector3(float(p[0]), float(p[1]), float(p[2]))

		var radius := float(definition.get("interaction_radius", 1.5))
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = maxf(radius, 0.25)
		collision.shape = shape
		observation.add_child(collision)

		var size_raw = definition.get("size", [0.8, 0.8, 0.12])
		var marker := _box(
			observation,
			"Marker",
			Vector3(0, float(size_raw[1]) * 0.5, 0),
			Vector3(float(size_raw[0]), float(size_raw[1]), float(size_raw[2])),
			_mat(Color("#505050"))
		)
		marker.visible = bool(definition.get("visible_marker", false))

		var label := Label3D.new()
		label.name = "Label3D"
		label.text = str(definition.get("label", "OBSERVAR"))
		label.font_size = 18
		label.outline_size = 6
		label.position = Vector3(0, float(size_raw[1]) + 0.35, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.visible = bool(_presentation.get("show_observation_labels", false))
		observation.add_child(label)

		root.add_child(observation)


func _build_workers() -> void:
	var root := Node3D.new()
	root.name = "AmbientWorkers"
	add_child(root)
	for definition in _worker_defs:
		if typeof(definition) != TYPE_DICTIONARY:
			continue
		var worker := _create_worker(definition)
		root.add_child(worker)

func _create_worker(definition: Dictionary) -> Node3D:
	var worker := Node3D.new()
	worker.name = str(definition.get("id", "Worker"))
	var p = definition.get("position", [0,0,0])
	worker.position = Vector3(float(p[0]),float(p[1]),float(p[2]))

	var body := MeshInstance3D.new()
	body.name = "Body"
	var capsule := CapsuleMesh.new()
	capsule.height = 1.45
	capsule.radius = 0.34
	body.mesh = capsule
	body.position.y = 0.86
	var accent := Color("#BDBDBD")
	if definition.has("accent"):
		accent = Color(str(definition["accent"]))
	body.material_override = _mat(accent)
	worker.add_child(body)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.height = 0.52
	sphere.radius = 0.26
	head.mesh = sphere
	head.position = Vector3(0,1.75,0)
	head.material_override = _mat(Color("#6E6E6E"))
	worker.add_child(head)

	var label := Label3D.new()
	label.text = str(definition.get("display_name", "Trabalhador"))
	label.font_size = 18
	label.outline_size = 6
	label.position = Vector3(0,2.25,0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visible = bool(_presentation.get("show_worker_labels", false))
	worker.add_child(label)
	worker.add_to_group("vardhelm_ambient_worker")

	var route_raw: Array = definition.get("route", [])
	if route_raw.size() >= 2:
		var route: Array[Vector3] = []
		for rp in route_raw:
			route.append(Vector3(float(rp[0]),float(rp[1]),float(rp[2])))
		_animate_worker(worker, route, float(definition.get("idle_seconds",2.0)), float(definition.get("work_seconds",2.0)))
	return worker

func _animate_worker(worker: Node3D, route: Array[Vector3], idle_time: float, work_time: float) -> void:
	var tween := create_tween()
	tween.set_loops()
	for target in route:
		tween.tween_property(worker, "position", target, work_time)
		tween.tween_interval(idle_time)
	var body := worker.get_node_or_null("Body")
	if body:
		var breathe := create_tween()
		breathe.set_loops()
		breathe.tween_property(body, "scale", Vector3(1.0,1.035,1.0), 0.55)
		breathe.tween_property(body, "scale", Vector3.ONE, 0.55)



func react_to_memory(memory_id: String) -> void:
	if memory_id.is_empty():
		return
	var response_definitions: Array = _memory_response_defs
	for definition in response_definitions:
		if str(definition.get("memory_id", "")) != memory_id:
			continue
		var duration := float(definition.get("duration", 2.2))
		var worker_attention := bool(definition.get("worker_attention", true))
		var station_pulse := bool(definition.get("station_pulse", false))
		if worker_attention:
			for worker in get_tree().get_nodes_in_group("vardhelm_ambient_worker"):
				if worker is Node3D:
					var tween := worker.create_tween()
					tween.tween_property(worker, "rotation_degrees:y", worker.rotation_degrees.y + 7.0, duration * 0.35)
					tween.tween_property(worker, "rotation_degrees:y", worker.rotation_degrees.y, duration * 0.65)
		if station_pulse:
			_pulse_station_labels(duration)
		return

func _pulse_station_labels(duration: float) -> void:
	var stations_node := get_node_or_null("AmbientStations")
	if stations_node == null:
		return
	for label in stations_node.get_children():
		if label is Label3D:
			var original: Color = label.modulate
			var tween := label.create_tween()
			tween.tween_property(label, "modulate", Color(1.0, 0.78, 0.45, 1.0), duration * 0.35)
			tween.tween_property(label, "modulate", original, duration * 0.65)


func apply_narrative_consequence(consequence_id: String, world_state: WorldState) -> void:
	if consequence_id.is_empty() or world_state == null:
		return
	var definitions: Array = _narrative_consequence_defs
	for definition in definitions:
		if str(definition.get("id", "")) != consequence_id:
			continue
		var flag_id := str(definition.get("world_flag", ""))
		var state_id := str(definition.get("environment_state", ""))
		if flag_id != "" and not world_state.has_flag(flag_id):
			return
		if state_id != "":
			environment_states[state_id] = true
		_apply_persistent_state_visuals(state_id)
		return

func _apply_persistent_state_visuals(state_id: String) -> void:
	if state_id == "":
		return
	# Persistent consequences stay subtle: no lore reveal, only world-state dressing.
	if state_id == "echo_awakened":
		_set_station_attention(true)
	elif state_id == "maintenance_remembered":
		_set_story_prop_marked("QUADRO DE MANUTENÇÃO", true)
	elif state_id == "sealed_panel_remembered":
		_set_story_prop_marked("PAINEL SELADO", true)
	elif state_id == "tools_remembered":
		_set_story_prop_marked("SUPORTE DE FERRAMENTAS", true)

func _set_station_attention(enabled: bool) -> void:
	var stations_node := get_node_or_null("AmbientStations")
	if stations_node == null:
		return
	for label in stations_node.get_children():
		if label is Label3D:
			if enabled:
				label.modulate = Color(1.0, 0.86, 0.62, 1.0)

func _set_story_prop_marked(prop_label: String, enabled: bool) -> void:
	if not enabled:
		return
	var props_node := get_node_or_null("EnvironmentalStoryProps")
	if props_node == null:
		return
	for node in props_node.get_children():
		if node is Node3D:
			var label := node.get_node_or_null("Label") as Label3D
			if label != null and label.text == prop_label:
				label.modulate = Color(1.0, 0.86, 0.62, 1.0)

func react_to_consequence(consequence_id: String) -> void:
	if consequence_id != "vardhelm_first_echo_complete":
		return
	var workers_root := get_node_or_null("AmbientWorkers")
	if workers_root != null:
		for worker in workers_root.get_children():
			if worker is Node3D:
				_react_worker(worker)
	var stations_root := get_node_or_null("AmbientStations")
	if stations_root != null:
		for station in stations_root.get_children():
			if station is Node3D:
				_react_station(station)

func _react_worker(worker: Node3D) -> void:
	var origin := worker.global_position
	var target := origin + Vector3(0.0, 0.0, 0.35)
	var tween := create_tween()
	tween.tween_property(worker, "global_position", target, 0.18)
	tween.tween_property(worker, "global_position", origin, 0.28)
	var original_rotation := worker.rotation.y
	tween.tween_property(worker, "rotation:y", original_rotation + deg_to_rad(8.0), 0.16)
	tween.tween_property(worker, "rotation:y", original_rotation, 0.22)

	var label := worker.get_node_or_null("Label3D") as Label3D
	if label != null:
		var old_modulate := label.modulate
		label.modulate = Color("#FFF0C2")
		var label_tween := create_tween()
		label_tween.tween_interval(1.8)
		label_tween.tween_property(label, "modulate", old_modulate, 0.35)

func _react_station(station: Node3D) -> void:
	var label := station.get_node_or_null("Label3D") as Label3D
	if label == null:
		return
	var original_text := label.text
	var original_modulate := label.modulate
	label.text = original_text + " • ATENÇÃO"
	label.modulate = Color("#FFE1A3")

	var pulse := create_tween()
	pulse.set_loops(3)
	pulse.tween_property(label, "scale", Vector3(1.08, 1.08, 1.08), 0.18)
	pulse.tween_property(label, "scale", Vector3.ONE, 0.22)

	var restore := create_tween()
	restore.tween_interval(2.4)
	restore.tween_property(label, "modulate", original_modulate, 0.35)
	restore.tween_callback(func() -> void:
		if is_instance_valid(label):
			label.text = original_text
			label.scale = Vector3.ONE
	)
