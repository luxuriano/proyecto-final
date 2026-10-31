# PauseMenu.gd (Autoload)
# Menu de pausa: Esc lo abre y lo cierra. Permite volver al juego o salir al menu principal.
extends CanvasLayer

const ESCENA_MENU := "res://Scenes/menu.tscn"
const FUENTE = preload("res://static/Oswald-Bold.ttf")

const COLOR_TEXTO := Color(0.62, 0.345, 1.0)
const COLOR_FONDO := Color(0.93, 0.88, 0.96)
const COLOR_FONDO_HOVER := Color(0.98, 0.94, 1.0)
const COLOR_FONDO_PRESIONADO := Color(0.85, 0.79, 0.92)
const COLOR_BORDE := Color(0.43, 0.38, 0.5)

var raiz: Control
var grupo_principal: VBoxContainer
var grupo_confirmar: VBoxContainer
var boton_continuar: Button
var boton_no: Button

var abierto := false


func _ready() -> void:
	# Tiene que seguir funcionando mientras el juego esta en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	_crear_interfaz()

	raiz.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if abierto:
		if grupo_confirmar.visible:
			_cancelar_salida()
		else:
			_reanudar()

		get_viewport().set_input_as_handled()
		return

	if _se_puede_pausar():
		_abrir()
		get_viewport().set_input_as_handled()


# No se pausa en el menu principal (ahi Esc cierra la pantalla de slots)
func _se_puede_pausar() -> bool:
	var escena := get_tree().current_scene

	if escena == null:
		return false

	if escena.scene_file_path == ESCENA_MENU:
		return false

	return not get_tree().paused


func _abrir() -> void:
	abierto = true
	get_tree().paused = true

	grupo_principal.visible = true
	grupo_confirmar.visible = false
	raiz.visible = true

	boton_continuar.grab_focus()


func _reanudar() -> void:
	abierto = false
	raiz.visible = false
	get_tree().paused = false


func _pedir_confirmacion() -> void:
	grupo_principal.visible = false
	grupo_confirmar.visible = true

	boton_no.grab_focus()


func _cancelar_salida() -> void:
	grupo_confirmar.visible = false
	grupo_principal.visible = true

	boton_continuar.grab_focus()


func _salir_al_menu() -> void:
	_reanudar()
	get_tree().change_scene_to_file(ESCENA_MENU)


# ======================= CONSTRUCCION DE LA INTERFAZ =======================

func _crear_interfaz() -> void:
	raiz = Control.new()
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fondo_oscuro := ColorRect.new()
	fondo_oscuro.color = Color(0, 0, 0, 0.6)
	raiz.add_child(fondo_oscuro)
	fondo_oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	raiz.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", _estilo(COLOR_FONDO, COLOR_BORDE, 4, 16))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 28)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_right", 28)
	margen.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margen)

	var caja := VBoxContainer.new()
	margen.add_child(caja)

	# --- Pantalla principal de la pausa ---
	grupo_principal = VBoxContainer.new()
	grupo_principal.add_theme_constant_override("separation", 14)
	caja.add_child(grupo_principal)

	var titulo := Label.new()
	_estilizar_label(titulo, 40)
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grupo_principal.add_child(titulo)

	boton_continuar = _crear_boton("CONTINUAR", 30, Vector2(0, 64))
	boton_continuar.pressed.connect(_reanudar)
	grupo_principal.add_child(boton_continuar)

	var boton_salir := _crear_boton("SALIR AL MENÚ", 30, Vector2(0, 64))
	boton_salir.pressed.connect(_pedir_confirmacion)
	grupo_principal.add_child(boton_salir)

	# --- Confirmacion para salir al menu ---
	grupo_confirmar = VBoxContainer.new()
	grupo_confirmar.add_theme_constant_override("separation", 14)
	grupo_confirmar.visible = false
	caja.add_child(grupo_confirmar)

	var aviso := Label.new()
	_estilizar_label(aviso, 28)
	aviso.text = "¿SALIR AL MENÚ?\nSE PERDERÁ EL PROGRESO QUE NO HAYAS GUARDADO."
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.custom_minimum_size = Vector2(400, 0)
	grupo_confirmar.add_child(aviso)

	var boton_si := _crear_boton("SÍ, SALIR", 28, Vector2(0, 56))
	boton_si.pressed.connect(_salir_al_menu)
	grupo_confirmar.add_child(boton_si)

	boton_no = _crear_boton("NO, VOLVER", 28, Vector2(0, 56))
	boton_no.pressed.connect(_cancelar_salida)
	grupo_confirmar.add_child(boton_no)


func _estilizar_label(etiqueta: Label, tamano: int) -> void:
	etiqueta.add_theme_font_override("font", FUENTE)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", COLOR_TEXTO)


func _crear_boton(texto: String, tamano: int, minimo: Vector2) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = minimo

	boton.add_theme_font_override("font", FUENTE)
	boton.add_theme_font_size_override("font_size", tamano)

	boton.add_theme_color_override("font_color", COLOR_TEXTO)
	boton.add_theme_color_override("font_hover_color", COLOR_TEXTO)
	boton.add_theme_color_override("font_pressed_color", COLOR_TEXTO)
	boton.add_theme_color_override("font_hover_pressed_color", COLOR_TEXTO)
	boton.add_theme_color_override("font_focus_color", COLOR_TEXTO)

	boton.add_theme_stylebox_override("normal", _estilo(COLOR_FONDO, COLOR_BORDE, 3, 8))
	boton.add_theme_stylebox_override("hover", _estilo(COLOR_FONDO_HOVER, COLOR_TEXTO, 3, 8))
	boton.add_theme_stylebox_override("pressed", _estilo(COLOR_FONDO_PRESIONADO, COLOR_TEXTO, 3, 8))
	boton.add_theme_stylebox_override("focus", _estilo(COLOR_FONDO_HOVER, COLOR_TEXTO, 3, 8))

	return boton


func _estilo(fondo: Color, borde: Color, grosor: int, radio: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(radio)
	estilo.set_content_margin_all(12)
	return estilo
