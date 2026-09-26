class_name QuestData
extends Resource

@export var quest_id: String = ""
@export var title_key: String = ""
@export var objective_keys: Array[String] = []
@export var completion_consequence: String = ""

func is_valid() -> bool:
    return not quest_id.strip_edges().is_empty() and not objective_keys.is_empty()
