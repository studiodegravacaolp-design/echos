class_name SaveV2PersistenceInventory
extends RefCounted

## Bloco C9 — detecção SOMENTE LEITURA dos saves existentes (legado × V2).
## Nunca grava, converte, move ou apaga arquivos. Base da política em
## docs/architecture/SAVE_MIGRATION_POLICY.md.
##
##   legado: JSON Dictionary com "version" + "world"/"quests" e SEM "format"
##           (formato do SaveService antigo)
##   V2:     envelope com format = SaveV2Envelope.FORMAT, validado pelo C1

const LEGACY_ABSENT := "absent"
const LEGACY_PRESENT := "legacy"
## Existe, mas não é um save legado reconhecível (JSON inválido/forma desconhecida).
const LEGACY_UNRECOGNIZED := "unrecognized"
## O arquivo do caminho legado é, na verdade, um envelope V2 (confusão de formatos).
const LEGACY_IS_V2_ENVELOPE := "v2_envelope_in_legacy_path"

const V2_ABSENT := "absent"
const V2_VALID := "valid"
const V2_INVALID := "invalid"

const SCENARIO_NONE := "none"
const SCENARIO_LEGACY_ONLY := "legacy_only"
const SCENARIO_V2_ONLY := "v2_only"
const SCENARIO_BOTH := "legacy_and_v2"


static func inspect(legacy_path: String, v2_path: String) -> Dictionary:
	var legacy := classify_legacy(legacy_path)
	var v2 := classify_v2(v2_path)
	var has_legacy: bool = legacy["status"] == LEGACY_PRESENT
	var has_v2: bool = v2["status"] == V2_VALID
	var scenario := SCENARIO_NONE
	if has_legacy and has_v2:
		scenario = SCENARIO_BOTH
	elif has_legacy:
		scenario = SCENARIO_LEGACY_ONLY
	elif has_v2:
		scenario = SCENARIO_V2_ONLY
	return {"legacy": legacy, "v2": v2, "scenario": scenario, "distinct_paths": legacy_path != v2_path}


static func classify_legacy(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": LEGACY_ABSENT, "path": path}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"status": LEGACY_UNRECOGNIZED, "path": path, "reason": "não é JSON Dictionary"}
	var data: Dictionary = parsed
	if data.has("format"):
		if data["format"] == SaveV2Envelope.FORMAT:
			return {"status": LEGACY_IS_V2_ENVELOPE, "path": path}
		return {"status": LEGACY_UNRECOGNIZED, "path": path, "reason": "campo format desconhecido"}
	if data.has("version") and (data.has("world") or data.has("quests")):
		return {"status": LEGACY_PRESENT, "path": path, "version": data["version"]}
	return {"status": LEGACY_UNRECOGNIZED, "path": path, "reason": "forma desconhecida"}


static func classify_v2(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": V2_ABSENT, "path": path}
	var loaded := SaveV2Service.new(path).load_game_state()
	if loaded.ok:
		return {"status": V2_VALID, "path": path, "slot_id": String(loaded.envelope["metadata"]["slot_id"])}
	return {"status": V2_INVALID, "path": path, "code": loaded.code}
