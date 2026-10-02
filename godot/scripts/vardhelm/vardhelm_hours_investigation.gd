class_name VardhelmHoursInvestigation
extends RefCounted

## C25 — Os horários: primeiro passo jogável da investigação de Vardhelm.
##
## Depois do gancho de Durn ("Então não fui só eu."), a investigação começa pelo que ele
## anotou: os horários de hoje. A escolha da primeira conversa decide COMO o jogador chega
## a eles, não O QUE descobre:
##   - "Sentir o quê?" (vardhelm_heard_echo): Durn continua no lugar dele e conta.
##   - "Não senti nada." (vardhelm_felt_nothing): Durn foi sozinho até onde o Eco aconteceu;
##     só aponta a folha que deixou no lugar de sempre (C16), que agora pode ser lida.
## Os dois caminhos chegam ao mesmo objetivo. A comparação com a rotina da cidade acontece
## no quadro de turnos da rua (C23): o jogador percebe uma relação, não uma resposta.
##
## Estado: só quests (QuestState → GameState → Save V2) e o que já existia (flags da
## escolha, diálogos concluídos, observações vistas). Nenhuma flag nova; o texto das
## observações, o objetivo exibido e a fala escolhida para Durn são DERIVADOS.
## Progresso só por ação do jogador (H8): nada depende de tempo; o Load nunca avança nada.

const THE_HOURS_QUEST_PATH := "res://data/quests/vardhelm_the_hours.json"
const THOSE_HOURS_QUEST_PATH := "res://data/quests/vardhelm_those_hours.json"
const THE_HOURS_DIALOGUE_PATH := "res://data/dialogue/vardhelm_the_hours.json"
const THE_NOTES_DIALOGUE_PATH := "res://data/dialogue/vardhelm_the_notes.json"

const THE_HOURS_QUEST_ID := "vardhelm_the_hours"
const THOSE_HOURS_QUEST_ID := "vardhelm_those_hours"
const HOURS_OBJECTIVE := "hours"
const COMPARE_OBJECTIVE := "compare"
const THE_HOURS_DIALOGUE_ID := "vardhelm_the_hours"
const THE_NOTES_DIALOGUE_ID := "vardhelm_the_notes"
## Depois de concluída, a conversa não se repete: Durn só retoma o que disse por último.
const THE_HOURS_REMINDER_ENTRY := "unknown"
const THE_NOTES_REMINDER_ENTRY := "sheet"

const FELT_NOTHING_FLAG := "vardhelm_felt_nothing"
const NOTES_OBSERVATION_ID := "durn_notes"
const SHIFT_BOARD_OBSERVATION_ID := "foundry_street_shift_board"

const OBJECTIVE_ASK_DURN_KEY := "quest.vardhelm.the_hours.objective.ask_durn"
const OBJECTIVE_READ_NOTES_KEY := "quest.vardhelm.the_hours.objective.read_notes"
const OBJECTIVE_COMPARE_KEY := "quest.vardhelm.the_hours.objective.compare"
const OBJECTIVE_FIND_OUT_KEY := "quest.vardhelm.those_hours.objective.find_out"
## Texto das observações quando o jogador já está investigando os horários.
const NOTES_HOURS_TEXT_KEY := "observation.durn_notes.hours"
const SHIFT_BOARD_HOURS_TEXT_KEY := "observation.foundry_street_shift_board.hours"

var the_hours_quest: QuestData
var those_hours_quest: QuestData
var the_hours_dialogue: DialogueData
var the_notes_dialogue: DialogueData

var _quests: QuestController
var _narrative: NarrativeController


func _init(quest_controller: QuestController, narrative_controller: NarrativeController) -> void:
	_quests = quest_controller
	_narrative = narrative_controller
	the_hours_quest = JsonDataLoader.load_quest(THE_HOURS_QUEST_PATH)
	those_hours_quest = JsonDataLoader.load_quest(THOSE_HOURS_QUEST_PATH)
	the_hours_dialogue = JsonDataLoader.load_dialogue(THE_HOURS_DIALOGUE_PATH)
	the_notes_dialogue = JsonDataLoader.load_dialogue(THE_NOTES_DIALOGUE_PATH)


# --- leitura do estado (tudo derivado de quests + flags existentes) -------------------

func is_started() -> bool:
	return _quests.states.active.has(THE_HOURS_QUEST_ID) or _quests.states.is_completed(THE_HOURS_QUEST_ID)


