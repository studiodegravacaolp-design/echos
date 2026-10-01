class_name SaveV2Envelope
extends RefCounted

## Envelope do Save V2 (Bloco C1). O envelope é JSON puro (Dictionary):
##
##   {
##     "format": "echoes_of_the_soul_save",
##     "schema_version": 2,                 <- formato do SAVE
##     "game_version": "0.1.0-dev",
##     "metadata": { "slot_id", "created_at", "updated_at" },   <- só dados técnicos
##     "state": { ... GameState.to_dict() ... "state_version": 1 },  <- contrato A2
##     "checksum": "sha256:<hex>"
##   }
##
## schema_version (save) e state.state_version (GameState) são independentes.

const FORMAT := "echoes_of_the_soul_save"
const SCHEMA_VERSION := 2
## Não existe versão canônica de runtime (project.godot não define
## application/config/version). Constante explícita e documentada; não é
## inferida do nome da pasta nem de data/hora.
const GAME_VERSION := "0.1.0-dev"
const DEFAULT_SLOT_ID := "shadow"

const KEYS := ["format", "schema_version", "game_version", "metadata", "state", "checksum"]
## created_at/updated_at: segundos Unix (UTC), inteiros — somente metadata técnica.
const METADATA_KEYS := ["slot_id", "created_at", "updated_at"]


## Monta o envelope completo (com checksum) a partir de um estado já
## serializado e de metadata técnica.
static func create(state_data: Dictionary, metadata: Dictionary) -> Dictionary:
	var envelope := {
		"format": FORMAT,
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"metadata": metadata.duplicate(true),
		"state": state_data.duplicate(true),
	}
	envelope[SaveV2Checksum.FIELD] = SaveV2Checksum.compute(envelope)
	return envelope


static func make_metadata(slot_id: String, created_at: int, updated_at: int) -> Dictionary:
	return {"slot_id": slot_id, "created_at": created_at, "updated_at": updated_at}
