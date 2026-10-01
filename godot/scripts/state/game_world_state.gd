class_name GameWorldState
extends RefCounted

## WorldState canônico (A1 §3.3). Quatro subseções com semânticas distintas —
## nunca uma coleção única:
##
##   flags         fatos narrativos booleanos (nomes atuais preservados)
##   values        escalares genéricos não booleanos
##   consequences  consequências aplicadas (idempotente) e sua fonte
##   observations  observações ambientais descobertas
##
## environment_states NÃO pertence a este contrato: é derivado de flags e
## consequências + dados de conteúdo, e nunca é persistido.
##
## Nome de classe distinto do runtime (scripts/narrative/world_state.gd) para
## não colidir com o class_name WorldState existente.

const SECTION_KEYS := ["flags", "values", "consequences", "observations"]
const CONSEQUENCE_KEYS := ["applied", "source_type", "source_id"]
const OBSERVATION_KEYS := ["discovered"]

var flags: Dictionary[String, bool] = {}
var values: Dictionary[String, Variant] = {}
var consequences: Dictionary[String, Dictionary] = {}
var observations: Dictionary[String, Dictionary] = {}


func set_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.strip_edges().is_empty():
		return
	flags[flag_id] = value


func has_flag(flag_id: String) -> bool:
	return bool(flags.get(flag_id, false))


## Aceita somente escalares JSON (bool, número, String). Retorna false se recusado.
## Números são normalizados para float: JSON só tem "número", e um int gravado
## voltaria como float — normalizar na entrada mantém memória == JSON (R2).
func set_value(key: String, value: Variant) -> bool:
	if key.strip_edges().is_empty() or not GameStateSerde.is_json_scalar(value):
		return false
	values[key] = float(value) if GameStateSerde.is_number(value) else value
	return true


func get_value(key: String, default_value: Variant = null) -> Variant:
	return values.get(key, default_value)


## Registra uma consequência aplicada. Idempotente: a primeira aplicação
## prevalece (inclusive sua fonte). Retorna true somente na primeira vez.
func apply_consequence(consequence_id: String, source_type: String = "", source_id: String = "") -> bool:
	if consequence_id.strip_edges().is_empty() or consequences.has(consequence_id):
		return false
	var record := {"applied": true}
	if not source_type.is_empty():
		record["source_type"] = source_type
	if not source_id.is_empty():
		record["source_id"] = source_id
	consequences[consequence_id] = record
	return true


func is_consequence_applied(consequence_id: String) -> bool:
	return consequences.has(consequence_id)


func get_consequence(consequence_id: String) -> Dictionary:
	return consequences.get(consequence_id, {}).duplicate(true)


## Marca uma observação como descoberta. Retorna true somente na primeira vez.
func discover_observation(observation_id: String) -> bool:
	if observation_id.strip_edges().is_empty() or observations.has(observation_id):
		return false
	observations[observation_id] = {"discovered": true}
	return true


func is_observation_discovered(observation_id: String) -> bool:
	return observations.has(observation_id)


func to_dict() -> Dictionary:
	var out_flags := {}
	for flag_id in flags:
		out_flags[flag_id] = flags[flag_id]
	var out_values := {}
	for key in values:
		out_values[key] = values[key]
	var out_consequences := {}
	for consequence_id in consequences:
		out_consequences[consequence_id] = consequences[consequence_id].duplicate(true)
	var out_observations := {}
	for observation_id in observations:
		out_observations[observation_id] = {"discovered": true}
	return {
		"flags": out_flags,
		"values": out_values,
		"consequences": out_consequences,
		"observations": out_observations,
	}


## Reconstrução com conversão explícita; entradas malformadas são ignoradas
## (use validate_dict para detectá-las).
static func from_dict(data: Dictionary) -> GameWorldState:
	var state := GameWorldState.new()
	var raw_flags := GameStateSerde.as_dictionary(data.get("flags"))
	for flag_id in raw_flags:
		if typeof(raw_flags[flag_id]) == TYPE_BOOL:
			state.set_flag(str(flag_id), bool(raw_flags[flag_id]))
	var raw_values := GameStateSerde.as_dictionary(data.get("values"))
	for key in raw_values:
		state.set_value(str(key), raw_values[key])
	var raw_consequences := GameStateSerde.as_dictionary(data.get("consequences"))
	for consequence_id in raw_consequences:
		var record := GameStateSerde.as_dictionary(raw_consequences[consequence_id])
		if not GameStateSerde.is_true(record.get("applied")):
			continue
		var source_type := String(record["source_type"]) if typeof(record.get("source_type")) == TYPE_STRING else ""
		var source_id := String(record["source_id"]) if typeof(record.get("source_id")) == TYPE_STRING else ""
		state.apply_consequence(str(consequence_id), source_type, source_id)
	var raw_observations := GameStateSerde.as_dictionary(data.get("observations"))
	for observation_id in raw_observations:
		var record := GameStateSerde.as_dictionary(raw_observations[observation_id])
		if GameStateSerde.is_true(record.get("discovered")):
			state.discover_observation(str(observation_id))
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "world", errors):
		return errors
	var root: Dictionary = data
	GameStateSerde.check_allowed_keys(root, SECTION_KEYS, "world", errors)
	for section in SECTION_KEYS:
		GameStateSerde.require_dictionary(root.get(section), "world.%s" % section, errors)

	for flag_id in GameStateSerde.as_dictionary(root.get("flags")):
		if typeof(root["flags"][flag_id]) != TYPE_BOOL:
			errors.append("world.flags.%s: esperado bool" % str(flag_id))

	for key in GameStateSerde.as_dictionary(root.get("values")):
		if not GameStateSerde.is_json_scalar(root["values"][key]):
			errors.append("world.values.%s: esperado bool, número ou String" % str(key))

	var raw_consequences := GameStateSerde.as_dictionary(root.get("consequences"))
	for consequence_id in raw_consequences:
		var path := "world.consequences.%s" % str(consequence_id)
		if not GameStateSerde.require_dictionary(raw_consequences[consequence_id], path, errors):
			continue
		var record: Dictionary = raw_consequences[consequence_id]
		GameStateSerde.check_allowed_keys(record, CONSEQUENCE_KEYS, path, errors)
		if not GameStateSerde.is_true(record.get("applied")):
			errors.append("%s.applied: esperado true" % path)
		for optional_key in ["source_type", "source_id"]:
			if record.has(optional_key) and not GameStateSerde.is_non_empty_string(record[optional_key]):
				errors.append("%s.%s: esperado String não vazia" % [path, optional_key])

	var raw_observations := GameStateSerde.as_dictionary(root.get("observations"))
	for observation_id in raw_observations:
		var path := "world.observations.%s" % str(observation_id)
		if not GameStateSerde.require_dictionary(raw_observations[observation_id], path, errors):
			continue
		var record: Dictionary = raw_observations[observation_id]
		GameStateSerde.check_allowed_keys(record, OBSERVATION_KEYS, path, errors)
		if not GameStateSerde.is_true(record.get("discovered")):
			errors.append("%s.discovered: esperado true" % path)
	return errors
