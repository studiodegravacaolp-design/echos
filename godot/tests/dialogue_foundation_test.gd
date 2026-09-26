extends SceneTree

func _init() -> void:
    var first: DialogueEntry = DialogueEntry.new()
    first.speaker_id = "speaker_a"
    first.text = "Test line."

    var second: DialogueEntry = DialogueEntry.new()
    second.speaker_id = "speaker_b"
    second.text = "Second line."

    var data: DialogueData = DialogueData.new()
    data.dialogue_id = "test_dialogue"
    data.entries = [first, second]

    assert(data.is_valid(), "Valid dialogue data must pass validation")

    var session: DialogueSession = DialogueSession.new(data)
    assert(session.start(), "A valid dialogue must start")
    assert(session.is_active(), "Started session must be active")
    assert(session.get_current_entry() == first, "Session must begin at first entry")

    assert(session.advance(), "Advancing to second entry must succeed")
    assert(session.get_current_entry() == second, "Current entry must be second entry")

    assert(not session.advance(), "Advancing past final entry must end the session")
    assert(not session.is_active(), "Session must be inactive after final entry")

    var invalid: DialogueData = DialogueData.new()
    invalid.dialogue_id = "invalid"
    assert(not invalid.is_valid(), "Empty dialogue must be invalid")

    session.end()
    quit()
