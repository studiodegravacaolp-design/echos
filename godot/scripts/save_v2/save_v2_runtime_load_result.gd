class_name SaveV2RuntimeLoadResult
extends RefCounted

## Bloco C7 — resultado de um Load V2 operacional. Nunca esconde erro.
##
## `status` é o desfecho; em falha de apply/validação pós-restore o rollback é
## executado e registrado em `rollback_status`:
##   APPLY_FAILURE / POST_RESTORE_MISMATCH + rollback_status = ROLLBACK_SUCCESS
##   ROLLBACK_FAILURE (status) + original_failure = falha que motivou o rollback

const DISABLED := "DISABLED"
const SUCCESS := "SUCCESS"
## Arquivo inexistente ou ilegível (E/S).
const LOAD_FAILURE := "LOAD_FAILURE"
## Envelope, checksum, schema ou GameState inválidos.
const VALIDATION_FAILURE := "VALIDATION_FAILURE"
## C8: Load recusado porque há uma sessão de diálogo aberta (estado transitório
## sem contrato de restauração). Nada é tocado; o jogador conclui o diálogo antes.
const LOAD_REJECTED_TRANSIENT_DIALOGUE := "LOAD_REJECTED_TRANSIENT_DIALOGUE"
## Recusado antes de tocar no jogo principal (plano, rehearsal, snapshot, alvo).
const RESTORE_REJECTED := "RESTORE_REJECTED"
## Falha durante a aplicação no jogo principal (rollback executado).
const APPLY_FAILURE := "APPLY_FAILURE"
## Aplicação concluída, mas o runtime não corresponde ao GameState/rehearsal (rollback executado).
const POST_RESTORE_MISMATCH := "POST_RESTORE_MISMATCH"
const ROLLBACK_SUCCESS := "ROLLBACK_SUCCESS"
## O rollback também falhou: estado do jogo principal não confirmado.
const ROLLBACK_FAILURE := "ROLLBACK_FAILURE"

const STATUSES := [DISABLED, SUCCESS, LOAD_FAILURE, VALIDATION_FAILURE, LOAD_REJECTED_TRANSIENT_DIALOGUE, RESTORE_REJECTED, APPLY_FAILURE, POST_RESTORE_MISMATCH, ROLLBACK_SUCCESS, ROLLBACK_FAILURE]

const CODE_FLAG_DISABLED := "FLAG_DISABLED"
const CODE_INVALID_MAIN_TARGET := "INVALID_MAIN_TARGET"
const CODE_SNAPSHOT_NOT_REVERSIBLE := "SNAPSHOT_NOT_REVERSIBLE"
const CODE_APPLY_ERROR := "APPLY_ERROR"
const CODE_APPLY_INCOMPLETE := "APPLY_INCOMPLETE"
const CODE_PERSISTENT_MISMATCH := "PERSISTENT_MISMATCH"
const CODE_FUNCTIONAL_MISMATCH := "FUNCTIONAL_MISMATCH"

var status: String = LOAD_FAILURE
var code: String = SaveV2Errors.OK
var message: String = ""
var details: Array[String] = []
## Etapas concluídas: flag, rehearsal, snapshot, rollback_rehearsal, apply, post_restore.
var steps: Array[String] = []
var path: String = ""
## Relatório do rehearsal (pipeline C6).
var rehearsal: Dictionary = {}
var snapshot_taken: bool = false
var main_touched: bool = false
var apply: Dictionary = {}
var post_restore: Dictionary = {}
var original_failure: Dictionary = {}
var rollback_status: String = ""
var rollback_details: Array[String] = []
## C8: tempo por etapa em ms (rehearsal, snapshot, rollback_rehearsal, apply, post_restore, rollback, total).
var timings_ms: Dictionary = {}
## C8: game_loaded publicado (somente após SUCCESS).
var event_published: bool = false
## GameState carregado (válido) — somente em SUCCESS.
var state: GameState = null


func is_success() -> bool:
	return status == SUCCESS


func describe() -> String:
	var text := "%s/%s %s" % [status, code, message]
	if not rollback_status.is_empty():
		text += " (rollback: %s)" % rollback_status
	if not details.is_empty():
		text += " [%s]" % "; ".join(details)
	return text


func to_dict() -> Dictionary:
	return {
		"status": status, "code": code, "message": message, "details": details.duplicate(),
		"steps": steps.duplicate(), "path": path, "rehearsal": rehearsal.duplicate(true),
		"snapshot_taken": snapshot_taken, "main_touched": main_touched, "apply": apply.duplicate(true),
		"post_restore": post_restore.duplicate(true), "original_failure": original_failure.duplicate(true),
		"rollback_status": rollback_status, "rollback_details": rollback_details.duplicate(),
		"timings_ms": timings_ms.duplicate(), "event_published": event_published,
	}
