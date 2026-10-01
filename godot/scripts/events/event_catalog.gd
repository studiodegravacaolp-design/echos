class_name GameEventCatalog
extends RefCounted

## Catálogo central dos tipos de evento estruturado (Bloco B1).
##
## Tipos são GENÉRICOS (echo_triggered); IDs de entidades são DADOS do payload
## ({"echo_id": "echo.vardhelm.first"}). Nunca existe um tipo por entidade.
## Payloads carregam só IDs estáveis e dados semânticos — nunca texto de UI,
## Node, Resource ou referência de cena.

const SCHEMA_VERSION := 1

const SCENARIO_ENTERED := "scenario_entered"
const DIALOGUE_STARTED := "dialogue_started"
const DIALOGUE_CHOICE_SELECTED := "dialogue_choice_selected"
const DIALOGUE_COMPLETED := "dialogue_completed"
const QUEST_STARTED := "quest_started"
const QUEST_PROGRESSED := "quest_progressed"
const QUEST_COMPLETED := "quest_completed"
const ECHO_TRIGGERED := "echo_triggered"
const MEMORY_RECOVERED := "memory_recovered"
const CONSEQUENCE_APPLIED := "consequence_applied"
const OBSERVATION_DISCOVERED := "observation_discovered"
const NPC_STATE_CHANGED := "npc_state_changed"
const WORLD_STATE_CHANGED := "world_state_changed"
const SCENARIO_COMPLETED := "scenario_completed"
const GAME_SAVED := "game_saved"
const GAME_LOADED := "game_loaded"

## Definição por tipo: campos obrigatórios e opcionais do payload, com o tipo
## Variant esperado. Strings obrigatórias não podem ser vazias.
## "reserved": tipo existe no catálogo mas nenhum sistema o publica ainda.
const DEFINITIONS := {
	SCENARIO_ENTERED: {"required": {"scenario_id": TYPE_STRING}, "optional": {}, "reserved": false},
	DIALOGUE_STARTED: {"required": {"dialogue_id": TYPE_STRING}, "optional": {}, "reserved": false},
	DIALOGUE_CHOICE_SELECTED: {"required": {"dialogue_id": TYPE_STRING, "entry_id": TYPE_STRING, "choice_id": TYPE_STRING}, "optional": {}, "reserved": false},
	DIALOGUE_COMPLETED: {"required": {"dialogue_id": TYPE_STRING}, "optional": {}, "reserved": false},
	QUEST_STARTED: {"required": {"quest_id": TYPE_STRING}, "optional": {}, "reserved": false},
	QUEST_PROGRESSED: {"required": {"quest_id": TYPE_STRING, "objective_id": TYPE_STRING}, "optional": {}, "reserved": false},
	QUEST_COMPLETED: {"required": {"quest_id": TYPE_STRING}, "optional": {}, "reserved": false},
	ECHO_TRIGGERED: {"required": {"echo_id": TYPE_STRING}, "optional": {}, "reserved": false},
	MEMORY_RECOVERED: {"required": {"memory_id": TYPE_STRING, "source_type": TYPE_STRING, "source_id": TYPE_STRING}, "optional": {}, "reserved": false},
	CONSEQUENCE_APPLIED: {"required": {"consequence_id": TYPE_STRING}, "optional": {"source_type": TYPE_STRING, "source_id": TYPE_STRING}, "reserved": false},
	OBSERVATION_DISCOVERED: {"required": {"observation_id": TYPE_STRING}, "optional": {"memory_id": TYPE_STRING}, "reserved": false},
	NPC_STATE_CHANGED: {"required": {"npc_id": TYPE_STRING}, "optional": {"interaction_enabled": TYPE_BOOL}, "reserved": false},
	WORLD_STATE_CHANGED: {"required": {"state_id": TYPE_STRING}, "optional": {}, "reserved": false},
	# Preparado: ainda não existe encerramento real de cenário no gameplay.
	SCENARIO_COMPLETED: {"required": {"scenario_id": TYPE_STRING}, "optional": {}, "reserved": true},
	# Publicados desde o Bloco C2 pelo SaveV2ShadowCoordinator, SOMENTE após
	# sucesso real do Save V2 (sombra). O SaveService antigo não publica eventos.
	GAME_SAVED: {"required": {}, "optional": {"slot_id": TYPE_STRING}, "reserved": false},
	GAME_LOADED: {"required": {}, "optional": {"slot_id": TYPE_STRING}, "reserved": false},
}


