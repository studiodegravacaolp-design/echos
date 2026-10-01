class_name SaveV2RuntimeSaveCoordinator
extends RefCounted

## Bloco C8 — Save V2 OPERACIONAL (opt-in: SAVE_V2_OPERATIONAL_SAVE_ENABLED).
##
##   runtime -> projeção persistente completa (SaveV2RuntimeSnapshot.project)
##           -> validação -> GameState sombra sincronizado (cópia)
##           -> SaveV2Service (formato C1, escrita atômica) -> checksum literal
##           -> SUCCESS -> game_saved
##
## Sem sandbox (o Save não precisa de rehearsal). Não grava estado derivado nem
## transitório (UI, câmera, áudio, timers, animações, efeitos, sessão de
## diálogo). Não conhece SaveService: o save antigo nunca é gravado por aqui.
## O GameState continua sombra do gameplay; a projeção é a representação
## persistente oficial do V2.

const EVENT_SOURCE := "save_v2"

var config: SaveV2OperationalConfig
var service: SaveV2Service
var bus: GameEventBus = null
var last_result: SaveV2RuntimeSaveResult = null


func _init(operational_config: SaveV2OperationalConfig = null, event_bus: GameEventBus = null) -> void:
	config = operational_config if operational_config != null else SaveV2OperationalConfig.new()
	service = SaveV2Service.new(config.path)
	bus = event_bus


func is_enabled() -> bool:
	return config.save_enabled


## `recorder` (opcional): GameState sombra da experiência, sincronizado com a projeção.
func save_runtime(main_targets: RuntimeRestoreTargets, recorder: GameStateShadowRecorder = null) -> SaveV2RuntimeSaveResult:
	var result := SaveV2RuntimeSaveResult.new()
	result.path = config.path
	var started := Time.get_ticks_usec()
	if not config.save_enabled:
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.DISABLED, SaveV2RuntimeSaveResult.CODE_FLAG_DISABLED,
			"Save V2 operacional desligado (SAVE_V2_OPERATIONAL_SAVE_ENABLED = false); nada foi gravado"))
	result.steps.append("flag")
	var target_errors: Array = []
	if main_targets == null:
		target_errors.append("alvo principal nulo")
	else:
		if main_targets.is_sandbox:
			target_errors.append("alvo declarado sandbox")
		for requirement in [["player", main_targets.player], ["world_state", main_targets.world_state], ["quest_state", main_targets.quest_state]]:
			if requirement[1] == null:
				target_errors.append("alvo sem %s" % requirement[0])
	if not target_errors.is_empty():
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.SAVE_REJECTED, SaveV2RuntimeSaveResult.CODE_INVALID_MAIN_TARGET, "alvo inválido; nada foi gravado", target_errors))

	# Sessão de diálogo aberta é permitida: só a parte persistente é projetada.
	result.dialogue_session_open = main_targets.derivations != null and main_targets.derivations.is_dialogue_session_open()
	if result.dialogue_session_open:
		result.details.append("diálogo em andamento: gravado só o DialogueRuntimeState persistente (a sessão não é salva)")

	# 1. Projeção persistente completa do runtime.
	var step_started := Time.get_ticks_usec()
	var projection := SaveV2RuntimeSnapshot.project(main_targets)
	var state: GameState = projection["state"]
	if not Array(projection["quarantined"]).is_empty():
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.SAVE_REJECTED, SaveV2RuntimeSaveResult.CODE_UNREPRESENTABLE_RUNTIME, "runtime com dados sem representação no GameState; nada foi gravado", Array(projection["quarantined"])))
	result.steps.append("project")
	# 2. Validação.
	var errors := state.validate()
	if not errors.is_empty():
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.VALIDATION_FAILURE, SaveV2Errors.INVALID_STATE, "GameState projetado inválido; nada foi gravado", Array(errors)))
	result.steps.append("validate")
	result.timings_ms["project"] = _ms(step_started)
	# 3. Sombra sincronizada (cópia): o próximo save/load parte do estado real.
	if recorder != null:
		recorder.sync_sampled_state()
		var comparison := GameStateComparator.compare(recorder.game_state, state, "sombra", "runtime")
		for path in comparison.divergent_paths():
			result.shadow_divergence.append(path)
		recorder.game_state = GameState.from_dict(state.to_dict())
	result.steps.append("sync")
	# 4. Gravação (formato C1) + checksum sobre o texto literal.
	step_started = Time.get_ticks_usec()
	var written := service.save_game_state(state, SaveV2OperationalConfig.SLOT_ID)
	if not written.ok:
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.WRITE_FAILURE, written.code, written.message, Array(written.details)))
	result.steps.append("write")
	var split := SaveV2Checksum.split_file_text(FileAccess.get_file_as_string(config.path))
	if not split["ok"] or SaveV2Checksum.compute_from_text(String(split["covered"])) != String(split["checksum"]):
		return _finish(_outcome(result, SaveV2RuntimeSaveResult.WRITE_FAILURE, SaveV2Errors.INVALID_CHECKSUM, "arquivo gravado não confere com o checksum"))
	result.checksum = String(split["checksum"])
	result.steps.append("checksum")
	result.timings_ms["write"] = _ms(step_started)
	result.timings_ms["total"] = _ms(started)
	result.state = GameState.from_dict(state.to_dict())
	_outcome(result, SaveV2RuntimeSaveResult.SUCCESS, SaveV2Errors.OK, "Save V2 gravado")
	# game_saved só depois de gravar e verificar o arquivo.
	if bus != null:
		result.event_published = bus.publish(GameEventCatalog.GAME_SAVED, {"slot_id": SaveV2OperationalConfig.SLOT_ID}, EVENT_SOURCE) != null
	return _finish(result)


func _outcome(result: SaveV2RuntimeSaveResult, status: String, code: String, message: String, details: Array = []) -> SaveV2RuntimeSaveResult:
	result.status = status
	result.code = code
	result.message = message
	for detail in details:
		result.details.append(str(detail))
	return result


func _finish(result: SaveV2RuntimeSaveResult) -> SaveV2RuntimeSaveResult:
	last_result = result
	return result


static func _ms(started_usec: int) -> float:
	return snappedf(float(Time.get_ticks_usec() - started_usec) / 1000.0, 0.001)
