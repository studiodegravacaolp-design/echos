class_name GameStateShadowRecorder
extends RefCounted

## GameState em MODO SOMBRA (Bloco A3), alimentado por EVENTOS ESTRUTURADOS
## desde o Bloco B1:
##
##   Gameplay -> GameplayEventPublisher -> GameEventBus -> GameStateShadowRecorder -> GameState
##
## O runtime atual (WorldState, QuestState e controladores) continua sendo a
## FONTE DE VERDADE. O recorder é o ÚNICO que escreve no GameState: o
## GameEventBus não conhece o GameState e o publisher não conhece o recorder
## (eventos e estado ficam separados). Nada daqui volta para o gameplay, e o
## recorder nunca chama o SaveService nem publica eventos.
##
## Dono: objeto de runtime da experiência (VardhelmVerticalSlice.shadow_state).
## Não é Autoload nem singleton; é liberado junto com a experiência.
##
## A localização do jogador não é evento (é contínua): é AMOSTRADA em
## sync_sampled_state()/snapshot().

var game_state: GameState = GameState.new()
## Eventos consumidos cujo conteúdo não pôde ser aplicado (ID fora do catálogo
## canônico). Nada é descartado em silêncio.
var diagnostics: Array[String] = []
## event_id de cada evento consumido, na ordem de chegada.
var consumed_event_ids: Array[String] = []

var _player_ref: WeakRef = null


# ---------------------------------------------------------------------------
# Ligação com o barramento e com o jogador
# ---------------------------------------------------------------------------

func attach(bus: GameEventBus) -> void:
	bus.subscribe(consume)


func detach(bus: GameEventBus) -> void:
	bus.unsubscribe(consume)


## Referência explícita ao jogador; posição/rotação são amostradas no sync.
func track_player(player: Node3D) -> void:
	_player_ref = weakref(player) if player != null else null


## Jogador acompanhado (somente leitura; null se ausente ou fora da árvore).
func tracked_player() -> Node3D:
	var player: Node3D = _player_ref.get_ref() as Node3D if _player_ref != null else null
	return player if player != null and player.is_inside_tree() else null


# ---------------------------------------------------------------------------
# Consumo de eventos -> GameState
# ---------------------------------------------------------------------------

func consume(event: GameEvent) -> void:
	if event == null:
		return
	consumed_event_ids.append(event.event_id)
	var p := event.payload
	var type := event.event_type
	if type == GameEventCatalog.SCENARIO_ENTERED:
		if _expect(GameIdCatalog.KIND_SCENARIO, p["scenario_id"], event):
			game_state.player.scenario_id = String(p["scenario_id"])
	elif type == GameEventCatalog.DIALOGUE_CHOICE_SELECTED:
		# Última escolha por ponto de decisão (decisão A1 #6), sem histórico.
		if _expect(GameIdCatalog.KIND_DIALOGUE, p["dialogue_id"], event):
			game_state.dialogue.record_choice(String(p["dialogue_id"]), String(p["entry_id"]), String(p["choice_id"]))
	elif type == GameEventCatalog.DIALOGUE_COMPLETED:
		if _expect(GameIdCatalog.KIND_DIALOGUE, p["dialogue_id"], event):
			game_state.dialogue.mark_completed(String(p["dialogue_id"]))
	elif type == GameEventCatalog.QUEST_STARTED:
		if _expect(GameIdCatalog.KIND_QUEST, p["quest_id"], event):
			game_state.quests.start_quest(String(p["quest_id"]))
	elif type == GameEventCatalog.QUEST_PROGRESSED:
		if _expect(GameIdCatalog.KIND_QUEST, p["quest_id"], event):
			var quest_id := String(p["quest_id"])
			# Mesma regra do projetor: progresso sem registro implica quest ativa.
			if game_state.quests.get_status(quest_id) == GameQuestState.STATUS_NOT_STARTED:
				game_state.quests.start_quest(quest_id)
			game_state.quests.set_objective_complete(quest_id, String(p["objective_id"]))
	elif type == GameEventCatalog.QUEST_COMPLETED:
		# Só o status: a quest não aplica consequência (decisões A1 #4/#5).
		if _expect(GameIdCatalog.KIND_QUEST, p["quest_id"], event):
			game_state.quests.complete_quest(String(p["quest_id"]))
	elif type == GameEventCatalog.CONSEQUENCE_APPLIED:
		_apply_consequence(p, event)
	elif type == GameEventCatalog.ECHO_TRIGGERED:
		if _expect(GameIdCatalog.KIND_ECHO, p["echo_id"], event):
			game_state.memory.resolve_echo(String(p["echo_id"]))
	elif type == GameEventCatalog.MEMORY_RECOVERED:
		_apply_memory(p, event)
	elif type == GameEventCatalog.OBSERVATION_DISCOVERED:
		_apply_observation(p, event)
	elif type == GameEventCatalog.NPC_STATE_CHANGED:
		if _expect(GameIdCatalog.KIND_NPC, p["npc_id"], event) and p.has("interaction_enabled"):
			game_state.npcs.set_interaction_enabled(String(p["npc_id"]), bool(p["interaction_enabled"]))
	# dialogue_started (sessão transitória), world_state_changed (estado de
	# ambiente é derivado, A1 §3.3), scenario_completed (sem seção de cenário
	# ainda) e game_saved/game_loaded (Bloco C) não alteram o GameState.


