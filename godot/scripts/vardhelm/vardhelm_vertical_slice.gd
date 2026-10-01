class_name VardhelmVerticalSlice
extends Node3D

const VARDHELM_LIFE := preload("res://scripts/vardhelm/vardhelm_ambient_life.gd")

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const NPC_SCENE := preload("res://scenes/npc/npc.tscn")
const DIALOGUE_BOX_SCENE := preload("res://scenes/ui/dialogue_box.tscn")
const JSON_LOADER := preload("res://scripts/data/json_data_loader.gd")
const VARDHELM_DRESSING := preload("res://scripts/vardhelm/vardhelm_set_dressing.gd")

const DIALOGUE_PATH := "res://data/dialogue/vardhelm_intro.json"
const QUEST_PATH := "res://data/quests/vardhelm_first_echo.json"
# C12: ponte narrativa pós-Primeiro Eco (dados + localização; sistemas existentes).
const AFTER_ECHO_DIALOGUE_PATH := "res://data/dialogue/vardhelm_after_echo.json"
const FOLLOWUP_QUEST_PATH := "res://data/quests/vardhelm_sealed_panel.json"
const AFTER_ECHO_DIALOGUE_ID := "vardhelm_after_echo"
## Depois de concluída, a conversa pós-Eco não se repete: Durn só retoma a pista.
const AFTER_ECHO_REMINDER_ENTRY := "clue"
const FOLLOWUP_QUEST_ID := "vardhelm_sealed_panel"
const FOLLOWUP_OBJECTIVE_ID := "listen"
const FOLLOWUP_OBSERVATION_ID := "sealed_panel"
const FOLLOWUP_OBJECTIVE_KEY := "quest.vardhelm.sealed_panel.objective.listen"
# C13: status da conclusão do Eco; sai quando a próxima etapa começa.
const ECHO_DONE_STATUS := "Você registrou o primeiro Eco. Ctrl+S salva seu progresso."
const FOLLOWUP_DONE_KEY := "quest.vardhelm.sealed_panel.done"
# C14: encerramento da primeira sequência. Depois do painel, Durn diz uma última coisa
# (uma vez) e, nas próximas, fica em silêncio. Sem escolha e sem explicação.
const AFTER_PANEL_DIALOGUE_PATH := "res://data/dialogue/vardhelm_after_panel.json"
const AFTER_PANEL_DIALOGUE_ID := "vardhelm_after_panel"
const AFTER_PANEL_SILENT_ENTRY := "quiet"
# C16: o que Durn deixa no lugar de sempre quando sai sozinho (caminho "Não senti nada.").
const DURN_NOTES_OBSERVATION_ID := "durn_notes"
const LOCALE_PATH := "res://data/localization/pt-BR.json"
# C18: tempos do ciclo de vida das janelas contextuais (dados).
const CONTEXTUAL_WINDOWS_PATH := "res://data/ui/contextual_windows.json"
const QUEST_ID := "vardhelm_first_echo"
const OBJECTIVE_ID := "observe"
# C11: prioridade de interação de Durn = a das observações (2): o detector escolhe o
# mais próximo entre eles. O Eco (10) continua acima.
const NPC_INTERACTION_PRIORITY := 2

var dialogue_controller: DialogueController
var quest_controller: QuestController
var narrative_controller: NarrativeController
var localization: LocalizationService
var save_service: SaveService
var dialogue_box: DialogueBox
var dialogue_data: DialogueData
var quest_data: QuestData
var after_echo_dialogue_data: DialogueData
var followup_quest_data: QuestData
var after_panel_dialogue_data: DialogueData

var objective_panel: PanelContainer
var objective_label: Label
var status_label: Label
var interaction_hint: PanelContainer
var interaction_hint_label: Label
## C18: ciclo de vida da dica "E • …" (abre, espera ao sair, cancela ao voltar, fecha).
var hint_lifecycle: ContextualWindowLifecycle
## C21: o pátio sob a Forja 01 (vida, talha, atmosfera e reação derivada).
var foundry_district: VardhelmFoundryDistrict
var memory_panel: PanelContainer
var memory_title: Label
var memory_text: Label
var echo_memory_timer: SceneTreeTimer
var completion_banner: PanelContainer
var completion_label: Label
var observation_panel: PanelContainer
var memory_notification_panel: PanelContainer
var memory_notification_title: Label
var memory_notification_text: Label
var memory_count_label: Label
var observation_title: Label
var observation_text: Label
var observation_timer: SceneTreeTimer

var player: PlayerController
var npc: NPCController
var echo: EchoMemoryInteractable
var _npc_interactable: Interactable
var _durn_label: Label3D
var _post_echo_marker: MeshInstance3D
## C15: lugar de sempre de Durn e a caminhada dele quando fica sozinho.
var _durn_home: Transform3D
var _durn_walk: Tween = null

## Bloco A3 — GameState em modo sombra. Acompanha o runtime; NÃO é fonte de verdade.
var shadow_state: GameStateShadowRecorder
## Bloco B1 — eventos estruturados (objetos da experiência; sem Autoload).
var shadow_events: GameEventBus
var shadow_publisher: GameplayEventPublisher
## Bloco C2 — Save V2 sombra em paralelo ao SaveService (que segue operacional).
var shadow_save_v2: SaveV2ShadowCoordinator
# Blocos C7/C10.5: SAVE_V2_OPERATIONAL_LOAD/SAVE_ENABLED — padrão ON desde o C10.5
# (Ctrl+S/Ctrl+L usam só o V2; o legado só roda com as flags desligadas explicitamente).
var save_v2_operational_config: SaveV2OperationalConfig = SaveV2OperationalConfig.new()
var last_v2_load_result: SaveV2RuntimeLoadResult = null
var last_v2_save_result: SaveV2RuntimeSaveResult = null
# Bloco C9: mensagem transitória de Save/Load V2 (texto localizado).
const SAVE_V2_MESSAGE_SECONDS := 4.0
# Bloco C10: tamanho da mensagem de Save/Load (o status comum usa 12).
const SAVE_V2_MESSAGE_FONT_SIZE := 18
var _save_v2_message := ""
var _status_before_save_v2_message := ""

