class_name ContextualWindowLifecycle
extends Node

## C18 — ciclo de vida de uma janela contextual (só apresentação). Reutilizável:
## quem decide QUANDO abrir/fechar é o sistema existente (ex.: o candidato do detector
## de interação); este componente só decide COMO a janela entra, fica e sai.
##
##   HIDDEN ──request_open──▶ VISIBLE (fade-in curto; não reinicia se já está visível)
##   VISIBLE ──request_close──▶ PENDING_CLOSE (espera close_delay; continua na tela)
##   PENDING_CLOSE ──request_open──▶ VISIBLE (cancela o fechamento; sem animação)
##   PENDING_CLOSE ──timeout──▶ CLOSING (fade-out curto) ──▶ HIDDEN
##   CLOSING ──request_open──▶ VISIBLE (volta a partir da opacidade atual)
##   qualquer ──force_hide──▶ HIDDEN (imediato; ex.: uma conversa começou)
##
## Sem _process e sem checagem de distância: um Timer de uso único e tweens curtos.
## Estado transitório: nada disto é salvo.

signal state_changed(state: String)

const STATE_HIDDEN := "hidden"
const STATE_VISIBLE := "visible"
const STATE_PENDING_CLOSE := "pending_close"
const STATE_CLOSING := "closing"

var close_delay := 0.75
var fade_in := 0.10
var fade_out := 0.15
var state := STATE_HIDDEN
## Quantas vezes a janela entrou de fato (fade-in). Voltar durante o atraso não conta.
var open_count := 0

var _target: CanvasItem = null
var _timer: Timer = null
var _tween: Tween = null


## config: {"close_delay", "fade_in", "fade_out"} (segundos; valores ausentes = padrão).
func configure(target: CanvasItem, config: Dictionary = {}) -> void:
	_target = target
	close_delay = float(config.get("close_delay", close_delay))
	fade_in = float(config.get("fade_in", fade_in))
	fade_out = float(config.get("fade_out", fade_out))
	if _timer == null:
		_timer = Timer.new()
		_timer.name = "CloseDelay"
		_timer.one_shot = true
		_timer.timeout.connect(_on_close_timeout)
		add_child(_timer)
	_target.visible = false
	_set_alpha(1.0)
	_set_state(STATE_HIDDEN)


func is_open() -> bool:
	return state != STATE_HIDDEN


func is_close_pending() -> bool:
	return state == STATE_PENDING_CLOSE


func request_open() -> void:
	if _target == null:
		return
	match state:
		STATE_VISIBLE:
			return
		STATE_PENDING_CLOSE:
			_timer.stop()
			_set_state(STATE_VISIBLE)
		STATE_CLOSING:
			_kill_tween()
			_fade_to(1.0, fade_in)
			_set_state(STATE_VISIBLE)
		_:
			open_count += 1
			_kill_tween()
			_set_alpha(0.0)
			_target.visible = true
			_fade_to(1.0, fade_in)
			_set_state(STATE_VISIBLE)


func request_close() -> void:
	if state != STATE_VISIBLE:
		return
	if close_delay <= 0.0:
		_on_close_timeout()
		return
	_timer.start(close_delay)
	_set_state(STATE_PENDING_CLOSE)


func force_hide() -> void:
	if _target == null:
		return
	if _timer != null:
		_timer.stop()
	_kill_tween()
	_target.visible = false
	_set_alpha(1.0)
	_set_state(STATE_HIDDEN)


func _on_close_timeout() -> void:
	if state != STATE_PENDING_CLOSE and state != STATE_VISIBLE:
		return
	_set_state(STATE_CLOSING)
	_kill_tween()
	if fade_out <= 0.0 or not is_inside_tree():
		_finish_close()
		return
	_tween = create_tween()
	_tween.tween_property(_target, "modulate:a", 0.0, fade_out)
	_tween.tween_callback(_finish_close)


func _finish_close() -> void:
	if state != STATE_CLOSING:
		return
	_target.visible = false
	_set_alpha(1.0)
	_set_state(STATE_HIDDEN)


func _fade_to(alpha: float, duration: float) -> void:
	if duration <= 0.0 or not is_inside_tree():
		_set_alpha(alpha)
		return
	_tween = create_tween()
	_tween.tween_property(_target, "modulate:a", alpha, duration)


func _set_alpha(alpha: float) -> void:
	var color := _target.modulate
	color.a = alpha
	_target.modulate = color


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _set_state(next: String) -> void:
	if state == next:
		return
	state = next
	state_changed.emit(state)
