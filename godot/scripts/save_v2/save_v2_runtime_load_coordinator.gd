class_name SaveV2RuntimeLoadCoordinator
extends RefCounted

## Bloco C7 — Load V2 OPERACIONAL controlado, com rollback.
##
##   flag -> arquivo -> envelope -> checksum -> GameState -> RestorePlan
##        -> REHEARSAL em sandbox (pipeline C6 completo)             [falha: nada tocado]
##        -> SNAPSHOT transitório do runtime principal
##        -> REHEARSAL DO ROLLBACK (snapshot restaurado em sandbox)   [falha: nada tocado]
##        -> APPLY no runtime principal (mesmo restaurador/adapters)
##        -> VALIDAÇÃO pós-restore (persistente + funcional)
##        -> SUCCESS, ou ROLLBACK (snapshot -> RestorePlan -> adapters) + verificação
##
## Não conhece SaveService, Ctrl+S/Ctrl+L nem a cena. Publica apenas
## game_loaded (C8), e só após SUCCESS; nunca chama o load antigo (sem fallback
## silencioso). Sessão de diálogo aberta = LOAD_REJECTED_TRANSIENT_DIALOGUE. O snapshot
## nunca é gravado. O GameState não passa a dirigir o gameplay: é só a fonte da
## operação de persistência.

var config: SaveV2OperationalConfig
var registry: RuntimeRestoreAdapterRegistry
## C8: barramento de eventos da experiência (opcional). Só recebe game_loaded
## (evento existente), e só depois de SUCCESS — nunca em falha ou rollback.
var bus: GameEventBus = null
## Seams de teste: passo do RestorePlan que falha no apply / no rollback.
var fault_injection_apply_step: String = ""
var fault_injection_rollback_step: String = ""
const EVENT_SOURCE := "save_v2"
## Último resultado (log diagnóstico interno; não vira evento).
var last_result: SaveV2RuntimeLoadResult = null


func _init(operational_config: SaveV2OperationalConfig = null, adapter_registry: RuntimeRestoreAdapterRegistry = null, event_bus: GameEventBus = null) -> void:
	config = operational_config if operational_config != null else SaveV2OperationalConfig.new()
	registry = adapter_registry if adapter_registry != null else RuntimeRestoreAdapterRegistry.create_default()
	bus = event_bus


func is_enabled() -> bool:
	return config.enabled


