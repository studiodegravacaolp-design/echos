class_name VardhelmSetDressing
extends Node3D

# Ambientação procedural do setor FORJA 01.
# Não altera o LevelBuilder nem a geometria baked do cenário.
# Os elementos abaixo são set dressing/runtime: leitura espacial, iluminação e identidade industrial.

var _metal_dark := Color("#20262A")
var _metal_mid := Color("#3A3D40")
# C17.2: madeira velha (antes #6B4A32, lia laranja-marrom ao lado da forja).
var _metal_warm := Color("#4E3B2A")
var _rust := Color("#6A3E28")
var _ember := Color("#FF8A3D")
var _cyan := Color("#6FE7FF")
var _paper := Color("#C7D2DA")
# C17: o calor fica na forja (laranja-incandescente do BLUEPRINT_VISUAL_MESTRE); lâmpadas
# comuns são querosene fraco; faixas e anéis deixam de brilhar.
var _forge := Color("#FF7900")
var _kerosene := Color("#D9964F")
var _ochre_paint := Color("#5E4A2E")

func build(_owner: Node) -> void:
    _create_forge_core(Vector3(-6.2, 0.0, -0.9))
    _create_pipe_bank(Vector3(7.7, 0.0, -1.2))
    # C21.1: bancada 0,6 m a oeste (antes em x 0,0): abre 1,5 m entre ela e o respiro de
    # brasas, o caminho até o portão e a talha (antes 0,9 m para um jogador de 0,8 m).
    _create_workbench(Vector3(-0.6, 0.0, 4.7))
    _create_crate_cluster(Vector3(-8.0, 0.0, 2.4))
    _create_crate_cluster(Vector3(6.8, 0.0, 1.0))
    _create_wall_lamps()
    _create_floor_markings()
    # C17.2: rótulos flutuantes de protótipo removidos; o nome do setor fica só na placa
    # do portão (_create_entry_gate).
    _create_steam_vents()
    _create_overhead_cable()
    _create_overhead_beams()
    _create_storage_racks()
    _create_foundry_duct()
    _create_entry_gate()
    _create_floor_grates()
    _create_warning_bands()
    _create_work_lights()
    _create_bay_dust()

func _mat(color: Color, metallic := 0.45, roughness := 0.7) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

func _emissive(color: Color, energy := 2.0) -> StandardMaterial3D:
    var m := _mat(color.darkened(0.55), 0.2, 0.55)
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = energy
    return m

func _box(name: String, pos: Vector3, size: Vector3, material: Material, collision := false) -> Node3D:
    var node: Node3D
    if collision:
        node = StaticBody3D.new()
        (node as StaticBody3D).collision_layer = 1
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        shape_node.position = Vector3.ZERO
        node.add_child(shape_node)
    else:
        node = Node3D.new()
    node.name = name
    node.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    box.material = material
    mesh.mesh = box
    node.add_child(mesh)
    add_child(node)
    return node

func _cylinder(name: String, pos: Vector3, radius: float, height: float, material: Material, collision := false) -> Node3D:
    var node: Node3D
    if collision:
        node = StaticBody3D.new()
        (node as StaticBody3D).collision_layer = 1
        var shape_node := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = radius
        shape.height = height
        shape_node.shape = shape
        node.add_child(shape_node)
    else:
        node = Node3D.new()
    node.name = name
    node.position = pos
    var mesh := MeshInstance3D.new()
    var cyl := CylinderMesh.new()
    cyl.top_radius = radius
    cyl.bottom_radius = radius
    cyl.height = height
    cyl.material = material
    mesh.mesh = cyl
    node.add_child(mesh)
    add_child(node)
    return node

func _create_forge_core(center: Vector3) -> void:
    _box("ForgeBase", center + Vector3(0, 0.45, 0), Vector3(3.4, 0.9, 2.1), _mat(_metal_dark, 0.7, 0.65), true)
    _box("ForgeHousing", center + Vector3(0, 1.35, 0), Vector3(2.6, 1.0, 1.55), _mat(_metal_mid, 0.72, 0.6), true)
    _box("ForgeFace", center + Vector3(0, 1.38, 0.79), Vector3(1.35, 0.55, 0.08), _emissive(_forge, 2.4))
    # C17: a chaminé sobe bem acima das paredes (escala vertical); mesma base.
    _cylinder("ForgeChimney", center + Vector3(0.65, 4.8, 0), 0.38, 6.4, _mat(_metal_dark, 0.75, 0.55), true)
    _cylinder("ForgeGlow", center + Vector3(0, 1.38, 0.84), 0.38, 0.08, _emissive(_forge, 3.4))
    var glow := OmniLight3D.new()
    glow.name = "ForgeLight"
    glow.position = center + Vector3(0, 1.5, 1.1)
    glow.light_color = _forge
    glow.light_energy = 1.9
    glow.omni_range = 6.0
    add_child(glow)
    # C17: calor e fumaça saindo da boca da forja (sutil).
    _add_smoke("ForgeSmoke", center + Vector3(0, 2.0, 0.95), Vector3(0.5, 0.1, 0.2), 14, 3.2, Color(0.3, 0.28, 0.26, 0.16), 0.9)

