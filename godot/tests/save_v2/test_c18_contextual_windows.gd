extends RefCounted

## Bloco C18 — ciclo de vida das janelas contextuais (headless, determinístico).
## O componente é testado passo a passo (o atraso e os fades são disparados pelos mesmos
## métodos que o Timer e o tween chamam); o tempo real fica no playtest do C18.

const SLICE_SCENE := "res://scenes/prototypes/vardhelm_vertical_slice.tscn"
const CONFIG_PATH := "res://data/ui/contextual_windows.json"
const TEST_DIR := "user://save_v2_tests"
const V2_FILE := "user://save_v2_tests/c18.json"


func _isolate(t) -> void:
	for child in t.root.get_children():
		if child is VardhelmVerticalSlice:
			t.root.remove_child(child)
			child.queue_free()


func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_component(t)
	_test_slice(t)
	_isolate(t)
	var dir := DirAccess.open(TEST_DIR)
	if dir != null:
		for file_name in dir.get_files():
			dir.remove(file_name)
	DirAccess.remove_absolute(TEST_DIR)


func _test_component(t) -> void:
	t.section("C18 — componente ContextualWindowLifecycle")
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))["interaction_hint"]
	t.check(float(config["close_delay"]) == 0.75 and float(config["fade_in"]) == 0.10 and float(config["fade_out"]) == 0.15, "valores vindos de dados: atraso 0,75 s, fade-in 0,10 s, fade-out 0,15 s")
	var host := Node.new()
	t.root.add_child(host)
	var panel := PanelContainer.new()
	host.add_child(panel)
	var lifecycle := ContextualWindowLifecycle.new()
	host.add_child(lifecycle)
	lifecycle.configure(panel, config)
	var states: Array = []
	lifecycle.state_changed.connect(func(s): states.append(s))
	t.check(not panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "estado 1: fora da área, nenhuma janela")
	lifecycle.request_open()
	t.check(panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_VISIBLE and lifecycle.open_count == 1, "A. entrar → a janela aparece (fade-in)")
	lifecycle.request_open()
	lifecycle.request_open()
	t.check(lifecycle.open_count == 1 and states == ["visible"], "B. permanecer → a janela fica, sem reiniciar a animação")
	lifecycle.request_close()
	var timer := lifecycle.get_node("CloseDelay") as Timer
	t.check(panel.visible and lifecycle.is_close_pending() and not timer.is_stopped() and is_equal_approx(timer.wait_time, 0.75), "C. sair → não some na hora; fechamento pendente por 0,75 s")
	lifecycle.request_open()
	t.check(panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_VISIBLE and timer.is_stopped() and lifecycle.open_count == 1, "E. voltar antes do atraso → o fechamento é cancelado, a mesma janela continua (sem novo fade-in)")
	lifecycle.request_close()
	lifecycle._on_close_timeout()
	t.check(panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_CLOSING, "D. atraso vencido → fade-out curto")
	lifecycle._finish_close()
	t.check(not panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN and is_equal_approx(panel.modulate.a, 1.0), "D. … e a janela fecha (volta ao estado 1)")
	t.check(states == ["visible", "pending_close", "visible", "pending_close", "closing", "hidden"], "F. transições limpas, sem piscar: %s" % str(states))
	lifecycle.request_open()
	lifecycle.request_close()
	lifecycle._on_close_timeout()
	lifecycle.request_open()
	t.check(panel.visible and lifecycle.state == ContextualWindowLifecycle.STATE_VISIBLE and lifecycle.open_count == 2, "voltar durante o fade-out → retoma a partir da opacidade atual")
	lifecycle.request_close()
	lifecycle.force_hide()
	t.check(not panel.visible and timer.is_stopped() and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "force_hide fecha na hora e cancela o atraso")
	host.queue_free()


func _test_slice(t) -> void:
	t.section("C18 — dica \"E • …\" do Vardhelm")
	_isolate(t)
	var game := (load(SLICE_SCENE) as PackedScene).instantiate() as VardhelmVerticalSlice
	t.root.add_child(game)
	game.save_v2_operational_config.path = V2_FILE
	game.shadow_save_v2.service = SaveV2Service.new(V2_FILE)
	game.player.set_physics_process(false)
	var lifecycle := game.hint_lifecycle
	var hint := game.interaction_hint
	var rack := game.get_node("AmbientLife/EnvironmentalObservations/tool_rack") as EnvironmentalObservation
	game._on_candidate_changed(rack)
	t.check(hint.visible and game.interaction_hint_label.text == "E  •  Examinar", "observação: aproximar → \"E • Examinar\"")
	game._on_candidate_changed(null)
	t.check(hint.visible and lifecycle.is_close_pending() and game.interaction_hint_label.text == "E  •  Examinar", "afastar → a dica espera (mesmo texto) antes de fechar")
	game._on_candidate_changed(game._npc_interactable)
	t.check(hint.visible and not lifecycle.is_close_pending() and game.interaction_hint_label.text == "E  •  Falar com Durn" and lifecycle.open_count == 1, "chegar a outro alvo durante o atraso: mesma janela, texto novo")
	var hints := game.get_node("NarrativeUI").find_children("InteractionHint", "", true, false)
	t.check(hints.size() == 1, "G. uma única janela de dica (nada é recriado)")
	# H. diálogo principal: abrir a conversa fecha a dica na hora; a conversa não é tocada.
	game._npc_interactable.interact(game.player)
	t.check(game.dialogue_controller.is_active() and not hint.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "H. conversa aberta: a dica sai na hora (C11) e a conversa segue")
	game._on_candidate_changed(null)
	game._on_candidate_changed(rack)
	t.check(game.dialogue_controller.is_active() and not hint.visible, "H. com a conversa aberta, nada contextual abre nem a encerra")
	while game.dialogue_controller.is_active():
		var buttons: Array = game.dialogue_box.choices_box.get_children().filter(func(c): return c is Button and not c.is_queued_for_deletion())
		if buttons.is_empty():
			game.dialogue_box.continue_button.pressed.emit()
		else:
			(buttons[0] as Button).pressed.emit()
	t.check(game.quest_controller.states.active.has("vardhelm_first_echo"), "I. o E / a conversa continuam funcionando (quest iniciada)")
	# M/N. estado transitório: nada no Save; o Load não abre janela.
	game._on_candidate_changed(null)
	lifecycle.force_hide()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_S
	key.ctrl_pressed = true
	key.pressed = true
	game._on_candidate_changed(rack)
	t.root.push_input(key)
	var saved := FileAccess.get_file_as_string(V2_FILE).to_lower()
	t.check(game.last_v2_save_result.is_success() and not saved.contains("hint") and not saved.contains("context") and not saved.contains("window"), "M. Save V2 não guarda nada da janela contextual")
	lifecycle.force_hide()
	var load_key := InputEventKey.new()
	load_key.physical_keycode = KEY_L
	load_key.ctrl_pressed = true
	load_key.pressed = true
	t.root.push_input(load_key)
	t.check(game.last_v2_load_result.is_success() and not hint.visible and lifecycle.state == ContextualWindowLifecycle.STATE_HIDDEN, "N. o Load não abre a janela (mesmo com ela aberta no momento do Save)")
	_isolate(t)
