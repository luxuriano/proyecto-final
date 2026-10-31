extends CharacterBody2D

@export var speed: float = 120.0
@export var jump_force: float = 250.0
@export var double_jump_force: float = 250.0

# Gravedad por defecto en Godot
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var direccion: float = 0.0
var can_double_jump: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Movimiento izquierda/derecha
	direccion = Input.get_axis("izq", "der")
	velocity.x = direccion * speed

	# Girar el sprite
	if direccion != 0:
		anim.flip_h = direccion < 0

	# Salto y doble salto
	if is_on_floor():
		can_double_jump = true

		if Input.is_action_just_pressed("salto"):
			velocity.y = -jump_force

	elif Input.is_action_just_pressed("salto") and can_double_jump:
		# Doble salto
		velocity.y = -double_jump_force
		can_double_jump = false

	# Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# Animaciones
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
	elif direccion != 0:
		anim.play("run")
	else:
		anim.play("idle")

	move_and_slide()
