# SaveManager.gd (Autoload)
# Sistema de guardado con 3 slots (user://slot_1.json, slot_2.json, slot_3.json)
extends Node

const NUM_SLOTS := 3
const VERSION_GUARDADO := 1
const NIVEL_INICIAL := "res://Scenes/nivel_1.tscn"
const VIDA_MAXIMA := 5

# Se avisa cuando un nivel no se pudo abrir (el menu muestra el motivo)
signal error_de_carga(motivo: String)

# Slot en el que se esta jugando (lo elige el menu principal)
var slot_actual: int = 1

# Motivo corto del ultimo fallo (la estatua y el menu lo muestran en pantalla)
var ultimo_error: String = ""

var _tiempo_acumulado: float = 0.0
var _inicio_sesion_ms: int = 0
var _puede_reintentar: bool = false


func _ready() -> void:
	_inicio_sesion_ms = Time.get_ticks_msec()


# ======================= CONSULTAS =======================

func slot_valido(slot: int) -> bool:
	return slot >= 1 and slot <= NUM_SLOTS


func ruta_slot(slot: int) -> String:
	return "user://slot_%d.json" % slot


# Datos resumidos de un slot para mostrarlos en el menu
func leer_resumen(slot: int) -> Dictionary:
	var resumen := {
		"ocupado": false,
		"valido": false,
		"nivel": "",
		"puntos": 0,
		"vida": VIDA_MAXIMA,
		"tiempo": 0.0,
		"fecha": "",
		"anim1": true,
		"anim2": true,
		"anim3": true
	}

	if not slot_valido(slot):
		return resumen

	var ruta := ruta_slot(slot)
	resumen["ocupado"] = FileAccess.file_exists(ruta) or FileAccess.file_exists(ruta + ".bak")

	if not resumen["ocupado"]:
		return resumen

	var datos := _leer_datos_slot(slot)

	if datos.is_empty():
		return resumen

	resumen["valido"] = true
	resumen["nivel"] = str(datos.get("nivel", NIVEL_INICIAL))
	resumen["puntos"] = int(datos.get("puntos", 0))
	resumen["vida"] = int(datos.get("vida", VIDA_MAXIMA))
	resumen["tiempo"] = float(datos.get("tiempo_jugado", 0.0))
	resumen["fecha"] = str(datos.get("fecha", ""))

	return resumen


func hay_alguna_partida_valida() -> bool:
	for slot in range(1, NUM_SLOTS + 1):
		if leer_resumen(slot)["valido"]:
			return true

	return false


# ======================= ACCIONES =======================

# Empieza una partida nueva en el slot (crea el archivo enseguida)
func nueva_partida(slot: int) -> bool:
	ultimo_error = ""
	_puede_reintentar = false

	if not slot_valido(slot):
		ultimo_error = "slot invalido"
		return false

	GameState.reiniciar()

	slot_actual = slot
	_tiempo_acumulado = 0.0
	_inicio_sesion_ms = Time.get_ticks_msec()

	_borrar_archivos(ruta_slot(slot))

	if not _escribir_seguro(ruta_slot(slot), _construir_datos(NIVEL_INICIAL)):
		return false

	return _abrir_nivel(NIVEL_INICIAL)


# Guarda en el slot actual. "lyn" es el personaje y "posicion" donde reaparece al cargar.
func guardar_partida(lyn, posicion: Vector2) -> bool:
	ultimo_error = ""

	var escena = get_tree().current_scene

	if escena == null or escena.scene_file_path == "":
		ultimo_error = "escena sin .tscn"
		print("[Guardado] ERROR: ", ultimo_error)
		return false

	# Solo se guarda en los niveles (no dentro de la zona virus)
	if GameState.esta_en_zona_virus:
		ultimo_error = "zona virus"
		print("[Guardado] ERROR: ", ultimo_error)
		return false

	if not slot_valido(slot_actual):
		ultimo_error = "slot invalido"
		return false

	GameState.vida = lyn.vida
	GameState.puntos = lyn.puntos
	GameState.tiene_checkpoint = true
	GameState.posicion_checkpoint = posicion
	GameState.escena_checkpoint = escena.scene_file_path

	var guardado := _escribir_seguro(ruta_slot(slot_actual), _construir_datos(escena.scene_file_path))

	if guardado:
		print("[Guardado] OK slot ", slot_actual, " en ", ProjectSettings.globalize_path(ruta_slot(slot_actual)))
		print("[Guardado] ", GameState.monedas_recogidas.size(), " monedas, ", GameState.virus_derrotados.size(), " virus, ", GameState.items_recogidos.size(), " items, ", GameState.llaves_obtenidas.size(), " llaves, ", GameState.puertas_abiertas.size(), " puertas")

	return guardado


