class_name GameDialogueState
extends RefCounted

## DialogueState canônico (A1 §3.5, decisão #6). Somente a parte persistente:
##
##   completed  dialogue_id -> true
##   choices    dialogue_id -> { entry_id: choice_id }
##
## Cada ponto de decisão (dialogue_id + entry_id) guarda no máximo uma escolha:
## a ÚLTIMA realizada. Sem histórico completo. Diálogo/entrada atuais, texto,
## falante e qualquer estado de sessão ou UI ficam fora deste contrato.

const SECTION_KEYS := ["completed", "choices"]

var completed: Dictionary[String, bool] = {}
var choices: Dictionary[String, Dictionary] = {}


func mark_completed(dialogue_id: String) -> bool:
	if dialogue_id.strip_edges().is_empty() or completed.has(dialogue_id):
		return false
	completed[dialogue_id] = true
	return true


func is_completed(dialogue_id: String) -> bool:
	return completed.has(dialogue_id)


## Registra a escolha de um ponto de decisão, substituindo a anterior.
func record_choice(dialogue_id: String, entry_id: String, choice_id: String) -> bool:
	if dialogue_id.strip_edges().is_empty() or entry_id.strip_edges().is_empty() or choice_id.strip_edges().is_empty():
		return false
	if not choices.has(dialogue_id):
		choices[dialogue_id] = {}
	choices[dialogue_id][entry_id] = choice_id
	return true


func get_choice(dialogue_id: String, entry_id: String) -> String:
	if not choices.has(dialogue_id):
		return ""
	return String(choices[dialogue_id].get(entry_id, ""))


func to_dict() -> Dictionary:
	var out_completed := {}
	for dialogue_id in completed:
		out_completed[dialogue_id] = true
	var out_choices := {}
	for dialogue_id in choices:
		var points := {}
		var source: Dictionary = choices[dialogue_id]
		for entry_id in source:
			points[entry_id] = String(source[entry_id])
		out_choices[dialogue_id] = points
	return {"completed": out_completed, "choices": out_choices}


static func from_dict(data: Dictionary) -> GameDialogueState:
	var state := GameDialogueState.new()
	var raw_completed := GameStateSerde.as_dictionary(data.get("completed"))
	for dialogue_id in raw_completed:
		if GameStateSerde.is_true(raw_completed[dialogue_id]):
			state.mark_completed(str(dialogue_id))
	var raw_choices := GameStateSerde.as_dictionary(data.get("choices"))
	for dialogue_id in raw_choices:
		var points := GameStateSerde.as_dictionary(raw_choices[dialogue_id])
		for entry_id in points:
			if typeof(points[entry_id]) == TYPE_STRING:
				state.record_choice(str(dialogue_id), str(entry_id), String(points[entry_id]))
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "dialogue", errors):
		return errors
	var root: Dictionary = data
	GameStateSerde.check_allowed_keys(root, SECTION_KEYS, "dialogue", errors)
	if GameStateSerde.require_dictionary(root.get("completed"), "dialogue.completed", errors):
		var raw_completed: Dictionary = root["completed"]
		for dialogue_id in raw_completed:
			if not GameStateSerde.is_true(raw_completed[dialogue_id]):
				errors.append("dialogue.completed.%s: esperado true" % str(dialogue_id))
	if GameStateSerde.require_dictionary(root.get("choices"), "dialogue.choices", errors):
		var raw_choices: Dictionary = root["choices"]
		for dialogue_id in raw_choices:
			var path := "dialogue.choices.%s" % str(dialogue_id)
			if not GameStateSerde.require_dictionary(raw_choices[dialogue_id], path, errors):
				continue
			var points: Dictionary = raw_choices[dialogue_id]
			for entry_id in points:
				if not GameStateSerde.is_non_empty_string(points[entry_id]):
					errors.append("%s.%s: esperado choice_id (String)" % [path, str(entry_id)])
	return errors
