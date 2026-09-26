class_name VardhelmSetDressing
extends Node3D

# Ambientação procedural do setor FORJA 01.
# Não altera o LevelBuilder nem a geometria baked do cenário.
# Os elementos abaixo são set dressing/runtime: leitura espacial, iluminação e identidade industrial.

var _metal_dark := Color("#20262A")
var _metal_mid := Color("#3A3D40")
var _metal_warm := Color("#6B4A32")
var _rust := Color("#6A3E28")
var _ember := Color("#FF8A3D")
var _cyan := Color("#6FE7FF")
var _paper := Color("#C7D2DA")

func build(_owner: Node) -> void:
    _create_forge_core(Vector3(-6.2, 0.0, -0.9))
    _create_pipe_bank(Vector3(7.7, 0.0, -1.2))
    _create_workbench(Vector3(0.0, 0.0, 4.7))
    _create_crate_cluster(Vector3(-8.0, 0.0, 2.4))
    _create_crate_cluster(Vector3(6.8, 0.0, 1.0))
    _create_wall_lamps()
    _create_floor_markings()
    _create_zone_sign(Vector3(-8.7, 2.5, -5.9), "FORJA 01")
    _create_zone_sign(Vector3(7.9, 2.35, 5.9), "SETOR INDUSTRIAL")
    _create_steam_vents()
    _create_overhead_cable()
    _create_overhead_beams()
    _create_storage_racks()
    _create_foundry_duct()
    _create_entry_gate()
    _create_floor_grates()
    _create_warning_bands()
    _create_work_lights()

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
    _box("ForgeFace", center + Vector3(0, 1.38, 0.79), Vector3(1.35, 0.55, 0.08), _emissive(_ember, 2.2))
    _cylinder("ForgeChimney", center + Vector3(0.65, 2.65, 0), 0.38, 2.1, _mat(_metal_dark, 0.75, 0.55), true)
    _cylinder("ForgeGlow", center + Vector3(0, 1.38, 0.84), 0.38, 0.08, _emissive(_ember, 3.2))
    var glow := OmniLight3D.new()
    glow.name = "ForgeLight"
    glow.position = center + Vector3(0, 1.5, 1.1)
    glow.light_color = _ember
    glow.light_energy = 1.2
    glow.omni_range = 4.5
    add_child(glow)

func _create_pipe_bank(origin: Vector3) -> void:
    for i in range(4):
        var z := origin.z + float(i) * 0.75
        _cylinder("PipeBank_%02d" % i, Vector3(origin.x, 1.65, z), 0.13, 5.0, _mat(_rust, 0.65, 0.72))
        var cap := _cylinder("PipeCap_%02d" % i, Vector3(origin.x, 4.15, z), 0.2, 0.12, _mat(_metal_mid, 0.72, 0.6))
        cap.rotation_degrees.x = 90.0
    _box("PipeManifold", Vector3(origin.x, 2.0, origin.z + 1.1), Vector3(0.35, 0.35, 3.6), _mat(_metal_dark, 0.75, 0.6))

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
    var positions := [
        Vector3(-8.8, 2.4, 0.8),
        Vector3(8.8, 2.4, -4.5),
        Vector3(-1.0, 3.0, -6.45),
        Vector3(4.8, 2.4, 6.45)
    ]
    for i in range(positions.size()):
        _box("WallLamp_%02d" % i, positions[i], Vector3(0.16, 0.55, 0.16), _emissive(_ember, 2.0))
        var light := OmniLight3D.new()
        light.name = "LampLight_%02d" % i
        light.position = positions[i] + Vector3(0, -0.15, 0)
        light.light_color = _ember
        light.light_energy = 0.65
        light.omni_range = 3.0
        add_child(light)

func _create_floor_markings() -> void:
    var paint := _mat(Color("#687178"), 0.15, 0.85)
    for i in range(5):
        _box("FloorMark_%02d" % i, Vector3(-6.0 + float(i) * 3.0, 0.012, 1.8), Vector3(1.5, 0.025, 0.12), paint)
    _box("SafetyLine_Left", Vector3(-8.4, 0.014, -1.0), Vector3(0.12, 0.025, 5.0), paint)
    _box("SafetyLine_Right", Vector3(8.4, 0.014, 2.6), Vector3(0.12, 0.025, 4.5), paint)

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
        _cylinder("SteamRing_%02d" % i, positions[i] + Vector3(0, 0.4, 0), 0.32, 0.08, _emissive(_ember, 1.3))


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
    var duct := _mat(_metal_mid, 0.72, 0.62)
    _cylinder("MainDuct", Vector3(-6.2, 3.0, 1.7), 0.34, 6.0, duct)
    var branch := _cylinder("DuctBranch", Vector3(-3.3, 3.0, 1.7), 0.22, 2.3, duct)
    branch.rotation_degrees.z = 90.0
    _cylinder("DuctCap", Vector3(-3.3, 3.0, 2.85), 0.3, 0.12, _emissive(_ember, 0.8))

func _create_entry_gate() -> void:
    var frame := _mat(_metal_dark, 0.8, 0.55)
    var lintel := _box("EntryLintel", Vector3(0, 3.15, 6.35), Vector3(4.8, 0.35, 0.35), frame)
    lintel.rotation_degrees.y = 0.0
    _box("EntryPostL", Vector3(-2.2, 1.65, 6.35), Vector3(0.35, 3.0, 0.35), frame, true)
    _box("EntryPostR", Vector3(2.2, 1.65, 6.35), Vector3(0.35, 3.0, 0.35), frame, true)
    var sign := Label3D.new()
    sign.name = "EntrySign"
    sign.text = "FORJA 01  •  VARDHELM"
    sign.position = Vector3(0, 2.65, 6.12)
    sign.font_size = 28
    sign.modulate = _paper
    sign.outline_size = 7
    sign.outline_modulate = Color(0.02, 0.03, 0.04, 0.95)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(sign)

func _create_floor_grates() -> void:
    var grate := _mat(Color("#171D20"), 0.8, 0.72)
    for i in range(4):
        _box("FloorGrate_%02d" % i, Vector3(-4.5 + float(i) * 3.0, 0.018, -0.8), Vector3(1.8, 0.035, 0.5), grate)
        for j in range(5):
            _box("GrateBar_%02d_%02d" % [i, j], Vector3(-5.15 + float(i) * 3.0 + float(j) * 0.3, 0.04, -0.8), Vector3(0.06, 0.045, 0.55), _mat(_metal_mid, 0.65, 0.75))

func _create_warning_bands() -> void:
    var warning := _emissive(_ember, 0.55)
    for i in range(6):
        var x := -7.5 + float(i) * 3.0
        _box("WarningBand_%02d" % i, Vector3(x, 0.03, -5.55), Vector3(1.6, 0.045, 0.16), warning)

func _create_work_lights() -> void:
    var light_positions := [Vector3(-6.2, 2.7, 2.0), Vector3(0.0, 2.7, 2.0), Vector3(6.2, 2.7, 2.0)]
    for i in range(light_positions.size()):
        _cylinder("WorkLightFixture_%02d" % i, light_positions[i], 0.18, 0.1, _emissive(_ember, 1.5))
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
