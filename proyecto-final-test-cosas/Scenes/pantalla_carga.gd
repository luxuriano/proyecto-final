# PantallaCarga (Autoload con escena)
# Muestra una imagen mientras se carga un nivel, con fundido de entrada y de salida.
extends CanvasLayer

signal carga_fallida(motivo: String)

# Tiempo minimo que se ve la pantalla (para que no sea un parpadeo)
const SEGUNDOS_MINIMOS := 1.5
const DURACION_FUNDIDO := 0.35

@onready var raiz: Control = $Raiz
@onready var texto: Label = $Raiz/Texto
@onready var barra: ProgressBar = $Raiz/Barra

var _ruta := ""
var _tiempo := 0.0
var _cargando := false
var _progreso: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_process(false)

	_estilizar_barra()


# Carga el nivel en segundo plano mostrando la pantalla de carga
func cargar_nivel(ruta: String) -> void:
	if _cargando:
		return

	_ruta = ruta
	_tiempo = 0.0
	_cargando = true
	_progreso = []

	barra.value = 0.0
	texto.text = "CARGANDO"
	raiz.modulate.a = 0.0
	visible = true

	create_tween().tween_property(raiz, "modulate:a", 1.0, DURACION_FUNDIDO)

	var resultado := ResourceLoader.load_threaded_request(ruta, "", true)

	if resultado != OK:
		_fallar("leer nivel")
		return

	set_process(true)


func _process(delta: float) -> void:
	_tiempo += delta

	texto.text = "CARGANDO" + ".".repeat(int(_tiempo * 3.0) % 4)

	var estado := ResourceLoader.load_threaded_get_status(_ruta, _progreso)
	var avance := 0.0

	if _progreso.size() > 0:
		avance = float(_progreso[0])

	# La barra no llega al final antes del tiempo minimo
	barra.value = move_toward(barra.value, minf(avance, _tiempo / SEGUNDOS_MINIMOS), delta * 2.0)

	if estado == ResourceLoader.THREAD_LOAD_FAILED or estado == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fallar("leer nivel")
	elif estado == ResourceLoader.THREAD_LOAD_LOADED and _tiempo >= SEGUNDOS_MINIMOS:
		_terminar()


func _terminar() -> void:
	_cargando = false
	set_process(false)

	var escena := ResourceLoader.load_threaded_get(_ruta) as PackedScene

	if escena == null:
		_fallar("leer nivel")
		return

	barra.value = 1.0

	var resultado := get_tree().change_scene_to_packed(escena)

	if resultado != OK:
		_fallar("crear nivel (cod %d)" % resultado)
		return

	# Se espera a que el nivel ya este armado y recien ahi se hace el fundido de salida
	await get_tree().process_frame
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(raiz, "modulate:a", 0.0, DURACION_FUNDIDO)
	await tween.finished

	visible = false


func _fallar(motivo: String) -> void:
	_cargando = false
	set_process(false)
	visible = false

	print("[PantallaCarga] ERROR: ", motivo, " (", _ruta, ")")

	carga_fallida.emit(motivo)


func _estilizar_barra() -> void:
	var fondo_barra := StyleBoxFlat.new()
	fondo_barra.bg_color = Color(0, 0, 0, 0.5)
	fondo_barra.set_corner_radius_all(8)

	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.62, 0.345, 1.0)
	relleno.set_corner_radius_all(8)

	barra.add_theme_stylebox_override("background", fondo_barra)
	barra.add_theme_stylebox_override("fill", relleno)
