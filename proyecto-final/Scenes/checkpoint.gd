extends Area2D


var ya_usado = false


func _ready() -> void:
	monitoring = true
	monitorable = true


func _physics_process(_delta: float) -> void:

	if ya_usado:
		return

	var cuerpos = get_overlapping_bodies()

	for cuerpo in cuerpos:

		if cuerpo.name != "Lyn Personaje":
			continue

		if not cuerpo.has_method("activar_checkpoint"):
			continue

		activar_checkpoint(cuerpo)


func activar_checkpoint(lyn: Node2D) -> void:

	if ya_usado:
		return

	var posicion = global_position + Vector2(0, -20)

	lyn.activar_checkpoint(posicion)

	GameState.posicion_checkpoint = posicion
	GameState.tiene_checkpoint = true

	ya_usado = true

	monitoring = false
	monitorable = false
