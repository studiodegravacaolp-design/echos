class_name GameNPCState
extends RefCounted

## NPCState canônico (A1 §3.7): contrato genérico por NPC.
##
##   npc_id -> { "interaction_enabled": bool }
##
## Só existe registro quando o NPC difere do padrão (ausência = padrão).
## Nenhum NPC tem registro obrigatório — nem Durn (npc.vardhelm.durn).
## Sem IA, relacionamento, afinidade, máquina de estados ou histórico de
## diálogo (diálogo pertence a GameDialogueState).

const DEFAULT_INTERACTION_ENABLED := true
const RECORD_KEYS := ["interaction_enabled"]

var npcs: Dictionary[String, Dictionary] = {}


## Define a interação do NPC. Voltar ao padrão remove o registro.
func set_interaction_enabled(npc_id: String, enabled: bool) -> void:
	if npc_id.strip_edges().is_empty():
		return
	if enabled == DEFAULT_INTERACTION_ENABLED:
		npcs.erase(npc_id)
	else:
		npcs[npc_id] = {"interaction_enabled": enabled}


func is_interaction_enabled(npc_id: String) -> bool:
	if not npcs.has(npc_id):
		return DEFAULT_INTERACTION_ENABLED
	return bool(npcs[npc_id]["interaction_enabled"])


func has_record(npc_id: String) -> bool:
	return npcs.has(npc_id)


func to_dict() -> Dictionary:
	var out := {}
	for npc_id in npcs:
		out[npc_id] = {"interaction_enabled": bool(npcs[npc_id]["interaction_enabled"])}
	return out


static func from_dict(data: Dictionary) -> GameNPCState:
	var state := GameNPCState.new()
	for npc_id in data:
		var record := GameStateSerde.as_dictionary(data[npc_id])
		if typeof(record.get("interaction_enabled")) == TYPE_BOOL:
			state.set_interaction_enabled(str(npc_id), bool(record["interaction_enabled"]))
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "npcs", errors):
		return errors
	var root: Dictionary = data
	for npc_id in root:
		var path := "npcs.%s" % str(npc_id)
		if not GameStateSerde.require_dictionary(root[npc_id], path, errors):
			continue
		var record: Dictionary = root[npc_id]
		GameStateSerde.check_allowed_keys(record, RECORD_KEYS, path, errors)
		if typeof(record.get("interaction_enabled")) != TYPE_BOOL:
			errors.append("%s.interaction_enabled: esperado bool" % path)
	return errors
