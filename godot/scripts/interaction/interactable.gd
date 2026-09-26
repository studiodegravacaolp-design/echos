class_name Interactable
extends Area3D

## Base reusable interaction target.
##
## This class intentionally contains no NPC, dialogue, quest, UI, memory,
## inventory or narrative logic. Future interactive entities can compose or
## inherit from this contract without changing the interaction detector.

signal interaction_requested(actor: Node, interactable: Interactable)
signal interaction_state_changed(enabled: bool)

@export var interaction_id: String = ""
@export var interaction_enabled: bool = true
@export var interaction_priority: int = 0
@export var interaction_radius: float = 1.0


func _ready() -> void:
	monitorable = true
	collision_layer = 2
	collision_mask = 0
	_ensure_default_collision_shape()


func can_interact(actor: Node) -> bool:
	return interaction_enabled and actor != null


func interact(actor: Node) -> bool:
	if not can_interact(actor):
		return false

	interaction_requested.emit(actor, self)
	return true


func set_interaction_enabled(enabled: bool) -> void:
	if interaction_enabled == enabled:
		return

	interaction_enabled = enabled
	interaction_state_changed.emit(enabled)


func _ensure_default_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			return

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(interaction_radius, 0.01)
	collision.shape = sphere
	collision.name = "InteractionCollision"
	add_child(collision)
