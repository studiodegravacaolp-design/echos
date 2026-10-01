class_name SaveV2Checksum
extends RefCounted

## Checksum do Save V2 (Bloco C1).
##
## Algoritmo (único):
##   checksum = "sha256:" + SHA-256( C ) em hex minúsculo,
##   onde C = forma canônica (SaveV2Serializer.canonical_json) do envelope SEM o
##   campo "checksum" (format, game_version, metadata, schema_version, state),
##   codificada em UTF-8.
##
## Duas formas de obter C, com o mesmo resultado:
##   - em memória (ao gravar): C = canonical_json(envelope sem checksum);
##   - no arquivo (ao carregar): o arquivo É a forma canônica do envelope e
##     "checksum" é a 1ª chave, então C = arquivo sem o membro
##     `"checksum":"...",` — extraído literalmente, SEM reler números.
##     Isso torna a verificação imune à imprecisão do parser JSON do Godot.
##
## Determinístico, sem aleatoriedade e sem sal: detecta corrupção e edição;
## não é proteção contra adulteração intencional.

const PREFIX := "sha256:"
const FIELD := "checksum"
const _FILE_PREFIX := "{\"checksum\":\""


## Checksum a partir do envelope em memória. Retorna "" se houver valores não
## serializáveis (erros em `errors`).
static func compute(envelope: Dictionary, errors: PackedStringArray = PackedStringArray()) -> String:
	var covered := envelope.duplicate(true)
	covered.erase(FIELD)
	var local_errors := PackedStringArray()
	var canonical := SaveV2Serializer.canonical_json(covered, local_errors)
	if not local_errors.is_empty():
		errors.append_array(local_errors)
		return ""
	return compute_from_text(canonical)


## Checksum de um texto canônico já pronto (C).
static func compute_from_text(canonical_text: String) -> String:
	return PREFIX + canonical_text.sha256_text()


## Separa, do texto do arquivo, o checksum gravado e o texto coberto C.
## Retorna {"ok", "checksum", "covered", "error"}. Falha se o arquivo não
## estiver na forma canônica (ex.: reformatado) ou não tiver checksum.
static func split_file_text(file_text: String) -> Dictionary:
	var checksum_length := PREFIX.length() + 64
	if not file_text.begins_with(_FILE_PREFIX):
		return {"ok": false, "checksum": "", "covered": "", "error": "arquivo sem checksum na posição canônica (ausente ou arquivo reformatado)"}
	var checksum := file_text.substr(_FILE_PREFIX.length(), checksum_length)
	var separator_at := _FILE_PREFIX.length() + checksum_length
	if not is_well_formed(checksum) or file_text.substr(separator_at, 2) != "\",":
		return {"ok": false, "checksum": "", "covered": "", "error": "checksum malformado na forma canônica"}
	return {"ok": true, "checksum": checksum, "covered": "{" + file_text.substr(separator_at + 2), "error": ""}


static func is_well_formed(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING:
		return false
	var text := String(value)
	if not text.begins_with(PREFIX) or text.length() != PREFIX.length() + 64:
		return false
	return text.substr(PREFIX.length()).is_valid_hex_number(false) and text == text.to_lower()


## true se o checksum gravado no envelope (em memória) corresponde ao calculado.
static func matches(envelope: Dictionary) -> bool:
	if not is_well_formed(envelope.get(FIELD)):
		return false
	var expected := compute(envelope)
	return not expected.is_empty() and expected == String(envelope[FIELD])