func _ready() -> void:
    _setup_services()
    _setup_ui()
    _spawn_runtime_content()
    _setup_vardhelm_dressing()
    _setup_vardhelm_ambient_life()
    _setup_foundry_district()
    _setup_shadow_game_state()
    _connect_systems()
    _setup_shadow_world_observer()
    _start_intro_state()
    _refresh_persistent_world_state()

func _setup_services() -> void:
    dialogue_controller = DialogueController.new()
    dialogue_controller.name = "DialogueController"
    add_child(dialogue_controller)

    quest_controller = QuestController.new()
    quest_controller.name = "QuestController"
    add_child(quest_controller)

    narrative_controller = NarrativeController.new()
    narrative_controller.name = "NarrativeController"
    add_child(narrative_controller)

    localization = LocalizationService.new()
    localization.name = "LocalizationService"
    add_child(localization)
    localization.register_catalog("pt-BR", JSON_LOADER.read_dictionary(LOCALE_PATH))

    save_service = SaveService.new()
    save_service.name = "SaveService"
    add_child(save_service)

    dialogue_data = JSON_LOADER.load_dialogue(DIALOGUE_PATH)
    quest_data = JSON_LOADER.load_quest(QUEST_PATH)
    after_echo_dialogue_data = JSON_LOADER.load_dialogue(AFTER_ECHO_DIALOGUE_PATH)
    after_panel_dialogue_data = JSON_LOADER.load_dialogue(AFTER_PANEL_DIALOGUE_PATH)
    followup_quest_data = JSON_LOADER.load_quest(FOLLOWUP_QUEST_PATH)

func _setup_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "NarrativeUI"
    add_child(canvas)

    # C11: objetivo + status empilhados num container ancorado no topo esquerdo: o
    # status fica sempre abaixo do painel, qualquer que seja a altura do objetivo.
    var hud_top := VBoxContainer.new()
    hud_top.name = "HudTop"
    hud_top.position = Vector2(20, 18)
    hud_top.add_theme_constant_override("separation", 6)
    canvas.add_child(hud_top)

    objective_panel = PanelContainer.new()
    objective_panel.name = "ObjectivePanel"
    objective_panel.custom_minimum_size = Vector2(390, 76)
    objective_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    objective_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.055, 0.075, 0.92), Color(0.35, 0.75, 0.9, 0.75), 2, 10))
    hud_top.add_child(objective_panel)

    var objective_box := VBoxContainer.new()
    objective_box.add_theme_constant_override("separation", 4)
    objective_panel.add_child(objective_box)

    var objective_caption := Label.new()
    objective_caption.text = "VARDHELM"
    objective_caption.add_theme_color_override("font_color", Color("#6FE7FF"))
    objective_caption.add_theme_font_size_override("font_size", 13)
    objective_box.add_child(objective_caption)

    objective_label = Label.new()
    objective_label.name = "Objective"
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_label.add_theme_font_size_override("font_size", 18)
    objective_box.add_child(objective_label)

    status_label = Label.new()
    status_label.name = "Status"
    status_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    status_label.add_theme_color_override("font_color", Color("#C7D2DA"))
    status_label.add_theme_font_size_override("font_size", 12)
    hud_top.add_child(status_label)

    interaction_hint = PanelContainer.new()
    interaction_hint.name = "InteractionHint"
    interaction_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    interaction_hint.position = Vector2(-155, -78)
    interaction_hint.size = Vector2(310, 44)
    interaction_hint.visible = false
    interaction_hint.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.04, 0.05, 0.94), Color(0.43, 0.9, 1.0, 0.9), 2, 14))
    canvas.add_child(interaction_hint)

    interaction_hint_label = Label.new()
    interaction_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    interaction_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    interaction_hint_label.add_theme_font_size_override("font_size", 15)
    interaction_hint.add_child(interaction_hint_label)
    hint_lifecycle = ContextualWindowLifecycle.new()
    hint_lifecycle.name = "InteractionHintLifecycle"
    add_child(hint_lifecycle)
    hint_lifecycle.configure(interaction_hint, JSON_LOADER.read_dictionary(CONTEXTUAL_WINDOWS_PATH).get("interaction_hint", {}))

    dialogue_box = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
    dialogue_box.name = "DialogueBox"
    dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    # C10.5: offsets reais (24 px nas laterais, 36 px embaixo; cresce para cima). O
    # antigo size = (-48, 246) era descartado e a caixa passava da borda direita.
    dialogue_box.offset_left = 24
    dialogue_box.offset_right = -24
    dialogue_box.offset_top = -282
    dialogue_box.offset_bottom = -36
    dialogue_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
    canvas.add_child(dialogue_box)

    memory_panel = PanelContainer.new()
    memory_panel.name = "MemoryPanel"
    memory_panel.set_anchors_preset(Control.PRESET_CENTER)
    memory_panel.position = Vector2(-300, -120)
    memory_panel.size = Vector2(600, 240)
    memory_panel.visible = false
    memory_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.02, 0.07, 0.09, 0.96), Color(0.43, 0.9, 1.0, 0.95), 2, 16))
    canvas.add_child(memory_panel)

    var echo_memory_box := VBoxContainer.new()
    echo_memory_box.add_theme_constant_override("separation", 12)
    memory_panel.add_child(echo_memory_box)

    memory_title = Label.new()
    memory_title.text = "ECO DE MEMÓRIA"
    memory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    memory_title.add_theme_color_override("font_color", Color("#6FE7FF"))
    memory_title.add_theme_font_size_override("font_size", 26)
    echo_memory_box.add_child(memory_title)

    memory_text = Label.new()
    memory_text.text = "Um instante impossível atravessa sua memória."
    memory_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    memory_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    memory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    memory_text.add_theme_font_size_override("font_size", 20)
    echo_memory_box.add_child(memory_text)

    memory_notification_panel = PanelContainer.new()
    memory_notification_panel.name = "MemoryNotificationPanel"
    memory_notification_panel.visible = false
    # C10.5: ancorada no centro-inferior (antes: posição absoluta, fora do centro
    # e fora do lugar em janelas de outro formato). Mesmo tamanho (560x110).
    memory_notification_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    memory_notification_panel.offset_left = -280
    memory_notification_panel.offset_right = 280
    memory_notification_panel.offset_top = -128
    memory_notification_panel.offset_bottom = -18
    memory_notification_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    canvas.add_child(memory_notification_panel)

    var memory_notification_box := VBoxContainer.new()
    memory_notification_panel.add_child(memory_notification_box)

    memory_notification_title = Label.new()
    memory_notification_title.text = "MEMÓRIA REGISTRADA"
    memory_notification_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    memory_notification_box.add_child(memory_notification_title)

    memory_notification_text = Label.new()
    memory_notification_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    memory_notification_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    memory_notification_box.add_child(memory_notification_text)

    completion_banner = PanelContainer.new()
    completion_banner.name = "CompletionBanner"
    # C13: no HudTop, abaixo do objetivo e do status (antes, centralizado no topo,
    # cobria parte do objetivo em 1152×648 e em janelas estreitas).
    completion_banner.custom_minimum_size = Vector2(390, 56)
    completion_banner.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    completion_banner.visible = false
    completion_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.08, 0.06, 0.95), Color(0.45, 1.0, 0.65, 0.95), 2, 14))
    hud_top.add_child(completion_banner)

    completion_label = Label.new()
    completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    completion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    completion_label.add_theme_font_size_override("font_size", 19)
    completion_label.text = "✓ Primeiro Eco registrado"
    completion_banner.add_child(completion_label)

    observation_panel = PanelContainer.new()
    observation_panel.name = "ObservationPanel"
    observation_panel.set_anchors_preset(Control.PRESET_CENTER)
    observation_panel.position = Vector2(-330, -150)
    observation_panel.size = Vector2(660, 300)
    observation_panel.visible = false
    observation_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.045, 0.055, 0.97), Color(0.55, 0.82, 0.9, 0.95), 2, 16))
    canvas.add_child(observation_panel)

    var observation_box := VBoxContainer.new()
    observation_box.add_theme_constant_override("separation", 12)
    observation_panel.add_child(observation_box)

    observation_title = Label.new()
    observation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    observation_title.add_theme_color_override("font_color", Color("#6FE7FF"))
    observation_title.add_theme_font_size_override("font_size", 25)
    observation_box.add_child(observation_title)

    observation_text = Label.new()
    observation_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    observation_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    observation_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    observation_text.add_theme_font_size_override("font_size", 19)
    observation_box.add_child(observation_text)

