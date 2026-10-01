class_name SaveV2DiagnosticReport
extends RefCounted

## Bloco C6 — resultado de uma operação do diagnóstico Save V2.
##
## `status` segue a FAILURE POLICY (um único valor, nunca "best effort");
## `code` identifica o erro específico (SaveV2Errors ou código diagnóstico).

# --- failure policy -------------------------------------------------------------
const SUCCESS := "SUCCESS"
## A restauração começou a escrever no sandbox e falhou: sandbox descartado.
const PARTIAL_FAILURE := "PARTIAL_FAILURE"
## Falha sem estado restaurado (arquivo inexistente, E/S, divergência).
const FAILURE := "FAILURE"
## Arquivo ilegível, checksum inválido ou estado que não sobrevive à leitura.
const CORRUPTED_DATA := "CORRUPTED_DATA"
## Envelope/format/metadata/state fora do contrato.
const INVALID_SAVE := "INVALID_SAVE"
## schema_version não suportada (ex.: futura).
const UNSUPPORTED_SCHEMA := "UNSUPPORTED_SCHEMA"
## Restauração recusada ANTES de qualquer escrita (IDs sem destino, alvo não
## sandbox, cenário diferente, sandbox indisponível).
const RESTORE_REJECTED := "RESTORE_REJECTED"
## Flag desligada: nada foi executado (não é falha do save).
const DISABLED := "DISABLED"

const STATUSES := [SUCCESS, PARTIAL_FAILURE, FAILURE, CORRUPTED_DATA, INVALID_SAVE, UNSUPPORTED_SCHEMA, RESTORE_REJECTED, DISABLED]

# --- códigos diagnósticos (além de SaveV2Errors) ---------------------------------
const CODE_FLAG_DISABLED := "FLAG_DISABLED"
const CODE_UNKNOWN_ID := "UNKNOWN_ID"
const CODE_PLAN_INCOMPLETE := "PLAN_INCOMPLETE"
const CODE_SANDBOX_UNAVAILABLE := "SANDBOX_UNAVAILABLE"
const CODE_TARGET_NOT_SANDBOX := "TARGET_NOT_SANDBOX"
const CODE_RESTORE_REFUSED := "RESTORE_REFUSED"
const CODE_ADAPTER_FAILURE := "ADAPTER_FAILURE"
const CODE_CORE_STEP_FAILURE := "CORE_STEP_FAILURE"
const CODE_DERIVATION_FAILURE := "DERIVATION_FAILURE"
const CODE_UNSUPPORTED_CONTENT := "UNSUPPORTED_CONTENT"
const CODE_INCOMPLETE_RESTORE := "INCOMPLETE_RESTORE"
const CODE_RESTORE_MISMATCH := "RESTORE_MISMATCH"
const CODE_EXPECTED_MISMATCH := "EXPECTED_MISMATCH"

var operation: String = ""
var status: String = FAILURE
var code: String = SaveV2Errors.OK
var message: String = ""
var details: Array[String] = []
## Etapas concluídas, em ordem (flag, load, envelope, checksum, game_state, plan, sandbox, restore, verify, comparison).
var steps: Array[String] = []
var path: String = ""
var checksum: String = ""
var checksum_verified: bool = false
## GameState lido do arquivo (somente após checksum + validação).
var state: GameState = null
var plan_counts: Dictionary = {}
var restore: Dictionary = {}
## Runtime do sandbox × GameState carregado (resumo do restaurador).
var differences: Dictionary = {}
## GameState esperado × carregado / × runtime restaurado (quando informado).
var expected_comparison: Dictionary = {}
## C9: tempos (ms): file_validation, sandbox_create, sandbox_restore (restore + verificação + comparação).
var timings_ms: Dictionary = {}
var sandbox_created: bool = false
var sandbox_discarded: bool = false
## Sandbox mantido SOMENTE em SUCCESS (quem chamou decide quando descartar).
var sandbox: SaveV2DiagnosticSandbox = null
var targets: RuntimeRestoreTargets = null


func is_success() -> bool:
	return status == SUCCESS


func describe() -> String:
	var text := "%s/%s %s" % [status, code, message]
	if not details.is_empty():
		text += " [%s]" % "; ".join(details)
	return text


func to_dict() -> Dictionary:
	return {
		"operation": operation,
		"status": status,
		"code": code,
		"message": message,
		"details": details.duplicate(),
		"steps": steps.duplicate(),
		"path": path,
		"checksum": checksum,
		"checksum_verified": checksum_verified,
		"plan_counts": plan_counts.duplicate(),
		"restore": restore.duplicate(true),
		"differences": differences.duplicate(true),
		"expected_comparison": expected_comparison.duplicate(true),
		"sandbox_created": sandbox_created,
		"sandbox_discarded": sandbox_discarded,
		"timings_ms": timings_ms.duplicate(),
	}
