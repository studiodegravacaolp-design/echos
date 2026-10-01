class_name GameStateSerde
extends RefCounted

## Utilidades puras de (des)serialização do contrato GameState.
##
## Regra R2 (A1): a forma serializada usa somente Dictionary, Array, String,
## bool e número. Vector3 vira [x, y, z]. Nada que venha de JSON é atribuído
## diretamente a coleções tipadas — toda leitura converte explicitamente.


static func vector3_to_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]


static func is_number(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type == TYPE_INT or value_type == TYPE_FLOAT


static func is_whole_number(value: Variant) -> bool:
	return is_number(value) and float(value) == floorf(float(value))


static func is_json_scalar(value: Variant) -> bool:
	var value_type := typeof(value)
	return value_type == TYPE_BOOL or value_type == TYPE_INT or value_type == TYPE_FLOAT or value_type == TYPE_STRING


static func is_non_empty_string(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and not String(value).strip_edges().is_empty()


static func is_vector3_array(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var components: Array = value
	if components.size() != 3:
		return false
	for component in components:
		if not is_number(component) or not is_finite(float(component)):
			return false
	return true


static func array_to_vector3(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if not is_vector3_array(value):
		return fallback
	var components: Array = value
	return Vector3(float(components[0]), float(components[1]), float(components[2]))


## Comparações seguras: no GDScript 4, == entre tipos diferentes gera erro de
## script; dados vindos de JSON malformado nunca devem quebrar a validação.
static func is_true(value: Variant) -> bool:
	return typeof(value) == TYPE_BOOL and bool(value)


static func is_string_equal(value: Variant, expected: String) -> bool:
	return typeof(value) == TYPE_STRING and String(value) == expected


static func as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


## Registra em `errors` cada chave de `data` que não esteja em `allowed`.
static func check_allowed_keys(data: Dictionary, allowed: Array, path: String, errors: PackedStringArray) -> void:
	for key in data:
		if not allowed.has(key):
			errors.append("%s: campo desconhecido '%s'" % [path, str(key)])


## Retorna true se `value` for Dictionary; caso contrário registra o erro.
static func require_dictionary(value: Variant, path: String, errors: PackedStringArray) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("%s: esperado Dictionary" % path)
		return false
	return true
