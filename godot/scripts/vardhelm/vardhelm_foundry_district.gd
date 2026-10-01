class_name VardhelmFoundryDistrict
extends Node3D

## C21 — Distrito das Fundições: o pátio sob a Forja 01 (mesmo cenário, scenario.vardhelm).
##
## A geometria vem do LevelBuilder (level_data/vardhelm_foundry_district_01.json, assada em
## vp_02_vardhelm_foundry_district.tscn e instanciada no slice). Este nó só integra o
## pátio ao jogo, a partir de data/vardhelm/foundry_district.json:
##   - vida: um VardhelmAmbientLife com os dados do pátio (mesma classe, outro arquivo);
##   - passagem: a talha (dois TransitionPoint) entre o patamar da Forja 01 e o pátio;
##   - atmosfera: lampiões, placas, fumaça do respiro da Forja 01, vapor, poeira de carvão;
##   - névoa de altura e luz ambiente: acompanham a área do jogador (derivado da posição);
##   - desenho: o pátio só é desenhado no pátio ou perto do patamar (custo medido no C21);
##   - C23: a rua do distrito (vp_03), pelo portão sul do pátio, com uma segunda vida e
##     animações simples (carga da talha, pedra de afiar, trem de carga) vindas dos dados;
##   - reação: depois do Primeiro Eco o respiro da Forja 01 solta menos fumaça (derivado da
##     flag persistente vardhelm_first_echo_complete, a mesma que o C13 usa).
##
## Nada aqui é persistido: a posição do jogador (Save V2) define a área; o resto se deriva.
## Sem _process: sinais de Area3D e tweens curtos.

const CONFIG_PATH := "res://data/vardhelm/foundry_district.json"
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const VARDHELM_LIFE := preload("res://scripts/vardhelm/vardhelm_ambient_life.gd")
const ECHO_DONE_FLAG := "vardhelm_first_echo_complete"

signal area_changed(in_district: bool)

var config: Dictionary = {}
var life: VardhelmAmbientLife
## C23: todas as vidas do distrito (pátio = a primeira; rua = "StreetLife").
var lives: Array[VardhelmAmbientLife] = []
var hoist_top: TransitionPoint
var hoist_bottom: TransitionPoint
var player_in_district := false
## Perto do patamar da Forja 01 (de onde se vê o pátio lá embaixo).
var player_near_landing := false
## O pátio só é desenhado quando pode ser visto (derivado da área; ver _apply_view).
var district_drawn := true
var riding := false
var after_echo_applied := false

var _slice: Node
var _player: Node3D
var _level: Node3D
var _cage: Node3D
var _chains: Array[MeshInstance3D] = []
var _environment: Environment
var _fog_tween: Tween
var _fade: ColorRect
var _smoke: Array[CPUParticles3D] = []
## C23: níveis desenhados juntos (pátio + rua); o primeiro é o da talha.
var _levels: Array[Node3D] = []
var _animations: Array[Tween] = []


func setup(slice: Node) -> void:
	_slice = slice
	_player = slice.get("player")
	config = JSON_LOADER.read_dictionary(CONFIG_PATH)
	_level = slice.get_node_or_null(str(config.get("level_node", "VP02_FoundryDistrict"))) as Node3D
	if _level == null:
		push_error("VardhelmFoundryDistrict: nível do pátio ausente")
		return
	# O nível traz uma câmera (exigida pelo schema do LevelBuilder); a do jogador manda.
	_levels = [_level]
	for level_name in config.get("extra_levels", []):
		var extra := slice.get_node_or_null(str(level_name)) as Node3D
		if extra != null:
			_levels.append(extra)
	for level in _levels:
		var level_camera := level.get_node_or_null("Camera3D") as Camera3D
		if level_camera != null:
			level_camera.current = false
	var world_environment := slice.get_node_or_null("VP01_Vardhelm/WorldEnvironment") as WorldEnvironment
	if world_environment != null:
		_environment = world_environment.environment
	_build_life()
	_build_hoist()
	_build_area()
	_build_landing_view()
	_build_lamps()
	_build_signs()
	_build_atmosphere()
	_build_fade()
	_build_animations()
	var narrative = slice.get("narrative_controller")
	if narrative != null:
		narrative.consequence_applied.connect(func(_id) -> void: refresh.call_deferred())
	refresh()
	_apply_view()


func observation_root() -> Node:
	return life.get_node_or_null("EnvironmentalObservations") if life != null else null


