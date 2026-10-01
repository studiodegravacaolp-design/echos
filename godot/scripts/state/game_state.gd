class_name GameState
extends RefCounted

## Raiz canônica e versionada do estado persistente da partida (A1 §2–3).
##
##   GameState (state_version = 1)
##   ├── player    GamePlayerState
##   ├── world     GameWorldState
##   ├── quests    GameQuestState
##   ├── dialogue  GameDialogueState
##   ├── memory    GameMemoryState
##   └── npcs      GameNPCState
##   [reservado]   progression — sem campos até decisão de design
##
## Fora do GameState: idioma, áudio, câmera, input, timers, tweens, sessão de
## diálogo, UI, metadados de save, checksum e slot.
##
## state_version é a versão deste contrato e independe da "version" do
## arquivo de save atual. Este contrato NÃO está ligado ao SaveService.

const STATE_VERSION := 1
const SECTION_KEYS := ["player", "world", "quests", "dialogue", "memory", "npcs"]
const RESERVED_SECTION_KEYS := ["progression"]

var state_version: int = STATE_VERSION
var player: GamePlayerState = GamePlayerState.new()
var world: GameWorldState = GameWorldState.new()
var quests: GameQuestState = GameQuestState.new()
var dialogue: GameDialogueState = GameDialogueState.new()
var memory: GameMemoryState = GameMemoryState.new()
var npcs: GameNPCState = GameNPCState.new()


func to_dict() -> Dictionary:
	return {
		"state_version": state_version,
		"player": player.to_dict(),
		"world": world.to_dict(),
		"quests": quests.to_dict(),
		"dialogue": dialogue.to_dict(),
		"memory": memory.to_dict(),
		"npcs": npcs.to_dict(),
	}


## Reconstrói a partir de um Dictionary (ex.: vindo de JSON). Conversão
## explícita; state_version é lido como está para que validate_dict aponte
## versões não suportadas.
static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	var raw_version: Variant = data.get("state_version")
	if GameStateSerde.is_whole_number(raw_version):
		state.state_version = int(raw_version)
	state.player = GamePlayerState.from_dict(GameStateSerde.as_dictionary(data.get("player")))
	state.world = GameWorldState.from_dict(GameStateSerde.as_dictionary(data.get("world")))
	state.quests = GameQuestState.from_dict(GameStateSerde.as_dictionary(data.get("quests")))
	state.dialogue = GameDialogueState.from_dict(GameStateSerde.as_dictionary(data.get("dialogue")))
	state.memory = GameMemoryState.from_dict(GameStateSerde.as_dictionary(data.get("memory")))
	state.npcs = GameNPCState.from_dict(GameStateSerde.as_dictionary(data.get("npcs")))
	return state


func validate() -> PackedStringArray:
	return validate_dict(to_dict())


static func validate_dict(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not GameStateSerde.require_dictionary(data, "game_state", errors):
		return errors
	var root: Dictionary = data
	for key in root:
		if RESERVED_SECTION_KEYS.has(key):
			errors.append("game_state.%s: seção reservada, não suportada em state_version %d" % [str(key), STATE_VERSION])
		elif key != "state_version" and not SECTION_KEYS.has(key):
			errors.append("game_state: campo desconhecido '%s'" % str(key))
	var raw_version: Variant = root.get("state_version")
	if not GameStateSerde.is_whole_number(raw_version):
		errors.append("game_state.state_version: esperado inteiro")
	elif int(raw_version) != STATE_VERSION:
		errors.append("game_state.state_version: %d não suportada (esperado %d)" % [int(raw_version), STATE_VERSION])
	errors.append_array(GamePlayerState.validate_dict(root.get("player")))
	errors.append_array(GameWorldState.validate_dict(root.get("world")))
	errors.append_array(GameQuestState.validate_dict(root.get("quests")))
	errors.append_array(GameDialogueState.validate_dict(root.get("dialogue")))
	errors.append_array(GameMemoryState.validate_dict(root.get("memory")))
	errors.append_array(GameNPCState.validate_dict(root.get("npcs")))
	return errors
