class_name NPCController
extends CharacterBody3D

## Generic NPC foundation.
##
## This foundation provides only identity and a stable interaction anchor.
## It intentionally contains no AI, navigation, dialogue, quest, UI, combat,
## inventory or narrative logic.

@export var npc_id: String = ""
@export var display_name: String = ""
@export var interaction_enabled: bool = true


func _ready() -> void:
    _sync_interaction_state()


func set_interaction_enabled(enabled: bool) -> void:
    interaction_enabled = enabled
    _sync_interaction_state()


func _sync_interaction_state() -> void:
    var interactable := get_node_or_null("Interactable") as Interactable
    if interactable == null:
        return

    interactable.interaction_id = npc_id
    interactable.interaction_enabled = interaction_enabled
