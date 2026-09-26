class_name DialogueSession
extends RefCounted

var dialogue: DialogueData
var current_entry_id: String = ""
var selected_choice_id: String = ""

func _init(source: DialogueData = null) -> void:
    dialogue = source

func start(start_entry_id: String = "") -> bool:
    if dialogue == null or not dialogue.is_valid():
        return false
    if start_entry_id.is_empty():
        start_entry_id = dialogue.entries[0].entry_id
    if dialogue.get_entry(start_entry_id) == null:
        return false
    current_entry_id = start_entry_id
    selected_choice_id = ""
    return true

func is_active() -> bool:
    return dialogue != null and not current_entry_id.is_empty() and dialogue.get_entry(current_entry_id) != null

func get_current_entry() -> DialogueEntry:
    if not is_active():
        return null
    return dialogue.get_entry(current_entry_id)

func select_choice(choice_id: String) -> bool:
    var entry: DialogueEntry = get_current_entry()
    if entry == null:
        return false
    for choice: DialogueChoice in entry.choices:
        if choice.choice_id == choice_id:
            selected_choice_id = choice_id
            current_entry_id = choice.next_entry_id
            return dialogue.get_entry(current_entry_id) != null
    return false

func advance_linear() -> bool:
    var entry: DialogueEntry = get_current_entry()
    if entry == null or not entry.choices.is_empty():
        return false
    var index: int = dialogue.entries.find(entry)
    if index < 0 or index + 1 >= dialogue.entries.size():
        current_entry_id = ""
        return false
    current_entry_id = dialogue.entries[index + 1].entry_id
    return true

func end() -> void:
    current_entry_id = ""
    selected_choice_id = ""
