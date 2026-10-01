class_name GameStateComparator
extends RefCounted

## Comparação estrutural pura entre dois GameStates (Bloco A3), usada para
## confrontar o GameState sombra com a projeção do runtime atual.
##
## Informa: caminhos iguais, diferenças, campos ausentes de cada lado e IDs
## fora do GameIdCatalog. Não corrige, não mescla e não sobrescreve.

## Seções cujas CHAVES são IDs canônicos, com o tipo esperado.
const KEYED_ID_SECTIONS := {
	"world.consequences": GameIdCatalog.KIND_CONSEQUENCE,
	"world.observations": GameIdCatalog.KIND_OBSERVATION,
	"quests": GameIdCatalog.KIND_QUEST,
	"dialogue.completed": GameIdCatalog.KIND_DIALOGUE,
	"dialogue.choices": GameIdCatalog.KIND_DIALOGUE,
	"memory.echoes": GameIdCatalog.KIND_ECHO,
	"memory.memories": GameIdCatalog.KIND_MEMORY,
	"npcs": GameIdCatalog.KIND_NPC,
}


static func compare(left: GameState, right: GameState, left_label: String = "left", right_label: String = "right") -> GameStateComparison:
	return compare_dicts(left.to_dict(), right.to_dict(), left_label, right_label)


static func compare_dicts(left: Dictionary, right: Dictionary, left_label: String = "left", right_label: String = "right") -> GameStateComparison:
	var result := GameStateComparison.new()
	result.left_label = left_label
	result.right_label = right_label
	_compare_value(left, right, "", result)
	_collect_unexpected_ids(left, left_label, result)
	_collect_unexpected_ids(right, right_label, result)
	return result


static func _compare_value(left: Variant, right: Variant, path: String, result: GameStateComparison) -> void:
	if typeof(left) == TYPE_DICTIONARY and typeof(right) == TYPE_DICTIONARY:
		var left_dict: Dictionary = left
		var right_dict: Dictionary = right
		if left_dict.is_empty() and right_dict.is_empty():
			result.matching.append(path)
			return
		for key in left_dict:
			var child := _join(path, str(key))
			if right_dict.has(key):
				_compare_value(left_dict[key], right_dict[key], child, result)
			else:
				result.missing_in_right.append(child)
		for key in right_dict:
			if not left_dict.has(key):
				result.missing_in_left.append(_join(path, str(key)))
		return
	if _leaf_equal(left, right):
		result.matching.append(path)
	else:
		result.differences.append({"path": path, "left": left, "right": right})


static func _leaf_equal(left: Variant, right: Variant) -> bool:
	if GameStateSerde.is_number(left) and GameStateSerde.is_number(right):
		return is_equal_approx(float(left), float(right))
	if typeof(left) != typeof(right):
		return false
	if typeof(left) == TYPE_ARRAY:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in left_array.size():
			if not _leaf_equal(left_array[index], right_array[index]):
				return false
		return true
	if typeof(left) == TYPE_DICTIONARY:
		return JSON.stringify(left, "", true) == JSON.stringify(right, "", true)
	return left == right


static func _collect_unexpected_ids(state: Dictionary, side: String, result: GameStateComparison) -> void:
	var scenario_id: Variant = GameStateSerde.as_dictionary(GameStateSerde.as_dictionary(state.get("player")).get("location")).get("scenario_id")
	if typeof(scenario_id) == TYPE_STRING and not _is_canonical(GameIdCatalog.KIND_SCENARIO, String(scenario_id)):
		result.unexpected_ids.append({"side": side, "path": "player.location.scenario_id", "id": scenario_id})
	for section_path in KEYED_ID_SECTIONS:
		var kind: String = KEYED_ID_SECTIONS[section_path]
		var section := _dictionary_at(state, section_path)
		for id in section:
			if not _is_canonical(kind, str(id)):
				result.unexpected_ids.append({"side": side, "path": section_path, "id": str(id)})
	var memories := _dictionary_at(state, "memory.memories")
	for memory_id in memories:
		var record := GameStateSerde.as_dictionary(memories[memory_id])
		var source_type: Variant = record.get("source_type")
		var source_id: Variant = record.get("source_id")
		if typeof(source_type) != TYPE_STRING or typeof(source_id) != TYPE_STRING:
			continue
		if not _is_canonical(String(source_type), String(source_id)):
			result.unexpected_ids.append({"side": side, "path": "memory.memories.%s.source_id" % str(memory_id), "id": source_id})


## Só IDs canônicos contam como esperados: um alias legado dentro do GameState
## canônico também é inesperado.
static func _is_canonical(kind: String, id: String) -> bool:
	var known: Array = GameIdCatalog.KNOWN_IDS.get(kind, [])
	return known.has(id)


static func _dictionary_at(state: Dictionary, dotted_path: String) -> Dictionary:
	var current: Variant = state
	for part in dotted_path.split("."):
		current = GameStateSerde.as_dictionary(current).get(part)
	return GameStateSerde.as_dictionary(current)


static func _join(path: String, key: String) -> String:
	return key if path.is_empty() else "%s.%s" % [path, key]
