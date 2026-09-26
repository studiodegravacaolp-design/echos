class_name WorldState
extends RefCounted

var flags: Dictionary = {}
var values: Dictionary = {}
var memories: Array[String] = []

func set_flag(flag_id: String, value: bool = true) -> void:
    flags[flag_id] = value

func has_flag(flag_id: String) -> bool:
    return flags.get(flag_id, false)

func set_value(key: String, value: Variant) -> void:
    values[key] = value

func get_value(key: String, default_value: Variant = null) -> Variant:
    return values.get(key, default_value)

func add_memory(memory_id: String) -> void:
    if not memories.has(memory_id):
        memories.append(memory_id)
