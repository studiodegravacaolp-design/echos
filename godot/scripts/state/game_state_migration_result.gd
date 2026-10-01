class_name GameStateMigrationResult
extends RefCounted

## Resultado de uma migração/projeção para GameState. Nada é descartado em
## silêncio: todo dado de entrada termina em `state` (registrado em
## `migrated`), em `quarantined` (ID ou valor desconhecido/inválido, preservado
## bruto) ou em `excluded` (dado conhecido que não pertence ao GameState, como
## o idioma), sempre com uma explicação.

var state: GameState = GameState.new()
## "version" declarada pela origem; -1 quando ausente (ex.: projeção de runtime).
var source_version: int = -1
var migrated: Array[String] = []
## caminho de origem -> Array de valores brutos preservados.
var quarantined: Dictionary = {}
## chave de origem -> valor bruto excluído por não pertencer ao GameState.
var excluded: Dictionary = {}
var warnings: Array[String] = []


func note(message: String) -> void:
	migrated.append(message)


func warn(message: String) -> void:
	warnings.append(message)


func quarantine(path: String, raw_value: Variant, reason: String) -> void:
	if not quarantined.has(path):
		quarantined[path] = []
	var preserved: Variant = raw_value
	if typeof(raw_value) == TYPE_DICTIONARY or typeof(raw_value) == TYPE_ARRAY:
		preserved = raw_value.duplicate(true)
	quarantined[path].append(preserved)
	warnings.append("quarentena %s: %s" % [path, reason])


func exclude(key: String, raw_value: Variant, reason: String) -> void:
	excluded[key] = raw_value
	warnings.append("excluído %s: %s" % [key, reason])


func has_quarantine() -> bool:
	return not quarantined.is_empty()


func to_dict() -> Dictionary:
	return {
		"source_version": source_version,
		"state": state.to_dict(),
		"migrated": migrated.duplicate(),
		"quarantined": quarantined.duplicate(true),
		"excluded": excluded.duplicate(true),
		"warnings": warnings.duplicate(),
	}