## C23: as raízes de observação de todas as vidas do distrito (pátio e rua).
func observation_roots() -> Array[Node]:
	var roots: Array[Node] = []
	for each in lives:
		var root := each.get_node_or_null("EnvironmentalObservations")
		if root != null:
			roots.append(root)
	return roots


func life_named(life_name: String) -> VardhelmAmbientLife:
	for each in lives:
		if each.name == life_name:
			return each
	return null


# --- vida ------------------------------------------------------------------------------

func _build_life() -> void:
	life = _add_life("Life", str(config.get("life_data", "")), config.get("origin", [0, 0, 0]))
	# C23: vidas extras (ex.: a rua), mesma classe, outro arquivo e outra origem.
	for definition in config.get("extra_lives", []):
		_add_life(str(definition.get("name", "ExtraLife")), str(definition.get("data", "")), definition.get("origin", [0, 0, 0]))


func _add_life(life_name: String, data: String, origin) -> VardhelmAmbientLife:
	var each := VARDHELM_LIFE.new()
	each.name = life_name
	each.data_path = data
	each.position = _vec(origin)
	add_child(each)
	lives.append(each)
	return each


# --- talha: passagem entre o patamar da Forja 01 e o pátio -------------------------------

func _build_hoist() -> void:
	var hoist: Dictionary = config.get("hoist", {})
	_cage = _level.get_node_or_null(str(hoist.get("cage_node", ""))) as Node3D
	hoist_top = _transition(hoist.get("top", {}))
	hoist_bottom = _transition(hoist.get("bottom", {}))
	var chain_material := StandardMaterial3D.new()
	chain_material.albedo_color = Color("#1E222A")
	chain_material.metallic = 0.78
	chain_material.roughness = 0.55
	for x in hoist.get("chain_x", []):
		var chain := MeshInstance3D.new()
		chain.name = "HoistChain_%d" % _chains.size()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.04, 1.0, 0.04)
		chain.mesh = mesh
		chain.material_override = chain_material
		chain.set_meta("x", float(x))
		add_child(chain)
		_chains.append(chain)
	_place_cage(false)


func _transition(definition: Dictionary) -> TransitionPoint:
	var point := TransitionPoint.new()
	point.name = "Hoist_" + str(definition.get("id", "point"))
	point.interaction_id = str(definition.get("id", ""))
	point.prompt_key = str(definition.get("prompt_key", ""))
	point.destination = _vec(definition.get("destination", [0, 0, 0]))
	point.destination_id = str(definition.get("destination_id", ""))
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = float(definition.get("radius", 0.8))
	collision.shape = sphere
	point.add_child(collision)
	point.position = _vec(definition.get("position", [0, 0, 0]))
	add_child(point)
	point.interaction_requested.connect(_on_hoist_requested)
	return point


func _on_hoist_requested(_actor: Node, interactable: Interactable) -> void:
	if riding or _player == null:
		return
	var point := interactable as TransitionPoint
	if point == null:
		return
	riding = true
	var hoist: Dictionary = config.get("hoist", {})
	var fade := float(hoist.get("fade_seconds", 0.3))
	var hold := float(hoist.get("hold_seconds", 0.35))
	var start := _player.global_position
	_player.set_physics_process(false)
	_player.set("velocity", Vector3.ZERO)
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, fade)
	tween.tween_callback(func() -> void:
		# Um Load durante o escurecimento já pôs o jogador em outro lugar: não o move.
		if _player.global_position.distance_to(start) < 0.5:
			_player.global_position = point.destination
		_place_cage(point == hoist_top)
	)
	tween.tween_interval(hold)
	tween.tween_property(_fade, "color:a", 0.0, fade)
	tween.tween_callback(func() -> void:
		_player.set_physics_process(true)
		riding = false
	)


## A gaiola fica do lado em que o jogador está (derivado; nunca salvo).
func _place_cage(at_bottom: bool) -> void:
	if _cage == null:
		return
	var hoist: Dictionary = config.get("hoist", {})
	_cage.position.y = float(hoist.get("cage_bottom_y" if at_bottom else "cage_top_y", 0.0))
	var pulley := _vec(hoist.get("pulley_bottom", [0, 0, 0]))
	var cage_top := _cage.global_position.y + 2.34
	var length := maxf(pulley.y - cage_top, 0.05)
	for chain in _chains:
		chain.global_position = Vector3(pulley.x + float(chain.get_meta("x")), cage_top + length / 2.0, pulley.z)
		chain.scale = Vector3(1.0, length, 1.0)


