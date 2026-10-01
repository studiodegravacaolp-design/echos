class_name DialogueRuntimeState
extends RefCounted

## Bloco C5 — contrato do estado PERSISTENTE de diálogo no runtime.
##
## Destino de runtime para o DialogueState do GameState (A1 §3.5, decisão #6):
##
##   completed  dialogue_id -> true
##   choices    dialogue_id -> { entry_id: choice_id }   (ÚLTIMA escolha por ponto de decisão)
##
## Pertence ao DialogueController (`persistent_state`), que o preenche quando uma
## escolha válida é aceita e quando um diálogo termina. IDs são os do runtime
## (os mesmos do DialogueData: dialogue_id, entry_id, choice_id) — nunca texto,
## falante ou índice visual. Sem histórico, sem timestamps, sem estado de UI.
##
## Nenhum gameplay consulta este estado: ele só existe para que dados
## persistentes de diálogo tenham um destino explícito (restauração/comparação).
##
## TRANSIENTE (nunca entra aqui nem no GameState): ver TRANSIENT_FIELDS.

const PERSISTENT_FIELDS := ["completed", "choices"]
## Estado da conversa em andamento e da apresentação — não persistido, não restaurado.
const TRANSIENT_FIELDS := [
	"current_session",       # DialogueController.current_session / DialogueSession
	"current_entry",         # DialogueSession.current_entry_id
	"selected_choice",       # DialogueSession.selected_choice_id (escolha da sessão aberta)
	"visible_choices",       # botões de escolha exibidos
	"speaker",               # falante exibido na caixa
	"text",                  # texto exibido
	"animation",             # animação/efeitos da caixa
	"dialogue_box_visible",  # visibilidade da DialogueBox
]

var completed: Dictionary = {}
var choices: Dictionary = {}


func mark_completed(dialogue_id: String) -> bool:
	if dialogue_id.strip_edges().is_empty():
		return false
	completed[dialogue_id] = true
	return true


## 1. Este diálogo já foi concluído?
func is_completed(dialogue_id: String) -> bool:
	return completed.has(dialogue_id)


## Registra a escolha de um ponto de decisão, substituindo a anterior.
func record_choice(dialogue_id: String, entry_id: String, choice_id: String) -> bool:
	if dialogue_id.strip_edges().is_empty() or entry_id.strip_edges().is_empty() or choice_id.strip_edges().is_empty():
		return false
	if not choices.has(dialogue_id):
		choices[dialogue_id] = {}
	choices[dialogue_id][entry_id] = choice_id
	return true


## 2. Última escolha registrada para dialogue_id + entry_id ("" = nenhuma).
func last_choice(dialogue_id: String, entry_id: String) -> String:
	if not choices.has(dialogue_id):
		return ""
	return String(choices[dialogue_id].get(entry_id, ""))


## 3. É possível restaurar esta escolha? Só se o ponto de decisão e a escolha
## existem na definição do diálogo (identidade por IDs, não por texto/índice).
static func can_restore_choice(dialogue: DialogueData, entry_id: String, choice_id: String) -> bool:
	if dialogue == null:
		return false
	var entry := dialogue.get_entry(entry_id)
	if entry == null:
		return false
	for choice: DialogueChoice in entry.choices:
		if choice.choice_id == choice_id:
			return true
	return false


## 3. É possível restaurar a conclusão? Só para um diálogo com definição válida.
static func can_restore_completed(dialogue: DialogueData) -> bool:
	return dialogue != null and dialogue.is_valid()


## Substitui todo o estado persistente (restauração). Nada é mesclado.
func restore(completed_ids: Array, restored_choices: Dictionary) -> void:
	completed = {}
	choices = {}
	for dialogue_id in completed_ids:
		mark_completed(String(dialogue_id))
	for dialogue_id in restored_choices:
		var points: Dictionary = restored_choices[dialogue_id]
		for entry_id in points:
			record_choice(String(dialogue_id), String(entry_id), String(points[entry_id]))


## Somente os campos persistentes (cópia).
func to_dict() -> Dictionary:
	return {"completed": completed.duplicate(true), "choices": choices.duplicate(true)}
