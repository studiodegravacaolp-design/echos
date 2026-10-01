class_name SaveV2Serializer
extends RefCounted

## Serialização do Save V2 (Bloco C1).
##
## - O GameState é convertido pelo PRÓPRIO contrato (GameState.to_dict /
##   GameState.from_dict, que usam GameStateSerde) — nenhuma lógica de
##   serialização de estado é duplicada aqui.
## - Arquivo = FORMA CANÔNICA do envelope (canonical_json): uma linha, chaves
##   ordenadas. Como "checksum" é a primeira chave em ordem lexicográfica, o
##   texto coberto pelo checksum é exatamente o arquivo sem esse membro.
## - Motivo: o parser JSON do Godot 4.7.1 não devolve exatamente o mesmo double
##   para ~18% dos floats (medido no C1). O checksum é verificado sobre o TEXTO
##   gravado, nunca sobre números relidos (ver SaveV2Checksum).


static func state_to_dict(state: GameState) -> Dictionary:
	return state.to_dict()


## Reconstrói o GameState. Chamar SOMENTE depois de SaveV2Validator aceitar o
## envelope: from_dict é tolerante por contrato (A2), a rigidez vem do validador.
static func dict_to_state(data: Dictionary) -> GameState:
	return GameState.from_dict(data)


## Texto gravado no arquivo: a forma canônica do envelope (uma linha).
static func to_file_text(envelope: Dictionary) -> String:
	return canonical_json(envelope)


## Lê o texto do arquivo. Retorna {"ok": bool, "data": Variant, "error": String}.
static func parse_file_text(text: String) -> Dictionary:
	if text.strip_edges().is_empty():
		return {"ok": false, "data": null, "error": "arquivo vazio"}
	var json := JSON.new()
	var status := json.parse(text)
	if status != OK:
		return {"ok": false, "data": null, "error": "JSON inválido na linha %d: %s" % [json.get_error_line(), json.get_error_message()]}
	return {"ok": true, "data": json.data, "error": ""}


## Representação CANÔNICA e determinística de um valor JSON:
## - Dictionary: chaves (somente String) em ordem lexicográfica, sem espaços;
## - Array: elementos na ordem;
## - número inteiro — int, ou float finito de valor inteiro (|x| < 2^53) — sem
##   parte decimal (3 e 3.0 → "3"), pois JSON não distingue int de float e o
##   parser devolve floats;
## - demais floats: formato de precisão completa (round-trip exato do double);
## - String: escapada como em JSON; bool: true/false; null: null.
## Qualquer outro tipo (Object, Vector3, NaN, ±Inf…) é registrado em `errors`.
static func canonical_json(value: Variant, errors: PackedStringArray = PackedStringArray()) -> String:
	var value_type := typeof(value)
	if value_type == TYPE_NIL:
		return "null"
	if value_type == TYPE_BOOL:
		return "true" if bool(value) else "false"
	if value_type == TYPE_INT:
		return str(int(value))
	if value_type == TYPE_FLOAT:
		var number := float(value)
		if not is_finite(number):
			errors.append("número não finito")
			return "null"
		if number == floorf(number) and absf(number) < 9007199254740992.0:
			return str(int(number))
		return JSON.stringify(number, "", false, true)
	if value_type == TYPE_STRING:
		return JSON.stringify(String(value))
	if value_type == TYPE_ARRAY:
		var parts: PackedStringArray = []
		for item in value:
			parts.append(canonical_json(item, errors))
		return "[" + ",".join(parts) + "]"
	if value_type == TYPE_DICTIONARY:
		var dict: Dictionary = value
		var keys: Array[String] = []
		for key in dict:
			if typeof(key) != TYPE_STRING:
				errors.append("chave não String (%s)" % type_string(typeof(key)))
				continue
			keys.append(String(key))
		keys.sort()
		var parts: PackedStringArray = []
		for key in keys:
			parts.append(JSON.stringify(key) + ":" + canonical_json(dict[key], errors))
		return "{" + ",".join(parts) + "}"
	errors.append("tipo %s não serializável" % type_string(value_type))
	return "null"
