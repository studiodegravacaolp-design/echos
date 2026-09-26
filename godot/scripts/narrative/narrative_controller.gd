class_name NarrativeController
extends Node

signal consequence_applied(consequence_id: String)

var world_state: WorldState = WorldState.new()

func apply_consequence(consequence_id: String) -> void:
    if consequence_id.is_empty():
        return
    world_state.set_flag(consequence_id, true)
    world_state.add_memory(consequence_id)
    consequence_applied.emit(consequence_id)
