class_name DialogueData
extends Resource

@export var dialogue_id: String = ""
@export var entries: Array[DialogueEntry] = []

func is_valid() -> bool:
    if dialogue_id.strip_edges().is_empty() or entries.is_empty():
        return false
    var ids: Dictionary = {}
    for entry: DialogueEntry in entries:
        if entry == null or entry.entry_id.strip_edges().is_empty() or entry.text.strip_edges().is_empty():
            return false
        if ids.has(entry.entry_id):
            return false
        ids[entry.entry_id] = true
        for choice: DialogueChoice in entry.choices:
            if choice == null or choice.choice_id.strip_edges().is_empty() or choice.next_entry_id.strip_edges().is_empty():
                return false
    return true

func get_entry(entry_id: String) -> DialogueEntry:
    for entry: DialogueEntry in entries:
        if entry.entry_id == entry_id:
            return entry
    return null