func _create_pipe_bank(origin: Vector3) -> void:
    for i in range(4):
        var z := origin.z + float(i) * 0.75
        _cylinder("PipeBank_%02d" % i, Vector3(origin.x, 1.65, z), 0.13, 5.0, _mat(_rust, 0.65, 0.72))
        var cap := _cylinder("PipeCap_%02d" % i, Vector3(origin.x, 4.15, z), 0.2, 0.12, _mat(_metal_mid, 0.72, 0.6))
        cap.rotation_degrees.x = 90.0
    _box("PipeManifold", Vector3(origin.x, 2.0, origin.z + 1.1), Vector3(0.35, 0.35, 3.6), _mat(_metal_dark, 0.75, 0.6))
    # C17.1: um escape de vapor no coletor (máquina em uso).
    _add_smoke("PipeSteam", Vector3(origin.x - 0.25, 2.2, origin.z + 1.4), Vector3(0.05, 0.05, 0.1), 8, 2.0, Color(0.45, 0.44, 0.42, 0.08), 0.6)

func _create_workbench(center: Vector3) -> void:
    _box("WorkbenchTop", center + Vector3(0, 1.0, 0), Vector3(3.2, 0.22, 1.0), _mat(_metal_warm, 0.5, 0.65), true)
    for x in [-1.25, 1.25]:
        _box("WorkbenchLeg_%s" % str(x), center + Vector3(x, 0.5, 0), Vector3(0.18, 1.0, 0.72), _mat(_metal_dark, 0.72, 0.65), true)
    _box("WorkbenchToolRail", center + Vector3(0, 1.35, -0.38), Vector3(2.7, 0.16, 0.16), _mat(_metal_mid, 0.7, 0.6))

func _create_crate_cluster(center: Vector3) -> void:
    for i in range(3):
        var offset := Vector3(float(i % 2) * 0.85, 0.4 + float(i / 2) * 0.8, float(i / 2) * 0.55)
        _box("Crate_%d_%d" % [int(center.x), i], center + offset, Vector3(0.78, 0.8, 0.78), _mat(_metal_warm, 0.35, 0.8), true)

func _create_wall_lamps() -> void:
    # C17: lâmpadas presas às paredes altas e ao portão (antes duas flutuavam, e as
    # paredes sul/leste agora são parapeitos); querosene fraco, não brasa.
    var positions := [
        Vector3(-9.6, 2.6, 0.8),
        Vector3(8.0, 3.0, -6.55),
        Vector3(-1.0, 3.0, -6.55),
        Vector3(2.45, 2.5, 6.15)
    ]
    for i in range(positions.size()):
        _box("WallLamp_%02d" % i, positions[i], Vector3(0.16, 0.55, 0.16), _emissive(_kerosene, 0.7))
        var light := OmniLight3D.new()
        light.name = "LampLight_%02d" % i
        light.position = positions[i] + Vector3(0, -0.15, 0)
        light.light_color = _kerosene
        light.light_energy = 0.55
        light.omni_range = 3.0
        add_child(light)

func _create_floor_markings() -> void:
    var paint := _mat(Color("#687178"), 0.15, 0.85)
    for i in range(5):
        _box("FloorMark_%02d" % i, Vector3(-6.0 + float(i) * 3.0, 0.012, 1.8), Vector3(1.5, 0.025, 0.12), paint)
    _box("SafetyLine_Left", Vector3(-8.4, 0.014, -1.0), Vector3(0.12, 0.025, 5.0), paint)
    _box("SafetyLine_Right", Vector3(8.4, 0.014, 2.6), Vector3(0.12, 0.025, 4.5), paint)
    # C21.1: faixa de passagem pintada ao lado da bancada até o portão (mesma tinta das
    # marcas acima; sem colisão), para o caminho até a talha se ler pelo próprio piso.
    _box("PassageLine_West", Vector3(1.1, 0.014, 5.175), Vector3(0.08, 0.025, 3.15), paint)
    _box("PassageLine_East", Vector3(1.95, 0.014, 5.175), Vector3(0.08, 0.025, 3.15), paint)

func _create_zone_sign(pos: Vector3, text_value: String) -> void:
    var sign := Label3D.new()
    sign.name = "ZoneSign_" + text_value.replace(" ", "_")
    sign.text = text_value
    sign.position = pos
    sign.font_size = 34
    sign.modulate = _paper
    sign.outline_size = 8
    sign.outline_modulate = Color(0.02, 0.03, 0.04, 0.95)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(sign)

