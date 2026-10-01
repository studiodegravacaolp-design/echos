class_name GamePlayerState
extends RefCounted

## PlayerState canônico (A1 §3.2, decisão #5): somente a localização do
## jogador — cenário, posição exata e rotação exata.
##
## Fora deste contrato nesta etapa: HP, EP, XP, nível, atributos, equipamento,
## inventário, party, skills, área formal, checkpoint/spawn.

const LOCATION_KEYS := ["scenario_id", "position", "rotation"]

var scenario_id: String = GameIdCatalog.SCENARIO_VARDHELM
var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO


func to_dict() -> Dictionary:
	return {
		"location": {
			"scenario_id": scenario_id,
			"position": GameStateSerde.vector3_to_array(position),
			"rotation": GameStateSerde.vector3_to_array(rotation),
		},
	}


static func from_dict(data: Dictionary) -> GamePlayerState:
	var state := GamePlayerState.new()
	var location := GameStateSerde.as_dictionary(data.get("location"))
	if GameStateSerde.is_non_empty_string(location.get("scenario_id")):
		state.scenario_id = String(location["scenario_id"])
	state.position = GameStateSerde.array_to_vector3(location.get("position"), Vector3.ZERO)
	state.rotation = GameStateSerde.array_to_vector3(location.get("rotation"), Vector3.ZERO)
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "player", errors):
		return errors
	var root: Dictionary = data
	GameStateSerde.check_allowed_keys(root, ["location"], "player", errors)
	if not GameStateSerde.require_dictionary(root.get("location"), "player.location", errors):
		return errors
	var location: Dictionary = root["location"]
	GameStateSerde.check_allowed_keys(location, LOCATION_KEYS, "player.location", errors)
	if not GameStateSerde.is_non_empty_string(location.get("scenario_id")):
		errors.append("player.location.scenario_id: esperado String não vazia")
	for key in ["position", "rotation"]:
		if not GameStateSerde.is_vector3_array(location.get(key)):
			errors.append("player.location.%s: esperado [x, y, z] numérico e finito" % key)
	return errors