## `main_targets`: alvos do runtime PRINCIPAL (não sandbox). `sandbox`: fonte dos
## sandboxes de rehearsal (usa create_targets() e spawn()).
func load_into_runtime(main_targets: RuntimeRestoreTargets, sandbox: SaveV2DiagnosticSandbox) -> SaveV2RuntimeLoadResult:
	var result := SaveV2RuntimeLoadResult.new()
	var started := Time.get_ticks_usec()
	result.path = config.path
	if not config.enabled:
		return _finish(_outcome(result, SaveV2RuntimeLoadResult.DISABLED, SaveV2RuntimeLoadResult.CODE_FLAG_DISABLED,
			"Load V2 operacional desligado (SAVE_V2_OPERATIONAL_LOAD_ENABLED = false); nada foi executado"))
	result.steps.append("flag")
	var target_errors := _main_target_errors(main_targets)
	if sandbox == null:
		target_errors.append("nenhum sandbox para o rehearsal")
	if not target_errors.is_empty():
		return _finish(_outcome(result, SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2RuntimeLoadResult.CODE_INVALID_MAIN_TARGET, "alvos inválidos; nada foi tocado", target_errors))
	# C8: sessão de diálogo aberta = estado transitório sem contrato de restauração.
	# Recusa sem fechar, reabrir ou destruir a sessão; nada é tocado.
	if main_targets.derivations != null and main_targets.derivations.is_dialogue_session_open():
		return _finish(_outcome(result, SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE, SaveV2RuntimeLoadResult.LOAD_REJECTED_TRANSIENT_DIALOGUE,
			"há um diálogo em andamento; conclua o diálogo antes de carregar (sessão transitória não é restaurável)"))

	# 1. Rehearsal: o pipeline completo do C6 em sandbox. Nada do jogo principal é tocado.
	var step_started := Time.get_ticks_usec()
	var diagnostic := SaveV2DiagnosticCoordinator.new(SaveV2DiagnosticConfig.create(true, config.path), registry)
	var report := diagnostic.load_and_restore(sandbox)
	result.rehearsal = report.to_dict()
	if not report.is_success():
		return _finish(_outcome(result, _status_for_rehearsal(report), report.code, "rehearsal falhou; jogo principal intocado: %s" % report.message, Array(report.details)))
	var loaded := report.state
	var rehearsal_functional := SaveV2RuntimeSnapshot.describe(report.targets)
	# C9: custo do sandbox 1 (rehearsal do arquivo), por parte.
	result.timings_ms["sandbox1_file_validation"] = report.timings_ms.get("file_validation", 0.0)
	result.timings_ms["sandbox1_create"] = report.timings_ms.get("sandbox_create", 0.0)
	result.timings_ms["sandbox1_restore"] = report.timings_ms.get("sandbox_restore", 0.0)
	var discard_started := Time.get_ticks_usec()
	sandbox.discard()
	_time(result, "sandbox1_discard", discard_started)
	result.steps.append("rehearsal")
	_time(result, "rehearsal", step_started)
	step_started = Time.get_ticks_usec()

	# 2. Snapshot transitório — só depois de o arquivo passar pelo rehearsal.
	var snapshot := SaveV2RuntimeSnapshot.capture(main_targets)
	result.snapshot_taken = true
	var snapshot_errors: Array = []
	snapshot_errors.append_array(snapshot.quarantined)
	snapshot_errors.append_array(Array(snapshot.state.validate()))
	if not snapshot_errors.is_empty():
		return _finish(_outcome(result, SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2RuntimeLoadResult.CODE_SNAPSHOT_NOT_REVERSIBLE, "o runtime atual não é representável para rollback; nada foi tocado", snapshot_errors))
	result.steps.append("snapshot")
	_time(result, "snapshot", step_started)
	step_started = Time.get_ticks_usec()

	# 3. Rehearsal do rollback: o snapshot precisa voltar exatamente ao runtime atual.
	var rollback_errors := _rehearse_rollback(snapshot, sandbox.spawn(), result)
	if not rollback_errors.is_empty():
		return _finish(_outcome(result, SaveV2RuntimeLoadResult.RESTORE_REJECTED, SaveV2RuntimeLoadResult.CODE_SNAPSHOT_NOT_REVERSIBLE, "rollback não comprovado; nada foi tocado", rollback_errors))
	result.steps.append("rollback_rehearsal")
	_time(result, "rollback_rehearsal", step_started)
	step_started = Time.get_ticks_usec()

	# 4. Apply no runtime principal (mesmo núcleo + adapters).
	main_targets.operational_load_authorized = true
	var applier := GameStateRuntimeRestorer.new(registry)
	applier.fault_injection_step = fault_injection_apply_step
	var applied := applier.apply_to_runtime(loaded, main_targets)
	result.main_touched = not applied.applied.is_empty() or not applied.adapter_results.is_empty()
	result.apply = applied.to_dict()
	var apply_errors := _apply_errors(applied)
	if not apply_errors.is_empty():
		var code := SaveV2RuntimeLoadResult.CODE_APPLY_ERROR if not applied.success else SaveV2RuntimeLoadResult.CODE_APPLY_INCOMPLETE
		return _finish(_rollback(result, snapshot, main_targets, SaveV2RuntimeLoadResult.APPLY_FAILURE, code, "falha ao aplicar no jogo principal", apply_errors))
	result.steps.append("apply")
	_time(result, "apply", step_started)
	step_started = Time.get_ticks_usec()

	# 5. Validação pós-restore: persistente (projeção == GameState) + funcional (== rehearsal).
	var diff := applied.differences
	var persistent_ok := Array(diff.get("differences", [])).is_empty() and Array(diff.get("missing_in_left", [])).is_empty() \
		and Array(diff.get("missing_in_right", [])).is_empty() and Array(diff.get("unexpected_ids", [])).is_empty()
	var main_functional := SaveV2RuntimeSnapshot.describe(main_targets)
	var functional_ok := JSON.stringify(main_functional, "", true) == JSON.stringify(rehearsal_functional, "", true)
	result.post_restore = {"persistent": String(diff.get("summary", "")), "persistent_equal": persistent_ok, "functional_equal": functional_ok}
	if not persistent_ok:
		return _finish(_rollback(result, snapshot, main_targets, SaveV2RuntimeLoadResult.POST_RESTORE_MISMATCH, SaveV2RuntimeLoadResult.CODE_PERSISTENT_MISMATCH, "runtime principal difere do GameState carregado", [String(diff.get("summary", ""))]))
	if not functional_ok:
		return _finish(_rollback(result, snapshot, main_targets, SaveV2RuntimeLoadResult.POST_RESTORE_MISMATCH, SaveV2RuntimeLoadResult.CODE_FUNCTIONAL_MISMATCH, "estado derivado do runtime principal difere do rehearsal",
			[JSON.stringify(main_functional), JSON.stringify(rehearsal_functional)]))
	result.steps.append("post_restore")
	_time(result, "post_restore", step_started)

	main_targets.operational_load_authorized = false
	result.state = loaded
	_time(result, "total", started)
	# C8: game_loaded só depois de apply + validação pós-restore com SUCCESS.
	if bus != null:
		result.event_published = bus.publish(GameEventCatalog.GAME_LOADED, {"slot_id": SaveV2OperationalConfig.SLOT_ID}, EVENT_SOURCE) != null
	return _finish(_outcome(result, SaveV2RuntimeLoadResult.SUCCESS, SaveV2Errors.OK, "Load V2 aplicado ao jogo principal"))