func _create_steam_vents() -> void:
    var positions := [Vector3(-2.8, 0.0, 5.8), Vector3(2.8, 0.0, 5.8)]
    for i in range(positions.size()):
        _cylinder("SteamVent_%02d" % i, positions[i] + Vector3(0, 0.18, 0), 0.42, 0.36, _mat(_metal_dark, 0.75, 0.62), true)
        _cylinder("SteamRing_%02d" % i, positions[i] + Vector3(0, 0.4, 0), 0.32, 0.08, _mat(_rust, 0.6, 0.7))
        _add_smoke("Steam_%02d" % i, positions[i] + Vector3(0, 0.5, 0), Vector3(0.15, 0.05, 0.15), 10, 2.2, Color(0.45, 0.44, 0.42, 0.08), 0.7)


func _create_overhead_beams() -> void:
    var beam_mat := _mat(_metal_dark, 0.78, 0.58)
    for i in range(3):
        var x := -6.0 + float(i) * 6.0
        _box("OverheadBeam_%02d" % i, Vector3(x, 3.55, -1.2), Vector3(0.28, 0.28, 10.5), beam_mat)
        _box("BeamBrace_%02d" % i, Vector3(x, 3.15, -5.15), Vector3(0.65, 0.18, 1.1), beam_mat)
        _box("BeamBraceRear_%02d" % i, Vector3(x, 3.15, 5.15), Vector3(0.65, 0.18, 1.1), beam_mat)

func _create_storage_racks() -> void:
    var frame := _mat(_metal_mid, 0.72, 0.64)
    var shelf := _mat(_metal_warm, 0.38, 0.78)
    for side_x in [-8.1, 8.1]:
        for level in range(3):
            var y := 0.65 + float(level) * 0.85
            _box("RackShelf_%s_%02d" % [str(side_x), level], Vector3(side_x, y, 3.9), Vector3(1.2, 0.12, 2.2), shelf, true)
        for z in [2.9, 4.9]:
            _box("RackPost_%s_%s" % [str(side_x), str(z)], Vector3(side_x, 1.45, z), Vector3(0.14, 2.9, 0.14), frame, true)

func _create_foundry_duct() -> void:
    # C17: o duto vertical atravessava o painel selado; agora desce junto ao anteparo
    # (lado oeste) e o ramal corre por cima dele, acima das vigas.
    var duct := _mat(_metal_mid, 0.72, 0.62)
    _cylinder("MainDuct", Vector3(-8.2, 3.0, 1.45), 0.34, 6.0, duct)
    var branch := _cylinder("DuctBranch", Vector3(-5.6, 4.0, 1.45), 0.22, 5.2, duct)
    branch.rotation_degrees.z = 90.0
    var cap := _cylinder("DuctCap", Vector3(-3.0, 4.0, 1.45), 0.3, 0.12, _mat(_rust, 0.6, 0.7))
    cap.rotation_degrees.z = 90.0

func _create_entry_gate() -> void:
    var frame := _mat(_metal_dark, 0.8, 0.55)
    var lintel := _box("EntryLintel", Vector3(0, 3.15, 6.35), Vector3(4.8, 0.35, 0.35), frame)
    lintel.rotation_degrees.y = 0.0
    _box("EntryPostL", Vector3(-2.2, 1.65, 6.35), Vector3(0.35, 3.0, 0.35), frame, true)
    _box("EntryPostR", Vector3(2.2, 1.65, 6.35), Vector3(0.35, 3.0, 0.35), frame, true)
    # C17.2: placa de ferro presa sob a verga, com o nome pintado (fixa, voltada para fora);
    # antes era um texto flutuante que sempre encarava a câmera.
    _box("EntrySignPlate", Vector3(0, 2.72, 6.56), Vector3(1.9, 0.42, 0.05), _mat(Color("#1A1D22"), 0.7, 0.6))
    var sign := Label3D.new()
    sign.name = "EntrySign"
    sign.text = "FORJA 01"
    sign.position = Vector3(0, 2.72, 6.59)
    sign.font_size = 44
    sign.modulate = Color("#B9AE96")
    sign.outline_size = 0
    sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    add_child(sign)

func _create_floor_grates() -> void:
    var grate := _mat(Color("#171D20"), 0.8, 0.72)
    for i in range(4):
        _box("FloorGrate_%02d" % i, Vector3(-4.5 + float(i) * 3.0, 0.018, -0.8), Vector3(1.8, 0.035, 0.5), grate)
        for j in range(5):
            _box("GrateBar_%02d_%02d" % [i, j], Vector3(-5.15 + float(i) * 3.0 + float(j) * 0.3, 0.04, -0.8), Vector3(0.06, 0.045, 0.55), _mat(_metal_mid, 0.65, 0.75))

