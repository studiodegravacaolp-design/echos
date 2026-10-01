class_name SaveV2Service
extends RefCounted

## Save V2 em MODO SOMBRA (Bloco C1).
##
##   GameState -> to_dict -> SaveV2Envelope (+checksum) -> arquivo próprio
##   arquivo -> JSON -> SaveV2Validator -> GameState.from_dict -> GameState equivalente
##
## Paralelo ao SaveService atual: caminho próprio, não o chama, não é chamado
## por ele, não usa Ctrl+S/Ctrl+L e não publica eventos. Não conhece Player,
## DialogueBox, controladores, AmbientLife, UI nem Input. O estado carregado
## serve só para verificação — nenhum gameplay o consulta.
##
## Escrita atômica (ver §13 da doc):
##   texto -> <arquivo>.tmp -> releitura + validação do .tmp
##   -> [<arquivo> -> <arquivo>.bak] -> <arquivo>.tmp -> <arquivo> -> remove .bak
## Se qualquer passo falha, o save anterior é mantido (ou restaurado do .bak).

const DEFAULT_PATH := "user://echoes_of_the_soul_save_v2_shadow.json"
const TMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"

var path: String = DEFAULT_PATH
## Relógio injetável (segundos Unix UTC) — usado SOMENTE em metadata.
var clock: Callable


func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path
	clock = func() -> int: return _system_clock()


func has_save() -> bool:
	return FileAccess.file_exists(path)


func delete_save() -> bool:
	var removed_any := false
	for candidate in [path, path + TMP_SUFFIX, path + BACKUP_SUFFIX]:
		if FileAccess.file_exists(candidate):
			if DirAccess.remove_absolute(candidate) == OK:
				removed_any = true
	return removed_any and not has_save()


func save_game_state(state: GameState, slot_id: String = SaveV2Envelope.DEFAULT_SLOT_ID) -> SaveV2Result:
	if state == null:
		return SaveV2Result.failure(SaveV2Errors.INVALID_STATE, "GameState nulo", [], path)
	var state_errors := state.validate()
	if not state_errors.is_empty():
		return SaveV2Result.failure(SaveV2Errors.INVALID_STATE, "GameState inválido; nada foi gravado", Array(state_errors), path)

	var now := int(clock.call())
	var created_at := now
	var details: Array[String] = []
	if has_save():
		var previous := load_game_state()
		if previous.ok:
			created_at = int(previous.envelope["metadata"]["created_at"])
		else:
			details.append("save anterior inválido será substituído (%s)" % previous.code)
	var metadata := SaveV2Envelope.make_metadata(slot_id, mini(created_at, now), now)
	var envelope := SaveV2Envelope.create(SaveV2Serializer.state_to_dict(state), metadata)
	if String(envelope[SaveV2Checksum.FIELD]).is_empty():
		return SaveV2Result.failure(SaveV2Errors.INVALID_STATE, "estado com valores não serializáveis", [], path)

	var write := _write_atomically(SaveV2Serializer.to_file_text(envelope))
	if not write.ok:
		return write
	var result := SaveV2Result.success(path, envelope)
	result.details = details
	return result


func load_game_state() -> SaveV2Result:
	if not FileAccess.file_exists(path):
		return SaveV2Result.failure(SaveV2Errors.FILE_NOT_FOUND, "nenhum Save V2 em %s" % path, [], path)
	var read := _read_envelope(path)
	if not read.ok:
		return read
	var state := SaveV2Serializer.dict_to_state(read.envelope["state"])
	# Guarda contra perda silenciosa: o estado reconstruído precisa reproduzir o
	# state gravado — mesma estrutura, mesmos IDs e valores (números comparados
	# com is_equal_approx, pois o parser JSON pode diferir em 1 ulp).
	var fidelity := GameStateComparator.compare_dicts(read.envelope["state"], state.to_dict(), "gravado", "reconstruido")
	if not fidelity.is_equal():
		var lost: Array[String] = []
		for difference in fidelity.differences:
			lost.append(String(difference["path"]))
		lost.append_array(fidelity.missing_in_right)
		lost.append_array(fidelity.missing_in_left)
		return SaveV2Result.failure(SaveV2Errors.CORRUPTED_DATA, "state não sobrevive à reconstrução sem perda", lost, path)
	return SaveV2Result.success(path, read.envelope, state)


# ---------------------------------------------------------------------------

func _read_envelope(file_path: String) -> SaveV2Result:
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "não foi possível ler %s (%s)" % [file_path, error_string(FileAccess.get_open_error())], [], file_path)
	var parsed := SaveV2Serializer.parse_file_text(text)
	if not parsed["ok"]:
		return SaveV2Result.failure(SaveV2Errors.CORRUPTED_DATA, String(parsed["error"]), [], file_path)
	var validation := SaveV2Validator.validate(parsed["data"], text)
	validation.path = file_path
	return validation


func _write_atomically(text: String) -> SaveV2Result:
	var directory := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		var made := DirAccess.make_dir_recursive_absolute(directory)
		if made != OK:
			return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "não foi possível criar %s (%s)" % [directory, error_string(made)], [], path)

	var tmp_path := path + TMP_SUFFIX
	var backup_path := path + BACKUP_SUFFIX
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "não foi possível abrir %s (%s)" % [tmp_path, error_string(FileAccess.get_open_error())], [], path)
	file.store_string(text)
	file.flush()
	file.close()

	# Verifica o que realmente foi gravado antes de substituir o save atual.
	var verify := _read_envelope(tmp_path)
	if not verify.ok:
		DirAccess.remove_absolute(tmp_path)
		return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "verificação do arquivo temporário falhou; save anterior mantido", [verify.describe()], path)

	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		var moved := DirAccess.rename_absolute(path, backup_path)
		if moved != OK:
			DirAccess.remove_absolute(tmp_path)
			return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "não foi possível preparar a substituição (%s); save anterior mantido" % error_string(moved), [], path)
	var replaced := DirAccess.rename_absolute(tmp_path, path)
	if replaced != OK:
		if had_previous:
			DirAccess.rename_absolute(backup_path, path)
		DirAccess.remove_absolute(tmp_path)
		return SaveV2Result.failure(SaveV2Errors.IO_ERROR, "não foi possível substituir o save (%s); save anterior restaurado" % error_string(replaced), [], path)
	if had_previous:
		DirAccess.remove_absolute(backup_path)
	return SaveV2Result.success(path, {})


static func _system_clock() -> int:
	return int(Time.get_unix_time_from_system())
