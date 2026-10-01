class_name SaveV2DiagnosticCoordinator
extends RefCounted

## Bloco C6 — pipeline DIAGNÓSTICO completo do Save V2:
##
##   GameState -> save() -> arquivo V2 próprio
##   arquivo -> load -> envelope -> checksum -> GameState -> RestorePlan
##          -> sandbox NOVO -> núcleo + adapters -> verificação -> comparação -> relatório
##
## Não é o load operacional: não conhece SaveService, Ctrl+S/Ctrl+L, a cena, o
## jogo principal nem o EventBus (não publica eventos). O único alvo de escrita é
## um SaveV2DiagnosticSandbox criado para esta execução.
##
## FAILURE POLICY (SaveV2DiagnosticReport): um status + um código específico;
## nunca "best effort". Qualquer falha depois de o sandbox existir DESCARTA o
## sandbox — nada parcialmente restaurado sobrevive. O jogo principal nunca é
## alvo, então não há rollback a fazer nele (rollback real = requisito do C7).
##
## Flag (SaveV2DiagnosticConfig.enabled) desligada = nada é lido, gravado ou
## restaurado.

var config: SaveV2DiagnosticConfig
var service: SaveV2Service
var restorer: GameStateRuntimeRestorer
## Último relatório (diagnóstico interno; não vira evento).
var last_report: SaveV2DiagnosticReport = null


func _init(diagnostic_config: SaveV2DiagnosticConfig = null, registry: RuntimeRestoreAdapterRegistry = null) -> void:
	config = diagnostic_config if diagnostic_config != null else SaveV2DiagnosticConfig.new()
	service = SaveV2Service.new(config.path)
	restorer = GameStateRuntimeRestorer.new(registry if registry != null else RuntimeRestoreAdapterRegistry.create_default())


func is_enabled() -> bool:
	return config.enabled


# ---------------------------------------------------------------------------
# SAVE (diagnóstico) — mesmo formato do C1, arquivo próprio
# ---------------------------------------------------------------------------

func save(state: GameState) -> SaveV2DiagnosticReport:
	var report := _new_report("save")
	if not config.enabled:
		return _disabled(report)
	report.steps.append("flag")
	var written := service.save_game_state(state, SaveV2DiagnosticConfig.SLOT_ID)
	if not written.ok:
		return _finish(_from_save_error(report, written))
	report.steps.append("write")
	# Confirma no arquivo literal o que foi gravado.
	var verify := _verify_literal_checksum()
	if not verify.is_empty():
		return _finish(_fail(report, SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2Errors.INVALID_CHECKSUM, verify))
	report.steps.append("checksum")
	report.checksum = String(written.envelope[SaveV2Checksum.FIELD])
	report.checksum_verified = true
	report.status = SaveV2DiagnosticReport.SUCCESS
	report.code = SaveV2Errors.OK
	report.message = "Save V2 diagnóstico gravado"
	return _finish(report)


# ---------------------------------------------------------------------------
# LOAD + RESTORE (diagnóstico, somente em sandbox)
# ---------------------------------------------------------------------------