# Carga un slot y cambia al nivel guardado
func cargar_partida(slot: int) -> bool:
	ultimo_error = ""

	if not slot_valido(slot):
		ultimo_error = "slot invalido"
		return false

	var datos := _leer_datos_slot(slot)

	if datos.is_empty():
		ultimo_error = "partida danada o inexistente"
		print("[Carga] ERROR: ", ultimo_error)
		return false

	var nivel := str(datos.get("nivel", NIVEL_INICIAL))

	var posicion := Vector2.ZERO
	var cp = datos.get("checkpoint", [0, 0])

	if typeof(cp) == TYPE_ARRAY and cp.size() >= 2:
		posicion = Vector2(float(cp[0]), float(cp[1]))

	GameState.reiniciar()

	GameState.vida = clampi(int(datos.get("vida", VIDA_MAXIMA)), 1, VIDA_MAXIMA)
	GameState.puntos = maxi(int(datos.get("puntos", 0)), 0)

	GameState.tiene_checkpoint = bool(datos.get("tiene_checkpoint", false))
	GameState.posicion_checkpoint = posicion

	if GameState.tiene_checkpoint:
		GameState.escena_checkpoint = nivel

	GameState.items_recogidos = _a_textos(datos.get("items_recogidos", []))
	GameState.virus_derrotados = _a_textos(datos.get("virus_derrotados", []))
	GameState.monedas_recogidas = _a_textos(datos.get("monedas_recogidas", []))
	GameState.llaves_obtenidas = _a_textos(datos.get("llaves_obtenidas", []))
	GameState.puertas_abiertas = _a_textos(datos.get("puertas_abiertas", []))
	GameState.dash_desbloqueado = bool(datos.get("dash_desbloqueado", false))
	GameState.zona_virus_completada = bool(datos.get("zona_virus_completada", false))

	print("[Carga] Slot ", slot, ": ", GameState.monedas_recogidas.size(), " monedas, ", GameState.virus_derrotados.size(), " virus, ", GameState.items_recogidos.size(), " items, ", GameState.llaves_obtenidas.size(), " llaves, ", GameState.puertas_abiertas.size(), " puertas")

	GameState.cargando_partida = true

	slot_actual = slot
	_tiempo_acumulado = float(datos.get("tiempo_jugado", 0.0))
	_inicio_sesion_ms = Time.get_ticks_msec()

	_puede_reintentar = nivel != NIVEL_INICIAL

	if not _abrir_nivel(nivel):
		return _reintentar_con_nivel_inicial()

	return true


func borrar_slot(slot: int) -> void:
	if slot_valido(slot):
		_borrar_archivos(ruta_slot(slot))


# ======================= UTILIDADES =======================

func tiempo_total() -> float:
	return _tiempo_acumulado + float(Time.get_ticks_msec() - _inicio_sesion_ms) / 1000.0


func nombre_nivel(ruta: String) -> String:
	return ruta.get_file().get_basename().replace("_", " ").to_upper()


func formatear_tiempo(segundos: float) -> String:
	var total := int(segundos)
	var horas := floori(total / 3600.0)
	var minutos := floori((total % 3600) / 60.0)

	return "%02d:%02d:%02d" % [horas, minutos, total % 60]


# "2026-10-29 14:30:00" -> "29/10/2026 14:30"
func formatear_fecha(texto: String) -> String:
	var partes := texto.split(" ")

	if partes.size() < 2:
		return texto

	var fecha := partes[0].split("-")
	var hora := partes[1].split(":")

	if fecha.size() < 3 or hora.size() < 2:
		return texto

	return "%s/%s/%s %s:%s" % [fecha[2], fecha[1], fecha[0], hora[0], hora[1]]


# ======================= INTERNO =======================

func _construir_datos(nivel: String) -> Dictionary:
	return {
		"version": VERSION_GUARDADO,
		"nivel": nivel,
		"vida": int(GameState.vida),
		"puntos": int(GameState.puntos),
		"tiene_checkpoint": bool(GameState.tiene_checkpoint),
		"checkpoint": [GameState.posicion_checkpoint.x, GameState.posicion_checkpoint.y],
		"items_recogidos": _a_textos(GameState.items_recogidos),
		"virus_derrotados": _a_textos(GameState.virus_derrotados),
		"monedas_recogidas": _a_textos(GameState.monedas_recogidas),
		"llaves_obtenidas": _a_textos(GameState.llaves_obtenidas),
		"puertas_abiertas": _a_textos(GameState.puertas_abiertas),
		"dash_desbloqueado": bool(GameState.dash_desbloqueado),
		"zona_virus_completada": bool(GameState.zona_virus_completada),
		"tiempo_jugado": tiempo_total(),
		"fecha": Time.get_datetime_string_from_system(false, true)
	}


