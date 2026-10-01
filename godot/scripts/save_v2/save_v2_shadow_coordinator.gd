class_name SaveV2ShadowCoordinator
extends RefCounted

## Bloco C2 — DUAL SAVE / DUAL LOAD em MODO SOMBRA.
##
##   Ctrl+S -> SaveService antigo (operacional) -> depois: SaveV2Service grava o GameState sombra
##   Ctrl+L -> load antigo (operacional)        -> depois: SaveV2Service carrega e COMPARA
##
## O SaveService antigo continua sendo a fonte operacional do save/load.
## Este coordenador:
## - nunca restaura Player, WorldState, QuestState, DialogueController ou
##   qualquer outro sistema;
## - nunca substitui nem ressincroniza o GameState sombra com o estado carregado;
## - nunca altera UI/status; falha do V2 fica só no relatório;
## - publica game_saved / game_loaded SOMENTE após sucesso real do V2.
##
## Dono: objeto de runtime da experiência (VardhelmVerticalSlice.shadow_save_v2).
## Não é Node, Autoload nem singleton.

const EVENT_SOURCE := "save_v2"
## Relatórios guardados para diagnóstico (os mais recentes).
const MAX_REPORTS := 20

var service: SaveV2Service
var slot_id: String = SaveV2Envelope.DEFAULT_SLOT_ID
var last_save_report: Dictionary = {}
var last_load_report: Dictionary = {}
var reports: Array[Dictionary] = []

var _recorder: GameStateShadowRecorder
var _bus: GameEventBus


func _init(recorder: GameStateShadowRecorder, save_service: SaveV2Service, bus: GameEventBus = null) -> void:
	_recorder = recorder
	service = save_service
	_bus = bus


## Chamado DEPOIS do save antigo. Grava o GameState sombra (após amostrar a
## posição do jogador) no arquivo próprio do Save V2.
func after_legacy_save() -> Dictionary:
	var report := {"operation": "save", "slot_id": slot_id, "path": _path()}
	if _recorder == null or service == null:
		report["v2"] = {"ok": false, "code": "UNAVAILABLE", "message": "recorder ou serviço ausente"}
		return _store(report, true)
	_recorder.sync_sampled_state()
	var result := service.save_game_state(_recorder.game_state, slot_id)
	report["v2"] = _summary(result)
	if result.ok:
		report["event_published"] = _publish(GameEventCatalog.GAME_SAVED)
	return _store(report, true)


## Chamado DEPOIS do load antigo. Carrega o Save V2 e compara o estado
## carregado com (a) o runtime atual — já com o efeito do load antigo — e
## (b) o GameState sombra. Somente leitura: nada é restaurado.
func after_legacy_load(legacy_loaded: bool, world_state: WorldState, quest_state: QuestState) -> Dictionary:
	var report := {"operation": "load", "slot_id": slot_id, "path": _path(), "legacy_loaded": legacy_loaded}
	if _recorder == null or service == null:
		report["v2"] = {"ok": false, "code": "UNAVAILABLE", "message": "recorder ou serviço ausente"}
		return _store(report, false)
	var result := service.load_game_state()
	report["v2"] = _summary(result)
	if not result.ok:
		return _store(report, false)
	report["event_published"] = _publish(GameEventCatalog.GAME_LOADED)
	_recorder.sync_sampled_state()
	var player := _recorder.tracked_player()
	var projection := GameStateProjector.project(world_state, quest_state, player)
	report["vs_runtime"] = _comparison(GameStateComparator.compare(result.state, projection.state, "save_v2", "runtime"))
	report["vs_shadow"] = _comparison(GameStateComparator.compare(result.state, _recorder.game_state, "save_v2", "shadow"))
	return _store(report, false)


# ---------------------------------------------------------------------------

func _publish(event_type: String) -> bool:
	if _bus == null:
		return false
	return _bus.publish(event_type, {"slot_id": slot_id}, EVENT_SOURCE) != null


func _path() -> String:
	return service.path if service != null else ""


func _summary(result: SaveV2Result) -> Dictionary:
	var summary := {"ok": result.ok, "code": result.code, "message": result.message}
	if not result.details.is_empty():
		summary["details"] = result.details.duplicate()
	return summary


## Resumo JSON-safe da comparação (sem a lista de caminhos iguais).
func _comparison(comparison: GameStateComparison) -> Dictionary:
	var data := comparison.to_dict()
	data.erase("matching")
	data["matching_count"] = comparison.matching.size()
	data["summary"] = comparison.summary()
	return data


func _store(report: Dictionary, is_save: bool) -> Dictionary:
	if is_save:
		last_save_report = report
	else:
		last_load_report = report
	reports.append(report)
	while reports.size() > MAX_REPORTS:
		reports.pop_front()
	return report