func _create_warning_bands() -> void:
    var warning := _mat(_ochre_paint, 0.2, 0.85)
    for i in range(6):
        var x := -7.5 + float(i) * 3.0
        _box("WarningBand_%02d" % i, Vector3(x, 0.03, -5.55), Vector3(1.6, 0.045, 0.16), warning)

func _create_work_lights() -> void:
    var light_positions := [Vector3(-6.2, 2.7, 2.0), Vector3(0.0, 2.7, 2.0), Vector3(6.2, 2.7, 2.0)]
    for i in range(light_positions.size()):
        _cylinder("WorkLightFixture_%02d" % i, light_positions[i], 0.18, 0.1, _emissive(_ember, 1.5))
        # C17: haste até o cabo aéreo (y 3.5): a luminária pendura em algo. Nó à parte;
        # WorkLightFixture_*/WorkLight_* (C13) ficam iguais.
        _cylinder("WorkLightRod_%02d" % i, light_positions[i] + Vector3(0, 0.4, 0), 0.025, 0.7, _mat(_metal_dark, 0.75, 0.55))
        var light := OmniLight3D.new()
        light.name = "WorkLight_%02d" % i
        light.position = light_positions[i] + Vector3(0, -0.15, 0)
        light.light_color = _ember
        light.light_energy = 0.35
        light.omni_range = 2.4
        add_child(light)

func _create_overhead_cable() -> void:
    var cable := MeshInstance3D.new()
    cable.name = "OverheadCable"
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.035
    mesh.bottom_radius = 0.035
    mesh.height = 10.0
    mesh.material = _mat(Color("#12171A"), 0.35, 0.8)
    cable.mesh = mesh
    cable.position = Vector3(0, 3.5, 2.0)
    cable.rotation_degrees.z = 90.0
    add_child(cable)


# C17 — atmosfera sutil (CPUParticles3D, poucos elementos): fumaça da forja, vapor dos
# respiros e poeira suspensa na baia oeste. Só visual; nada de gameplay depende disso.
func _soft_particle_material(billboard: bool) -> StandardMaterial3D:
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
    if billboard:
        material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    return material

func _add_smoke(node_name: String, pos: Vector3, extents: Vector3, amount: int, lifetime: float, color: Color, size: float) -> CPUParticles3D:
    var particles := CPUParticles3D.new()
    particles.name = node_name
    particles.position = pos
    particles.amount = amount
    particles.lifetime = lifetime
    particles.preprocess = lifetime
    particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    particles.emission_box_extents = extents
    particles.direction = Vector3.UP
    particles.spread = 14.0
    particles.initial_velocity_min = 0.25
    particles.initial_velocity_max = 0.5
    particles.gravity = Vector3(0.05, 0.08, 0.0)
    particles.scale_amount_min = 0.6
    particles.scale_amount_max = 1.1
    var grow := Curve.new()
    grow.add_point(Vector2(0.0, 0.4))
    grow.add_point(Vector2(1.0, 1.6))
    particles.scale_amount_curve = grow
    var fade := Gradient.new()
    fade.set_color(0, Color(color.r, color.g, color.b, 0.0))
    fade.set_color(1, Color(color.r, color.g, color.b, 0.0))
    fade.add_point(0.25, color)
    particles.color_ramp = fade
    var quad := QuadMesh.new()
    quad.size = Vector2(size, size)
    quad.material = _soft_particle_material(true)
    particles.mesh = quad
    add_child(particles)
    return particles

func _create_bay_dust() -> void:
    var dust := CPUParticles3D.new()
    dust.name = "BayDust"
    dust.position = Vector3(-5.5, 1.8, 0.0)
    dust.amount = 48
    dust.lifetime = 9.0
    dust.preprocess = 9.0
    dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    dust.emission_box_extents = Vector3(4.0, 1.5, 5.0)
    dust.direction = Vector3(0.3, 0.2, 0.1)
    dust.spread = 180.0
    dust.initial_velocity_min = 0.02
    dust.initial_velocity_max = 0.08
    dust.gravity = Vector3.ZERO
    var fade := Gradient.new()
    fade.set_color(0, Color(0.85, 0.78, 0.66, 0.0))
    fade.set_color(1, Color(0.85, 0.78, 0.66, 0.0))
    fade.add_point(0.5, Color(0.85, 0.78, 0.66, 0.35))
    dust.color_ramp = fade
    var quad := QuadMesh.new()
    quad.size = Vector2(0.035, 0.035)
    quad.material = _soft_particle_material(true)
    dust.mesh = quad
    add_child(dust)
