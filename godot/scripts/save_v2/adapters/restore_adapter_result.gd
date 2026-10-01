class_name RestoreAdapterResult
extends RefCounted

## Resultado de um adapter de restauração (Bloco C4). Nunca apenas um bool.

var adapter: String = ""
var step: String = ""
## Campos (source_path) que o adapter sabe reconstruir.
var supported: Array[String] = []
## Campos efetivamente reconstruídos/verificados no sandbox.
var applied: Array[String] = []
## Campos que o runtime ainda não consegue consumir (informação segue no GameState).
var requires_adapter: Array[String] = []
var unsupported: Array[String] = []
var warnings: Array[String] = []
var errors: Array[String] = []


static func create(adapter_name: String, adapter_step: String) -> RestoreAdapterResult:
	var result := RestoreAdapterResult.new()
	result.adapter = adapter_name
	result.step = adapter_step
	return result


func is_ok() -> bool:
	return errors.is_empty()


func to_dict() -> Dictionary:
	return {
		"adapter": adapter,
		"step": step,
		"ok": is_ok(),
		"supported": supported.duplicate(),
		"applied": applied.duplicate(),
		"requires_adapter": requires_adapter.duplicate(),
		"unsupported": unsupported.duplicate(),
		"warnings": warnings.duplicate(),
		"errors": errors.duplicate(),
	}
