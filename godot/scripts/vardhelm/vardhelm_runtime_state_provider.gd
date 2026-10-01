class_name VardhelmRuntimeStateProvider
extends RuntimeStateDerivationContract

## Bloco C5 — implementação Vardhelm do RuntimeStateDerivationContract.
##
## Encapsula TODO o conhecimento específico do Vardhelm usado na restauração em
## sandbox: nós, caminhos, AmbientLife, apresentação e as derivações existentes
## da experiência (pela superfície pública derive_* do VardhelmVerticalSlice).
## O Save V2 e os adapters só enxergam o contrato.
##
## Não guarda estado, cópias nem cache: cada consulta lê o runtime na hora.
## Identidade por ID canônico (GameIdCatalog); nenhum NodePath é exposto.

const OBSERVATION_ROOT := "AmbientLife/EnvironmentalObservations"
const AMBIENT_LIFE := "AmbientLife"

var _slice: VardhelmVerticalSlice


func _init(slice: VardhelmVerticalSlice) -> void:
    _slice = slice


## Alvos de restauração desta experiência. NÃO declara sandbox: quem chama
## decide explicitamente (targets.is_sandbox = true).
func build_targets() -> RuntimeRestoreTargets:
    var targets := RuntimeRestoreTargets.new()
    if not _available():
        return targets
    targets.scenario_id = GameIdCatalog.SCENARIO_VARDHELM
    targets.player = _slice.player
    targets.world_state = _slice.narrative_controller.world_state
    targets.quest_state = _slice.quest_controller.states
    var npc_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_NPC, _slice.npc.npc_id)
    if not npc_id.is_empty():
        targets.npcs = {npc_id: _slice.npc}
    targets.dialogue_state = _slice.dialogue_controller.persistent_state
    # C12: todas as conversas do Vardhelm (inicial + pós-Eco), para validar escolhas.
    var definitions := {}
    for data in [_slice.dialogue_data, _slice.after_echo_dialogue_data, _slice.after_panel_dialogue_data]:
        if data == null:
            continue
        var dialogue_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_DIALOGUE, data.dialogue_id)
        if not dialogue_id.is_empty():
            definitions[dialogue_id] = data
    targets.dialogue_definitions = definitions
    targets.derivations = self
    return targets


# --- observações ---------------------------------------------------------------

func observation_ids() -> Array[String]:
    var ids: Array[String] = []
    for node in _observation_nodes():
        var observation_id := GameIdCatalog.canonical_id(GameIdCatalog.KIND_OBSERVATION, node.observation_id)
        if not observation_id.is_empty():
            ids.append(observation_id)
    return ids


## Mesmo estado que EnvironmentalObservation.interact() deixa: revelada e, se a
## observação tem fragmento, fragmento já registrado (não é emitido de novo).
func derive_observation_state(observation_id: String, discovered: bool) -> bool:
    var node := _observation(observation_id)
    if node == null:
        return false
    node.revealed = discovered
    node.memory_registered = discovered and not node.memory_id.is_empty()
    return true


func describe_observation(observation_id: String) -> Dictionary:
    var node := _observation(observation_id)
    if node == null:
        return {}
    return {"revealed": node.revealed, "fragment_registered": node.memory_registered}


# --- Eco -----------------------------------------------------------------------

func echo_ids() -> Array[String]:
    var ids: Array[String] = []
    if _available() and _slice.echo != null:
        ids.append(GameIdCatalog.ECHO_FIRST)
    return ids


func derive_echo_state() -> bool:
    if not _available() or _slice.echo == null:
        return false
    _slice.derive_echo_state()
    return true


## Só estado funcional. A visibilidade da esfera fica de fora do contrato
## (KNOWN GAMEPLAY BUG: EchoMemoryInteractable guarda o nó visual antes de ele existir).
func describe_echo(echo_id: String) -> Dictionary:
    if echo_id != GameIdCatalog.ECHO_FIRST or not _available() or _slice.echo == null:
        return {}
    return {"revealed": _slice.echo.revealed, "interaction_enabled": _slice.echo.interaction_enabled}


# --- apresentação da quest -----------------------------------------------------

func derive_quest_presentation() -> bool:
    if not _available():
        return false
    _slice.derive_quest_presentation()
    return true


func describe_quest_presentation(quest_id: String) -> Dictionary:
    var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_QUEST, quest_id)
    if not _available() or not [VardhelmVerticalSlice.QUEST_ID, VardhelmVerticalSlice.FOLLOWUP_QUEST_ID].has(legacy):
        return {}
    return {"completion_presented": _slice.is_quest_completion_presented(legacy)}


# --- ambiente ------------------------------------------------------------------

func derive_environment_state() -> bool:
    if _ambient_life() == null:
        return false
    _slice.derive_environment_state()
    return true


func environment_state_ids() -> Array[String]:
    var ids: Array[String] = []
    var ambient := _ambient_life()
    if ambient == null:
        return ids
    for state_id in ambient.environment_states:
        var canonical := GameIdCatalog.canonical_id(GameIdCatalog.KIND_ENVSTATE, str(state_id))
        ids.append(canonical if not canonical.is_empty() else str(state_id))
    return ids


# --- interno -------------------------------------------------------------------

func _available() -> bool:
    return is_instance_valid(_slice)


func _ambient_life() -> VardhelmAmbientLife:
    if not _available():
        return null
    return _slice.get_node_or_null(AMBIENT_LIFE) as VardhelmAmbientLife


func _observation_nodes() -> Array[EnvironmentalObservation]:
    var nodes: Array[EnvironmentalObservation] = []
    if not _available():
        return nodes
    # C21: a Forja 01 e o pátio das fundições (as raízes vêm do slice).
    var roots: Array = _slice.observation_roots() if _slice.has_method("observation_roots") else [_slice.get_node_or_null(OBSERVATION_ROOT)]
    for root in roots:
        if root == null:
            continue
        for child in root.get_children():
            if child is EnvironmentalObservation:
                nodes.append(child)
    return nodes


func _observation(observation_id: String) -> EnvironmentalObservation:
    var legacy := GameIdCatalog.legacy_id(GameIdCatalog.KIND_OBSERVATION, observation_id)
    if legacy.is_empty():
        return null
    for node in _observation_nodes():
        if node.observation_id == legacy:
            return node
    return null


# --- sessão transitória (C8) ---------------------------------------------------

## Conversa em andamento ou caixa de diálogo visível: estado transitório.
func is_dialogue_session_open() -> bool:
    if not _available():
        return false
    return _slice.dialogue_controller.is_active() or (_slice.dialogue_box != null and _slice.dialogue_box.visible)
