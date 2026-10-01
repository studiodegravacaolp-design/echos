extends Node3D
class_name VardhelmAmbientLife

const DATA_PATH := "res://data/vardhelm/ambient_life.json"
## C21: outra área de Vardhelm pode usar a mesma vida com outro arquivo (definir antes do
## _ready). O padrão continua sendo o da Forja 01.
var data_path: String = DATA_PATH
var environment_states: Dictionary = {}
const ENVIRONMENTAL_OBSERVATION := preload("res://scripts/interaction/environmental_observation.gd")
var _worker_defs: Array = []
var _stations: Array = []
var _story_defs: Array = []
var _observation_defs: Array = []
var _memory_response_defs: Array = []
var _narrative_consequence_defs: Array = []
## C13: reações persistentes (sutis) ao Primeiro Eco, derivadas de echo_awakened.
const ROUTINE_DEFAULT := "default"
const ROUTINE_AFTER_ECHO := "after_echo"
var _after_echo_def: Dictionary = {}
## C17.3: corpo de colisão leve dos trabalhadores comuns (raio/altura no JSON).
var _worker_body_def: Dictionary = {}
## C15: onde Durn fica quando o jogador disse "Não senti nada." e o Eco aconteceu.
var _durn_alone_def: Dictionary = {}
var _worker_routines: Dictionary = {}
var _flicker_tween: Tween = null
var _light_defaults: Dictionary = {}
var _audio_defaults: Dictionary = {}
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
	var file := FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("VardhelmAmbientLife: não foi possível abrir %s" % data_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("VardhelmAmbientLife: JSON inválido")
		return
	_worker_defs = parsed.get("workers", [])
	_stations = parsed.get("stations", [])
	_story_defs = parsed.get("story_props", [])
	_observation_defs = parsed.get("observations", [])
	# C16: observações que só existem sob uma condição derivada (lista separada; mesmas regras).
	_observation_defs = _observation_defs + parsed.get("conditional_observations", [])
	_memory_response_defs = parsed.get("memory_responses", [])
	_narrative_consequence_defs = parsed.get("narrative_consequences", [])
	_after_echo_def = parsed.get("after_echo", {})
	_worker_body_def = parsed.get("worker_body", {})
	_durn_alone_def = parsed.get("durn_alone", {})
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
		# C17.2: estrado de madeira baixo (antes: laje cinza de protótipo).
		_box(marker, "StationBase", Vector3(0,0.03,0), Vector3(1.8,0.06,0.9), _mat(Color("#3A2C20")))
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
			Vector3(float(s[0]),float(s[1]),float(s[2])), _mat(Color(str(definition.get("color", "#454545")))))
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
			_mat(Color(str(definition.get("marker_color", "#505050"))))
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
		# C16: observação que só existe em certas condições nasce indisponível; quem
		# decide quando ela aparece é a derivação (set_observation_available).
		observation.set_meta("marker_when_available", marker.visible)
		if bool(definition.get("starts_unavailable", false)):
			set_observation_available(observation.observation_id, false)


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
	# C23 (opcional): para onde o trabalhador parado olha, em graus (frente = −Z local).
	if definition.has("facing_degrees"):
		worker.rotation_degrees.y = float(definition["facing_degrees"])

	# C17.2: silhueta humana simples no lugar da cápsula (só visual). "accent" continua
	# sendo a cor da camisa; "outfit" (opcional) acrescenta avental/boné/calça.
	var outfit: Dictionary = definition.get("outfit", {}).duplicate()
	outfit["shirt"] = str(definition.get("accent", HumanoidSilhouette.DEFAULT_SHIRT))
	outfit["carrying"] = definition.has("carry")
	HumanoidSilhouette.build(worker, outfit)
	_add_worker_body(worker)

	# C17.1: opcional — material carregado nos braços ("carry": [largura, altura, profundidade]).
	if definition.has("carry"):
		var c = definition["carry"]
		var carried := MeshInstance3D.new()
		carried.name = "Carry"
		var box := BoxMesh.new()
		box.size = Vector3(float(c[0]), float(c[1]), float(c[2]))
		carried.mesh = box
		carried.position = Vector3(0, 1.0, -0.38)
		# C23 (opcional): carga em outra altura/distância (ex.: carrinho de mão empurrado).
		if definition.has("carry_offset"):
			var o = definition["carry_offset"]
			carried.position = Vector3(float(o[0]), float(o[1]), float(o[2]))
		carried.material_override = _mat(Color("#3F3022"))
		worker.add_child(carried)

	var label := Label3D.new()
	label.text = str(definition.get("display_name", "Trabalhador"))
	label.font_size = 18
	label.outline_size = 6
	label.position = Vector3(0,2.25,0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visible = bool(_presentation.get("show_worker_labels", false))
	worker.add_child(label)
	worker.add_to_group("vardhelm_ambient_worker")

	worker.set_meta("definition", definition)
	_start_routine(worker, ROUTINE_DEFAULT)
	_animate_worker(worker)
	return worker

## C13: rotina de trabalho do trabalhador. "default" = rota original; "after_echo" =
## rota alternativa opcional do JSON (after_echo_route), usada depois do Primeiro Eco.
func _start_routine(worker: Node3D, routine: String, delay := 0.0) -> void:
	var previous: Tween = _worker_routines.get(worker.name)
	if previous != null and previous.is_valid():
		previous.kill()
	_worker_routines.erase(worker.name)
	worker.set_meta("routine", routine)
	var definition: Dictionary = worker.get_meta("definition", {})
	var key := "after_echo_route" if routine == ROUTINE_AFTER_ECHO else "route"
	var prefix := "after_echo_" if routine == ROUTINE_AFTER_ECHO else ""
	var route: Array[Vector3] = []
	for rp in definition.get(key, []):
		route.append(Vector3(float(rp[0]), float(rp[1]), float(rp[2])))
	if route.size() < 2:
		return
	var idle_time := float(definition.get(prefix + "idle_seconds", 2.0))
	var work_time := float(definition.get(prefix + "work_seconds", 2.0))
	if delay > 0.0:
		var starter := create_tween()
		starter.tween_interval(delay)
		starter.tween_callback(func() -> void: _loop_route(worker, route, idle_time, work_time))
		_worker_routines[worker.name] = starter
	else:
		_loop_route(worker, route, idle_time, work_time)

func _loop_route(worker: Node3D, route: Array[Vector3], idle_time: float, work_time: float) -> void:
	var tween := create_tween()
	tween.set_loops()
	# C23 (opcional, "face_movement"): vira para o próximo ponto antes de andar até ele.
	var face := bool((worker.get_meta("definition", {}) as Dictionary).get("face_movement", false))
	for target in route:
		if face:
			tween.tween_callback(_face_towards.bind(worker, target))
		tween.tween_property(worker, "position", target, work_time)
		tween.tween_interval(idle_time)
	_worker_routines[worker.name] = tween

func _face_towards(worker: Node3D, target: Vector3) -> void:
	var d := target - worker.position
	d.y = 0.0
	if d.length() > 0.05:
		worker.rotation.y = atan2(-d.x, -d.z)

func _animate_worker(worker: Node3D) -> void:
	var body := worker.find_child("Body", true, false)
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
		_apply_after_echo_world()
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

## Bloco C7: desfaz o estado PERSISTENTE derivado (environment_states + marcações
## visuais persistentes de _apply_persistent_state_visuals), para que ele seja
## re-derivado do WorldState em um Load V2. Aditivo: nunca chamado pelo gameplay.
## Efeitos temporários (tweens de react_to_*) não são tocados.
func reset_persistent_state() -> void:
	environment_states.clear()
	_stop_closing_silence()
	_reset_after_echo_world()
	var stations_node := get_node_or_null("AmbientStations")
	if stations_node != null:
		for label in stations_node.get_children():
			if label is Label3D:
				label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var props_node := get_node_or_null("EnvironmentalStoryProps")
	if props_node != null:
		for node in props_node.get_children():
			if node is Node3D:
				var label := node.get_node_or_null("Label") as Label3D
				if label != null:
					label.modulate = Color(1.0, 1.0, 1.0, 1.0)


## C13 — Vardhelm reage ao Primeiro Eco, sem explicar nada. Tudo é DERIVADO de
## echo_awakened (flag vardhelm_first_echo_complete): aplicado quando o Eco acontece e
## re-derivado no Load V2 (reset_persistent_state + derivação existente). Idempotente:
## re-aplicar não reinicia rotina, piscar nem áudio.
##   1. a luz de trabalho sobre o painel selado fica mais fria e falha de vez em quando;
##   2. o trabalhador da oficina deixa a bancada e fica parado perto do painel;
##   3. o ruído das máquinas fica mais baixo.
func is_after_echo_world_applied() -> bool:
	return _flicker_tween != null and _flicker_tween.is_valid()

func _after_echo_light() -> OmniLight3D:
	var path := str(_after_echo_def.get("flicker_light", ""))
	return get_parent().get_node_or_null(path) as OmniLight3D if path != "" and get_parent() != null else null

## Malha da luminária (o set dressing embrulha a MeshInstance3D num Node3D).
func _after_echo_fixture() -> MeshInstance3D:
	var path := str(_after_echo_def.get("flicker_fixture", ""))
	var holder := get_parent().get_node_or_null(path) if path != "" and get_parent() != null else null
	if holder == null:
		return null
	for child in holder.get_children():
		if child is MeshInstance3D:
			return child
	return null

func _after_echo_audio() -> AudioStreamPlayer:
	var path := str(_after_echo_def.get("quiet_audio", ""))
	return get_parent().get_node_or_null(path) as AudioStreamPlayer if path != "" and get_parent() != null else null

func _apply_after_echo_world() -> void:
	var workers_root := get_node_or_null("AmbientWorkers")
	if workers_root != null:
		for worker in workers_root.get_children():
			var definition: Dictionary = worker.get_meta("definition", {})
			if definition.has("after_echo_route") and worker.get_meta("routine", "") != ROUTINE_AFTER_ECHO:
				# Depois do sobressalto do Eco (react_to_consequence) ele sai da rotina.
				_start_routine(worker, ROUTINE_AFTER_ECHO, float(_after_echo_def.get("routine_delay", 0.6)))
	var light := _after_echo_light()
	if light != null and not is_after_echo_world_applied():
		if _light_defaults.is_empty():
			_light_defaults = {"color": light.light_color, "energy": light.light_energy, "range": light.omni_range}
		var base_energy: float = _light_defaults["energy"]
		var cold := Color(str(_after_echo_def.get("flicker_color", "#FFFFFF")))
		var steps: Array = _after_echo_def.get("flicker_steps", [])
		light.light_color = cold
		light.omni_range = float(_after_echo_def.get("flicker_range", _light_defaults["range"]))
		if not steps.is_empty():
			light.light_energy = base_energy * float(steps[0][0])
		# A luminária (malha emissiva) acompanha a luz: fria e falhando junto.
		var fixture := _after_echo_fixture()
		var fixture_material: StandardMaterial3D = null
		var fixture_energy := float(_after_echo_def.get("fixture_energy", 1.5))
		if fixture != null:
			fixture_material = StandardMaterial3D.new()
			fixture_material.albedo_color = cold.darkened(0.55)
			fixture_material.emission_enabled = true
			fixture_material.emission = cold
			fixture_material.emission_energy_multiplier = fixture_energy * (float(steps[0][0]) if not steps.is_empty() else 1.0)
			fixture.material_override = fixture_material
		_flicker_tween = create_tween()
		_flicker_tween.set_loops()
		for step in steps:
			_flicker_tween.tween_property(light, "light_energy", base_energy * float(step[0]), float(step[1]))
			if fixture_material != null:
				_flicker_tween.parallel().tween_property(fixture_material, "emission_energy_multiplier", fixture_energy * float(step[0]), float(step[1]))
	var audio := _after_echo_audio()
	if audio != null:
		if _audio_defaults.is_empty():
			_audio_defaults = {"volume_db": audio.volume_db}
		audio.volume_db = float(_audio_defaults["volume_db"]) + float(_after_echo_def.get("quiet_audio_db", 0.0))

func _reset_after_echo_world() -> void:
	var workers_root := get_node_or_null("AmbientWorkers")
	if workers_root != null:
		for worker in workers_root.get_children():
			if worker.get_meta("routine", "") == ROUTINE_AFTER_ECHO:
				var definition: Dictionary = worker.get_meta("definition", {})
				var p = definition.get("position", [0, 0, 0])
				_start_routine(worker, ROUTINE_DEFAULT)
				worker.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()
	_flicker_tween = null
	var light := _after_echo_light()
	if light != null and not _light_defaults.is_empty():
		light.light_color = _light_defaults["color"]
		light.light_energy = _light_defaults["energy"]
		light.omni_range = _light_defaults["range"]
	var fixture := _after_echo_fixture()
	if fixture != null:
		fixture.material_override = null
	var audio := _after_echo_audio()
	if audio != null and not _audio_defaults.is_empty():
		audio.volume_db = _audio_defaults["volume_db"]


## C14 — encerramento da primeira sequência: ao concluir o exame do painel, Vardhelm
## fica em silêncio por alguns segundos (zumbido, vapor e máquinas quase somem) e a
## luz fria sobre o painel se apaga; depois tudo volta ao estado pós-Eco. Transitório
## (nada é salvo); um Load no meio interrompe e devolve o som e a luz ao estado derivado.
var _silence_tween: Tween = null
var _silence_defaults: Dictionary = {}

func is_closing_silence_active() -> bool:
	return _silence_tween != null and _silence_tween.is_valid()

func _silence_players() -> Array:
	var players: Array = []
	var definition: Dictionary = _after_echo_def.get("closing_silence", {})
	for path in definition.get("audio", []):
		var player := get_parent().get_node_or_null(str(path)) as AudioStreamPlayer if get_parent() != null else null
		if player != null:
			players.append(player)
			if not _silence_defaults.has(player.name):
				_silence_defaults[player.name] = player.volume_db
	return players

## Volume "de repouso" de cada som: o original, ou o do estado pós-Eco (máquinas).
func _resting_volume(player: AudioStreamPlayer) -> float:
	if player == _after_echo_audio() and not _audio_defaults.is_empty():
		var offset := float(_after_echo_def.get("quiet_audio_db", 0.0)) if environment_states.has("echo_awakened") else 0.0
		return float(_audio_defaults["volume_db"]) + offset
	return float(_silence_defaults.get(player.name, player.volume_db))

func play_closing_silence() -> void:
	if is_closing_silence_active():
		return
	var definition: Dictionary = _after_echo_def.get("closing_silence", {})
	var players := _silence_players()
	if definition.is_empty() or players.is_empty():
		return
	var fade_out := float(definition.get("fade_out", 1.2))
	var hold := float(definition.get("hold", 4.0))
	var fade_in := float(definition.get("fade_in", 3.0))
	var silent_db := float(definition.get("silent_db", -40.0))
	var light := _after_echo_light()
	var lamp_off := bool(definition.get("lamp_off", false)) and light != null and is_after_echo_world_applied()
	if lamp_off:
		_flicker_tween.pause()
	# Passos sequenciais explícitos: some (fade_out) → silêncio (hold) → volta (fade_in).
	_silence_tween = create_tween()
	for i in players.size():
		var step := _silence_tween.parallel() if i > 0 else _silence_tween
		step.tween_property(players[i], "volume_db", silent_db, fade_out)
	if lamp_off:
		_silence_tween.parallel().tween_property(light, "light_energy", 0.0, fade_out)
	_silence_tween.tween_interval(hold)
	for i in players.size():
		var step := _silence_tween.parallel() if i > 0 else _silence_tween
		step.tween_property(players[i], "volume_db", _resting_volume(players[i]), fade_in)
	_silence_tween.tween_callback(_end_closing_silence)

func _end_closing_silence() -> void:
	_silence_tween = null
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.play()

## Interrompe o encerramento (Load no meio dele): som no volume de repouso.
func _stop_closing_silence() -> void:
	if _silence_tween != null and _silence_tween.is_valid():
		_silence_tween.kill()
	_silence_tween = null
	for player in _silence_players():
		player.volume_db = _resting_volume(player)


## C15 — Durn sozinho: estado de ambiente derivado da consequência da escolha
## "Não senti nada." (vardhelm_felt_nothing → durn_alone). Só se mostra depois do Eco
## (echo_awakened): quem posiciona Durn é o slice, que é dono do NPC.
func durn_alone_def() -> Dictionary:
	return _durn_alone_def

func is_durn_alone_after_echo() -> bool:
	var state := str(_durn_alone_def.get("environment_state", ""))
	var after := str(_durn_alone_def.get("after", ""))
	return state != "" and environment_states.has(state) and (after == "" or environment_states.has(after))


## C16 — liga/desliga uma observação (interação + marca visível). Não guarda nada:
## a disponibilidade é derivada do estado persistente por quem chama.
func set_observation_available(observation_id: String, available: bool) -> void:
	var node := get_node_or_null("EnvironmentalObservations/%s" % observation_id) as EnvironmentalObservation
	if node == null:
		return
	node.interaction_enabled = available
	var marker := node.get_node_or_null("Marker") as Node3D
	if marker != null:
		marker.visible = available and bool(node.get_meta("marker_when_available", false))

func is_observation_available(observation_id: String) -> bool:
	var node := get_node_or_null("EnvironmentalObservations/%s" % observation_id) as EnvironmentalObservation
	return node != null and node.interaction_enabled


## C17.3 — o jogador não atravessa o corpo de um trabalhador. Cápsula fina (só pernas e
## tronco) num AnimatableBody3D filho do trabalhador: acompanha a rota do tween sem nenhum
## processamento novo, e a rota nunca depende da física (não trava nem treme).
##   camada 1 (a mesma do cenário, que o jogador já colide) · máscara 0 (não detecta nada:
##   trabalhadores não colidem entre si nem com o cenário) · fora da camada 2 (interação):
##   o detector do E não o enxerga. Durn é montado pelo slice e não passa por aqui.
func _add_worker_body(worker: Node3D) -> void:
	if _worker_body_def.is_empty():
		return
	var radius := float(_worker_body_def.get("radius", 0.25))
	var height := float(_worker_body_def.get("height", 1.7))
	var body := AnimatableBody3D.new()
	body.name = "BodyCollider"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = height
	shape.shape = capsule
	shape.position = Vector3(0, height / 2.0, 0)
	body.add_child(shape)
	worker.add_child(body)
