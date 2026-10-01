class_name SaveV2RuntimeSaveResult
extends RefCounted

## Bloco C8 — resultado de um Save V2 operacional. Nunca esconde erro.

const DISABLED := "DISABLED"
const SUCCESS := "SUCCESS"
## Runtime/alvo que não pode ser salvo com segurança (nada gravado).
const SAVE_REJECTED := "SAVE_REJECTED"
## GameState projetado inválido (nada gravado).
const VALIDATION_FAILURE := "VALIDATION_FAILURE"
## Falha do SaveV2Service ao gravar/verificar (save anterior preservado pela escrita atômica do C1).
const WRITE_FAILURE := "WRITE_FAILURE"

const STATUSES := [DISABLED, SUCCESS, SAVE_REJECTED, VALIDATION_FAILURE, WRITE_FAILURE]

const CODE_FLAG_DISABLED := "FLAG_DISABLED"
const CODE_INVALID_MAIN_TARGET := "INVALID_MAIN_TARGET"
const CODE_UNREPRESENTABLE_RUNTIME := "UNREPRESENTABLE_RUNTIME"

var status: String = WRITE_FAILURE
var code: String = SaveV2Errors.OK
var message: String = ""
var details: Array[String] = []
## Etapas: flag, project, validate, sync, write, checksum.
var steps: Array[String] = []
var path: String = ""
var checksum: String = ""
## Caminhos em que o GameState sombra divergia do runtime ANTES da sincronização.
var shadow_divergence: Array[String] = []
## Havia sessão de diálogo aberta: só o estado persistente foi salvo.
var dialogue_session_open: bool = false
var timings_ms: Dictionary = {}
## game_saved publicado (somente após SUCCESS).
var event_published: bool = false
## GameState gravado (cópia) — somente em SUCCESS.
var state: GameState = null


func is_success() -> bool:
	return status == SUCCESS


func describe() -> String:
	var text := "%s/%s %s" % [status, code, message]
	if not details.is_empty():
		text += " [%s]" % "; ".join(details)
	return text
