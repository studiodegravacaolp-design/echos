class_name InteractionDetector
extends Area3D

## Generic interaction detector intended to be attached to a player or other
## actor. It knows only about the Interactable contract and never about NPCs,
## dialogue, quests, UI, memory or narrative systems.

signal candidate_changed(candidate: Interactable)
signal interaction_performed(candidate: Interactable)

@export var detection_radius: float = 2.5
@export var interaction_action: StringName = &"interact"
@export var interaction_layer: int = 2

var current_candidate: Interactable = null


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = interaction_layer
	_ensure_detection_shape()


func _physics_process(_delta: float) -> void:
	_refresh_candidate()

	if current_candidate != null and Input.is_action_just_pressed(interaction_action):
		if current_candidate.interact(get_parent()):
			interaction_performed.emit(current_candidate)


func get_current_candidate() -> Interactable:
	return current_candidate


func try_interact(actor: Node = get_parent()) -> bool:
	if current_candidate == null:
		return false

	if not current_candidate.interact(actor):
		return false

	interaction_performed.emit(current_candidate)
	return true


func _refresh_candidate() -> void:
	var next_candidate := _find_best_candidate()

	if next_candidate == current_candidate:
		return

	current_candidate = next_candidate
	candidate_changed.emit(current_candidate)


func _find_best_candidate() -> Interactable:
	var best: Interactable = null
	var best_priority := -2147483648
	var best_distance := INF

	for area in get_overlapping_areas():
		var interactable := area as Interactable
		if interactable == null:
			continue

		if not interactable.can_interact(get_parent()):
			continue

		var distance := global_position.distance_squared_to(interactable.global_position)
		if interactable.interaction_priority > best_priority:
			best = interactable
			best_priority = interactable.interaction_priority
			best_distance = distance
		elif interactable.interaction_priority == best_priority and distance < best_distance:
			best = interactable
			best_distance = distance

	return best


func _ensure_detection_shape() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			return

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(detection_radius, 0.01)
	collision.shape = sphere
	collision.name = "DetectionCollision"
	add_child(collision)
