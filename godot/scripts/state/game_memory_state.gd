class_name GameMemoryState
extends RefCounted

## MemoryState canônico (A1 §3.6, decisões #1, #2 e #3).
##
##   echoes    echo_id   -> { "status": "resolved" }
##   memories  memory_id -> { "source_type": "echo" | "observation", "source_id": String }
##
## - Eco: fenômeno do mundo. Só "resolved" é persistido; dormente/disponível
##   são derivados (quest ativa).
## - Memória: registro do jogador. Origem "echo" (ex.: Primeiro Eco) ou
##   "observation" — memórias de origem observation são FRAGMENTOS (decisão #1).
##   Não há composição de fragmentos, diário, categorias nem ordenação temporal.
## - Consequências NÃO são memórias (ficam em GameWorldState.consequences), e
##   registrar uma memória não aplica consequência nem reação (decisão #3).

const ECHO_STATUS_RESOLVED := "resolved"
const SOURCE_ECHO := "echo"
const SOURCE_OBSERVATION := "observation"
const VALID_SOURCE_TYPES := [SOURCE_ECHO, SOURCE_OBSERVATION]
const SECTION_KEYS := ["echoes", "memories"]
const ECHO_KEYS := ["status"]
const MEMORY_KEYS := ["source_type", "source_id"]

var echoes: Dictionary[String, Dictionary] = {}
var memories: Dictionary[String, Dictionary] = {}


func resolve_echo(echo_id: String) -> bool:
	if echo_id.strip_edges().is_empty() or echoes.has(echo_id):
		return false
	echoes[echo_id] = {"status": ECHO_STATUS_RESOLVED}
	return true


func is_echo_resolved(echo_id: String) -> bool:
	return echoes.has(echo_id)


## Registra uma memória. Idempotente: o primeiro registro (e sua origem)
## prevalece. Recusa origem desconhecida ou IDs vazios.
func register_memory(memory_id: String, source_type: String, source_id: String) -> bool:
	if memory_id.strip_edges().is_empty() or source_id.strip_edges().is_empty():
		return false
	if not VALID_SOURCE_TYPES.has(source_type) or memories.has(memory_id):
		return false
	memories[memory_id] = {"source_type": source_type, "source_id": source_id}
	return true


func has_memory(memory_id: String) -> bool:
	return memories.has(memory_id)


func get_memory_source_type(memory_id: String) -> String:
	if not memories.has(memory_id):
		return ""
	return String(memories[memory_id]["source_type"])


## Fragmento de memória = memória cuja origem é uma observação (decisão #1).
func is_fragment(memory_id: String) -> bool:
	return get_memory_source_type(memory_id) == SOURCE_OBSERVATION


func to_dict() -> Dictionary:
	var out_echoes := {}
	for echo_id in echoes:
		out_echoes[echo_id] = {"status": ECHO_STATUS_RESOLVED}
	var out_memories := {}
	for memory_id in memories:
		out_memories[memory_id] = {
			"source_type": String(memories[memory_id]["source_type"]),
			"source_id": String(memories[memory_id]["source_id"]),
		}
	return {"echoes": out_echoes, "memories": out_memories}


static func from_dict(data: Dictionary) -> GameMemoryState:
	var state := GameMemoryState.new()
	var raw_echoes := GameStateSerde.as_dictionary(data.get("echoes"))
	for echo_id in raw_echoes:
		if GameStateSerde.is_string_equal(GameStateSerde.as_dictionary(raw_echoes[echo_id]).get("status"), ECHO_STATUS_RESOLVED):
			state.resolve_echo(str(echo_id))
	var raw_memories := GameStateSerde.as_dictionary(data.get("memories"))
	for memory_id in raw_memories:
		var record := GameStateSerde.as_dictionary(raw_memories[memory_id])
		if typeof(record.get("source_type")) == TYPE_STRING and typeof(record.get("source_id")) == TYPE_STRING:
			state.register_memory(str(memory_id), String(record["source_type"]), String(record["source_id"]))
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "memory", errors):
		return errors
	var root: Dictionary = data
	GameStateSerde.check_allowed_keys(root, SECTION_KEYS, "memory", errors)
	if GameStateSerde.require_dictionary(root.get("echoes"), "memory.echoes", errors):
		var raw_echoes: Dictionary = root["echoes"]
		for echo_id in raw_echoes:
			var path := "memory.echoes.%s" % str(echo_id)
			if not GameStateSerde.require_dictionary(raw_echoes[echo_id], path, errors):
				continue
			var record: Dictionary = raw_echoes[echo_id]
			GameStateSerde.check_allowed_keys(record, ECHO_KEYS, path, errors)
			if not GameStateSerde.is_string_equal(record.get("status"), ECHO_STATUS_RESOLVED):
				errors.append("%s.status: esperado 'resolved'" % path)
	if GameStateSerde.require_dictionary(root.get("memories"), "memory.memories", errors):
		var raw_memories: Dictionary = root["memories"]
		for memory_id in raw_memories:
			var path := "memory.memories.%s" % str(memory_id)
			if not GameStateSerde.require_dictionary(raw_memories[memory_id], path, errors):
				continue
			var record: Dictionary = raw_memories[memory_id]
			GameStateSerde.check_allowed_keys(record, MEMORY_KEYS, path, errors)
			if not VALID_SOURCE_TYPES.has(record.get("source_type")):
				errors.append("%s.source_type: esperado 'echo' ou 'observation'" % path)
			if not GameStateSerde.is_non_empty_string(record.get("source_id")):
				errors.append("%s.source_id: esperado String não vazia" % path)
	return errors
