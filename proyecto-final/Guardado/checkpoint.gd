# RobotStatue.gd
extends Area2D

@export var activation_animation_name: String = "activate"
@onready var sprite: Sprite2D = $Sprite2D # O Sprite2D / AnimationPlayer

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_activated:
		is_activated = true
		
		# Guardamos la posición en memoria dentro del Autoload (sin tocar disco)
		SaveManager.current_checkpoint_pos = global_position
		
		# Feedback visual / animación
		if sprite and sprite.sprite_frames.has_animation(activation_animation_name):
			sprite.play(activation_animation_name)
			
		print("🤖 Estatua Robot activada: Checkpoint de respawn registrado en ", global_position)
