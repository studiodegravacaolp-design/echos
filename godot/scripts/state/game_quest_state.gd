class_name GameQuestState
extends RefCounted

## QuestState canônico (A1 §3.4): um registro por quest com status único.
##
##   quest_id -> { "status": "active" | "completed", "objectives": { objective_id: bool } }
##
## Quest ausente = not_started (nunca serializado). Sem "failed" e sem
## recompensa: não existe lógica de recompensa no runtime, então nenhum campo
## reward_granted é criado agora (entra com versão de schema quando existir).
## completion_consequence permanece como dado de conteúdo da quest e não é
## aplicado por este contrato (decisão A1 #4: a fonte é o Eco).
##
## Nome de classe distinto do runtime (scripts/quest/quest_state.gd).

const STATUS_NOT_STARTED := "not_started"
const STATUS_ACTIVE := "active"
const STATUS_COMPLETED := "completed"
const PERSISTED_STATUSES := [STATUS_ACTIVE, STATUS_COMPLETED]
const RECORD_KEYS := ["status", "objectives"]

var quests: Dictionary[String, Dictionary] = {}


## Ativa uma quest ainda não iniciada. Não reabre quest concluída.
func start_quest(quest_id: String) -> bool:
	if quest_id.strip_edges().is_empty() or quests.has(quest_id):
		return false
	quests[quest_id] = {"status": STATUS_ACTIVE, "objectives": {}}
	return true


## Marca um objetivo. Requer que a quest já tenha registro.
func set_objective_complete(quest_id: String, objective_id: String, complete: bool = true) -> bool:
	if not quests.has(quest_id) or objective_id.strip_edges().is_empty():
		return false
	quests[quest_id]["objectives"][objective_id] = complete
	return true


## Conclui a quest (cria o registro se ainda não existir).
func complete_quest(quest_id: String) -> bool:
	if quest_id.strip_edges().is_empty():
		return false
	if not quests.has(quest_id):
		quests[quest_id] = {"status": STATUS_COMPLETED, "objectives": {}}
		return true
	if quests[quest_id]["status"] == STATUS_COMPLETED:
		return false
	quests[quest_id]["status"] = STATUS_COMPLETED
	return true


func get_status(quest_id: String) -> String:
	if not quests.has(quest_id):
		return STATUS_NOT_STARTED
	return String(quests[quest_id]["status"])


func is_objective_complete(quest_id: String, objective_id: String) -> bool:
	if not quests.has(quest_id):
		return false
	return bool(quests[quest_id]["objectives"].get(objective_id, false))


func to_dict() -> Dictionary:
	var out := {}
	for quest_id in quests:
		var objectives := {}
		var source: Dictionary = quests[quest_id]["objectives"]
		for objective_id in source:
			objectives[objective_id] = bool(source[objective_id])
		out[quest_id] = {"status": String(quests[quest_id]["status"]), "objectives": objectives}
	return out


static func from_dict(data: Dictionary) -> GameQuestState:
	var state := GameQuestState.new()
	for quest_id in data:
		var record := GameStateSerde.as_dictionary(data[quest_id])
		var status: Variant = record.get("status")
		if not PERSISTED_STATUSES.has(status):
			continue
		var objectives := {}
		var raw_objectives := GameStateSerde.as_dictionary(record.get("objectives"))
		for objective_id in raw_objectives:
			if typeof(raw_objectives[objective_id]) == TYPE_BOOL:
				objectives[str(objective_id)] = bool(raw_objectives[objective_id])
		state.quests[str(quest_id)] = {"status": String(status), "objectives": objectives}
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "quests", errors):
		return errors
	var root: Dictionary = data
	for quest_id in root:
		var path := "quests.%s" % str(quest_id)
		if not GameStateSerde.require_dictionary(root[quest_id], path, errors):
			continue
		var record: Dictionary = root[quest_id]
		GameStateSerde.check_allowed_keys(record, RECORD_KEYS, path, errors)
		if not PERSISTED_STATUSES.has(record.get("status")):
			errors.append("%s.status: esperado 'active' ou 'completed'" % path)
		if not GameStateSerde.require_dictionary(record.get("objectives"), "%s.objectives" % path, errors):
			continue
		var objectives: Dictionary = record["objectives"]
		for objective_id in objectives:
			if typeof(objectives[objective_id]) != TYPE_BOOL:
				errors.append("%s.objectives.%s: esperado bool" % [path, str(objective_id)])
	return errors