# Si el nivel guardado no abre, se empieza desde el nivel inicial (sin checkpoint)
func _reintentar_con_nivel_inicial() -> bool:
	if _puede_reintentar:
		_puede_reintentar = false
		GameState.tiene_checkpoint = false
		GameState.escena_checkpoint = ""
		return _abrir_nivel(NIVEL_INICIAL)

	GameState.cargando_partida = false
	return false


func _on_carga_fallida(motivo: String) -> void:
	if _reintentar_con_nivel_inicial():
		return

	ultimo_error = motivo
	error_de_carga.emit(motivo)


# Abre un nivel mostrando la pantalla de carga (si esta instalada) y,
# si no, cambia de escena directo. Dice exactamente por que falla.
func _abrir_nivel(ruta: String) -> bool:
	var pantalla = get_node_or_null("/root/PantallaCarga")

	if pantalla != null:
		if not pantalla.carga_fallida.is_connected(_on_carga_fallida):
			pantalla.carga_fallida.connect(_on_carga_fallida)

		pantalla.cargar_nivel(ruta)
		return true

	var escena := ResourceLoader.load(ruta) as PackedScene

	if escena == null:
		ultimo_error = "leer nivel"
		print("[Nivel] ERROR: no se pudo leer ", ruta, " (mira los errores rojos de la consola)")
		return false

	var resultado := get_tree().change_scene_to_packed(escena)

	if resultado != OK:
		ultimo_error = "crear nivel (cod %d)" % resultado
		print("[Nivel] ERROR: no se pudo crear ", ruta, " (cod ", resultado, ")")
		return false

	return true


func _abs(ruta: String) -> String:
	return ProjectSettings.globalize_path(ruta)


func _es_valido(datos: Dictionary) -> bool:
	return datos.has("nivel") and typeof(datos["nivel"]) == TYPE_STRING


func _leer_json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}

	var archivo := FileAccess.open(ruta, FileAccess.READ)

	if archivo == null:
		return {}

	var texto := archivo.get_as_text()
	archivo.close()

	var json := JSON.new()

	if json.parse(texto) != OK:
		return {}

	var datos = json.data

	if typeof(datos) != TYPE_DICTIONARY:
		return {}

	return datos


# Lee el slot; si el archivo principal esta danado usa la copia de seguridad (.bak)
func _leer_datos_slot(slot: int) -> Dictionary:
	var ruta := ruta_slot(slot)

	var datos := _leer_json(ruta)

	if _es_valido(datos):
		return datos

	datos = _leer_json(ruta + ".bak")

	if _es_valido(datos):
		print("[Guardado] Slot ", slot, " recuperado desde la copia de seguridad")
		return datos

	return {}


# Escribe en un archivo temporal, lo verifica y recien despues reemplaza el real.
# Asi, si se corta la luz o falla algo a la mitad, la partida anterior no se pierde.
func _escribir_seguro(ruta: String, datos: Dictionary) -> bool:
	var temporal := ruta + ".tmp"
	var texto := JSON.stringify(datos, "\t")

	var archivo := FileAccess.open(temporal, FileAccess.WRITE)

	if archivo == null:
		ultimo_error = "archivo (cod %d)" % FileAccess.get_open_error()
		print("[Guardado] ERROR: ", ultimo_error)
		return false

	archivo.store_string(texto)
	archivo.close()

	if not _es_valido(_leer_json(temporal)):
		ultimo_error = "verificacion fallida"
		print("[Guardado] ERROR: ", ultimo_error)
		DirAccess.remove_absolute(_abs(temporal))
		return false

	if FileAccess.file_exists(ruta):
		DirAccess.copy_absolute(_abs(ruta), _abs(ruta + ".bak"))

	var resultado := DirAccess.rename_absolute(_abs(temporal), _abs(ruta))

	if resultado != OK:
		# Plan B: escribir directo sobre el archivo final
		var directo := FileAccess.open(ruta, FileAccess.WRITE)

		if directo == null:
			ultimo_error = "archivo (cod %d)" % FileAccess.get_open_error()
			print("[Guardado] ERROR: ", ultimo_error)
			return false

		directo.store_string(texto)
		directo.close()

		DirAccess.remove_absolute(_abs(temporal))

	return true


func _borrar_archivos(ruta: String) -> void:
	for sufijo in ["", ".bak", ".tmp"]:
		var archivo: String = ruta + sufijo

		if FileAccess.file_exists(archivo):
			DirAccess.remove_absolute(_abs(archivo))


func _a_textos(lista) -> Array:
	var resultado := []

	if typeof(lista) != TYPE_ARRAY:
		return resultado

	for elemento in lista:
		resultado.append(str(elemento))

	return resultado