## Consequência -> world.consequences (nunca memory.memories) + espelho da
## flag legada de mesmo nome que o runtime grava (compatibilidade).
func _apply_consequence(p: Dictionary, event: GameEvent) -> void:
	var consequence_id := String(p["consequence_id"])
	if not _expect(GameIdCatalog.KIND_CONSEQUENCE, consequence_id, event):
		return
	var legacy_flag := GameIdCatalog.legacy_id(GameIdCatalog.KIND_CONSEQUENCE, consequence_id)
	if not legacy_flag.is_empty():
		game_state.world.set_flag(legacy_flag, true)
	game_state.world.apply_consequence(consequence_id, String(p.get("source_type", "")), String(p.get("source_id", "")))


## Memória (Eco ou fragmento de observação). Registrar memória não cria
## consequência nem reação (decisão A1 #3).
func _apply_memory(p: Dictionary, event: GameEvent) -> void:
	var memory_id := String(p["memory_id"])
	var source_type := String(p["source_type"])
	if not _expect(GameIdCatalog.KIND_MEMORY, memory_id, event) or not _expect(source_type, p["source_id"], event):
		return
	game_state.memory.register_memory(memory_id, source_type, String(p["source_id"]))


## Observação -> world.observations + espelho da flag "observation_<id>_seen".
func _apply_observation(p: Dictionary, event: GameEvent) -> void:
	var observation_id := String(p["observation_id"])
	if not _expect(GameIdCatalog.KIND_OBSERVATION, observation_id, event):
		return
	var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_OBSERVATION, observation_id)
	if not legacy.is_empty():
		game_state.world.set_flag("%s%s%s" % [
			GameIdCatalog.LEGACY_OBSERVATION_FLAG_PREFIX, legacy, GameIdCatalog.LEGACY_OBSERVATION_FLAG_SUFFIX,
		], true)
	game_state.world.discover_observation(observation_id)


# ---------------------------------------------------------------------------
# Amostragem, snapshot e comparação
# ---------------------------------------------------------------------------

## Copia do runtime a localização do jogador (global_position/global_rotation,
## os mesmos campos do SaveService).
func sync_sampled_state() -> void:
	var player: Node3D = _player_ref.get_ref() as Node3D if _player_ref != null else null
	if player != null and player.is_inside_tree():
		game_state.player.position = player.global_position
		game_state.player.rotation = player.global_rotation


## Estado sombra serializado (após amostragem).
func snapshot() -> Dictionary:
	sync_sampled_state()
	return game_state.to_dict()


## Compara o GameState sombra com a projeção do runtime atual. Não corrige,
## não sobrescreve o GameState sombra e não publica eventos.
func compare_with_runtime(world_state: WorldState, quest_state: QuestState) -> GameStateComparison:
	sync_sampled_state()
	var player: Node3D = _player_ref.get_ref() as Node3D if _player_ref != null else null
	var projection := GameStateProjector.project(world_state, quest_state, player if player != null and player.is_inside_tree() else null)
	return GameStateComparator.compare(game_state, projection.state, "shadow", "projection")


# ---------------------------------------------------------------------------

## O evento traz IDs canônicos; qualquer outro valor é registrado em
## diagnostics e não entra no GameState.
func _expect(kind: String, id: Variant, event: GameEvent) -> bool:
	var known: Array = GameIdCatalog.KNOWN_IDS.get(kind, [])
	if typeof(id) == TYPE_STRING and known.has(id):
		return true
	diagnostics.append("%s %s: %s '%s' fora do catálogo canônico; não aplicado" % [event.event_id, event.event_type, kind, str(id)])
	return false
