class_name SaveV2Errors
extends RefCounted

## Códigos de erro do Save V2 (Bloco C1). Toda falha do Save V2 usa um
## destes códigos — nunca uma string solta — e nunca há fallback silencioso.

const OK := "OK"
## Campo "format" ausente ou diferente de SaveV2Envelope.FORMAT.
const INVALID_FORMAT := "INVALID_FORMAT"
## schema_version inteiro, mas não suportado (ex.: 1 ou 3).
const UNSUPPORTED_SCHEMA := "UNSUPPORTED_SCHEMA"
## Estrutura do envelope inválida (não é Dictionary, vazio, campo ausente,
## campo desconhecido, schema_version não inteiro, game_version inválido).
const INVALID_ENVELOPE := "INVALID_ENVELOPE"
## "state" ausente, não Dictionary ou incompatível com o contrato GameState.
const INVALID_STATE := "INVALID_STATE"
## checksum ausente, malformado ou diferente do recalculado.
const INVALID_CHECKSUM := "INVALID_CHECKSUM"
## metadata ausente, não Dictionary, com campo desconhecido ou tipo inválido.
const INVALID_METADATA := "INVALID_METADATA"
## Arquivo ilegível como JSON (texto vazio, sintaxe inválida) ou estado que não
## sobrevive à reconstrução sem perda.
const CORRUPTED_DATA := "CORRUPTED_DATA"
## Não existe save no caminho do serviço.
const FILE_NOT_FOUND := "FILE_NOT_FOUND"
## Falha de E/S ao gravar, verificar ou substituir o arquivo (código adicional
## ao conjunto mínimo do C1; ver docs/architecture/BLOCK_C1_SAVE_V2_SHADOW.md §9).
const IO_ERROR := "IO_ERROR"

const ALL := [
	OK, INVALID_FORMAT, UNSUPPORTED_SCHEMA, INVALID_ENVELOPE, INVALID_STATE,
	INVALID_CHECKSUM, INVALID_METADATA, CORRUPTED_DATA, FILE_NOT_FOUND, IO_ERROR,
]
