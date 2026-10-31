# Estatua del dinosaurio: al apretar E guarda la partida en el slot actual y fija el checkpoint
extends Area2D

var lyn_actual = null
var ocupada = false

@onready var sprite = $Sprite2D
@onready var boton_e = $BotonE
@onready var label_e = $LabelE
@onready var pregunta = $Pregunta
@onready var mensaje = $Mensaje


func _ready() -> void:
	monitoring = true
	monitorable = true

	_mostrar_pregunta(false)
	mensaje.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Solo revisa la tecla E mientras Lyn esta cerca
	set_process(false)


func _process(_delta: float) -> void:
	if lyn_actual == null or ocupada:
		return

	if Input.is_action_just_pressed("ui_e"):
		_guardar()


func _on_body_entered(body: Node2D) -> void:
	if body.name != "Lyn Personaje":
		return

	lyn_actual = body
	set_process(true)

	if not ocupada:
		_mostrar_pregunta(true)


func _on_body_exited(body: Node2D) -> void:
	if body != lyn_actual:
		return

	lyn_actual = null
	set_process(false)

	_mostrar_pregunta(false)


func _guardar() -> void:
	if lyn_actual == null or ocupada:
		return

	ocupada = true
	_mostrar_pregunta(false)

	var posicion = global_position + Vector2(0, -20)

	# 1) Checkpoint: si Lyn muere reaparece aca
	lyn_actual.activar_checkpoint(posicion)

	# 2) Guardado en disco (slot elegido en el menu)
	if SaveManager.guardar_partida(lyn_actual, posicion):
		_mostrar_mensaje("Partida guardada (Slot %d)" % SaveManager.slot_actual)
	else:
		_mostrar_mensaje("Error al guardar: " + SaveManager.ultimo_error)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.0, 0.5), 0.15)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.5)

	await get_tree().create_timer(2.0).timeout

	ocupada = false

	if lyn_actual != null:
		_mostrar_pregunta(true)


func _mostrar_pregunta(mostrar: bool) -> void:
	boton_e.visible = mostrar
	label_e.visible = mostrar
	pregunta.visible = mostrar


func _mostrar_mensaje(texto: String) -> void:
	mensaje.text = texto
	mensaje.visible = true

	await get_tree().create_timer(1.5).timeout

	mensaje.visible = false
