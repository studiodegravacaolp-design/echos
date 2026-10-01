class_name RuntimeRestoreAdapterRegistry
extends RefCounted

## Registro explícito dos adapters de restauração (Bloco C4). Objeto comum —
## não é Autoload nem singleton; quem monta o restaurador escolhe o registry.
## Vazio = comportamento do C3 (sem adapters).

var _adapters: Array[RestoreAdapter] = []


## Registry com todos os adapters do C4, na ordem de execução.
static func create_default() -> RuntimeRestoreAdapterRegistry:
	var registry := RuntimeRestoreAdapterRegistry.new()
	registry.register(ConsequenceRestoreAdapter.new())
	registry.register(ObservationRestoreAdapter.new())
	registry.register(EchoRestoreAdapter.new())
	registry.register(MemoryRestoreAdapter.new())
	registry.register(DialogueRestoreAdapter.new())
	registry.register(QuestPresentationRestoreAdapter.new())
	registry.register(EnvironmentPresentationRestoreAdapter.new())
	return registry


## Recusa adapter nulo, com passo desconhecido ou com ID repetido.
func register(adapter: RestoreAdapter) -> bool:
	if adapter == null or not RestorePlan.STEPS.has(adapter.step()) or has(adapter.adapter_id()):
		return false
	_adapters.append(adapter)
	return true


func has(adapter_id: String) -> bool:
	for adapter in _adapters:
		if adapter.adapter_id() == adapter_id:
			return true
	return false


func all() -> Array[RestoreAdapter]:
	return _adapters.duplicate()


func adapters_for(step: String) -> Array[RestoreAdapter]:
	var out: Array[RestoreAdapter] = []
	for adapter in _adapters:
		if adapter.step() == step:
			out.append(adapter)
	return out


func ids() -> Array[String]:
	var out: Array[String] = []
	for adapter in _adapters:
		out.append(adapter.adapter_id())
	return out
