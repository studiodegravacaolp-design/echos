class_name SaveV2PlayerMessages
extends RefCounted

## Bloco C9 — separa MENSAGEM DO JOGADOR de LOG TÉCNICO.
##
## O jogador vê só uma chave de localização (texto no catálogo pt-BR), nunca
## códigos (LOAD_FAILURE, POST_RESTORE_MISMATCH, ROLLBACK_FAILURE...), detalhes
## ou stack trace. O log técnico carrega código, detalhes, falha original e
## falha do rollback.

const KEY_SAVED := "save.v2.saved"
const KEY_SAVE_FAILED := "save.v2.save_failed"
const KEY_SAVE_WRITE_FAILED := "save.v2.save_write_failed"
const KEY_LOADED := "save.v2.loaded"
const KEY_LOAD_REJECTED_DIALOGUE := "save.v2.load_rejected_dialogue"
const KEY_LOAD_NO_SAVE := "save.v2.load_no_save"
const KEY_LOAD_LEGACY_ONLY := "save.v2.load_legacy_only"
const KEY_LOAD_INVALID := "save.v2.load_invalid"
const KEY_LOAD_REJECTED := "save.v2.load_rejected"
const KEY_LOAD_FAILED_RESTORED := "save.v2.load_failed_restored"
const KEY_LOAD_UNSAFE := "save.v2.load_unsafe"

const ALL_KEYS := [
	KEY_SAVED, KEY_SAVE_FAILED, KEY_SAVE_WRITE_FAILED, KEY_LOADED, KEY_LOAD_REJECTED_DIALOGUE,
	KEY_LOAD_NO_SAVE, KEY_LOAD_LEGACY_ONLY, KEY_LOAD_INVALID, KEY_LOAD_REJECTED,
	KEY_LOAD_FAILED_RESTORED, KEY_LOAD_UNSAFE,
]


## Chave de localização para o resultado de um Load V2. `legacy_save_present`:
## existe só um save no formato legado (o V2 não o carrega).
static func load_key(result: SaveV2RuntimeLoadResult, legacy_save_present: bool = false) -> String:
	match result.status:
		SaveV2RuntimeLoadResult.SUCCESS:
			return KEY_LOADED
		SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE:
			return KEY_LOAD_REJECTED_DIALOGUE
		SaveV2RuntimeLoadResult.LOAD_FAILURE:
			if result.code == SaveV2Errors.FILE_NOT_FOUND:
				return KEY_LOAD_LEGACY_ONLY if legacy_save_present else KEY_LOAD_NO_SAVE
			return KEY_LOAD_INVALID
		SaveV2RuntimeLoadResult.VALIDATION_FAILURE:
			return KEY_LOAD_INVALID
		SaveV2RuntimeLoadResult.RESTORE_REJECTED:
			return KEY_LOAD_REJECTED
		SaveV2RuntimeLoadResult.APPLY_FAILURE, SaveV2RuntimeLoadResult.POST_RESTORE_MISMATCH:
			# Só chega aqui com rollback confirmado (ROLLBACK_SUCCESS).
			return KEY_LOAD_FAILED_RESTORED
		SaveV2RuntimeLoadResult.ROLLBACK_FAILURE:
			return KEY_LOAD_UNSAFE
		_:
			return KEY_LOAD_REJECTED


static func save_key(result: SaveV2RuntimeSaveResult) -> String:
	match result.status:
		SaveV2RuntimeSaveResult.SUCCESS:
			return KEY_SAVED
		SaveV2RuntimeSaveResult.WRITE_FAILURE:
			return KEY_SAVE_WRITE_FAILED
		_:
			return KEY_SAVE_FAILED


## Log técnico completo (nunca mostrado ao jogador).
static func load_log(result: SaveV2RuntimeLoadResult) -> String:
	var text := "Load V2 %s" % result.describe()
	if not result.original_failure.is_empty():
		text += " | falha original: %s" % JSON.stringify(result.original_failure)
	if not result.rollback_details.is_empty():
		text += " | falha do rollback: %s" % "; ".join(result.rollback_details)
	return text


static func save_log(result: SaveV2RuntimeSaveResult) -> String:
	return "Save V2 %s" % result.describe()


# --- C10: severidade (apresentação) ---------------------------------------------

const SEVERITY_SUCCESS := "success"
const SEVERITY_WARNING := "warning"
const SEVERITY_ERROR := "error"


## Severidade da mensagem, para destacar na UI existente (cor/borda). Nunca
## muda o texto nem expõe código técnico.
static func severity_of(key: String) -> String:
	match key:
		KEY_SAVED, KEY_LOADED:
			return SEVERITY_SUCCESS
		KEY_LOAD_REJECTED_DIALOGUE, KEY_LOAD_NO_SAVE, KEY_LOAD_LEGACY_ONLY:
			return SEVERITY_WARNING
		_:
			return SEVERITY_ERROR