# --- área: névoa de altura e luz ambiente derivadas da posição do jogador ------------------

func _build_area() -> void:
	var area_def: Dictionary = config.get("area", {})
	var area := Area3D.new()
	area.name = "DistrictArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = _vec(area_def.get("size", [1, 1, 1]))
	collision.shape = shape
	area.add_child(collision)
	area.position = _vec(area_def.get("center", [0, 0, 0]))
	add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body == _player:
			_set_player_area(true)
	)
	area.body_exited.connect(func(body: Node) -> void:
		if body == _player:
			_set_player_area(false)
	)


func _set_player_area(in_district: bool) -> void:
	if player_in_district == in_district:
		return
	player_in_district = in_district
	if not riding:
		_place_cage(in_district)
	var fog: Dictionary = config.get("fog", {})
	if _environment != null:
		var height := float(fog.get("district_height" if in_district else "forge_height", _environment.fog_height))
		var ambient := float(fog.get("district_ambient" if in_district else "forge_ambient", _environment.ambient_light_energy))
		var seconds := float(fog.get("blend_seconds", 0.35))
		if _fog_tween != null and _fog_tween.is_valid():
			_fog_tween.kill()
		_fog_tween = create_tween().set_parallel()
		_fog_tween.tween_property(_environment, "fog_height", height, seconds)
		_fog_tween.tween_property(_environment, "ambient_light_energy", ambient, seconds)
	_apply_view()
	area_changed.emit(in_district)


func _build_landing_view() -> void:
	var view: Dictionary = config.get("landing_view", {})
	if view.is_empty():
		return
	var area := Area3D.new()
	area.name = "LandingView"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = _vec(view.get("size", [1, 1, 1]))
	collision.shape = shape
	area.add_child(collision)
	area.position = _vec(view.get("center", [0, 0, 0]))
	add_child(area)
	area.body_entered.connect(func(body: Node) -> void:
		if body == _player:
			player_near_landing = true
			_apply_view()
	)
	area.body_exited.connect(func(body: Node) -> void:
		if body == _player:
			player_near_landing = false
			_apply_view()
	)


## Da Forja 01 o pátio fica escondido sob o piso e na névoa, mas seria desenhado mesmo
## assim (não há oclusão): só é desenhado no pátio ou perto do patamar. A talha fica sempre
## visível (orienta o jogador desde dentro da Forja). Colisão e vida não mudam.
func _apply_view() -> void:
	var drawn := player_in_district or player_near_landing
	if drawn == district_drawn or _level == null:
		return
	district_drawn = drawn
	var keep := str(config.get("landing_view", {}).get("always_visible_prefix", "Hoist"))
	for level in _levels:
		var generated := level.get_node_or_null("Generated")
		if generated == null:
			continue
		for child in generated.get_children():
			if child.name == "Props":
				for prop in child.get_children():
					if not String(prop.name).begins_with(keep):
						(prop as Node3D).visible = drawn
			elif child is Node3D:
				(child as Node3D).visible = drawn
	for each in lives:
		each.visible = drawn
	for node in get_children():
		if node is OmniLight3D or node is CPUParticles3D or node is Label3D:
			(node as Node3D).visible = drawn


# --- C23: animações simples de cenário (dados) -------------------------------------------------

## Cada entrada: {"level", "node" (relativo ao nível), "move": [dx,dy,dz] (vai e volta) ou
## "spin": "x"|"y"|"z" (volta completa), "seconds"}. Tweens em laço; nada é salvo.
func _build_animations() -> void:
	for definition in config.get("animations", []):
		var level := _slice.get_node_or_null(str(definition.get("level", ""))) as Node3D
		var node := level.get_node_or_null(str(definition.get("node", ""))) as Node3D if level != null else null
		if node == null:
			push_warning("VardhelmFoundryDistrict: animação sem nó: %s" % str(definition))
			continue
		var seconds := float(definition.get("seconds", 2.0))
		var tween := create_tween().set_loops()
		if definition.has("move"):
			var start := node.position
			var target := start + _vec(definition["move"])
			tween.tween_property(node, "position", target, seconds).set_trans(Tween.TRANS_SINE)
			tween.tween_property(node, "position", start, seconds).set_trans(Tween.TRANS_SINE)
		elif definition.has("spin"):
			var axis := str(definition["spin"])
			var base: float = node.rotation[ ["x", "y", "z"].find(axis) ]
			tween.tween_property(node, "rotation:" + axis, base + TAU, seconds).from(base)
		_animations.append(tween)