## `expected` (opcional): GameState capturado no momento do save, para comparação.
## Em SUCCESS o sandbox fica em report.sandbox (quem chamou o descarta); em
## qualquer outro status ele já foi descartado.
func load_and_restore(sandbox: SaveV2DiagnosticSandbox, expected: GameState = null) -> SaveV2DiagnosticReport:
	var report := _new_report("load")
	var started := Time.get_ticks_usec()
	if not config.enabled:
		return _disabled(report)
	report.steps.append("flag")

	# 1–4. arquivo -> envelope -> checksum -> GameState (SaveV2Service/Validator do C1).
	var loaded := service.load_game_state()
	if not loaded.ok:
		return _finish(_from_save_error(report, loaded))
	report.steps.append_array(["load", "envelope"])
	var literal := _verify_literal_checksum()
	if not literal.is_empty():
		return _finish(_fail(report, SaveV2DiagnosticReport.CORRUPTED_DATA, SaveV2Errors.INVALID_CHECKSUM, literal))
	report.checksum = String(loaded.envelope[SaveV2Checksum.FIELD])
	report.checksum_verified = true
	report.steps.append("checksum")
	var state := loaded.state
	var state_errors := state.validate()
	if not state_errors.is_empty():
		return _finish(_fail(report, SaveV2DiagnosticReport.INVALID_SAVE, SaveV2Errors.INVALID_STATE, "GameState inválido", Array(state_errors)))
	report.state = state
	report.steps.append("game_state")

	# 5. RestorePlan — tudo precisa ter destino antes de qualquer escrita.
	var plan := restorer.diagnose(state)
	report.plan_counts = plan.counts()
	var unknown: Array = []
	for item in plan.by_status(RestorePlan.STATUS_UNSUPPORTED):
		unknown.append(String(item["source_path"]))
	if not unknown.is_empty():
		return _finish(_fail(report, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_UNKNOWN_ID, "IDs sem destino no runtime; nada foi restaurado", unknown))
	var missing: Array = []
	for item in plan.by_status(RestorePlan.STATUS_REQUIRES_ADAPTER):
		missing.append(String(item["source_path"]))
	# "progression" é a seção reservada (sem campos no GameState): not_implemented
	# aceito. Qualquer outro not_implemented seria dado sem destino.
	for item in plan.by_status(RestorePlan.STATUS_NOT_IMPLEMENTED):
		if String(item["source_path"]) != "progression":
			missing.append(String(item["source_path"]))
	if not missing.is_empty():
		return _finish(_fail(report, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_PLAN_INCOMPLETE, "campos sem restauração completa; nada foi restaurado", missing))
	report.steps.append("plan")

	# 6. sandbox NOVO.
	if sandbox == null:
		return _finish(_fail(report, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_SANDBOX_UNAVAILABLE, "nenhum sandbox informado"))
	report.timings_ms["file_validation"] = _ms(started)
	var sandbox_started := Time.get_ticks_usec()
	var targets := sandbox.create_targets()
	report.timings_ms["sandbox_create"] = _ms(sandbox_started)
	var restore_began := Time.get_ticks_usec()
	report.sandbox_created = targets != null
	if targets == null:
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_SANDBOX_UNAVAILABLE, "sandbox não criou alvos"))
	if not targets.is_sandbox:
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_TARGET_NOT_SANDBOX, "alvo não declarado sandbox; restauração recusada"))
	report.steps.append("sandbox")

	# 7. núcleo + adapters.
	var result := restorer.apply_to_sandbox(state, targets)
	report.restore = result.to_dict()
	report.differences = result.differences
	if not result.success:
		if not result.partial_failure:
			return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.RESTORE_REJECTED, SaveV2DiagnosticReport.CODE_RESTORE_REFUSED, "restauração recusada antes de qualquer escrita", Array(result.errors)))
		var adapter_failed := false
		for entry in result.adapter_results:
			if not Array(entry["errors"]).is_empty():
				adapter_failed = true
		var failure_code := SaveV2DiagnosticReport.CODE_ADAPTER_FAILURE if adapter_failed else SaveV2DiagnosticReport.CODE_CORE_STEP_FAILURE
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.PARTIAL_FAILURE, failure_code, "restauração interrompida no sandbox", Array(result.errors)))
	report.steps.append("restore")

	# 8. verificação: nenhum campo pode ter ficado sem restaurar (sem "best effort").
	var not_derived: Array = []
	var not_supported: Array = []
	for entry in result.adapter_results:
		not_derived.append_array(Array(entry["requires_adapter"]))
		not_supported.append_array(Array(entry["unsupported"]))
	if not not_derived.is_empty():
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.CODE_DERIVATION_FAILURE, "derivação indisponível no sandbox; estado incompleto descartado", not_derived))
	if not not_supported.is_empty():
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.CODE_UNSUPPORTED_CONTENT, "conteúdo sem destino no runtime; estado incompleto descartado", not_supported))
	# Todo item supported/adapter-supported do plano precisa ter sido aplicado
	# (ex.: NPC ou Eco sem alvo no sandbox não passa em silêncio).
	var applied := {}
	for item in result.applied:
		applied[String(item["source_path"])] = true
	for entry in result.adapter_results:
		for path in entry["applied"]:
			applied[String(path)] = true
	var unapplied: Array = []
	for item in plan.items:
		var status := String(item["status"])
		if (status == RestorePlan.STATUS_SUPPORTED or status == RestorePlan.STATUS_ADAPTER_SUPPORTED) and not applied.has(String(item["source_path"])):
			unapplied.append(String(item["source_path"]))
	if not unapplied.is_empty():
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.PARTIAL_FAILURE, SaveV2DiagnosticReport.CODE_INCOMPLETE_RESTORE, "campos do plano não aplicados no sandbox; estado incompleto descartado", unapplied))
	report.steps.append("verify")

	# 9. comparação.
	var diff := result.differences
	if not (Array(diff.get("differences", [])).is_empty() and Array(diff.get("missing_in_left", [])).is_empty()
			and Array(diff.get("missing_in_right", [])).is_empty() and Array(diff.get("unexpected_ids", [])).is_empty()):
		return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.FAILURE, SaveV2DiagnosticReport.CODE_RESTORE_MISMATCH, "runtime restaurado difere do GameState carregado", [String(diff.get("summary", ""))]))
	if expected != null:
		var player: Node3D = targets.player if targets.player != null and targets.player.is_inside_tree() else null
		var runtime_state := GameStateProjector.project(targets.world_state, targets.quest_state, player, targets.dialogue_state).state
		var vs_loaded := GameStateComparator.compare(expected, state, "esperado", "carregado")
		var vs_runtime := GameStateComparator.compare(expected, runtime_state, "esperado", "restaurado")
		report.expected_comparison = {"loaded": vs_loaded.summary(), "restored": vs_runtime.summary(),
			"loaded_equal": vs_loaded.is_equal(), "restored_equal": vs_runtime.is_equal()}
		if not vs_loaded.is_equal() or not vs_runtime.is_equal():
			return _finish(_discard(report, sandbox, SaveV2DiagnosticReport.FAILURE, SaveV2DiagnosticReport.CODE_EXPECTED_MISMATCH, "estado restaurado difere do GameState esperado", [vs_loaded.summary(), vs_runtime.summary()]))
	report.steps.append("comparison")
	report.timings_ms["sandbox_restore"] = _ms(restore_began)

	report.status = SaveV2DiagnosticReport.SUCCESS
	report.code = SaveV2Errors.OK
	report.message = "Load V2 diagnóstico restaurado no sandbox"
	report.sandbox = sandbox
	report.targets = targets
	return _finish(report)