func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style

func _spawn_runtime_content() -> void:
    var generated := get_node_or_null("VP01_Vardhelm/Generated")
    if generated == null:
        generated = get_node_or_null("Generated")

    var player_spawn := generated.get_node_or_null("Spawns/PlayerSpawn") if generated != null else null
    var npc_spawn := generated.get_node_or_null("Spawns/NPCSpawn") if generated != null else null

    player = PLAYER_SCENE.instantiate() as PlayerController
    player.name = "Player"
    add_child(player)
    if player_spawn != null:
        player.global_transform = player_spawn.global_transform

    npc = NPC_SCENE.instantiate() as NPCController
    npc.name = "Durn"
    npc.npc_id = "vardhelm.durn"
    npc.display_name = "Durn"
    add_child(npc)
    if npc_spawn != null:
        npc.global_transform = npc_spawn.global_transform
    _durn_home = npc.global_transform
    _style_durn()

    var bridge := NPCDialogueBridge.new()
    bridge.name = "DialogueBridge"
    bridge.dialogue = dialogue_data
    bridge.start_entry_id = "start"
    npc.add_child(bridge)

    _npc_interactable = npc.get_node("Interactable") as Interactable
    # C11: antes (0) as observações (2, sempre examináveis) ganhavam de Durn mesmo
    # com ele mais perto: o quadro ao lado dele recebia o E e a conversa não abria.
    # Mesma prioridade = vence o mais próximo (regra existente do InteractionDetector).
    _npc_interactable.interaction_priority = NPC_INTERACTION_PRIORITY

    echo = EchoMemoryInteractable.new()
    echo.name = "FirstEcho"
    echo.memory_id = "vardhelm_first_echo_memory"
    echo.consequence_id = "vardhelm_first_echo_complete"
    echo.quest_id = QUEST_ID
    echo.objective_id = OBJECTIVE_ID
    echo.position = Vector3(2.5, 1.0, -3.0)
    add_child(echo)

    var echo_shape := CollisionShape3D.new()
    var echo_sphere := SphereShape3D.new()
    echo_sphere.radius = 1.15
    echo_shape.shape = echo_sphere
    echo.add_child(echo_shape)

    var mesh := MeshInstance3D.new()
    mesh.name = "Visual"
    var sphere := SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#6FE7FF")
    material.emission_enabled = true
    material.emission = Color("#6FE7FF")
    material.emission_energy_multiplier = 3.0
    material.metallic = 0.15
    material.roughness = 0.25
    sphere.material = material
    mesh.mesh = sphere
    echo.add_child(mesh)

    var light := OmniLight3D.new()
    light.name = "Light"
    light.light_color = Color("#6FE7FF")
    light.light_energy = 2.5
    light.omni_range = 5.0
    echo.add_child(light)

    _post_echo_marker = MeshInstance3D.new()
    _post_echo_marker.name = "MemoryAfterglow"
    _post_echo_marker.position = Vector3(2.5, 0.06, -3.0)
    var marker_mesh := CylinderMesh.new()
    marker_mesh.top_radius = 1.0
    marker_mesh.bottom_radius = 1.0
    marker_mesh.height = 0.06
    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = Color("#6FE7FF")
    marker_material.emission_enabled = true
    marker_material.emission = Color("#6FE7FF")
    marker_material.emission_energy_multiplier = 1.4
    marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    marker_material.albedo_color.a = 0.35
    marker_mesh.material = marker_material
    _post_echo_marker.mesh = marker_mesh
    _post_echo_marker.visible = false
    add_child(_post_echo_marker)

