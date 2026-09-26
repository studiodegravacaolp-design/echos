extends SceneTree

const NPC_SCENE_PATH: String = "res://scenes/npc/npc.tscn"


func _init() -> void:
    var packed_scene: PackedScene = load(NPC_SCENE_PATH) as PackedScene
    assert(packed_scene != null, "NPC scene must load")

    var npc: NPCController = packed_scene.instantiate() as NPCController
    assert(npc != null, "NPC scene root must be NPCController")

    npc.npc_id = "test_npc"
    npc.display_name = "Test NPC"

    var interactable: Interactable = npc.get_node("Interactable") as Interactable
    assert(interactable != null, "NPC must contain an Interactable child")

    npc._ready()
    assert(interactable.interaction_id == "test_npc", "NPC id must sync to Interactable")

    npc.set_interaction_enabled(false)
    assert(not interactable.interaction_enabled, "Interaction must disable with NPC")

    npc.set_interaction_enabled(true)
    assert(interactable.interaction_enabled, "Interaction must re-enable with NPC")

    npc.queue_free()
    quit()
