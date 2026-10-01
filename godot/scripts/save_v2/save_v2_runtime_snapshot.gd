class_name SaveV2RuntimeSnapshot
extends RefCounted

## Bloco C7 — snapshot TRANSITÓRIO do runtime principal, tirado depois do
## rehearsal e antes do apply de um Load V2. Existe só durante a operação:
## nunca é gravado (sem arquivo, sem user://), não é save do jogador e não
## substitui o GameState sombra.
##
##   state      GameState projetado do runtime (+ NPCs + cenário) — é o que o
##              rollback restaura, pelo MESMO restaurador/adapters do C3–C5
##   raw        cópia exata das estruturas persistentes do runtime (verificação)
##   functional estados derivados lidos pelo RuntimeStateDerivationContract
##
## Não captura câmera, UI transitória, áudio, timers, animações, input ou efeitos.

var state: GameState = null
## Itens que a projeção não conseguiu representar (snapshot não reversível).
var quarantined: Array[String] = []
var raw: Dictionary = {}
var player_position: Vector3 = Vector3.ZERO
var player_rotation: Vector3 = Vector3.ZERO
var functional: Dictionary = {}


static func capture(targets: RuntimeRestoreTargets) -> SaveV2RuntimeSnapshot:
	var snapshot := SaveV2RuntimeSnapshot.new()
	var projection := project(targets)
	snapshot.state = projection["state"]
	snapshot.quarantined = projection["quarantined"]
	snapshot.raw = raw_of(targets)
	snapshot.player_position = targets.player.global_position
	snapshot.player_rotation = targets.player.global_rotation
	snapshot.functional = describe(targets)
	return snapshot


## Projeção COMPLETA do estado persistente do runtime como GameState: player
## (posição, rotação, cenário), world, consequences, observations, quests,
## diálogo persistente, memória e NPCs. Nada derivado nem transitório. Usada pelo
## snapshot (C7) e pelo Save V2 operacional (C8).
## Retorna {"state": GameState, "quarantined": Array[String]}.
static func project(targets: RuntimeRestoreTargets) -> Dictionary:
	var projection := GameStateProjector.project(targets.world_state, targets.quest_state, targets.player, targets.dialogue_state)
	var state := projection.state
	state.player.scenario_id = targets.scenario_id
	for npc_id in targets.npcs:
		var npc := targets.npcs[npc_id] as NPCController
		if npc != null and not npc.interaction_enabled:
			state.npcs.set_interaction_enabled(String(npc_id), false)
	var quarantined: Array[String] = []
	for path in projection.quarantined:
		quarantined.append(String(path))
	return {"state": state, "quarantined": quarantined}


## Estruturas persistentes do runtime, em forma comparável (memórias como
## conjunto: a ordem de WorldState.memories não é preservada — limitação C3).
static func raw_of(targets: RuntimeRestoreTargets) -> Dictionary:
	var memories: Array = []
	for memory_id in targets.world_state.memories:
		memories.append(String(memory_id))
	memories.sort()
	var npcs := {}
	for npc_id in targets.npcs:
		var npc := targets.npcs[npc_id] as NPCController
		npcs[String(npc_id)] = npc.interaction_enabled if npc != null else null
	return {
		"scenario_id": targets.scenario_id,
		"flags": targets.world_state.flags.duplicate(true),
		"values": targets.world_state.values.duplicate(true),
		"memories": memories,
		"quests_active": targets.quest_state.active.duplicate(true),
		"quests_completed": targets.quest_state.completed.duplicate(true),
		"objective_progress": targets.quest_state.objective_progress.duplicate(true),
		"dialogue": targets.dialogue_state.to_dict() if targets.dialogue_state != null else {},
		"npcs": npcs,
	}


## Estados derivados pelo contrato formal (C5): observações, Ecos, apresentação
## da quest e estados de ambiente. Nada de UI transitória.
static func describe(targets: RuntimeRestoreTargets) -> Dictionary:
	var derivations := targets.derivations if targets.derivations != null else RuntimeStateDerivationContract.new()
	var observations := {}
	for observation_id in derivations.observation_ids():
		observations[observation_id] = derivations.describe_observation(observation_id)
	var echoes := {}
	for echo_id in derivations.echo_ids():
		echoes[echo_id] = derivations.describe_echo(echo_id)
	var quests := {}
	for quest_id in GameIdCatalog.KNOWN_IDS.get(GameIdCatalog.KIND_QUEST, []):
		var described := derivations.describe_quest_presentation(String(quest_id))
		if not described.is_empty():
			quests[String(quest_id)] = described
	var environment := derivations.environment_state_ids()
	environment.sort()
	return {"observations": observations, "echoes": echoes, "quests": quests, "environment": environment}


## Diferenças entre o runtime atual e este snapshot ([] = idêntico).
func differences(targets: RuntimeRestoreTargets) -> Array[String]:
	var out: Array[String] = []
	var current := raw_of(targets)
	for key in raw:
		if JSON.stringify(current.get(key), "", true) != JSON.stringify(raw[key], "", true):
			out.append("raw.%s" % key)
	if not targets.player.global_position.is_equal_approx(player_position):
		out.append("player.position")
	if not targets.player.global_rotation.is_equal_approx(player_rotation):
		out.append("player.rotation")
	var current_functional := describe(targets)
	for key in functional:
		if JSON.stringify(current_functional.get(key), "", true) != JSON.stringify(functional[key], "", true):
			out.append("functional.%s" % key)
	return out
