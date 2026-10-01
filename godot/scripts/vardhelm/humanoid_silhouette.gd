class_name HumanoidSilhouette
extends RefCounted

## C17.2 — silhueta humana simples (só visual; sem rig, animação ou colisão), para ler
## "pessoa" em vez de "cápsula" à distância da câmera. Usada pelos trabalhadores do
## AmbientLife e por Durn. Tudo opcional, vindo de um dicionário:
##   shirt / trousers / skin: cor · apron: bool · cap: bool · coat: cor (casaco longo)
##   carrying: bool (braços à frente) · scale: float
## Devolve o tronco, chamado "Body" (o AmbientLife anima a respiração por esse nome).

const DEFAULT_SHIRT := "#8E877C"
const DEFAULT_TROUSERS := "#2B2A28"
const DEFAULT_SKIN := "#8A7766"
const APRON := "#3B2C22"
const CAP := "#1E1D1C"


static func _material(color: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.9
	return material


static func _capsule(parent: Node3D, node_name: String, radius: float, height: float, pos: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	parent.add_child(node)
	return node


static func build(parent: Node3D, spec: Dictionary) -> MeshInstance3D:
	var shirt := str(spec.get("shirt", DEFAULT_SHIRT))
	var trousers := str(spec.get("trousers", DEFAULT_TROUSERS))
	var skin := str(spec.get("skin", DEFAULT_SKIN))
	var coat := str(spec.get("coat", ""))
	var carrying := bool(spec.get("carrying", false))

	var root := Node3D.new()
	root.name = "Silhouette"
	root.scale = Vector3.ONE * float(spec.get("scale", 1.0))
	parent.add_child(root)

	for side in [-1.0, 1.0]:
		_capsule(root, "Leg_%s" % ("L" if side < 0 else "R"), 0.09, 0.84, Vector3(0.11 * side, 0.42, 0.0), trousers)

	var body: MeshInstance3D
	if coat != "":
		# Casaco longo: desce até os joelhos e dá outra silhueta (Durn).
		body = _capsule(root, "Body", 0.28, 1.25, Vector3(0, 1.02, 0), coat)
	else:
		body = _capsule(root, "Body", 0.23, 0.8, Vector3(0, 1.22, 0), shirt)

	var sleeve := coat if coat != "" else shirt
	for side in [-1.0, 1.0]:
		var arm := _capsule(root, "Arm_%s" % ("L" if side < 0 else "R"), 0.065, 0.62, Vector3(0.3 * side, 1.22, 0.0), sleeve)
		if carrying:
			arm.rotation_degrees = Vector3(-65.0, 0.0, 0.0)
			arm.position = Vector3(0.24 * side, 1.18, -0.2)
		else:
			arm.rotation_degrees = Vector3(0.0, 0.0, 6.0 * side)

	if bool(spec.get("apron", false)):
		var apron := MeshInstance3D.new()
		apron.name = "Apron"
		var box := BoxMesh.new()
		box.size = Vector3(0.4, 0.66, 0.04)
		apron.mesh = box
		apron.position = Vector3(0, 1.05, -0.2)
		apron.material_override = _material(APRON)
		root.add_child(apron)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	head.mesh = sphere
	head.position = Vector3(0, 1.76, 0)
	head.material_override = _material(skin)
	root.add_child(head)

	if bool(spec.get("cap", false)):
		var cap := MeshInstance3D.new()
		cap.name = "Cap"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.15
		cylinder.bottom_radius = 0.16
		cylinder.height = 0.08
		cap.mesh = cylinder
		cap.position = Vector3(0, 1.88, 0)
		cap.material_override = _material(CAP)
		root.add_child(cap)

	return body
