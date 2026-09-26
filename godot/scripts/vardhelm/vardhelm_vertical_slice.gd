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
const LOCALE_PATH := "res://data/localization/pt-BR.json"
const QUEST_ID := "vardhelm_first_echo"
const OBJECTIVE_ID := "observe"

var dialogue_controller: DialogueController
var quest_controller: QuestController
var narrative_controller: NarrativeController
var localization: LocalizationService
var save_service: SaveService
var dialogue_box: DialogueBox
var dialogue_data: DialogueData
var quest_data: QuestData

var objective_panel: PanelContainer
var objective_label: Label
var status_label: Label
var interaction_hint: PanelContainer
var interaction_hint_label: Label
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

func _ready() -> void:
    _setup_services()
    _setup_ui()
    _spawn_runtime_content()
    _setup_vardhelm_dressing()
    _setup_vardhelm_ambient_life()
    _connect_systems()
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

func _setup_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "NarrativeUI"
    add_child(canvas)

    objective_panel = PanelContainer.new()
    objective_panel.name = "ObjectivePanel"
    objective_panel.position = Vector2(20, 18)
    objective_panel.size = Vector2(390, 76)
    objective_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.055, 0.075, 0.92), Color(0.35, 0.75, 0.9, 0.75), 2, 10))
    canvas.add_child(objective_panel)

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
    status_label.position = Vector2(20, 100)
    status_label.add_theme_color_override("font_color", Color("#C7D2DA"))
    status_label.add_theme_font_size_override("font_size", 12)
    canvas.add_child(status_label)

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

    dialogue_box = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
    dialogue_box.name = "DialogueBox"
    dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    dialogue_box.position = Vector2(24, -282)
    dialogue_box.size = Vector2(-48, 246)
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
    memory_notification_panel.position = Vector2(360, 520)
    memory_notification_panel.size = Vector2(560, 110)
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
    completion_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
    completion_banner.position = Vector2(-300, 24)
    completion_banner.size = Vector2(600, 76)
    completion_banner.visible = false
    completion_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.08, 0.06, 0.95), Color(0.45, 1.0, 0.65, 0.95), 2, 14))
    canvas.add_child(completion_banner)

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
    _style_durn()

    var bridge := NPCDialogueBridge.new()
    bridge.name = "DialogueBridge"
    bridge.dialogue = dialogue_data
    bridge.start_entry_id = "start"
    npc.add_child(bridge)

    _npc_interactable = npc.get_node("Interactable") as Interactable

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

func _setup_vardhelm_dressing() -> void:
    var dressing := VARDHELM_DRESSING.new()
    dressing.name = "VardhelmSetDressing"
    add_child(dressing)
    dressing.build(self)

func _connect_systems() -> void:
    _npc_interactable.interaction_requested.connect(_on_npc_interaction)
    echo.interaction_requested.connect(_on_echo_interaction)
    echo.memory_revealed.connect(_on_memory_revealed)
    dialogue_controller.entry_changed.connect(_on_dialogue_entry_changed)
    dialogue_controller.dialogue_finished.connect(_on_dialogue_finished)
    dialogue_controller.consequence_requested.connect(_on_dialogue_consequence)
    dialogue_box.advance_requested.connect(_on_dialogue_advance)
    dialogue_box.choice_requested.connect(_on_dialogue_choice)
    quest_controller.quest_started.connect(_on_quest_started)
    quest_controller.objective_completed.connect(_on_objective_completed)
    quest_controller.quest_completed.connect(_on_quest_completed)
    narrative_controller.consequence_applied.connect(_on_consequence_applied)
    player.get_node("InteractionDetector").candidate_changed.connect(_on_candidate_changed)
    var observation_root := get_node_or_null("AmbientLife/EnvironmentalObservations")
    if observation_root != null:
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
    dialogue_controller.start_dialogue(dialogue_data, "start")

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

func _on_dialogue_finished(_dialogue: DialogueData) -> void:
    dialogue_box.hide_dialogue()
    if not quest_controller.states.active.has(QUEST_ID) and not quest_controller.states.completed.has(QUEST_ID):
        quest_controller.start_quest(QUEST_ID)
    _refresh_objective_text()

func _on_dialogue_consequence(consequence_id: String) -> void:
    narrative_controller.apply_consequence(consequence_id)

func _on_consequence_applied(consequence_id: String) -> void:
    status_label.text = "Memória registrada: " + consequence_id
    var ambient_life := get_node_or_null("AmbientLife") as VardhelmAmbientLife
    if ambient_life != null:
        ambient_life.react_to_consequence(consequence_id)
        ambient_life.apply_narrative_consequence(consequence_id, narrative_controller.world_state)
    _refresh_objective_text()

func _on_dialogue_advance() -> void:
    dialogue_controller.advance()

func _on_dialogue_choice(choice_id: String) -> void:
    dialogue_controller.select_choice(choice_id)

func _on_quest_started(_quest_id: String) -> void:
    echo.interaction_enabled = true
    _refresh_objective_text()
    status_label.text = "O caminho está aberto. Encontre o fenômeno no setor industrial."

func _on_objective_completed(_quest_id: String, _objective_id: String) -> void:
    _refresh_objective_text()

func _on_quest_completed(_quest_id: String) -> void:
    echo.interaction_enabled = false
    if _post_echo_marker != null:
        _post_echo_marker.visible = true
    objective_label.text = "✓ Primeiro Eco — concluído"
    status_label.text = "Você registrou o primeiro Eco. Ctrl+S salva seu progresso."
    completion_banner.visible = true
    completion_banner.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(completion_banner, "modulate:a", 1.0, 0.3)

func _refresh_objective_text() -> void:
    if quest_controller.states.is_completed(QUEST_ID):
        _on_quest_completed(QUEST_ID)
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

func _refresh_memory_count() -> void:
    if memory_count_label == null or narrative_controller == null:
        return
    memory_count_label.text = "Memórias registradas: %d" % narrative_controller.world_state.memories.size()

func _on_candidate_changed(candidate: Interactable) -> void:
    if dialogue_controller.is_active():
        interaction_hint.visible = false
        return
    interaction_hint.visible = candidate != null and candidate.interaction_enabled
    if not interaction_hint.visible:
        return
    if candidate == echo:
        interaction_hint_label.text = "E  •  Observar o Eco"
    elif candidate == _npc_interactable:
        interaction_hint_label.text = "E  •  Falar com Durn"
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
        if save_service.save_game(narrative_controller.world_state, quest_controller.states, localization.language, player):
            status_label.text = "Jogo salvo."
    elif event.is_action_pressed("load_game"):
        var loaded := save_service.load_game(narrative_controller.world_state, quest_controller.states, player)
        if not loaded.is_empty():
            _apply_loaded_visual_state()
            status_label.text = "Jogo carregado."
            _refresh_objective_text()

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
