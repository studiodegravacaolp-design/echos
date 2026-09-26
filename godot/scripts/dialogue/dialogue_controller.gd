class_name DialogueController
extends Node

signal dialogue_started(dialogue: DialogueData)
signal entry_changed(entry: DialogueEntry)
signal choices_changed(choices: Array[DialogueChoice])
signal dialogue_finished(dialogue: DialogueData)
signal consequence_requested(consequence_id: String)

var current_session: DialogueSession = null

func start_dialogue(dialogue: DialogueData, start_entry_id: String = "") -> bool:
    end_dialogue()
    if dialogue == null:
        return false
    var session: DialogueSession = DialogueSession.new(dialogue)
    if not session.start(start_entry_id):
        return false
    current_session = session
    dialogue_started.emit(dialogue)
    _emit_current()
    return true

func is_active() -> bool:
    return current_session != null and current_session.is_active()

func get_current_entry() -> DialogueEntry:
    if not is_active():
        return null
    return current_session.get_current_entry()

func advance() -> bool:
    if not is_active():
        return false
    var entry: DialogueEntry = current_session.get_current_entry()
    if not entry.choices.is_empty():
        return false
    if current_session.advance_linear():
        _emit_current()
        return true
    var finished: DialogueData = current_session.dialogue
    current_session = null
    dialogue_finished.emit(finished)
    return false

func select_choice(choice_id: String) -> bool:
    if not is_active():
        return false
    var entry: DialogueEntry = current_session.get_current_entry()
    for choice: DialogueChoice in entry.choices:
        if choice.choice_id == choice_id:
            for consequence: String in choice.consequences:
                consequence_requested.emit(consequence)
            var moved: bool = current_session.select_choice(choice_id)
            if moved:
                _emit_current()
            else:
                var finished: DialogueData = current_session.dialogue
                current_session = null
                dialogue_finished.emit(finished)
            return moved
    return false

func end_dialogue() -> void:
    if current_session == null:
        return
    var finished: DialogueData = current_session.dialogue
    current_session.end()
    current_session = null
    dialogue_finished.emit(finished)

func _emit_current() -> void:
    var entry: DialogueEntry = get_current_entry()
    if entry == null:
        return
    entry_changed.emit(entry)
    choices_changed.emit(entry.choices)