static func is_known_type(event_type: String) -> bool:
	return DEFINITIONS.has(event_type)


static func is_reserved(event_type: String) -> bool:
	return DEFINITIONS.has(event_type) and bool(DEFINITIONS[event_type]["reserved"])


static func schema_version_of(event_type: String) -> int:
	return SCHEMA_VERSION if DEFINITIONS.has(event_type) else -1


static func all_types() -> Array[String]:
	var types: Array[String] = []
	for event_type in DEFINITIONS:
		types.append(String(event_type))
	return types


## Valida tipo, origem e payload. Retorna a lista de erros (vazia = válido).
static func validate(event_type: Variant, source: Variant, payload: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if typeof(event_type) != TYPE_STRING or not DEFINITIONS.has(event_type):
		errors.append("event_type desconhecido: %s" % str(event_type))
		return errors
	if typeof(source) != TYPE_STRING or String(source).strip_edges().is_empty():
		errors.append("%s: source deve ser String não vazia" % event_type)
	if typeof(payload) != TYPE_DICTIONARY:
		errors.append("%s: payload deve ser Dictionary" % event_type)
		return errors
	var data: Dictionary = payload
	collect_json_errors(data, "payload", errors)
	if not errors.is_empty():
		return errors
	var required: Dictionary = DEFINITIONS[event_type]["required"]
	var optional: Dictionary = DEFINITIONS[event_type]["optional"]
	for key in required:
		if not data.has(key):
			errors.append("%s: campo obrigatório ausente '%s'" % [event_type, key])
		else:
			_check_field(event_type, key, data[key], int(required[key]), errors)
	for key in data:
		if required.has(key):
			continue
		if not optional.has(key):
			errors.append("%s: campo não previsto '%s'" % [event_type, str(key)])
		else:
			_check_field(event_type, key, data[key], int(optional[key]), errors)
	return errors


## Recusa qualquer valor que não seja JSON puro: objetos (Node, Resource,
## referências de cena), Vector3, StringName em chave etc.
static func collect_json_errors(value: Variant, path: String, errors: PackedStringArray) -> void:
	var value_type := typeof(value)
	if value_type == TYPE_BOOL or value_type == TYPE_INT or value_type == TYPE_FLOAT or value_type == TYPE_STRING:
		return
	if value_type == TYPE_DICTIONARY:
		var dict: Dictionary = value
		for key in dict:
			if typeof(key) != TYPE_STRING:
				errors.append("%s: chave não String (%s)" % [path, type_string(typeof(key))])
				continue
			collect_json_errors(dict[key], "%s.%s" % [path, key], errors)
	elif value_type == TYPE_ARRAY:
		var items: Array = value
		for index in items.size():
			collect_json_errors(items[index], "%s[%d]" % [path, index], errors)
	elif value_type == TYPE_OBJECT:
		errors.append("%s: objeto não permitido no payload (Node/Resource/referência de cena)" % path)
	else:
		errors.append("%s: tipo %s não serializável em JSON" % [path, type_string(value_type)])


static func _check_field(event_type: String, key: String, value: Variant, expected_type: int, errors: PackedStringArray) -> void:
	if typeof(value) != expected_type:
		errors.append("%s.%s: esperado %s" % [event_type, key, type_string(expected_type)])
	elif expected_type == TYPE_STRING and String(value).strip_edges().is_empty():
		errors.append("%s.%s: String vazia" % [event_type, key])