func _style_durn() -> void:
    var visual := npc.get_node_or_null("Visual") as MeshInstance3D
    if visual != null:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color("#D7B98A")
        material.roughness = 0.78
        material.metallic = 0.05
        visual.material_override = material
        # C17.2: a cápsula dá lugar à mesma silhueta simples dos trabalhadores, mas com
        # o casaco longo cor de couro que já o identificava, um pouco mais alto, e a placa
        # "DURN" de sempre. Só visual: colisão, interação e posição do NPC não mudam.
        visual.visible = false
        HumanoidSilhouette.build(npc, {"coat": "#CDAE80", "trousers": "#2A2622", "skin": "#8C7866", "scale": 1.06})

    _durn_label = Label3D.new()
    _durn_label.name = "Nameplate"
    _durn_label.text = "DURN"
    _durn_label.position = Vector3(0, 2.1, 0)
    _durn_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _durn_label.font_size = 32
    _durn_label.modulate = Color("#FFD7A1")
    _durn_label.outline_size = 8
    _durn_label.outline_modulate = Color(0.02, 0.03, 0.04, 0.9)
    npc.add_child(_durn_label)



func _setup_vardhelm_ambient_life() -> void:
    var existing := get_node_or_null("AmbientLife")
    if existing:
        existing.queue_free()
    var life := VARDHELM_LIFE.new()
    life.name = "AmbientLife"
    add_child(life)

# C21: o Distrito das Fundições (pátio sob a Forja 01) — mesma cena, mesmo cenário.
func _setup_foundry_district() -> void:
    if get_node_or_null("VP02_FoundryDistrict") == null:
        return
    foundry_district = VardhelmFoundryDistrict.new()
    foundry_district.name = "FoundryDistrict"
    add_child(foundry_district)
    foundry_district.setup(self)

## C21: todas as raízes de observações ambientais (Forja 01 e pátio). Usada pela ligação
## com o painel, pela sombra (EventBus) e pelo provedor de estado do Save V2.
func observation_roots() -> Array[Node]:
    var roots: Array[Node] = []
    var forge := get_node_or_null("AmbientLife/EnvironmentalObservations")
    if forge != null:
        roots.append(forge)
    # C23: todas as vidas do distrito (pátio e rua).
    if foundry_district != null:
        roots.append_array(foundry_district.observation_roots())
    return roots

func _setup_vardhelm_dressing() -> void:
    var dressing := VARDHELM_DRESSING.new()
    dressing.name = "VardhelmSetDressing"
    add_child(dressing)
    dressing.build(self)

# Blocos A3/B1: só registram em paralelo (referências explícitas; sem Autoload).
#   gameplay -> GameplayEventPublisher -> GameEventBus -> GameStateShadowRecorder -> GameState
# Chamado antes de _connect_systems para que a escolha de diálogo seja lida na
# entrada em que foi feita. Não altera nenhum comportamento existente.
func _setup_shadow_game_state() -> void:
    shadow_events = GameEventBus.new()
    shadow_state = GameStateShadowRecorder.new()
    shadow_state.attach(shadow_events)
    shadow_state.track_player(player)
    shadow_publisher = GameplayEventPublisher.new(shadow_events)
    shadow_publisher.observe_dialogue(dialogue_controller, dialogue_box)
    shadow_publisher.observe_quests(quest_controller)
    shadow_publisher.observe_narrative(narrative_controller)
    shadow_publisher.observe_echo(echo)
    shadow_publisher.observe_npc(npc)
    for observation_root in observation_roots():
        for child in observation_root.get_children():
            if child is EnvironmentalObservation:
                shadow_publisher.observe_observation(child)
    shadow_publisher.publish_scenario_entered(GameIdCatalog.SCENARIO_VARDHELM)
    shadow_save_v2 = SaveV2ShadowCoordinator.new(shadow_state, SaveV2Service.new(), shadow_events)

# Bloco B1: chamado depois de _connect_systems para observar as reações do mundo
# (estados de ambiente) após o AmbientLife reagir. Somente leitura.
func _setup_shadow_world_observer() -> void:
    shadow_publisher.observe_world_reactions(narrative_controller, get_node_or_null("AmbientLife") as VardhelmAmbientLife)

func _connect_systems() -> void:
    _npc_interactable.interaction_requested.connect(_on_npc_interaction)
    echo.interaction_requested.connect(_on_echo_interaction)
    echo.memory_revealed.connect(_on_memory_revealed)
    dialogue_controller.entry_changed.connect(_on_dialogue_entry_changed)
    dialogue_controller.dialogue_finished.connect(_on_dialogue_finished)
    dialogue_controller.dialogue_started.connect(_on_dialogue_started)
    dialogue_controller.consequence_requested.connect(_on_dialogue_consequence)
    dialogue_box.advance_requested.connect(_on_dialogue_advance)
    dialogue_box.choice_requested.connect(_on_dialogue_choice)
    quest_controller.quest_started.connect(_on_quest_started)
    quest_controller.objective_completed.connect(_on_objective_completed)
    quest_controller.quest_completed.connect(_on_quest_completed)
    narrative_controller.consequence_applied.connect(_on_consequence_applied)
    player.get_node("InteractionDetector").candidate_changed.connect(_on_candidate_changed)
    for observation_root in observation_roots():
        for child in observation_root.get_children():
            if child is EnvironmentalObservation:
                child.observation_revealed.connect(_on_observation_revealed)

