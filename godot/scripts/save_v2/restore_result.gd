class_name RestoreResult
extends RefCounted

## Resultado de uma restauração em sandbox (Blocos C3/C4). Nunca apenas um bool.

var success: bool = false
## true quando parte dos passos foi aplicada e depois houve erro: o alvo NÃO
## deve ser usado como estado válido (descartar o sandbox).
var partial_failure: bool = false
var plan: RestorePlan = null
## Itens efetivamente aplicados/verificados pelo núcleo, na ordem.
var applied: Array[Dictionary] = []
var adapter_supported: Array[Dictionary] = []
var requires_adapter: Array[Dictionary] = []
var unsupported: Array[Dictionary] = []
var not_implemented: Array[Dictionary] = []
## RestoreAdapterResult.to_dict() de cada adapter executado, na ordem.
var adapter_results: Array[Dictionary] = []
var warnings: Array[String] = []
var errors: Array[String] = []
## Passos concluídos, em ordem.
var completed_steps: Array[String] = []
## Comparação runtime restaurado (projetado) × GameState.
var differences: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"success": success,
		"partial_failure": partial_failure,
		"completed_steps": completed_steps.duplicate(),
		"applied": applied.duplicate(true),
		"adapter_supported": adapter_supported.duplicate(true),
		"requires_adapter": requires_adapter.duplicate(true),
		"unsupported": unsupported.duplicate(true),
		"not_implemented": not_implemented.duplicate(true),
		"adapter_results": adapter_results.duplicate(true),
		"warnings": warnings.duplicate(),
		"errors": errors.duplicate(),
		"differences": differences.duplicate(true),
	}
