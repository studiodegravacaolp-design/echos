class_name EchoMemoryInteractable
extends Interactable

signal memory_revealed(memory_id: String)

@export var memory_id: String = "vardhelm_first_echo_memory"
@export var consequence_id: String = "vardhelm_first_echo_complete"
@export var quest_id: String = "vardhelm_first_echo"
@export var objective_id: String = "observe"

var revealed := false
var _visual: MeshInstance3D
var _light: OmniLight3D

func _ready() -> void:
    interaction_priority = 10
    interaction_id = memory_id
    _visual = get_node_or_null("Visual") as MeshInstance3D
    _light = get_node_or_null("Light") as OmniLight3D
    super._ready()

func interact(actor: Node) -> bool:
    if revealed:
        return false
    var accepted := super.interact(actor)
    if not accepted:
        return false
    revealed = true
    interaction_enabled = false
    # Bloco C8: o slice adiciona "Visual"/"Light" DEPOIS do _ready deste nó;
    # resolve as referências na hora de usar (a esfera ficava visível).
    if _visual == null:
        _visual = get_node_or_null("Visual") as MeshInstance3D
    if _light == null:
        _light = get_node_or_null("Light") as OmniLight3D
    if _visual != null:
        _visual.visible = false
    if _light != null:
        _light.visible = false
    memory_revealed.emit(memory_id)
    return true
