extends RefCounted

## Bloco C8 — correção do bug da esfera do Eco.
## EchoMemoryInteractable guardava `_visual`/`_light` no próprio _ready, que roda
## quando o slice faz add_child(echo) — ANTES de o slice criar "Visual"/"Light".
## Ao ser resolvido ao vivo, a esfera ficava visível; a derivação do load a ocultava.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"


func run(t) -> void:
	test_echo_visual_state_after_resolution(t)


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func _press_choice(slice: VardhelmVerticalSlice, index: int) -> void:
	var buttons: Array = []
	for child in slice.dialogue_box.choices_box.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	(buttons[index] as Button).pressed.emit()


func test_echo_visual_state_after_resolution(t) -> void:
	t.section("C8 — test_echo_visual_state_after_resolution")
	# 1. Mesma ordem do slice: nó entra na árvore, filhos visuais depois.
	var holder := Node3D.new()
	t.root.add_child(holder)
	var echo := EchoMemoryInteractable.new()
	holder.add_child(echo)
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	echo.add_child(visual)
	var light := OmniLight3D.new()
	light.name = "Light"
	echo.add_child(light)
	echo.interaction_enabled = true
	var actor := Node3D.new()
	holder.add_child(actor)
	t.check(visual.visible and light.visible, "antes: esfera e luz visíveis")
	t.check(echo.interact(actor) and echo.revealed and not echo.interaction_enabled, "Eco resolvido")
	t.check(not visual.visible and not light.visible, "filhos criados após o _ready: esfera e luz ocultas ao resolver")
	# 2. Ordem inversa (filhos antes do _ready) continua funcionando.
	var early := EchoMemoryInteractable.new()
	var early_visual := MeshInstance3D.new()
	early_visual.name = "Visual"
	early.add_child(early_visual)
	holder.add_child(early)
	early.interaction_enabled = true
	early.interact(actor)
	t.check(not early_visual.visible, "filhos criados antes do _ready: esfera oculta")
	t.root.remove_child(holder)
	holder.queue_free()

	# 3. Vardhelm real: jogo ao vivo == derivação usada pelo Load V2.
	_isolate(t)
	var slice := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(slice)
	slice.player.set_physics_process(false)
	slice._npc_interactable.interact(slice.player)
	_press_choice(slice, 0)
	slice.dialogue_box.continue_button.pressed.emit()
	slice.dialogue_box.continue_button.pressed.emit()
	var live_visual := slice.echo.get_node("Visual") as MeshInstance3D
	var live_light := slice.echo.get_node("Light") as OmniLight3D
	t.check(live_visual.visible and live_light.visible, "Vardhelm: esfera visível antes de resolver")
	slice.echo.interact(slice.player)
	t.check(slice.echo.revealed and not live_visual.visible and not live_light.visible, "Vardhelm ao vivo: Eco resolvido oculta esfera e luz")
	slice.derive_echo_state()
	t.check(not live_visual.visible and not live_light.visible and slice.echo.revealed and not slice.echo.interaction_enabled, "derivação do Load V2 == estado ao vivo")
	var gameplay_source := FileAccess.get_file_as_string("res://scripts/echo/echo_memory_interactable.gd")
	t.check(not gameplay_source.contains("GameState") and not gameplay_source.contains("SaveV2"), "correção local ao EchoMemoryInteractable (sem GameState/Save V2)")
	t.root.remove_child(slice)
	slice.queue_free()
