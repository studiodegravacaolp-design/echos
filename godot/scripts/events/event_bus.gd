class_name GameEventBus
extends RefCounted

## Barramento de eventos estruturados (Bloco B1). Objeto de runtime da
## experiência — NÃO é Autoload nem singleton.
##
## Só distribui eventos: não conhece controladores, SaveService, UI,
## AmbientLife, WorldState nem GameState, e não controla gameplay.
##
## - publish(): valida no GameEventCatalog, numera (event_id/tick sequenciais,
##   determinísticos) e entrega a todos os inscritos.
## - Entrega em FILA (FIFO): um evento publicado por um listener durante a
##   entrega de outro só é entregue depois que o atual chegar a todos — a ordem
##   causal de publicação é preservada para todos os listeners.
## - Cada listener recebe o mesmo GameEvent imutável (payload devolvido em cópia).

var rejected: Array[String] = []

var _subscribers: Array[Dictionary] = []   # { "listener": Callable, "types": Array }
var _queue: Array[GameEvent] = []
var _dispatching := false
var _sequence := 0


## Inscreve um listener (Callable que recebe GameEvent). `event_types` vazio =
## todos os tipos. Retorna false se já inscrito ou inválido.
func subscribe(listener: Callable, event_types: Array = []) -> bool:
	if not listener.is_valid() or is_subscribed(listener):
		return false
	_subscribers.append({"listener": listener, "types": event_types.duplicate()})
	return true


func unsubscribe(listener: Callable) -> bool:
	for index in _subscribers.size():
		if _subscribers[index]["listener"] == listener:
			_subscribers.remove_at(index)
			return true
	return false


func is_subscribed(listener: Callable) -> bool:
	for subscriber in _subscribers:
		if subscriber["listener"] == listener:
			return true
	return false


func subscriber_count() -> int:
	return _subscribers.size()


## Publica um fato. Retorna o GameEvent criado, ou null se rejeitado (tipo
## desconhecido, payload inválido/não serializável) — nada é entregue nesse caso.
func publish(event_type: String, payload: Dictionary, source: String) -> GameEvent:
	var errors := GameEventCatalog.validate(event_type, source, payload)
	if not errors.is_empty():
		rejected.append("; ".join(errors))
		return null
	_sequence += 1
	var event := GameEvent.create("evt-%06d" % _sequence, event_type, source, payload, _sequence)
	_queue.append(event)
	if not _dispatching:
		_drain()
	return event


## Quantidade de eventos aceitos até agora.
func published_count() -> int:
	return _sequence


func _drain() -> void:
	_dispatching = true
	while not _queue.is_empty():
		var event: GameEvent = _queue.pop_front()
		for subscriber in _subscribers.duplicate():
			if not _subscribers.has(subscriber):
				continue  # desinscrito durante a entrega
			var types: Array = subscriber["types"]
			if not types.is_empty() and not types.has(event.event_type):
				continue
			var listener: Callable = subscriber["listener"]
			if listener.is_valid():
				listener.call(event)
	_dispatching = false
