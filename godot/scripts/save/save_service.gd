class_name SaveService
extends Node

const SAVE_PATH := "user://echoes_of_the_soul_save.json"

func save_game(world_state: WorldState, quest_state: QuestState, language: String, player: Node3D = null) -> bool:
    var payload: Dictionary = {
        "version": 2,
        "language": language,
        "world": {
            "flags": world_state.flags,
            "values": world_state.values,
            "memories": world_state.memories
        },
        "quests": {
            "active": quest_state.active,
            "completed": quest_state.completed,
            "objective_progress": quest_state.objective_progress
        }
    }
    if player != null:
        payload["player"] = {
            "position": [player.global_position.x, player.global_position.y, player.global_position.z],
            "rotation": [player.global_rotation.x, player.global_rotation.y, player.global_rotation.z]
        }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(payload))
    return true

func load_game(world_state: WorldState, quest_state: QuestState, player: Node3D = null) -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return {}
    var world: Dictionary = parsed.get("world", {})
    world_state.flags = world.get("flags", {})
    world_state.values = world.get("values", {})
    world_state.memories = world.get("memories", [])
    var quests: Dictionary = parsed.get("quests", {})
    quest_state.active = quests.get("active", {})
    quest_state.completed = quests.get("completed", {})
    quest_state.objective_progress = quests.get("objective_progress", {})
    if player != null:
        var player_data: Dictionary = parsed.get("player", {})
        var position_data: Array = player_data.get("position", [])
        var rotation_data: Array = player_data.get("rotation", [])
        if position_data.size() == 3:
            player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
        if rotation_data.size() == 3:
            player.global_rotation = Vector3(float(rotation_data[0]), float(rotation_data[1]), float(rotation_data[2]))
    return parsed
