class_name QuestState
extends RefCounted

var active: Dictionary = {}
var completed: Dictionary = {}
var objective_progress: Dictionary = {}

func start_quest(quest_id: String) -> void:
    if quest_id.is_empty():
        return
    active[quest_id] = true
    if not objective_progress.has(quest_id):
        objective_progress[quest_id] = {}

func set_objective_complete(quest_id: String, objective_id: String) -> void:
    if not objective_progress.has(quest_id):
        objective_progress[quest_id] = {}
    objective_progress[quest_id][objective_id] = true

func is_objective_complete(quest_id: String, objective_id: String) -> bool:
    return objective_progress.has(quest_id) and objective_progress[quest_id].get(objective_id, false)

func complete_quest(quest_id: String) -> void:
    active.erase(quest_id)
    completed[quest_id] = true

func is_completed(quest_id: String) -> bool:
    return completed.get(quest_id, false)
