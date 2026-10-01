class_name RecordedEvents
extends RefCounted

## Listener de diagnóstico (Bloco B1): grava os eventos publicados em um
## GameEventBus para verificação de quantidade, tipo, ordem e payload. Sem UI.

var events: Array[GameEvent] = []


func attach(bus: GameEventBus, event_types: Array = []) -> void:
	bus.subscribe(record, event_types)


func detach(bus: GameEventBus) -> void:
	bus.unsubscribe(record)


func record(event: GameEvent) -> void:
	events.append(event)


func clear() -> void:
	events.clear()


func count(event_type: String = "") -> int:
	if event_type.is_empty():
		return events.size()
	return of_type(event_type).size()


## Tipos na ordem em que foram recebidos.
func types() -> Array[String]:
	var out: Array[String] = []
	for event in events:
		out.append(event.event_type)
	return out


func of_type(event_type: String) -> Array[GameEvent]:
	var out: Array[GameEvent] = []
	for event in events:
		if event.event_type == event_type:
			out.append(event)
	return out


## Eventos de um tipo cujo payload contém todos os pares de `fields`.
func matching(event_type: String, fields: Dictionary) -> Array[GameEvent]:
	var out: Array[GameEvent] = []
	for event in of_type(event_type):
		var payload := event.payload
		var ok := true
		for key in fields:
			if not payload.has(key) or typeof(payload[key]) != typeof(fields[key]) or payload[key] != fields[key]:
				ok = false
				break
		if ok:
			out.append(event)
	return out


func to_dicts() -> Array:
	var out: Array = []
	for event in events:
		out.append(event.to_dict())
	return out