func _start_intro_state() -> void:
    objective_label.text = "Fale com Durn para descobrir o que está acontecendo."
    status_label.text = "WASD / setas — mover   •   E — interagir   •   Ctrl+S — salvar   •   Ctrl+L — carregar"
    echo.visible = true
    echo.interaction_enabled = false
    if _post_echo_marker != null:
        _post_echo_marker.visible = false
    completion_banner.visible = false
    _refresh_objective_text()

func _on_npc_interaction(_actor: Node, _target: Interactable) -> void:
    if dialogue_controller.is_active():
        return
    # C12: antes do Primeiro Eco, a conversa inicial de sempre. Depois dele, Durn
    # reage à descoberta uma vez; concluída essa conversa, só retoma a pista.
    # C14: depois do painel examinado, a última fala dele (uma vez); depois, silêncio.
    if not _first_echo_resolved():
        dialogue_controller.start_dialogue(dialogue_data, "start")
    elif quest_controller.states.is_completed(FOLLOWUP_QUEST_ID):
        if not dialogue_controller.persistent_state.is_completed(AFTER_PANEL_DIALOGUE_ID):
            dialogue_controller.start_dialogue(after_panel_dialogue_data, "heard")
        else:
            dialogue_controller.start_dialogue(after_panel_dialogue_data, AFTER_PANEL_SILENT_ENTRY)
    elif not dialogue_controller.persistent_state.is_completed(AFTER_ECHO_DIALOGUE_ID):
        dialogue_controller.start_dialogue(after_echo_dialogue_data, "start")
    else:
        dialogue_controller.start_dialogue(after_echo_dialogue_data, AFTER_ECHO_REMINDER_ENTRY)

func _first_echo_resolved() -> bool:
    return narrative_controller.world_state.has_flag("vardhelm_first_echo_complete") or quest_controller.states.is_completed(QUEST_ID)

func _on_echo_interaction(_actor: Node, _target: Interactable) -> void:
    if not quest_controller.states.active.has(QUEST_ID):
        status_label.text = "Durn ainda não pediu para você investigar o fenômeno."
        return
    narrative_controller.apply_consequence(echo.consequence_id)
    if not quest_controller.states.is_objective_complete(QUEST_ID, OBJECTIVE_ID):
        quest_controller.complete_objective(QUEST_ID, OBJECTIVE_ID)
    if quest_data != null and quest_data.objective_keys.size() == 1:
        quest_controller.complete_quest(QUEST_ID)

func _on_memory_revealed(_memory_id: String) -> void:
    memory_panel.visible = true
    memory_panel.modulate.a = 0.0
    memory_text.text = "Um instante impossível atravessa sua memória. Por um momento, Vardhelm parece lembrar de algo que não pertence ao presente."
    var tween := create_tween()
    tween.tween_property(memory_panel, "modulate:a", 1.0, 0.25)
    echo_memory_timer = get_tree().create_timer(3.2)
    echo_memory_timer.timeout.connect(_hide_memory_panel, CONNECT_ONE_SHOT)

func _hide_memory_panel() -> void:
    if not is_instance_valid(memory_panel):
        return
    var tween := create_tween()
    tween.tween_property(memory_panel, "modulate:a", 0.0, 0.25)
    tween.tween_callback(func() -> void: memory_panel.visible = false)

func _on_dialogue_entry_changed(entry: DialogueEntry) -> void:
    dialogue_box.show_entry(entry, localization)

# C11: com uma conversa aberta o detector de interação fica suspenso (o E não
# examina objetos por trás do diálogo); volta quando a conversa termina.
func _on_dialogue_started(_dialogue: DialogueData) -> void:
    _set_world_interaction_enabled(false)
    hint_lifecycle.force_hide()

func _set_world_interaction_enabled(enabled: bool) -> void:
    var detector := player.get_node_or_null("InteractionDetector")
    if detector != null:
        detector.set_physics_process(enabled)

func _on_dialogue_finished(dialogue: DialogueData) -> void:
    dialogue_box.hide_dialogue()
    _set_world_interaction_enabled(true)
    # A dica volta conforme o candidato atual (o detector ficou suspenso durante a conversa).
    _on_candidate_changed(player.get_node("InteractionDetector").current_candidate)
    if not quest_controller.states.active.has(QUEST_ID) and not quest_controller.states.completed.has(QUEST_ID):
        quest_controller.start_quest(QUEST_ID)
    # C12: a conversa pós-Eco abre a próxima investigação (painel selado).
    if dialogue != null and dialogue.dialogue_id == AFTER_ECHO_DIALOGUE_ID and not quest_controller.states.active.has(FOLLOWUP_QUEST_ID) and not quest_controller.states.is_completed(FOLLOWUP_QUEST_ID):
        quest_controller.start_quest(FOLLOWUP_QUEST_ID)
    _refresh_objective_text()

func _on_dialogue_consequence(consequence_id: String) -> void:
    narrative_controller.apply_consequence(consequence_id)

func _on_consequence_applied(consequence_id: String) -> void:
    # C14: o status não mostra mais o ID técnico da consequência ("Memória registrada:
    # vardhelm_heard_echo" aparecia no meio da primeira conversa).
    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life != null:
        ambient_life.react_to_consequence(consequence_id)
        ambient_life.apply_narrative_consequence(consequence_id, narrative_controller.world_state)
    _apply_durn_presence(true)
    _refresh_objective_text()

func _on_dialogue_advance() -> void:
    dialogue_controller.advance()

func _on_dialogue_choice(choice_id: String) -> void:
    dialogue_controller.select_choice(choice_id)

func _on_quest_started(quest_id: String) -> void:
    if quest_id != QUEST_ID:
        _refresh_objective_text()
        return
    echo.interaction_enabled = true
    _refresh_objective_text()
    status_label.text = "O caminho está aberto. Encontre o fenômeno no setor industrial."

func _on_objective_completed(_quest_id: String, _objective_id: String) -> void:
    _refresh_objective_text()

