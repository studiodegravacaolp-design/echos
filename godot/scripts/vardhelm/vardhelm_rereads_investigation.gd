class_name VardhelmRereadsInvestigation
extends RefCounted

## C26 — Releituras e padrão: o que o jogador já viu na Forja vira evidência nova.
##
## Depois da comparação no quadro de turnos (C25: dois horários de Durn caem minutos antes
## da troca de turno; o de 17h41 não), o jogador volta à Forja 01 com outra pergunta. Os
## mesmos objetos dizem mais, em qualquer ordem:
##   - quadro de manutenção: uma linha raspada; resta o fim de um horário, "...58";
##   - painel selado: os parafusos do reforço são mais novos que a placa (continua fechado, H1).
## Com as duas evidências, "Nesses horários" se conclui e começa "O reforço": descobrir
## quem reforçou o painel e onde ficam os registros da Forja (prepara o Galpão, H3).
##
## É mudança de INTERPRETAÇÃO, não do mundo: o texto contextual é derivado do que o jogador
## já sabe (a comparação feita); a primeira leitura de cada objeto continua a mesma. Quem
## examinou os objetos antes não precisa "desver": a releitura aparece ao examinar de novo.
## Estado: só quests (objetivos "mark" e "panel" de "Nesses horários"; "O reforço"). Nenhuma
## flag nova, nenhuma memória nova; progresso só por ação do jogador (H8).

const THOSE_HOURS_QUEST_ID := "vardhelm_those_hours"
const REINFORCEMENT_QUEST_PATH := "res://data/quests/vardhelm_the_reinforcement.json"
const REINFORCEMENT_QUEST_ID := "vardhelm_the_reinforcement"
const THE_HOURS_QUEST_ID := "vardhelm_the_hours"
const MARK_OBJECTIVE := "mark"
const PANEL_OBJECTIVE := "panel"
const THE_MARK_DIALOGUE_PATH := "res://data/dialogue/vardhelm_the_mark.json"
const THE_MARK_DIALOGUE_ID := "vardhelm_the_mark"

const BOARD_OBSERVATION_ID := "maintenance_board"
const PANEL_OBSERVATION_ID := "sealed_panel"
const BOARD_REREAD_KEY := "observation.maintenance_board.reread"
const PANEL_REREAD_KEY := "observation.sealed_panel.reread"
const OBJECTIVE_TRACE_KEY := "quest.vardhelm.the_reinforcement.objective.trace"
const FELT_NOTHING_FLAG := "vardhelm_felt_nothing"

var reinforcement_quest: QuestData
var the_mark_dialogue: DialogueData

var _quests: QuestController
var _narrative: NarrativeController


func _init(quest_controller: QuestController, narrative_controller: NarrativeController) -> void:
	_quests = quest_controller
	_narrative = narrative_controller
	reinforcement_quest = JsonDataLoader.load_quest(REINFORCEMENT_QUEST_PATH)
	the_mark_dialogue = JsonDataLoader.load_dialogue(THE_MARK_DIALOGUE_PATH)


# --- leitura do estado (tudo derivado de quests + flags existentes) -------------------

## A releitura existe quando o jogador já comparou os horários com a rotina (C25).
func can_reread() -> bool:
	return _quests.states.is_completed(THE_HOURS_QUEST_ID)


func found_mark() -> bool:
	return _quests.states.is_completed(THOSE_HOURS_QUEST_ID) or _quests.states.is_objective_complete(THOSE_HOURS_QUEST_ID, MARK_OBJECTIVE)


func noticed_panel() -> bool:
	return _quests.states.is_completed(THOSE_HOURS_QUEST_ID) or _quests.states.is_objective_complete(THOSE_HOURS_QUEST_ID, PANEL_OBJECTIVE)


func is_tracing() -> bool:
	return _quests.states.active.has(REINFORCEMENT_QUEST_ID) or _quests.states.is_completed(REINFORCEMENT_QUEST_ID)


## Chave do objetivo desta etapa ("" = ainda não chegou aqui; vale o objetivo do C25).
func objective_key() -> String:
	return OBJECTIVE_TRACE_KEY if is_tracing() else ""


## Texto de uma observação relida por quem já sabe o que procurar. Só o quadro de
## manutenção e o painel ganham releitura; a primeira leitura nunca é substituída antes.
func observation_text_key(observation_id: String, text_key: String) -> String:
	if not can_reread():
		return text_key
	if observation_id == BOARD_OBSERVATION_ID:
		return BOARD_REREAD_KEY
	if observation_id == PANEL_OBSERVATION_ID:
		return PANEL_REREAD_KEY
	return text_key


## Reação curta de Durn depois da linha raspada (só no caminho em que ele confia): [] se não
## é a vez dela. No outro caminho ele continua em silêncio. Nunca uma nova etapa.
func durn_dialogue() -> Array:
	if not found_mark():
		return []
	if _narrative != null and _narrative.world_state.has_flag(FELT_NOTHING_FLAG):
		return []
	return [the_mark_dialogue, "not_me"]


# --- progresso (só por ação do jogador; nunca no Load) -------------------------------

## Uma observação foi examinada: o quadro dá a linha raspada; o painel, o reforço mais novo.
## Com as duas, a evidência basta e a investigação segue para o reforço.
func on_observation(observation_id: String) -> bool:
	if not _quests.states.active.has(THOSE_HOURS_QUEST_ID):
		return false
	var objective := ""
	if observation_id == BOARD_OBSERVATION_ID:
		objective = MARK_OBJECTIVE
	elif observation_id == PANEL_OBSERVATION_ID:
		objective = PANEL_OBJECTIVE
	if objective.is_empty() or _quests.states.is_objective_complete(THOSE_HOURS_QUEST_ID, objective):
		return false
	_quests.complete_objective(THOSE_HOURS_QUEST_ID, objective)
	if found_mark() and noticed_panel():
		_quests.complete_quest(THOSE_HOURS_QUEST_ID)
		_quests.start_quest(REINFORCEMENT_QUEST_ID)
	return true
