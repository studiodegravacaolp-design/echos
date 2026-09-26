class_name DialogueBox
extends PanelContainer

signal advance_requested
signal choice_requested(choice_id: String)

@onready var speaker_label: Label = $Margin/VBox/Speaker
@onready var text_label: Label = $Margin/VBox/Text
@onready var choices_box: VBoxContainer = $Margin/VBox/Choices
@onready var continue_button: Button = $Margin/VBox/Continue

func _ready() -> void:
    continue_button.pressed.connect(_on_continue_pressed)

func show_entry(entry: DialogueEntry, localizer: LocalizationService = null) -> void:
    visible = true
    speaker_label.text = entry.speaker_id
    text_label.text = localizer.tr_key(entry.text) if localizer != null else entry.text
    for child in choices_box.get_children():
        child.queue_free()
    continue_button.visible = entry.choices.is_empty()
    for choice: DialogueChoice in entry.choices:
        var button := Button.new()
        button.text = localizer.tr_key(choice.text_key) if localizer != null else choice.text_key
        button.pressed.connect(_on_choice_pressed.bind(choice.choice_id))
        choices_box.add_child(button)

func hide_dialogue() -> void:
    visible = false

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("dialogue_advance") and continue_button.visible:
        advance_requested.emit()

func _on_continue_pressed() -> void:
    advance_requested.emit()

func _on_choice_pressed(choice_id: String) -> void:
    choice_requested.emit(choice_id)
