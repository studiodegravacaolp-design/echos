class_name GameplayEventPublisher
extends RefCounted

## Adaptador NÃO INVASIVO do Bloco B1:
##
##   GAMEPLAY ATUAL (sinais existentes) -> GameplayEventPublisher -> GameEventBus
##
## Escuta sinais que o gameplay já emite e publica eventos estruturados com IDs
## canônicos. Não altera controladores, sinais, WorldState, QuestState nem o
## GameState, e nada do que ele publica volta para o gameplay.
##
## Regras:
## - Um acontecimento gera um evento uma única vez. Reaplicar uma consequência
##   já aplicada ou reexaminar uma observação já descoberta NÃO são fatos novos
##   (ficam em `suppressed_repeats`). Escolhas e conclusões de diálogo repetidas
##   SÃO fatos novos e são publicadas.
## - ID do runtime fora do GameIdCatalog: nada é publicado; vai para `diagnostics`.
## - Estados sem sinal no runtime (interação de NPC e estados de ambiente) são
##   verificados nas fronteiras de evento (poll) e só geram evento quando mudam.

const SOURCE_EXPERIENCE := "experience"
const SOURCE_DIALOGUE := "dialogue"
const SOURCE_QUEST := "quest"
const SOURCE_NARRATIVE := "narrative"
const SOURCE_ECHO := "echo"
const SOURCE_OBSERVATION := "observation"
const SOURCE_NPC := "npc"
const SOURCE_WORLD := "world"

var diagnostics: Array[String] = []
var suppressed_repeats: Array[String] = []

var _bus: GameEventBus
var _dialogue_controller_ref: WeakRef = null
var _ambient_ref: WeakRef = null
var _published_consequences: Dictionary = {}
var _discovered_observations: Dictionary = {}
var _known_world_states: Dictionary = {}
## [{ "ref": WeakRef(NPCController), "npc_id": String, "interaction_enabled": bool }]
var _tracked_npcs: Array[Dictionary] = []


func _init(bus: GameEventBus) -> void:
	_bus = bus


## Bloco C9: depois de um Load V2 com SUCCESS o mundo pode ter VOLTADO no tempo.
## Realinha a deduplicação ao estado carregado (sem publicar nada), para que
## repetir uma consequência/observação desfeita pelo load volte a gerar evento e
## a sombra continue acompanhando o runtime. Estados de ambiente e NPCs passam a
## refletir o runtime atual.
func resync_after_load(state: GameState) -> void:
	_published_consequences = {}
	for consequence_id in state.world.consequences:
		_published_consequences[String(consequence_id)] = true
	_discovered_observations = {}
	for observation_id in state.world.observations:
		_discovered_observations[String(observation_id)] = true
	_known_world_states = {}
	var ambient := _ambient_ref.get_ref() as VardhelmAmbientLife if _ambient_ref != null else null
	if ambient != null:
		for runtime_state_id in ambient.environment_states:
			if bool(ambient.environment_states[runtime_state_id]):
				_known_world_states[str(runtime_state_id)] = true
	for tracked in _tracked_npcs:
		var npc := (tracked["ref"] as WeakRef).get_ref() as NPCController
		if npc != null:
			tracked["interaction_enabled"] = npc.interaction_enabled


# ---------------------------------------------------------------------------
# Cenário
# ---------------------------------------------------------------------------

func publish_scenario_entered(scenario_id: String = GameIdCatalog.SCENARIO_VARDHELM) -> void:
	var canonical := _canonical(GameIdCatalog.KIND_SCENARIO, scenario_id)
	if not canonical.is_empty():
		_publish(GameEventCatalog.SCENARIO_ENTERED, {"scenario_id": canonical}, SOURCE_EXPERIENCE)


