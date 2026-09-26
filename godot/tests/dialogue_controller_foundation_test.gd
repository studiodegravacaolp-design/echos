extends SceneTree

func _init() -> void:
    var first: DialogueEntry = DialogueEntry.new()
    first.speaker_id = "a"
    first.text = "First."

    var second: DialogueEntry = DialogueEntry.new()
    second.speaker_id = "b"
    second.text = "Second."

    var data: DialogueData = DialogueData.new()
    data.dialogue_id = "controller_test"
    data.entries = [first, second]

    var controller: DialogueController = DialogueController.new()
    root.add_child(controller)

    assert(controller.start_dialogue(data), "Controller must start valid dialogue")
    assert(controller.is_active(), "Controller must be active after start")
    assert(controller.get_current_entry() == first, "First entry must be current")

    assert(controller.advance(), "First advance must succeed")
    assert(controller.get_current_entry() == second, "Second entry must be current")

    assert(not controller.advance(), "Advance after final entry must finish")
    assert(not controller.is_active(), "Controller must be inactive after finish")
    assert(controller.get_current_entry() == null, "No entry may remain after finish")

    assert(not controller.start_dialogue(null), "Null dialogue must not start")

    controller.queue_free()
    quit()
