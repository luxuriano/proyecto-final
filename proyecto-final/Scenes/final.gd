extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Animacion.play("final")

func _process(delta: float) -> void:
	if $Animacion.animation_finished:
		await $Animacion.animation_finished
		PantallaCarga.cargar_nivel("res://Scenes/menu.tscn")
