class_name JsonDataLoader
extends RefCounted

static func read_dictionary(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("JsonDataLoader: arquivo não encontrado: " + path)
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("JsonDataLoader: não foi possível abrir: " + path)
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        push_error("JsonDataLoader: JSON inválido ou não é Dictionary: " + path)
        return {}
    return parsed

static func load_dialogue(path: String) -> DialogueData:
    var raw := read_dictionary(path)
    if raw.is_empty():
        return null
    var data := DialogueData.new()
    data.dialogue_id = str(raw.get("dialogue_id", ""))
    for raw_entry in raw.get("entries", []):
        if not raw_entry is Dictionary:
            continue
        var entry := DialogueEntry.new()
        entry.entry_id = str(raw_entry.get("entry_id", ""))
        entry.speaker_id = str(raw_entry.get("speaker_id", ""))
        entry.text = str(raw_entry.get("text", ""))
        for raw_choice in raw_entry.get("choices", []):
            if not raw_choice is Dictionary:
                continue
            var choice := DialogueChoice.new()
            choice.choice_id = str(raw_choice.get("choice_id", ""))
            choice.text_key = str(raw_choice.get("text_key", ""))
            choice.next_entry_id = str(raw_choice.get("next_entry_id", ""))
            for consequence in raw_choice.get("consequences", []):
                choice.consequences.append(str(consequence))
            entry.choices.append(choice)
        data.entries.append(entry)
    if not data.is_valid():
        push_error("JsonDataLoader: DialogueData inválido: " + path)
        return null
    return data

static func load_quest(path: String) -> QuestData:
    var raw := read_dictionary(path)
    if raw.is_empty():
        return null
    var data := QuestData.new()
    data.quest_id = str(raw.get("quest_id", ""))
    data.title_key = str(raw.get("title_key", ""))
    for objective in raw.get("objective_keys", []):
        data.objective_keys.append(str(objective))
    data.completion_consequence = str(raw.get("completion_consequence", ""))
    if not data.is_valid():
        push_error("JsonDataLoader: QuestData inválido: " + path)
        return null
    return data
