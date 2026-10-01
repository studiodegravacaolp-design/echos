class_name RestorePlan
extends RefCounted

## Plano de restauração GameState -> runtime (Blocos C3/C4). Um item por campo do
## GameState, sempre com destino, ação e status explícitos — nenhum campo é
## omitido ou descartado em silêncio.
##
## Status:
##   supported          restaurado/verificado diretamente no runtime existente (núcleo C3)
##   adapter-supported  reconstruído por um adapter (C4) a partir de estruturas existentes
##   requires_adapter   há destino conceitual, mas o runtime ainda não consegue consumir
##   unsupported        sem destino
##   not_implemented    reservado

const STATUS_SUPPORTED := "supported"
const STATUS_ADAPTER_SUPPORTED := "adapter-supported"
const STATUS_REQUIRES_ADAPTER := "requires_adapter"
const STATUS_UNSUPPORTED := "unsupported"
const STATUS_NOT_IMPLEMENTED := "not_implemented"
const STATUSES := [STATUS_SUPPORTED, STATUS_ADAPTER_SUPPORTED, STATUS_REQUIRES_ADAPTER, STATUS_UNSUPPORTED, STATUS_NOT_IMPLEMENTED]

const ACTION_RESTORE := "restore"
const ACTION_VERIFY := "verify"
const ACTION_DERIVE := "derive"
const ACTION_NOT_APPLIED := "not_applied"

## Ordem de dependência da restauração (C4).
const STEPS := [
	"scenario", "player", "world", "consequences", "observations", "quests",
	"echo", "memory", "npcs", "dialogue", "presentation", "progression",
]

## { "step", "source_path", "destination", "action", "status", "note" }
var items: Array[Dictionary] = []


func add(step: String, source_path: String, destination: String, action: String, status: String, note: String = "") -> void:
	items.append({
		"step": step,
		"source_path": source_path,
		"destination": destination,
		"action": action,
		"status": status,
		"note": note,
	})


## Refina um item existente (usado pelos adapters). Retorna false se não existir.
func update(source_path: String, changes: Dictionary) -> bool:
	for item in items:
		if item["source_path"] == source_path:
			for key in changes:
				item[key] = changes[key]
			return true
	return false


func by_status(status: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in items:
		if item["status"] == status:
			out.append(item)
	return out


func by_step(step: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in items:
		if item["step"] == step:
			out.append(item)
	return out


func find(source_path: String) -> Dictionary:
	for item in items:
		if item["source_path"] == source_path:
			return item
	return {}


func counts() -> Dictionary:
	var out := {}
	for status in STATUSES:
		out[status] = by_status(status).size()
	return out


func to_dict() -> Dictionary:
	return {"items": items.duplicate(true), "counts": counts()}
