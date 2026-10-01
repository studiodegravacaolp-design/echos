class_name GameEvent
extends RefCounted

## Evento estruturado (Bloco B1): descreve um FATO que já aconteceu no gameplay.
##
## Campos: event_id, event_type, schema_version, source, payload e tick.
## - tick: número de sequência do GameEventBus (ordem causal determinística);
##   não há timestamp do sistema operacional — nada depende de relógio.
## - payload: somente IDs estáveis e dados semânticos (JSON puro).
##
## IMUTABILIDADE: os campos são somente leitura (tentativas de escrita são
## ignoradas com aviso) e `payload` sempre devolve uma CÓPIA PROFUNDA. Assim
## um listener nunca altera o evento original nem o que os outros recebem.
## Instâncias devem ser criadas pelo GameEventBus (GameEvent.create).

var event_id: String:
	get:
		return _event_id
	set(_value):
		_reject_write("event_id")

var event_type: String:
	get:
		return _event_type
	set(_value):
		_reject_write("event_type")

var schema_version: int:
	get:
		return _schema_version
	set(_value):
		_reject_write("schema_version")

var source: String:
	get:
		return _source
	set(_value):
		_reject_write("source")

var tick: int:
	get:
		return _tick
	set(_value):
		_reject_write("tick")

var payload: Dictionary:
	get:
		return _payload.duplicate(true)
	set(_value):
		_reject_write("payload")

var _event_id: String = ""
var _event_type: String = ""
var _schema_version: int = GameEventCatalog.SCHEMA_VERSION
var _source: String = ""
var _tick: int = 0
var _payload: Dictionary = {}


## Cria um evento já validado. Retorna null se tipo, origem ou payload forem
## inválidos (ver GameEventCatalog.validate).
static func create(id: String, type: String, origin: String, data: Dictionary, sequence: int) -> GameEvent:
	if not GameEventCatalog.validate(type, origin, data).is_empty() or id.strip_edges().is_empty():
		return null
	var event := GameEvent.new()
	event._event_id = id
	event._event_type = type
	event._schema_version = GameEventCatalog.schema_version_of(type)
	event._source = origin
	event._tick = sequence
	event._payload = data.duplicate(true)
	return event


## Valor de um campo do payload (cópia para containers).
func get_value(key: String, default_value: Variant = null) -> Variant:
	var value: Variant = _payload.get(key, default_value)
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		return value.duplicate(true)
	return value


func to_dict() -> Dictionary:
	return {
		"event_id": _event_id,
		"event_type": _event_type,
		"schema_version": _schema_version,
		"source": _source,
		"tick": _tick,
		"payload": _payload.duplicate(true),
	}


func _reject_write(field: String) -> void:
	push_warning("GameEvent é imutável: escrita em '%s' ignorada (%s)" % [field, _event_id])