# ---------------------------------------------------------------------------

func _main_target_errors(targets: RuntimeRestoreTargets) -> Array:
	var errors: Array = []
	if targets == null:
		return ["alvo principal nulo"]
	if targets.is_sandbox:
		errors.append("alvo principal declarado sandbox")
	for requirement in [["player", targets.player], ["world_state", targets.world_state], ["quest_state", targets.quest_state]]:
		if requirement[1] == null:
			errors.append("alvo principal sem %s" % requirement[0])
	if targets.player != null and not targets.player.is_inside_tree():
		errors.append("player principal fora da árvore")
	return errors


func _rehearse_rollback(snapshot: SaveV2RuntimeSnapshot, check: SaveV2DiagnosticSandbox, result: SaveV2RuntimeLoadResult) -> Array:
	if check == null:
		return ["sem sandbox para comprovar o rollback"]
	var create_started := Time.get_ticks_usec()
	var targets := check.create_targets()
	_time(result, "sandbox2_create", create_started)
	if targets == null or not targets.is_sandbox:
		check.discard()
		return ["sandbox do rollback indisponível"]
	var restore_began := Time.get_ticks_usec()
	var restored := GameStateRuntimeRestorer.new(registry).apply_to_sandbox(snapshot.state, targets)
	var errors: Array = []
	if not restored.success:
		errors.append_array(Array(restored.errors))
	else:
		errors.append_array(_apply_errors(restored))
		errors.append_array(Array(snapshot.differences(targets)))
	_time(result, "sandbox2_restore", restore_began)
	var discard_started := Time.get_ticks_usec()
	check.discard()
	_time(result, "sandbox2_discard", discard_started)
	return errors


