extends Node

var vida = 5
var puntos = 0

var tiene_checkpoint = false
var posicion_checkpoint = Vector2.ZERO
var escena_checkpoint = ""

var esta_en_zona_virus = false
var volviendo_desde_zona_virus = false
var cargando_partida = false

var items_recogidos = []
var virus_derrotados = []
var monedas_recogidas = []

var zona_virus_completada = false


# El checkpoint solo vale si fue activado en la escena actual
func checkpoint_valido() -> bool:
	var escena = get_tree().current_scene

	if escena == null:
		return false

	return tiene_checkpoint and escena_checkpoint == escena.scene_file_path


# Deja todo como en una partida nueva
func reiniciar() -> void:
	vida = 5
	puntos = 0

	tiene_checkpoint = false
	posicion_checkpoint = Vector2.ZERO
	escena_checkpoint = ""

	esta_en_zona_virus = false
	volviendo_desde_zona_virus = false
	cargando_partida = false

	items_recogidos.clear()
	virus_derrotados.clear()
	monedas_recogidas.clear()

	zona_virus_completada = false
