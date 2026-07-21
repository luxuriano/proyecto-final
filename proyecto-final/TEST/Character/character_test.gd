extends CharacterBody2D

@export var speed = 120
var direccion := 0.0
var jump = 150
const gravity := 9
var DUBLE_JUMP = true
@onready var anim := $AnimatedSprite2D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	direccion = Input.get_axis("izq","der")
	velocity.x = direccion * speed
	
	if direccion != 0:
		anim.play("walk")
	else :
		anim.play("idle")
	
	anim.flip_h = direccion > 0 if direccion != 0 else anim.flip_h
	
	if is_on_floor() and Input.is_action_just_pressed("salto"):
		velocity.y -= jump
		DUBLE_JUMP=true
	elif !is_on_floor() and Input.is_action_just_pressed("salto"):
		velocity.y -= jump
		DUBLE_JUMP=false
	else:
		velocity.y += gravity
	
	move_and_slide()
	
