class_name VardhelmAudio
extends Node

@onready var hum_player: AudioStreamPlayer = $VardhelmHum
@onready var steam_player: AudioStreamPlayer = $VardhelmSteam
@onready var machinery_player: AudioStreamPlayer = $VardhelmMachinery

func _ready() -> void:
    _configure_player(hum_player, -6.0)
    _configure_player(steam_player, -16.0)
    _configure_player(machinery_player, -20.0)

    _loop_player(hum_player)
    _loop_player(steam_player)
    _loop_player(machinery_player)

    _start_player(hum_player)
    _start_player(steam_player)
    _start_player(machinery_player)

func _configure_player(player: AudioStreamPlayer, volume_db: float) -> void:
    if player == null:
        return
    player.bus = &"Master"
    player.volume_db = volume_db
    player.stream_paused = false

func _start_player(player: AudioStreamPlayer) -> void:
    if player == null or player.stream == null:
        return
    if not player.playing:
        player.play()

func _loop_player(player: AudioStreamPlayer) -> void:
    if player == null:
        return
    if not player.finished.is_connected(_on_player_finished):
        player.finished.connect(_on_player_finished.bind(player))

func _on_player_finished(player: AudioStreamPlayer) -> void:
    if is_instance_valid(player):
        player.play()

func stop_all() -> void:
    for player in [hum_player, steam_player, machinery_player]:
        if is_instance_valid(player):
            player.stop()

func start_all() -> void:
    for player in [hum_player, steam_player, machinery_player]:
        _start_player(player)
