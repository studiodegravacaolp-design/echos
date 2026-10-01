extends CharacterBody3D
class_name PlayerController

# Fundação mínima de movimento do Player (estilo ortográfico 2.5D).
# Sem combate, stats, habilidades ou lógica de interação — a detecção de interação
# pertence ao InteractionDetector, separado do movimento do Player.

@export var move_speed: float = 5.0
@export var gravity: float = 20.0

@onready var camera: Camera3D = $CameraRig/Camera3D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# get_vector(neg_x, pos_x, neg_y, pos_y): "move_up" é o pos_y proposital
	# aqui — assim input.y > 0 significa "em direção ao topo da tela", que é
	# o que multiplicamos por "forward" abaixo. Não inverter esta ordem.
	var input_vector := Input.get_vector("move_left", "move_right", "move_down", "move_up")
	# C11: Ctrl+S / Ctrl+L usam as mesmas teclas físicas do movimento (S = move_down).
	# Com Ctrl pressionado o personagem não anda: antes, salvar gravava a posição e o
	# personagem recuava logo em seguida, e o Load parecia devolver a outro lugar.
	if Input.is_key_pressed(KEY_CTRL):
		input_vector = Vector2.ZERO
	var direction := _movement_direction(input_vector)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()


# Converte o input 2D (tela) em uma direção 3D no plano do chão, relativa à
# orientação da câmera atual do Player — evita que "cima/baixo/lados" pareçam
# invertidos ou diagonais numa câmera ortográfica fixa em ângulo (2.5D).
func _movement_direction(input_vector: Vector2) -> Vector3:
	if input_vector == Vector2.ZERO or camera == null:
		return Vector3.ZERO

	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	return (right * input_vector.x + forward * input_vector.y).normalized()