func _on_quest_completed(quest_id: String) -> void:
    if quest_id != QUEST_ID:
        _refresh_objective_text()
        return
    echo.interaction_enabled = false
    if _post_echo_marker != null:
        _post_echo_marker.visible = true
    objective_label.text = "✓ Primeiro Eco — concluído"
    status_label.text = ECHO_DONE_STATUS
    completion_banner.visible = true
    completion_banner.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(completion_banner, "modulate:a", 1.0, 0.3)

func _refresh_objective_text() -> void:
    if quest_controller.states.is_completed(QUEST_ID):
        _on_quest_completed(QUEST_ID)
        _apply_followup_objective()
        return
    if quest_controller.states.active.has(QUEST_ID):
        objective_label.text = "Investigue o fenômeno no setor industrial."
    else:
        objective_label.text = "Fale com Durn para descobrir o que está acontecendo."

func _on_memory_fragment_discovered(memory_id: String, memory_category: String, memory_title_key: String, memory_text_key: String) -> void:
    if narrative_controller == null:
        return
    var world_state := narrative_controller.world_state
    if world_state.memories.has(memory_id):
        _refresh_memory_count()
        return

    world_state.add_memory(memory_id)
    _refresh_memory_count()

    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life != null:
        ambient_life.react_to_memory(memory_id)

    var title := localization.tr_key(memory_title_key)
    var text := localization.tr_key(memory_text_key)
    memory_notification_title.text = "MEMÓRIA REGISTRADA"
    memory_notification_text.text = "%s\n%s\n%s" % [title, text, memory_category]
    memory_notification_panel.visible = true

    var timer := get_tree().create_timer(4.5)
    timer.timeout.connect(_hide_memory_notification)

func _hide_memory_notification() -> void:
    if is_instance_valid(memory_notification_panel):
        memory_notification_panel.visible = false

func _refresh_persistent_world_state() -> void:
    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life == null or narrative_controller == null:
        return
    for memory_id in narrative_controller.world_state.memories:
        ambient_life.apply_narrative_consequence(str(memory_id), narrative_controller.world_state)
    if narrative_controller.world_state.has_flag("vardhelm_first_echo_complete"):
        ambient_life.apply_narrative_consequence("vardhelm_first_echo_complete", narrative_controller.world_state)
    _apply_durn_presence(false)
    if foundry_district != null:
        foundry_district.refresh()

func _refresh_memory_count() -> void:
    if memory_count_label == null or narrative_controller == null:
        return
    memory_count_label.text = "Memórias registradas: %d" % narrative_controller.world_state.memories.size()

# C18: a dica é uma janela contextual com ciclo de vida. Quem abre/fecha continua sendo o
# candidato do detector (nada mudou no detector, na prioridade ou no E); o ciclo só evita o
# sumiço brusco: ao sair, espera um pouco; se o jogador volta, a janela fica.
func _on_candidate_changed(candidate: Interactable) -> void:
    if dialogue_controller.is_active():
        hint_lifecycle.force_hide()
        return
    if candidate == null or not candidate.interaction_enabled:
        hint_lifecycle.request_close()
        return
    hint_lifecycle.request_open()
    if candidate == echo:
        interaction_hint_label.text = "E  •  Observar o Eco"
    elif candidate == _npc_interactable:
        interaction_hint_label.text = "E  •  Falar com Durn"
    elif candidate is TransitionPoint:
        interaction_hint_label.text = "E  •  %s" % localization.tr_key((candidate as TransitionPoint).prompt_key)
    elif candidate is EnvironmentalObservation:
        interaction_hint_label.text = "E  •  Examinar"
    else:
        interaction_hint_label.text = "E  •  Interagir"

func _on_observation_revealed(observation_id: String, title_key: String, text_key: String) -> void:
    var title := localization.tr_key(title_key)
    var text := localization.tr_key(text_key)
    observation_title.text = title
    observation_text.text = text
    observation_panel.visible = true
    observation_panel.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(observation_panel, "modulate:a", 1.0, 0.22)

    var flag_id := "observation_%s_seen" % observation_id
    narrative_controller.world_state.set_flag(flag_id, true)
    narrative_controller.world_state.set_value("observation.%s.seen" % observation_id, true)
    # C12: examinar o painel selado depois que Durn o apontou conclui a etapa.
    if observation_id == FOLLOWUP_OBSERVATION_ID and quest_controller.states.active.has(FOLLOWUP_QUEST_ID):
        quest_controller.complete_objective(FOLLOWUP_QUEST_ID, FOLLOWUP_OBJECTIVE_ID)
        quest_controller.complete_quest(FOLLOWUP_QUEST_ID)
        # C14: encerramento — por alguns segundos Vardhelm fica em silêncio e a luz
        # sobre o painel se apaga; depois tudo volta ao estado pós-Eco. Só ao vivo
        # (nunca num Load) e só na conclusão.
        var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
        if ambient_life != null:
            ambient_life.play_closing_silence()

    observation_timer = get_tree().create_timer(5.0)
    observation_timer.timeout.connect(_hide_observation_panel, CONNECT_ONE_SHOT)

func _hide_observation_panel() -> void:
    if not is_instance_valid(observation_panel):
        return
    var tween := create_tween()
    tween.tween_property(observation_panel, "modulate:a", 0.0, 0.22)
    tween.tween_callback(func() -> void:
        observation_panel.visible = false
    )

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("save_game"):
        # Bloco C8: flag ligada = SOMENTE Save V2 operacional (o save antigo não é gravado).
        if save_v2_operational_config != null and save_v2_operational_config.save_enabled:
            get_viewport().set_input_as_handled()
            _run_operational_v2_save()
            return
        if save_service.save_game(narrative_controller.world_state, quest_controller.states, localization.language, player):
            status_label.text = "Jogo salvo."
        # Bloco C2: Save V2 sombra DEPOIS do save antigo; não altera o fluxo nem a UI.
        if shadow_save_v2 != null:
            shadow_save_v2.after_legacy_save()
    elif event.is_action_pressed("load_game"):
        # Bloco C7: flag ligada = SOMENTE Load V2 operacional (sem fallback silencioso).
        if save_v2_operational_config != null and save_v2_operational_config.enabled:
            get_viewport().set_input_as_handled()
            _run_operational_v2_load()
            return
        var loaded := save_service.load_game(narrative_controller.world_state, quest_controller.states, player)
        if not loaded.is_empty():
            _apply_loaded_visual_state()
            status_label.text = "Jogo carregado."
            _refresh_objective_text()
        # Bloco C2: Load V2 sombra DEPOIS do load antigo; só compara, nada é restaurado.
        if shadow_save_v2 != null:
            shadow_save_v2.after_legacy_load(not loaded.is_empty(), narrative_controller.world_state, quest_controller.states)

