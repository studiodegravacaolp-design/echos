class_name SaveV2Validator
extends RefCounted

## Validação estrita do envelope Save V2 (Bloco C1). Sem fallback silencioso:
## a primeira categoria de erro encontrada é devolvida com código explícito.
##
## Ordem:
##   1. envelope é Dictionary não vazio                       -> INVALID_ENVELOPE
##   2. format existe e é FORMAT                              -> INVALID_FORMAT
##   3. schema_version existe e é inteiro                     -> INVALID_ENVELOPE
##      schema_version suportado (== 2; futuro/antigo recusado) -> UNSUPPORTED_SCHEMA
##   4. somente campos conhecidos; game_version String        -> INVALID_ENVELOPE
##   5. metadata Dictionary com slot_id/created_at/updated_at  -> INVALID_METADATA
##   6. state Dictionary                                      -> INVALID_STATE
##   7. checksum existe, String bem formada e confere         -> INVALID_CHECKSUM
##   8. state compatível com o contrato GameState (A2)        -> INVALID_STATE
##      (inclui Vector3 como [x, y, z] numérico e finito)
##
## `file_text` (opcional): texto exato lido do arquivo. Quando presente, o
## checksum é verificado sobre esse texto (SaveV2Checksum.split_file_text),
## sem depender de números relidos; sem ele, sobre a forma canônica do
## envelope em memória. O algoritmo é o mesmo nos dois casos.


static func validate(envelope: Variant, file_text: String = "") -> SaveV2Result:
	if typeof(envelope) != TYPE_DICTIONARY:
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "envelope não é Dictionary (%s)" % type_string(typeof(envelope)))
	var data: Dictionary = envelope
	if data.is_empty():
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "envelope vazio")

	if not data.has("format"):
		return _fail(SaveV2Errors.INVALID_FORMAT, "campo 'format' ausente")
	if typeof(data["format"]) != TYPE_STRING or String(data["format"]) != SaveV2Envelope.FORMAT:
		return _fail(SaveV2Errors.INVALID_FORMAT, "format '%s' diferente de '%s'" % [str(data["format"]), SaveV2Envelope.FORMAT])

	if not data.has("schema_version"):
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "campo 'schema_version' ausente")
	if not GameStateSerde.is_whole_number(data["schema_version"]):
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "schema_version não é inteiro (%s)" % str(data["schema_version"]))
	var schema := int(data["schema_version"])
	if schema != SaveV2Envelope.SCHEMA_VERSION:
		return _fail(SaveV2Errors.UNSUPPORTED_SCHEMA, "schema_version %d não suportado (suportado: %d)" % [schema, SaveV2Envelope.SCHEMA_VERSION])

	var unknown: Array[String] = []
	for key in data:
		if not SaveV2Envelope.KEYS.has(key):
			unknown.append(str(key))
	if not unknown.is_empty():
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "campos desconhecidos no envelope", unknown)
	if not GameStateSerde.is_non_empty_string(data.get("game_version")):
		return _fail(SaveV2Errors.INVALID_ENVELOPE, "game_version ausente ou não é String não vazia")

	var metadata_errors := validate_metadata(data.get("metadata"))
	if not metadata_errors.is_empty():
		return _fail(SaveV2Errors.INVALID_METADATA, "metadata inválida", Array(metadata_errors))

	if not data.has("state"):
		return _fail(SaveV2Errors.INVALID_STATE, "campo 'state' ausente")
	if typeof(data["state"]) != TYPE_DICTIONARY:
		return _fail(SaveV2Errors.INVALID_STATE, "state não é Dictionary")

	if not data.has(SaveV2Checksum.FIELD):
		return _fail(SaveV2Errors.INVALID_CHECKSUM, "campo 'checksum' ausente")
	if not SaveV2Checksum.is_well_formed(data[SaveV2Checksum.FIELD]):
		return _fail(SaveV2Errors.INVALID_CHECKSUM, "checksum malformado (esperado 'sha256:' + 64 hex minúsculos)")
	var expected := ""
	if file_text.is_empty():
		var checksum_errors := PackedStringArray()
		expected = SaveV2Checksum.compute(data, checksum_errors)
		if expected.is_empty():
			return _fail(SaveV2Errors.CORRUPTED_DATA, "envelope com valores não serializáveis", Array(checksum_errors))
	else:
		var split := SaveV2Checksum.split_file_text(file_text)
		if not split["ok"]:
			return _fail(SaveV2Errors.INVALID_CHECKSUM, String(split["error"]))
		if String(split["checksum"]) != String(data[SaveV2Checksum.FIELD]):
			return _fail(SaveV2Errors.INVALID_CHECKSUM, "checksum do texto difere do checksum do envelope")
		expected = SaveV2Checksum.compute_from_text(String(split["covered"]))
	if expected != String(data[SaveV2Checksum.FIELD]):
		return _fail(SaveV2Errors.INVALID_CHECKSUM, "checksum não confere (dados alterados após o checksum)", ["gravado: %s" % data[SaveV2Checksum.FIELD], "calculado: %s" % expected])

	var state_errors := GameState.validate_dict(data["state"])
	if not state_errors.is_empty():
		return _fail(SaveV2Errors.INVALID_STATE, "state incompatível com o contrato GameState", Array(state_errors))

	return SaveV2Result.success("", data)


static func validate_metadata(metadata: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if typeof(metadata) != TYPE_DICTIONARY:
		errors.append("metadata ausente ou não é Dictionary")
		return errors
	var data: Dictionary = metadata
	for key in data:
		if not SaveV2Envelope.METADATA_KEYS.has(key):
			errors.append("metadata: campo desconhecido '%s' (somente dados técnicos)" % str(key))
	if not GameStateSerde.is_non_empty_string(data.get("slot_id")):
		errors.append("metadata.slot_id: esperado String não vazia")
	for key in ["created_at", "updated_at"]:
		if not GameStateSerde.is_whole_number(data.get(key)) or float(data.get(key)) < 0.0:
			errors.append("metadata.%s: esperado inteiro >= 0 (segundos Unix)" % key)
	if errors.is_empty() and int(data["created_at"]) > int(data["updated_at"]):
		errors.append("metadata: created_at posterior a updated_at")
	return errors


static func _fail(code: String, message: String, details: Array = []) -> SaveV2Result:
	return SaveV2Result.failure(code, message, details)
