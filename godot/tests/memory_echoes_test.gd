extends Node

func _ready() -> void:
    var world_state := WorldState.new()
    world_state.add_memory("test_memory")
    world_state.add_memory("test_memory")
    assert(world_state.memories.size() == 1, "Memories must not duplicate.")
    world_state.add_memory("second_memory")
    assert(world_state.memories.size() == 2, "A new memory must be registered.")
    print("Vardhelm 08 memory echoes test: PASS")
