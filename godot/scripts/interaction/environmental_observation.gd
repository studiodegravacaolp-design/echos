class_name EnvironmentalObservation
extends Interactable

signal observation_revealed(observation_id: String, title_key: String, text_key: String)
signal memory_fragment_discovered(memory_id: String, memory_category: String, memory_title_key: String, memory_text_key: String)

@export var observation_id: String = ""
@export var title_key: String = ""
@export var text_key: String = ""
@export var after_echo_text_key: String = ""
@export var seen_flag: String = ""
@export var memory_id: String = ""
@export var memory_category: String = ""
@export var memory_title_key: String = ""
@export var memory_text_key: String = ""

var revealed := false
var memory_registered := false

func _ready() -> void:
    interaction_priority = 2
    interaction_id = observation_id
    super._ready()

func interact(actor: Node) -> bool:
    if not can_interact(actor):
        return false
    var accepted := super.interact(actor)
    if not accepted:
        return false
    revealed = true
    var chosen_text := text_key
    if after_echo_text_key != "" and actor != null:
        var slice := actor.get_parent()
        if slice != null:
            var narrative = slice.get_node_or_null("NarrativeController")
            if narrative != null and narrative.world_state.has_flag("vardhelm_first_echo_complete"):
                chosen_text = after_echo_text_key
    observation_revealed.emit(observation_id, title_key, chosen_text)
    if not memory_registered and memory_id != "":
        memory_registered = true
        memory_fragment_discovered.emit(memory_id, memory_category, memory_title_key, memory_text_key)
    return true