func _apply_loaded_visual_state() -> void:
    var completed := narrative_controller.world_state.has_flag("vardhelm_first_echo_complete") or quest_controller.states.is_completed(QUEST_ID)
    var active := quest_controller.states.active.has(QUEST_ID) or quest_controller.states.objective_progress.has(QUEST_ID)

    echo.revealed = completed
    echo.interaction_enabled = active and not completed
    var visual := echo.get_node_or_null("Visual") as MeshInstance3D
    var light := echo.get_node_or_null("Light") as OmniLight3D
    if visual != null:
        visual.visible = not completed
    if light != null:
        light.visible = not completed
    if _post_echo_marker != null:
        _post_echo_marker.visible = completed
    if completed:
        completion_banner.visible = true
    elif active:
        completion_banner.visible = false

# Bloco C5: superfície PÚBLICA das derivações já existentes, consumida pelo
# VardhelmRuntimeStateProvider (restauração em sandbox). Só delegam aos métodos
# acima; nenhum comportamento novo e nada é chamado pelo gameplay.
func derive_echo_state() -> void:
    _apply_loaded_visual_state()

# C7: em um Load V2 no jogo principal o estado pode VOLTAR (ex.: save anterior
# ao Eco). Sem quest concluída o banner de conclusão fica oculto, como no início
# (_start_intro_state); a conclusão volta a exibi-lo em _refresh_objective_text.
func derive_quest_presentation() -> void:
    if not quest_controller.states.is_completed(QUEST_ID):
        completion_banner.visible = false
    _refresh_objective_text()

# C7: o ambiente persistente é re-derivado do zero (reset + derivação existente).
func derive_environment_state() -> void:
    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life != null:
        ambient_life.reset_persistent_state()
    _refresh_persistent_world_state()

# Bloco C7: Load V2 OPERACIONAL (opt-in). Só com
# SAVE_V2_OPERATIONAL_LOAD_ENABLED; sem fallback para o load antigo.
func _run_operational_v2_load() -> void:
    var coordinator := SaveV2RuntimeLoadCoordinator.new(save_v2_operational_config, null, shadow_events)
    var main_targets := VardhelmRuntimeStateProvider.new(self).build_targets()
    _present_v2_load_result(coordinator.load_into_runtime(main_targets, VardhelmDiagnosticSandbox.new(get_parent(), "SaveV2LoadRehearsal")))

# Bloco C9: resultado do Load V2 -> mensagem LOCALIZADA ao jogador + log técnico
# separado (código, detalhes, falha original, falha do rollback).
func _present_v2_load_result(result: SaveV2RuntimeLoadResult) -> void:
    last_v2_load_result = result
    var legacy_only := false
    if result.is_success():
        # A sombra passa a acompanhar o estado carregado (continua sombra).
        shadow_state.game_state = GameState.from_dict(result.state.to_dict())
        # C9: a deduplicação dos eventos acompanha o estado carregado.
        shadow_publisher.resync_after_load(result.state)
        # C10: a UI transitória do estado anterior ao load é descartada.
        _discard_transient_ui_after_load()
    else:
        if result.status == SaveV2RuntimeLoadResult.ROLLBACK_FAILURE:
            push_error(SaveV2PlayerMessages.load_log(result))
        else:
            push_warning(SaveV2PlayerMessages.load_log(result))
        if result.code == SaveV2Errors.FILE_NOT_FOUND:
            var inventory := SaveV2PersistenceInventory.inspect(SaveService.SAVE_PATH, save_v2_operational_config.path)
            legacy_only = inventory["legacy"]["status"] == SaveV2PersistenceInventory.LEGACY_PRESENT
    if result.main_touched:
        # C10: teleporte do load/rollback — a velocidade anterior (estado físico
        # transitório) não continua no estado carregado.
        player.velocity = Vector3.ZERO
    _show_save_v2_message(SaveV2PlayerMessages.load_key(result, legacy_only))

# Bloco C8: Save V2 OPERACIONAL (opt-in). Só com SAVE_V2_OPERATIONAL_SAVE_ENABLED;
# grava a projeção persistente do runtime e sincroniza a sombra. Sem sandbox.
func _run_operational_v2_save() -> void:
    var coordinator := SaveV2RuntimeSaveCoordinator.new(save_v2_operational_config, shadow_events)
    _present_v2_save_result(coordinator.save_runtime(VardhelmRuntimeStateProvider.new(self).build_targets(), shadow_state))

func _present_v2_save_result(result: SaveV2RuntimeSaveResult) -> void:
    last_v2_save_result = result
    if not result.is_success():
        push_warning(SaveV2PlayerMessages.save_log(result))
    _show_save_v2_message(SaveV2PlayerMessages.save_key(result))

# Bloco C9: mensagem de Save/Load V2 no status existente; some sozinha e devolve
# o texto anterior. Não fecha nem altera diálogo, nem cria UI nova.
func _show_save_v2_message(key: String) -> void:
    var message := localization.tr_key(key)
    if status_label.text != _save_v2_message:
        _status_before_save_v2_message = status_label.text
    _save_v2_message = message
    status_label.text = message
    _style_save_v2_message(SaveV2PlayerMessages.severity_of(key))
    get_tree().create_timer(SAVE_V2_MESSAGE_SECONDS).timeout.connect(_clear_save_v2_message.bind(message), CONNECT_ONE_SHOT)

