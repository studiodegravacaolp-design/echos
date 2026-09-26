extends Node

func _ready() -> void:
    var world_state := WorldState.new()
    world_state.set_flag("observation_maintenance_board_seen", true)
    world_state.add_memory("vardhelm_memory_maintenance_board")
    assert(world_state.has_flag("observation_maintenance_board_seen"))
    assert(world_state.memories.has("vardhelm_memory_maintenance_board"))
    print("Vardhelm 10 narrative consequence test: PASS")
