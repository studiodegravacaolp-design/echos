class_name RestoreAdapter
extends RefCounted

## Contrato dos adapters de restauração (Blocos C4/C5).
##
##   diagnose(GameState, RestorePlan)                         -> refina itens do plano (sem mutação)
##   apply(GameState, RestorePlan, RuntimeRestoreTargets)     -> RestoreAdapterResult
##
## Um adapter NÃO cria fonte de verdade nova: só usa estruturas e derivações que
## o runtime já possui, através de contratos formais (C5): WorldState/QuestState,
## DialogueRuntimeState e RuntimeStateDerivationContract — nunca métodos privados
## da experiência. Não guarda estado, não publica eventos, não conhece a cena nem
## o SaveService. Só é executado em alvos sandbox.


## Identificador estável do adapter.
func adapter_id() -> String:
	return "restore_adapter"


## Passo de RestorePlan.STEPS em que o adapter roda.
func step() -> String:
	return ""


func diagnose(_state: GameState, _plan: RestorePlan) -> void:
	pass


func apply(_state: GameState, _plan: RestorePlan, _targets: RuntimeRestoreTargets) -> RestoreAdapterResult:
	return new_result()


func new_result() -> RestoreAdapterResult:
	return RestoreAdapterResult.create(adapter_id(), step())


## Marca um item do plano como reconstruível pelo adapter.
func promote(plan: RestorePlan, source_path: String, destination: String, action: String, note: String) -> bool:
	return plan.update(source_path, {
		"status": RestorePlan.STATUS_ADAPTER_SUPPORTED,
		"destination": destination,
		"action": action,
		"note": note,
	})


## Registra no resultado, a partir do plano, os itens deste adapter por status.
func collect_plan_items(plan: RestorePlan, result: RestoreAdapterResult, prefix: String) -> void:
	for item in plan.by_step(step()):
		var source := String(item["source_path"])
		if not source.begins_with(prefix):
			continue
		if item["status"] == RestorePlan.STATUS_ADAPTER_SUPPORTED:
			result.supported.append(source)
		elif item["status"] == RestorePlan.STATUS_REQUIRES_ADAPTER:
			result.requires_adapter.append(source)
		elif item["status"] == RestorePlan.STATUS_UNSUPPORTED:
			result.unsupported.append(source)


## Derivações do sandbox; sem contrato informado, a implementação padrão (que
## não deriva nada — o adapter reporta requires_adapter).
func derivations_of(targets: RuntimeRestoreTargets) -> RuntimeStateDerivationContract:
	if targets != null and targets.derivations != null:
		return targets.derivations
	return RuntimeStateDerivationContract.new()