## Preparado para quando existir um encerramento real. Nenhum ponto do
## gameplay atual chama este método.
func publish_scenario_completed(scenario_id: String) -> void:
	var canonical := _canonical(GameIdCatalog.KIND_SCENARIO, scenario_id)
	if not canonical.is_empty():
		_publish(GameEventCatalog.SCENARIO_COMPLETED, {"scenario_id": canonical}, SOURCE_EXPERIENCE)


# ---------------------------------------------------------------------------
# Conexão com sinais existentes
# ---------------------------------------------------------------------------

## A escolha só é aceita pela DialogueBox (choice_requested) e o slice avança a
## sessão no mesmo instante; por isso este observador deve ser conectado ANTES
## dos handlers do VardhelmVerticalSlice.
func observe_dialogue(controller: DialogueController, box: DialogueBox = null) -> void:
	if controller == null:
		return
	_dialogue_controller_ref = weakref(controller)
	controller.dialogue_started.connect(_on_dialogue_started)
	controller.dialogue_finished.connect(_on_dialogue_finished)
	if box != null:
		box.choice_requested.connect(handle_choice_submitted)


func observe_quests(controller: QuestController) -> void:
	if controller == null:
		return
	controller.quest_started.connect(_on_quest_started)
	controller.objective_completed.connect(_on_objective_completed)
	controller.quest_completed.connect(_on_quest_completed)


func observe_narrative(controller: NarrativeController) -> void:
	if controller == null:
		return
	controller.consequence_applied.connect(_on_consequence_applied)


func observe_echo(echo: EchoMemoryInteractable) -> void:
	if echo == null:
		return
	echo.memory_revealed.connect(_on_echo_memory_revealed)


func observe_observation(observation: EnvironmentalObservation) -> void:
	if observation == null:
		return
	observation.observation_revealed.connect(_on_observation_revealed.bind(observation.memory_id))
	# Sinal que o runtime atual não conecta: aqui ele só vira evento.
	observation.memory_fragment_discovered.connect(_on_memory_fragment_discovered.bind(observation.observation_id))


func observe_npc(npc: NPCController) -> void:
	if npc == null:
		return
	var npc_id := _canonical(GameIdCatalog.KIND_NPC, npc.npc_id)
	if npc_id.is_empty():
		return
	_tracked_npcs.append({"ref": weakref(npc), "npc_id": npc_id, "interaction_enabled": npc.interaction_enabled})


## Reações do mundo (estados de ambiente derivados). Deve ser chamado DEPOIS de
## a experiência conectar seus próprios handlers: assim a verificação roda
## após a reação do AmbientLife à consequência, preservando a ordem causal.
func observe_world_reactions(narrative: NarrativeController, ambient_life: VardhelmAmbientLife) -> void:
	if ambient_life == null:
		return
	_ambient_ref = weakref(ambient_life)
	for state_id in ambient_life.environment_states:
		_known_world_states[str(state_id)] = true
	if narrative != null:
		narrative.consequence_applied.connect(_on_consequence_effects_settled)


## Verifica estados sem sinal (NPC e ambiente) e publica só mudanças reais.
func poll() -> void:
	_poll_npcs()
	_poll_world_states()


# ---------------------------------------------------------------------------
# Handlers
# ---------------------------------------------------------------------------

## Escolha submetida pela UI. Publica só se a escolha existe na entrada atual
## (mesma condição em que DialogueController.select_choice a aceita).
func handle_choice_submitted(choice_id: String) -> void:
	var controller := _dialogue_controller()
	if controller == null or not controller.is_active():
		return
	var entry := controller.get_current_entry()
	if entry == null:
		return
	for choice: DialogueChoice in entry.choices:
		if choice.choice_id == choice_id:
			var dialogue_id := _canonical(GameIdCatalog.KIND_DIALOGUE, controller.current_session.dialogue.dialogue_id)
			if not dialogue_id.is_empty():
				_publish(GameEventCatalog.DIALOGUE_CHOICE_SELECTED, {
					"dialogue_id": dialogue_id,
					"entry_id": entry.entry_id,
					"choice_id": choice_id,
				}, SOURCE_DIALOGUE)
			return