## Erros de uma aplicação: falha do restaurador, campos não derivados/sem destino
## ou itens do plano não aplicados (nunca "best effort").
func _apply_errors(applied: RestoreResult) -> Array:
	var errors: Array = []
	if not applied.success:
		errors.append_array(Array(applied.errors))
		return errors
	var done := {}
	for item in applied.applied:
		done[String(item["source_path"])] = true
	for entry in applied.adapter_results:
		for path in entry["requires_adapter"]:
			errors.append("não derivado: %s" % path)
		for path in entry["unsupported"]:
			errors.append("sem destino: %s" % path)
		for path in entry["applied"]:
			done[String(path)] = true
	for item in applied.plan.items:
		var status := String(item["status"])
		if (status == RestorePlan.STATUS_SUPPORTED or status == RestorePlan.STATUS_ADAPTER_SUPPORTED) and not done.has(String(item["source_path"])):
			errors.append("não aplicado: %s" % item["source_path"])
	return errors


## Restaura o snapshot pelo MESMO restaurador/adapters e confirma 0 diferenças.
func _rollback(result: SaveV2RuntimeLoadResult, snapshot: SaveV2RuntimeSnapshot, main_targets: RuntimeRestoreTargets,
		failure_status: String, failure_code: String, message: String, details: Array) -> SaveV2RuntimeLoadResult:
	result.original_failure = {"status": failure_status, "code": failure_code, "message": message, "details": details.duplicate()}
	var rollback_started := Time.get_ticks_usec()
	var roller := GameStateRuntimeRestorer.new(registry)
	roller.fault_injection_step = fault_injection_rollback_step
	var rolled := roller.apply_to_runtime(snapshot.state, main_targets)
	var rollback_errors: Array = []
	if not rolled.success:
		rollback_errors.append_array(Array(rolled.errors))
	else:
		rollback_errors.append_array(Array(snapshot.differences(main_targets)))
	main_targets.operational_load_authorized = false
	_time(result, "rollback", rollback_started)
	for error in rollback_errors:
		result.rollback_details.append(str(error))
	if rollback_errors.is_empty():
		result.rollback_status = SaveV2RuntimeLoadResult.ROLLBACK_SUCCESS
		return _outcome(result, failure_status, failure_code, message + "; rollback restaurou o estado anterior (0 diferenças)", details)
	result.rollback_status = SaveV2RuntimeLoadResult.ROLLBACK_FAILURE
	return _outcome(result, SaveV2RuntimeLoadResult.ROLLBACK_FAILURE, failure_code,
		"%s; ROLLBACK FALHOU — estado do jogo principal não confirmado" % message, details)


static func _status_for_rehearsal(report: SaveV2DiagnosticReport) -> String:
	match report.status:
		SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2DiagnosticReport.INVALID_SAVE, SaveV2DiagnosticReport.UNSUPPORTED_SCHEMA:
			return SaveV2RuntimeLoadResult.VALIDATION_FAILURE
		SaveV2DiagnosticReport.FAILURE:
			if report.code == SaveV2Errors.FILE_NOT_FOUND or report.code == SaveV2Errors.IO_ERROR:
				return SaveV2RuntimeLoadResult.LOAD_FAILURE
			return SaveV2RuntimeLoadResult.RESTORE_REJECTED
		_:
			return SaveV2RuntimeLoadResult.RESTORE_REJECTED


func _outcome(result: SaveV2RuntimeLoadResult, status: String, code: String, message: String, details: Array = []) -> SaveV2RuntimeLoadResult:
	result.status = status
	result.code = code
	result.message = message
	for detail in details:
		result.details.append(str(detail))
	return result


func _finish(result: SaveV2RuntimeLoadResult) -> SaveV2RuntimeLoadResult:
	last_result = result
	return result


## C8: mede uma etapa (ms, 3 casas).
func _time(result: SaveV2RuntimeLoadResult, step: String, started_usec: int) -> void:
	result.timings_ms[step] = snappedf(float(Time.get_ticks_usec() - started_usec) / 1000.0, 0.001)