func knows_hours() -> bool:
	return _quests.states.is_completed(THE_HOURS_QUEST_ID) or _quests.states.is_objective_complete(THE_HOURS_QUEST_ID, HOURS_OBJECTIVE)


func compared() -> bool:
	return _quests.states.is_completed(THE_HOURS_QUEST_ID)


## Caminho "Não senti nada.": a consequência persistente da primeira escolha (C15).
func denied_route() -> bool:
	return _narrative != null and _narrative.world_state.has_flag(FELT_NOTHING_FLAG)


## Chave do objetivo a exibir ("" = esta etapa ainda não começou).
func objective_key() -> String:
	if _quests.states.active.has(THOSE_HOURS_QUEST_ID) or _quests.states.is_completed(THOSE_HOURS_QUEST_ID):
		return OBJECTIVE_FIND_OUT_KEY
	if not _quests.states.active.has(THE_HOURS_QUEST_ID):
		return ""
	if knows_hours():
		return OBJECTIVE_COMPARE_KEY
	return OBJECTIVE_READ_NOTES_KEY if denied_route() else OBJECTIVE_ASK_DURN_KEY


## Todas as chaves de objetivo desta etapa (para saber se a etapa anterior já foi
## apresentada como concluída: o objetivo seguinte a substitui).
static func objective_keys() -> Array[String]:
	return [OBJECTIVE_ASK_DURN_KEY, OBJECTIVE_READ_NOTES_KEY, OBJECTIVE_COMPARE_KEY, OBJECTIVE_FIND_OUT_KEY]


## Texto de uma observação, visto por quem está investigando os horários. Só as duas
## fontes dos horários mudam; as outras ficam como estão.
func observation_text_key(observation_id: String, text_key: String) -> String:
	if observation_id == NOTES_OBSERVATION_ID and is_started():
		return NOTES_HOURS_TEXT_KEY
	if observation_id == SHIFT_BOARD_OBSERVATION_ID and knows_hours():
		return SHIFT_BOARD_HOURS_TEXT_KEY
	return text_key


## Conversa de Durn nesta etapa: [DialogueData, entry_id], ou [] se não é a vez dela.
## Caminho da confiança: ele conta; caminho da negação: ele aponta a folha e, depois que
## o jogador leu, não tem mais o que dizer (o silêncio do C14 continua sendo dele).
func durn_dialogue(dialogue_state: DialogueRuntimeState, silent: DialogueData, silent_entry: String) -> Array:
	if not is_started():
		return []
	if denied_route():
		if knows_hours():
			return [silent, silent_entry]
		if dialogue_state.is_completed(THE_NOTES_DIALOGUE_ID):
			return [the_notes_dialogue, THE_NOTES_REMINDER_ENTRY]
		return [the_notes_dialogue, "denied"]
	if dialogue_state.is_completed(THE_HOURS_DIALOGUE_ID):
		return [the_hours_dialogue, THE_HOURS_REMINDER_ENTRY]
	return [the_hours_dialogue, "noted"]


# --- progresso (só por ação do jogador; nunca no Load) -------------------------------

## O gancho foi dito: a investigação dos horários começa (uma vez).
func start() -> bool:
	if is_started():
		return false
	_quests.start_quest(THE_HOURS_QUEST_ID)
	return true


## Fim de uma conversa: Durn contou os horários (caminho da confiança).
func on_dialogue_finished(dialogue: DialogueData) -> bool:
	if dialogue == null or dialogue.dialogue_id != THE_HOURS_DIALOGUE_ID:
		return false
	return _learn_hours()


## Uma observação foi examinada: a folha dá os horários; o quadro de turnos, a comparação.
func on_observation(observation_id: String) -> bool:
	if observation_id == NOTES_OBSERVATION_ID:
		return _learn_hours()
	if observation_id == SHIFT_BOARD_OBSERVATION_ID and knows_hours() and not compared():
		_quests.complete_objective(THE_HOURS_QUEST_ID, COMPARE_OBJECTIVE)
		_quests.complete_quest(THE_HOURS_QUEST_ID)
		_quests.start_quest(THOSE_HOURS_QUEST_ID)
		return true
	return false


func _learn_hours() -> bool:
	if not _quests.states.active.has(THE_HOURS_QUEST_ID) or knows_hours():
		return false
	_quests.complete_objective(THE_HOURS_QUEST_ID, HOURS_OBJECTIVE)
	return true
