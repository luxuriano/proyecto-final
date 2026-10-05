extends Node

var vida = 5
var puntos = 0

var tiene_checkpoint = false
var posicion_checkpoint = Vector2.ZERO

var esta_en_zona_virus = false
var volviendo_desde_zona_virus = false

var items_recogidos = []
var virus_derrotados = []

var zona_virus_completada = false