# ---------------------------------------------------------------------------

func _new_report(operation: String) -> SaveV2DiagnosticReport:
	var report := SaveV2DiagnosticReport.new()
	report.operation = operation
	report.path = config.path
	return report


func _disabled(report: SaveV2DiagnosticReport) -> SaveV2DiagnosticReport:
	report.status = SaveV2DiagnosticReport.DISABLED
	report.code = SaveV2DiagnosticReport.CODE_FLAG_DISABLED
	report.message = "diagnóstico Save V2 desligado (SAVE_V2_DIAGNOSTIC_ENABLED = false); nada foi executado"
	return _finish(report)


func _fail(report: SaveV2DiagnosticReport, status: String, code: String, message: String, details: Array = []) -> SaveV2DiagnosticReport:
	report.status = status
	report.code = code
	report.message = message
	for detail in details:
		report.details.append(str(detail))
	return report


## Falha com sandbox existente: descarta antes de devolver o relatório.
func _discard(report: SaveV2DiagnosticReport, sandbox: SaveV2DiagnosticSandbox, status: String, code: String, message: String, details: Array = []) -> SaveV2DiagnosticReport:
	sandbox.discard()
	report.sandbox_discarded = sandbox.is_discarded()
	report.details.append("sandbox descartado; jogo principal não foi tocado")
	return _fail(report, status, code, message, details)


func _from_save_error(report: SaveV2DiagnosticReport, result: SaveV2Result) -> SaveV2DiagnosticReport:
	return _fail(report, status_for(result.code), result.code, result.message, Array(result.details))


## SaveV2Errors -> status da failure policy.
static func status_for(save_error: String) -> String:
	match save_error:
		SaveV2Errors.OK:
			return SaveV2DiagnosticReport.SUCCESS
		SaveV2Errors.CORRUPTED_DATA, SaveV2Errors.INVALID_CHECKSUM:
			return SaveV2DiagnosticReport.CORRUPTED_DATA
		SaveV2Errors.UNSUPPORTED_SCHEMA:
			return SaveV2DiagnosticReport.UNSUPPORTED_SCHEMA
		SaveV2Errors.INVALID_FORMAT, SaveV2Errors.INVALID_ENVELOPE, SaveV2Errors.INVALID_METADATA, SaveV2Errors.INVALID_STATE:
			return SaveV2DiagnosticReport.INVALID_SAVE
		_:
			return SaveV2DiagnosticReport.FAILURE


## Recalcula o checksum sobre o texto LITERAL do arquivo. "" = confere.
func _verify_literal_checksum() -> String:
	var text := FileAccess.get_file_as_string(config.path)
	var split := SaveV2Checksum.split_file_text(text)
	if not split["ok"]:
		return String(split["error"])
	if SaveV2Checksum.compute_from_text(String(split["covered"])) != String(split["checksum"]):
		return "checksum do arquivo literal não confere"
	return ""


func _finish(report: SaveV2DiagnosticReport) -> SaveV2DiagnosticReport:
	last_report = report
	return report


## C9: ms desde `started_usec` (3 casas).
static func _ms(started_usec: int) -> float:
	return snappedf(float(Time.get_ticks_usec() - started_usec) / 1000.0, 0.001)
