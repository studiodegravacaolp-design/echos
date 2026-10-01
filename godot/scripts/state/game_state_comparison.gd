class_name GameStateComparison
extends RefCounted

## Resultado da comparação estrutural entre dois GameStates (Bloco A3).
## Apenas informa — não corrige nem sobrescreve nenhum dos lados.

var left_label: String = "left"
var right_label: String = "right"
## Caminhos-folha com o mesmo valor nos dois lados.
var matching: Array[String] = []
## { "path", "left", "right" } — mesmo caminho, valores diferentes.
var differences: Array[Dictionary] = []
## Caminhos presentes só no lado direito (ausentes no esquerdo).
var missing_in_left: Array[String] = []
## Caminhos presentes só no lado esquerdo (ausentes no direito).
var missing_in_right: Array[String] = []
## { "side", "path", "id" } — IDs fora do GameIdCatalog canônico.
var unexpected_ids: Array[Dictionary] = []


## true quando não há diferença nem campo ausente em nenhum dos lados.
func is_equal() -> bool:
	return differences.is_empty() and missing_in_left.is_empty() and missing_in_right.is_empty()


func has_unexpected_ids() -> bool:
	return not unexpected_ids.is_empty()


## Caminhos divergentes (diferença ou ausência) que começam com `prefix`.
func divergent_paths(prefix: String = "") -> Array[String]:
	var paths: Array[String] = []
	for difference in differences:
		if String(difference["path"]).begins_with(prefix):
			paths.append(String(difference["path"]))
	for path in missing_in_left + missing_in_right:
		if path.begins_with(prefix):
			paths.append(path)
	return paths


func summary() -> String:
	return "%s × %s: %d iguais, %d diferenças, %d ausentes em %s, %d ausentes em %s, %d IDs inesperados" % [
		left_label, right_label, matching.size(), differences.size(),
		missing_in_left.size(), left_label, missing_in_right.size(), right_label, unexpected_ids.size(),
	]


func to_dict() -> Dictionary:
	return {
		"left": left_label,
		"right": right_label,
		"equal": is_equal(),
		"matching": matching.duplicate(),
		"differences": differences.duplicate(true),
		"missing_in_left": missing_in_left.duplicate(),
		"missing_in_right": missing_in_right.duplicate(),
		"unexpected_ids": unexpected_ids.duplicate(true),
	}
