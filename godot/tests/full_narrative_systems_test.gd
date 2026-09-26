extends SceneTree

func _init() -> void:
    var entry_a: DialogueEntry = DialogueEntry.new()
    entry_a.entry_id = "a"
    entry_a.speaker_id = "npc"
    entry_a.text = "A"

    var entry_b: DialogueEntry = DialogueEntry.new()
    entry_b.entry_id = "b"
    entry_b.speaker_id = "npc"
    entry_b.text = "B"

    var choice: DialogueChoice = DialogueChoice.new()
    choice.choice_id = "go"
    choice.text_key = "Go"
    choice.next_entry_id = "b"
    choice.consequences = ["memory_test"]

    entry_a.choices = [choice]

    var dialogue: DialogueData = DialogueData.new()
    dialogue.dialogue_id = "integration"
    dialogue.entries = [entry_a, entry_b]
    assert(dialogue.is_valid())

    var dialogue_controller: DialogueController = DialogueController.new()
    root.add_child(dialogue_controller)
    assert(dialogue_controller.start_dialogue(dialogue))

    var narrative: NarrativeController = NarrativeController.new()
    root.add_child(narrative)
    dialogue_controller.consequence_requested.connect(narrative.apply_consequence)
    assert(dialogue_controller.select_choice("go"))
    assert(narrative.world_state.has_flag("memory_test"))

    var quests: QuestController = QuestController.new()
    root.add_child(quests)
    quests.start_quest("vardhelm_first_echo")
    quests.complete_objective("vardhelm_first_echo", "observe")
    quests.complete_quest("vardhelm_first_echo")
    assert(quests.states.is_completed("vardhelm_first_echo"))

    var localizer: LocalizationService = LocalizationService.new()
    root.add_child(localizer)
    localizer.register_catalog("pt-BR", {"hello": "Olá"})
    assert(localizer.tr_key("hello") == "Olá")

    var save: SaveService = SaveService.new()
    root.add_child(save)
    assert(save.save_game(narrative.world_state, quests.states, localizer.language))

    var restored_world: WorldState = WorldState.new()
    var restored_quests: QuestState = QuestState.new()
    var loaded: Dictionary = save.load_game(restored_world, restored_quests)
    assert(not loaded.is_empty())
    assert(restored_world.has_flag("memory_test"))
    assert(restored_quests.is_completed("vardhelm_first_echo"))

    dialogue_controller.queue_free()
    narrative.queue_free()
    quests.queue_free()
    localizer.queue_free()
    save.queue_free()
    quit()
