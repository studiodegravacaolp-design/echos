extends SceneTree

const InteractableScript = preload("res://scripts/interaction/interactable.gd")
const InteractionDetectorScript = preload("res://scripts/interaction/interaction_detector.gd")


func _init() -> void:
	var target: Interactable = InteractableScript.new()
	var detector: InteractionDetector = InteractionDetectorScript.new()
	var actor := Node3D.new()

	assert(target is Area3D)
	assert(detector is Area3D)
	assert(target.interaction_enabled)
	assert(target.interaction_priority == 0)
	assert(target.can_interact(actor))
	assert(not target.can_interact(null))
	assert(not target.interact(null))

	target.set_interaction_enabled(false)
	assert(not target.can_interact(actor))
	assert(not target.interact(actor))

	actor.add_child(detector)
	root.add_child(actor)
	root.add_child(target)

	assert(detector.get_current_candidate() == null)

	target.queue_free()
	actor.queue_free()
	quit()
