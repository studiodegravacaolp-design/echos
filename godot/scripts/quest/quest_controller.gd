class_name QuestController
extends Node

signal quest_started(quest_id: String)
signal objective_completed(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String)

var states: QuestState = QuestState.new()

func start_quest(quest_id: String) -> void:
    states.start_quest(quest_id)
    quest_started.emit(quest_id)

func complete_objective(quest_id: String, objective_id: String) -> void:
    states.set_objective_complete(quest_id, objective_id)
    objective_completed.emit(quest_id, objective_id)

func complete_quest(quest_id: String) -> void:
    states.complete_quest(quest_id)
    quest_completed.emit(quest_id)
