class_name SaveV2Result
extends RefCounted

## Resultado explícito de uma operação do Save V2: sucesso, ou um código de
## SaveV2Errors com mensagem e detalhes. Nunca há sucesso parcial silencioso.

var ok: bool = false
var code: String = SaveV2Errors.OK
var message: String = ""
var details: Array[String] = []
## Estado reconstruído (somente em load bem-sucedido).
var state: GameState = null
## Envelope gravado/lido (JSON puro).
var envelope: Dictionary = {}
var path: String = ""


static func success(result_path: String, result_envelope: Dictionary, result_state: GameState = null) -> SaveV2Result:
	var result := SaveV2Result.new()
	result.ok = true
	result.path = result_path
	result.envelope = result_envelope
	result.state = result_state
	return result


static func failure(error_code: String, error_message: String, error_details: Array = [], result_path: String = "") -> SaveV2Result:
	var result := SaveV2Result.new()
	result.ok = false
	result.code = error_code
	result.message = error_message
	for detail in error_details:
		result.details.append(str(detail))
	result.path = result_path
	return result


func describe() -> String:
	if ok:
		return "OK %s" % path
	var text := "%s: %s" % [code, message]
	if not details.is_empty():
		text += " [%s]" % "; ".join(details)
	return text