# --- atmosfera ------------------------------------------------------------------------------

func _build_lamps() -> void:
	for definition in config.get("lamps", []):
		var light := OmniLight3D.new()
		light.name = "Lamp_%d" % get_child_count()
		light.light_color = Color(str(definition.get("color", "#D89A5A")))
		light.light_energy = float(definition.get("energy", 0.8))
		light.omni_range = float(definition.get("range", 6.0))
		light.shadow_enabled = false
		light.position = _vec(definition.get("position", [0, 0, 0]))
		add_child(light)


func _build_signs() -> void:
	for definition in config.get("signs", []):
		var sign := Label3D.new()
		sign.name = "Sign_%d" % get_child_count()
		sign.text = str(definition.get("text", ""))
		sign.font_size = int(definition.get("font_size", 32))
		sign.modulate = Color("#C9C0AE")
		sign.outline_size = 6
		sign.outline_modulate = Color(0.02, 0.03, 0.04, 0.9)
		sign.position = _vec(definition.get("position", [0, 0, 0]))
		add_child(sign)


func _build_atmosphere() -> void:
	for definition in config.get("smoke", []):
		var particles := _particles(definition, Vector3.UP, 14.0, Vector2(0.25, 0.5))
		_smoke.append(particles)
	var dust: Dictionary = config.get("dust", {})
	if not dust.is_empty():
		var particles := _particles(dust, Vector3(0.3, 0.2, 0.1), 180.0, Vector2(0.02, 0.08))
		particles.gravity = Vector3.ZERO


func _particles(definition: Dictionary, direction: Vector3, spread: float, velocity: Vector2) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = str(definition.get("name", "Dust"))
	particles.position = _vec(definition.get("position", [0, 0, 0]))
	particles.amount = int(definition.get("amount", 16))
	particles.lifetime = float(definition.get("lifetime", 6.0))
	particles.preprocess = particles.lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = _vec(definition.get("extents", [0.5, 0.5, 0.5]))
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = velocity.x
	particles.initial_velocity_max = velocity.y
	particles.gravity = Vector3(0.05, 0.08, 0.0)
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.6))
	particles.scale_amount_curve = grow
	particles.set_meta("definition", definition)
	_apply_alpha(particles, 1.0)
	var quad := QuadMesh.new()
	var size := float(definition.get("size", 1.0))
	quad.size = Vector2(size, size)
	quad.material = _soft_particle_material()
	particles.mesh = quad
	add_child(particles)
	return particles


func _apply_alpha(particles: CPUParticles3D, ratio: float) -> void:
	var definition: Dictionary = particles.get_meta("definition", {})
	var color := Color(str(definition.get("color", "#808080")))
	color.a = float(definition.get("alpha", 0.5)) * ratio
	var fade := Gradient.new()
	fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
	fade.set_color(1, Color(color.r, color.g, color.b, 0.0))
	fade.add_point(0.3, color)
	particles.color_ramp = fade
	particles.set_meta("alpha_ratio", ratio)


func _soft_particle_material() -> StandardMaterial3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 64
	texture.height = 64
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	return material


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HoistFade"
	layer.layer = 20
	add_child(layer)
	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(0.02, 0.02, 0.025, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


# --- reação derivada -----------------------------------------------------------------------

## Re-deriva a apresentação a partir do estado persistente (início, Eco ao vivo, Load).
func refresh() -> void:
	var narrative = _slice.get("narrative_controller") if _slice != null else null
	var echo_done: bool = narrative != null and narrative.world_state.has_flag(ECHO_DONE_FLAG)
	after_echo_applied = echo_done
	for particles in _smoke:
		var definition: Dictionary = particles.get_meta("definition", {})
		var ratio := float(definition.get("after_echo_ratio", 1.0)) if echo_done else 1.0
		_apply_alpha(particles, ratio)


func smoke_ratio(emitter_name: String) -> float:
	for particles in _smoke:
		if particles.name == emitter_name:
			return float(particles.get_meta("alpha_ratio", 1.0))
	return -1.0


func _vec(value) -> Vector3:
	if typeof(value) != TYPE_ARRAY or value.size() < 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