func _on_dialogue_started(dialogue: DialogueData) -> void:
	if dialogue == null:
		return
	var dialogue_id := _canonical(GameIdCatalog.KIND_DIALOGUE, dialogue.dialogue_id)
	if not dialogue_id.is_empty():
		_publish(GameEventCatalog.DIALOGUE_STARTED, {"dialogue_id": dialogue_id}, SOURCE_DIALOGUE)


func _on_dialogue_finished(dialogue: DialogueData) -> void:
	if dialogue == null:
		return
	var dialogue_id := _canonical(GameIdCatalog.KIND_DIALOGUE, dialogue.dialogue_id)
	if not dialogue_id.is_empty():
		_publish(GameEventCatalog.DIALOGUE_COMPLETED, {"dialogue_id": dialogue_id}, SOURCE_DIALOGUE)


func _on_quest_started(runtime_quest_id: String) -> void:
	var quest_id := _canonical(GameIdCatalog.KIND_QUEST, runtime_quest_id)
	if not quest_id.is_empty():
		_publish(GameEventCatalog.QUEST_STARTED, {"quest_id": quest_id}, SOURCE_QUEST)


func _on_objective_completed(runtime_quest_id: String, objective_id: String) -> void:
	var quest_id := _canonical(GameIdCatalog.KIND_QUEST, runtime_quest_id)
	if not quest_id.is_empty():
		_publish(GameEventCatalog.QUEST_PROGRESSED, {"quest_id": quest_id, "objective_id": objective_id}, SOURCE_QUEST)


func _on_quest_completed(runtime_quest_id: String) -> void:
	var quest_id := _canonical(GameIdCatalog.KIND_QUEST, runtime_quest_id)
	if not quest_id.is_empty():
		_publish(GameEventCatalog.QUEST_COMPLETED, {"quest_id": quest_id}, SOURCE_QUEST)


func _on_consequence_applied(runtime_consequence_id: String) -> void:
	var consequence_id := _canonical(GameIdCatalog.KIND_CONSEQUENCE, runtime_consequence_id)
	if consequence_id.is_empty():
		return
	if _published_consequences.has(consequence_id):
		suppressed_repeats.append("%s: reaplicação de %s (já aplicada)" % [GameEventCatalog.CONSEQUENCE_APPLIED, consequence_id])
		return
	_published_consequences[consequence_id] = true
	var payload := {"consequence_id": consequence_id}
	var source: Dictionary = GameIdCatalog.CONSEQUENCE_SOURCES.get(consequence_id, {})
	if source.has("source_type") and source.has("source_id"):
		payload["source_type"] = String(source["source_type"])
		payload["source_id"] = String(source["source_id"])
	_publish(GameEventCatalog.CONSEQUENCE_APPLIED, payload, SOURCE_NARRATIVE)


## Handler tardio (conectado depois da experiência): efeitos da consequência já
## aplicados pelo AmbientLife.
func _on_consequence_effects_settled(_runtime_consequence_id: String) -> void:
	_poll_world_states()


## Eco resolvido: echo_triggered seguido de memory_recovered (decisão A1 #2).
func _on_echo_memory_revealed(runtime_memory_id: String) -> void:
	var memory_id := _canonical(GameIdCatalog.KIND_MEMORY, runtime_memory_id)
	if memory_id.is_empty():
		return
	var echo_id := ""
	for candidate in GameIdCatalog.ECHOES:
		if GameIdCatalog.ECHOES[candidate]["memory_id"] == memory_id:
			echo_id = String(candidate)
	if echo_id.is_empty():
		diagnostics.append("echo: memória '%s' sem Eco no GameIdCatalog" % runtime_memory_id)
		return
	_publish(GameEventCatalog.ECHO_TRIGGERED, {"echo_id": echo_id}, SOURCE_ECHO)
	_publish(GameEventCatalog.MEMORY_RECOVERED, {
		"memory_id": memory_id,
		"source_type": GameMemoryState.SOURCE_ECHO,
		"source_id": echo_id,
	}, SOURCE_ECHO)


