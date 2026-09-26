class_name DialogueEntry
extends Resource

@export var entry_id: String = ""
@export var speaker_id: String = ""
@export_multiline var text: String = ""
@export var choices: Array[DialogueChoice] = []
