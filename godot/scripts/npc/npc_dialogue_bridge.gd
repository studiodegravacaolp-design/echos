class_name NPCDialogueBridge
extends Node

@export var dialogue: DialogueData
@export var start_entry_id: String = ""

func interact(dialogue_controller: DialogueController) -> bool:
    if dialogue_controller == null or dialogue == null:
        return false
    return dialogue_controller.start_dialogue(dialogue, start_entry_id)