func _on_observation_revealed(runtime_observation_id: String, _title_key: String, _text_key: String, runtime_memory_id: String) -> void:
	var observation_id := _canonical(GameIdCatalog.KIND_OBSERVATION, runtime_observation_id)
	if observation_id.is_empty():
		return
	if _discovered_observations.has(observation_id):
		suppressed_repeats.append("%s: reexame de %s (já descoberta)" % [GameEventCatalog.OBSERVATION_DISCOVERED, observation_id])
		return
	_discovered_observations[observation_id] = true
	var payload := {"observation_id": observation_id}
	var memory_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_MEMORY, runtime_memory_id)
	if not memory_id.is_empty():
		payload["memory_id"] = memory_id
	_publish(GameEventCatalog.OBSERVATION_DISCOVERED, payload, SOURCE_OBSERVATION)


## Fragmento de memória de uma observação (decisão A1 #1). Sem consequência.
func _on_memory_fragment_discovered(runtime_memory_id: String, _category: String, _title_key: String, _text_key: String, runtime_observation_id: String) -> void:
	var memory_id := _canonical(GameIdCatalog.KIND_MEMORY, runtime_memory_id)
	var observation_id := _canonical(GameIdCatalog.KIND_OBSERVATION, runtime_observation_id)
	if memory_id.is_empty() or observation_id.is_empty():
		return
	_publish(GameEventCatalog.MEMORY_RECOVERED, {
		"memory_id": memory_id,
		"source_type": GameMemoryState.SOURCE_OBSERVATION,
		"source_id": observation_id,
	}, SOURCE_OBSERVATION)


# ---------------------------------------------------------------------------

func _poll_npcs() -> void:
	for tracked in _tracked_npcs:
		var npc := (tracked["ref"] as WeakRef).get_ref() as NPCController
		if npc == null or npc.interaction_enabled == bool(tracked["interaction_enabled"]):
			continue
		tracked["interaction_enabled"] = npc.interaction_enabled
		_publish(GameEventCatalog.NPC_STATE_CHANGED, {
			"npc_id": String(tracked["npc_id"]),
			"interaction_enabled": npc.interaction_enabled,
		}, SOURCE_NPC)


func _poll_world_states() -> void:
	if _ambient_ref == null:
		return
	var ambient := _ambient_ref.get_ref() as VardhelmAmbientLife
	if ambient == null:
		return
	for runtime_state_id in ambient.environment_states:
		var key := str(runtime_state_id)
		if _known_world_states.has(key) or not bool(ambient.environment_states[runtime_state_id]):
			continue
		_known_world_states[key] = true
		var state_id := _canonical(GameIdCatalog.KIND_ENVSTATE, key)
		if not state_id.is_empty():
			_publish(GameEventCatalog.WORLD_STATE_CHANGED, {"state_id": state_id}, SOURCE_WORLD)


func _publish(event_type: String, payload: Dictionary, source: String) -> void:
	if _bus.publish(event_type, payload, source) == null:
		diagnostics.append("evento rejeitado pelo catálogo: %s %s" % [event_type, JSON.stringify(payload)])
	# Fronteira de evento: estados sem sinal só mudam em resposta a gameplay.
	if event_type != GameEventCatalog.NPC_STATE_CHANGED and event_type != GameEventCatalog.WORLD_STATE_CHANGED:
		_poll_npcs()


func _dialogue_controller() -> DialogueController:
	if _dialogue_controller_ref == null:
		return null
	return _dialogue_controller_ref.get_ref() as DialogueController


func _canonical(kind: String, runtime_id: String) -> String:
	var canonical := GameIdCatalog.canonical_id(kind, runtime_id)
	if canonical.is_empty():
		diagnostics.append("%s: ID '%s' fora do GameIdCatalog; evento não publicado" % [kind, runtime_id])
	return canonical