func _clear_save_v2_message(message: String) -> void:
    if not is_instance_valid(status_label) or _save_v2_message != message:
        return
    # O texto anterior só volta se a mensagem ainda estiver na tela; se o jogo já
    # escreveu outro status nesse meio-tempo, ele fica — mas sem o destaque (C11).
    if status_label.text == message:
        status_label.text = _status_before_save_v2_message
    _reset_status_style()
    _save_v2_message = ""

# Bloco C10: após Load V2 com SUCCESS, descarta a UI TRANSITÓRIA que ainda mostra o
# estado anterior (Eco de memória, observação, notificação de memória). HUD
# estrutural, objetivo/banner (derivados) e diálogo não são tocados.
func _discard_transient_ui_after_load() -> void:
    for panel in [memory_panel, observation_panel, memory_notification_panel]:
        if panel != null:
            panel.visible = false

# Bloco C10: destaque da mensagem de Save/Load no status existente (maior, com
# fundo e cor pela severidade). Volta ao estilo original quando a mensagem some.
func _style_save_v2_message(severity: String) -> void:
    var accent := Color("#7CF0A8")
    if severity == SaveV2PlayerMessages.SEVERITY_WARNING:
        accent = Color("#FFD27A")
    elif severity == SaveV2PlayerMessages.SEVERITY_ERROR:
        accent = Color("#FF8A7A")
    var style := _make_panel_style(Color(0.02, 0.04, 0.05, 0.94), accent, 2, 8)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    status_label.add_theme_stylebox_override("normal", style)
    status_label.add_theme_font_size_override("font_size", SAVE_V2_MESSAGE_FONT_SIZE)
    status_label.add_theme_color_override("font_color", accent)

func _reset_status_style() -> void:
    status_label.remove_theme_stylebox_override("normal")
    status_label.add_theme_font_size_override("font_size", 12)
    status_label.add_theme_color_override("font_color", Color("#C7D2DA"))


# C11: se o jogo escrever outro status enquanto a mensagem de Save/Load está na
# tela, o destaque sai imediatamente (não "empresta" a cor ao texto do jogo).
func _process(_delta: float) -> void:
    if not _save_v2_message.is_empty() and status_label.text != _save_v2_message:
        _reset_status_style()
        _save_v2_message = ""

# C12: objetivo da próxima investigação (depois do Primeiro Eco), da localização. O
# banner de conclusão do Primeiro Eco sai de cena quando a próxima etapa começa.
func _apply_followup_objective() -> void:
    if quest_controller.states.is_completed(FOLLOWUP_QUEST_ID):
        objective_label.text = localization.tr_key(FOLLOWUP_DONE_KEY)
        completion_banner.visible = false
    elif quest_controller.states.active.has(FOLLOWUP_QUEST_ID):
        objective_label.text = localization.tr_key(FOLLOWUP_OBJECTIVE_KEY)
        completion_banner.visible = false
    else:
        return
    if status_label.text == ECHO_DONE_STATUS:
        status_label.text = ""

# C12: a conclusão de uma quest está apresentada? (usado pela derivação do Save V2)
# Primeiro Eco: banner de conclusão ou a próxima etapa que o substitui.
func is_quest_completion_presented(runtime_quest_id: String) -> bool:
    var followup_shown := objective_label.text == localization.tr_key(FOLLOWUP_OBJECTIVE_KEY) or objective_label.text == localization.tr_key(FOLLOWUP_DONE_KEY)
    if runtime_quest_id == QUEST_ID:
        return completion_banner.visible or followup_shown
    if runtime_quest_id == FOLLOWUP_QUEST_ID:
        return objective_label.text == localization.tr_key(FOLLOWUP_DONE_KEY)
    return false

# C15: consequência da escolha "Não senti nada." Durn tinha dito "Se acontecer de
# novo... procure por mim."; se o jogador negou, quando o Eco acontece ele não espera:
# vai sozinho até onde o Eco aconteceu e fica ali. Posição DERIVADA do estado
# (durn_alone + echo_awakened no AmbientLife): ao vivo ele caminha; num Load (ou na
# derivação) ele já está no lugar. Nada novo é salvo; o NPC não é recriado.
func _apply_durn_presence(animated: bool) -> void:
    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life == null or npc == null:
        return
    var target := _durn_home
    # C16: longe do lugar de sempre, Durn deixa ali o que fazia (a folha): a observação
    # durn_notes só existe enquanto ele está fora. Mesma condição derivada, sem estado novo.
    ambient_life.set_observation_available(DURN_NOTES_OBSERVATION_ID, ambient_life.is_durn_alone_after_echo())
    if ambient_life.is_durn_alone_after_echo():
        var definition := ambient_life.durn_alone_def()
        var p: Array = definition.get("position", [])
        var f: Array = definition.get("face", [])
        target = Transform3D(_durn_home.basis, Vector3(float(p[0]), float(p[1]), float(p[2])))
        var facing := Vector3(float(f[0]), float(p[1]), float(f[2])) - target.origin
        if facing.length() > 0.01:
            target.basis = Basis.looking_at(facing, Vector3.UP)
    if animated and npc.global_transform.origin.distance_to(target.origin) < 0.01:
        return
    if animated and _durn_walk != null and _durn_walk.is_valid():
        return
    if _durn_walk != null and _durn_walk.is_valid():
        _durn_walk.kill()
    _durn_walk = null
    if not animated:
        npc.global_transform = target
        return
    var walk_def := ambient_life.durn_alone_def()
    npc.global_transform = Transform3D(target.basis, npc.global_transform.origin)
    _durn_walk = create_tween()
    _durn_walk.tween_interval(float(walk_def.get("delay", 1.0)))
    _durn_walk.tween_property(npc, "global_position", target.origin, float(walk_def.get("walk_seconds", 3.0)))
    _durn_walk.tween_callback(func() -> void: _durn_walk = null)

func is_durn_away_from_home() -> bool:
    return npc != null and not _durn_home.origin.is_equal_approx(npc.global_position)
