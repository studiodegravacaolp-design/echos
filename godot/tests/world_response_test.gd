extends Node

func _ready() -> void:
    var world_state := WorldState.new()
    world_state.add_memory("vardhelm_memory_maintenance_board")
    world_state.add_memory("vardhelm_memory_maintenance_board")
    assert(world_state.memories.size() == 1, "WorldState memory registration must remain unique.")
    assert(world_state.memories.has("vardhelm_memory_maintenance_board"), "Memory must be present.")
    print("Vardhelm 09 world response test: PASS")
