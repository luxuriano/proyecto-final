extends Node2D

enum Modo { NUEVA, CONTINUAR }

const FUENTE = preload("res://static/Oswald-Bold.ttf")

const COLOR_TEXTO := Color(0.62, 0.345, 1.0)
const COLOR_FONDO := Color(0.93, 0.88, 0.96)
const COLOR_FONDO_HOVER := Color(0.98, 0.94, 1.0)
const COLOR_FONDO_PRESIONADO := Color(0.85, 0.79, 0.92)
const COLOR_FONDO_OFF := Color(0.8, 0.76, 0.84)
const COLOR_BORDE := Color(0.43, 0.38, 0.5)
const COLOR_ERROR := Color(0.8, 0.1, 0.2)

@onready var nueva_partida = $NuevaPartida
@onready var continuar_partida = $ContinuarPartida
@onready var salir = $Salir

var modo: Modo = Modo.NUEVA

var panel_slots: Control
var ventana_confirmar: Control
var texto_confirmar: Label
var titulo: Label
var mensaje: Label
var botones_slot: Array[Button] = []
var botones_borrar: Array[Button] = []

var accion_pendiente: Callable = Callable()


func _ready() -> void:
	# La ventana vieja de confirmacion ya no se usa (ahora se crea dentro del panel de slots)
	var ventana_vieja = get_node_or_null("VentanaNuevaPartida")

	if ventana_vieja != null:
		ventana_vieja.visible = false

	_crear_panel_slots()

	nueva_partida.pressed.connect(_on_nueva_partida_pressed)
	continuar_partida.pressed.connect(_on_continuar_partida_pressed)
	salir.pressed.connect(_on_salir_pressed)

	_actualizar_boton_continuar()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if ventana_confirmar.visible:
		_on_cancelar_pressed()
	elif panel_slots.visible:
		_cerrar_panel()
	else:
		return

	get_viewport().set_input_as_handled()


# ======================= MENU PRINCIPAL =======================

func _on_nueva_partida_pressed() -> void:
	modo = Modo.NUEVA
	_abrir_panel()


func _on_continuar_partida_pressed() -> void:
	modo = Modo.CONTINUAR
	_abrir_panel()


func _on_salir_pressed() -> void:
	get_tree().quit()


# "Continuar" queda apagado si no hay ninguna partida guardada
func _actualizar_boton_continuar() -> void:
	var hay_partida: bool = SaveManager.hay_alguna_partida_valida()

	continuar_partida.disabled = not hay_partida

	if hay_partida:
		continuar_partida.mouse_filter = Control.MOUSE_FILTER_STOP
		continuar_partida.modulate = Color(1, 1, 1, 1)
	else:
		continuar_partida.mouse_filter = Control.MOUSE_FILTER_IGNORE
		continuar_partida.modulate = Color(1, 1, 1, 0.4)


# ======================= PANEL DE SLOTS =======================

func _abrir_panel() -> void:
	if modo == Modo.NUEVA:
		titulo.text = "NUEVA PARTIDA: ELIGE UN SLOT"
	else:
		titulo.text = "CONTINUAR PARTIDA: ELIGE UN SLOT"

	mensaje.visible = false

	_refrescar_slots()

	panel_slots.visible = true


func _cerrar_panel() -> void:
	panel_slots.visible = false
	_actualizar_boton_continuar()


func _refrescar_slots() -> void:
	for i in range(SaveManager.NUM_SLOTS):
		var slot: int = i + 1
		var resumen: Dictionary = SaveManager.leer_resumen(slot)

		var boton: Button = botones_slot[i]
		var boton_borrar: Button = botones_borrar[i]

		if not resumen["ocupado"]:
			boton.text = "SLOT %d\nVACÍO" % slot
			boton.disabled = (modo == Modo.CONTINUAR)
			boton_borrar.disabled = true

		elif not resumen["valido"]:
			boton.text = "SLOT %d\nPARTIDA DAÑADA" % slot
			boton.disabled = (modo == Modo.CONTINUAR)
			boton_borrar.disabled = false

		else:
			boton.text = "SLOT %d - %s\nPUNTOS: %d   VIDA: %d/5\nTIEMPO: %s   %s" % [
				slot,
				SaveManager.nombre_nivel(resumen["nivel"]),
				resumen["puntos"],
				resumen["vida"],
				SaveManager.formatear_tiempo(resumen["tiempo"]),
				SaveManager.formatear_fecha(resumen["fecha"])
			]
			boton.disabled = false
			boton_borrar.disabled = false


func _on_slot_pressed(slot: int) -> void:
	# Mientras se pide confirmacion, los slots no responden
	if ventana_confirmar.visible:
		return

	var resumen: Dictionary = SaveManager.leer_resumen(slot)

	if modo == Modo.CONTINUAR:
		if resumen["valido"] and not SaveManager.cargar_partida(slot):
			_mostrar_mensaje("NO SE PUDO CARGAR: " + SaveManager.ultimo_error.to_upper())
		return

	if resumen["ocupado"]:
		_pedir_confirmacion(
			"¿SOBRESCRIBIR LA PARTIDA DEL SLOT %d?\nSE PERDERÁ SU PROGRESO ACTUAL." % slot,
			_iniciar_nueva.bind(slot)
		)
	else:
		_iniciar_nueva(slot)


func _iniciar_nueva(slot: int) -> void:
	if not SaveManager.nueva_partida(slot):
		_mostrar_mensaje("NO SE PUDO CREAR LA PARTIDA: " + SaveManager.ultimo_error.to_upper())


func _on_borrar_pressed(slot: int) -> void:
	if ventana_confirmar.visible:
		return

	_pedir_confirmacion(
		"¿BORRAR LA PARTIDA DEL SLOT %d?\nESTA ACCIÓN NO SE PUEDE DESHACER." % slot,
		_borrar_slot.bind(slot)
	)


func _borrar_slot(slot: int) -> void:
	SaveManager.borrar_slot(slot)
	_refrescar_slots()


func _mostrar_mensaje(texto: String) -> void:
	mensaje.text = texto
	mensaje.visible = true

	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(mensaje):
		mensaje.visible = false


# ======================= VENTANA DE CONFIRMACION =======================

func _pedir_confirmacion(texto: String, accion: Callable) -> void:
	texto_confirmar.text = texto
	accion_pendiente = accion
	ventana_confirmar.visible = true


func _on_confirmar_pressed() -> void:
	ventana_confirmar.visible = false

	var accion: Callable = accion_pendiente
	accion_pendiente = Callable()

	if accion.is_valid():
		accion.call()


func _on_cancelar_pressed() -> void:
	ventana_confirmar.visible = false
	accion_pendiente = Callable()


# ======================= CONSTRUCCION DE LA INTERFAZ =======================

func _crear_panel_slots() -> void:
	panel_slots = Control.new()
	panel_slots.z_index = 50
	panel_slots.visible = false
	panel_slots.position = Vector2.ZERO
	panel_slots.size = get_viewport_rect().size
	add_child(panel_slots)

	var fondo_oscuro := ColorRect.new()
	fondo_oscuro.color = Color(0, 0, 0, 0.6)
	panel_slots.add_child(fondo_oscuro)
	fondo_oscuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	panel_slots.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", _estilo(COLOR_FONDO, COLOR_BORDE, 4, 16))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	margen.add_child(caja)

	titulo = Label.new()
	_estilizar_label(titulo, 34, COLOR_TEXTO)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(titulo)

	for i in range(SaveManager.NUM_SLOTS):
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 10)
		caja.add_child(fila)

		var boton := _crear_boton("", 20, Vector2(0, 96))
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.pressed.connect(_on_slot_pressed.bind(i + 1))
		fila.add_child(boton)
		botones_slot.append(boton)

		var boton_borrar := _crear_boton("BORRAR", 20, Vector2(120, 96))
		boton_borrar.pressed.connect(_on_borrar_pressed.bind(i + 1))
		fila.add_child(boton_borrar)
		botones_borrar.append(boton_borrar)

	mensaje = Label.new()
	_estilizar_label(mensaje, 20, COLOR_ERROR)
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.visible = false
	caja.add_child(mensaje)

	var volver := _crear_boton("VOLVER", 26, Vector2(0, 50))
	volver.pressed.connect(_cerrar_panel)
	caja.add_child(volver)

	# Siempre al final: asi queda por encima de todo lo demas
	_crear_ventana_confirmacion()


func _crear_ventana_confirmacion() -> void:
	ventana_confirmar = Control.new()
	ventana_confirmar.visible = false
	panel_slots.add_child(ventana_confirmar)
	ventana_confirmar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	ventana_confirmar.add_child(velo)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	ventana_confirmar.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	panel.add_theme_stylebox_override("panel", _estilo(COLOR_FONDO, COLOR_BORDE, 4, 16))
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 28)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_right", 28)
	margen.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margen)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 20)
	margen.add_child(caja)

	texto_confirmar = Label.new()
	_estilizar_label(texto_confirmar, 28, COLOR_TEXTO)
	texto_confirmar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_confirmar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto_confirmar.custom_minimum_size = Vector2(560, 0)
	caja.add_child(texto_confirmar)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)

	var boton_confirmar := _crear_boton("CONFIRMAR", 28, Vector2(0, 60))
	boton_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_confirmar.pressed.connect(_on_confirmar_pressed)
	fila.add_child(boton_confirmar)

	var boton_cancelar := _crear_boton("CANCELAR", 28, Vector2(0, 60))
	boton_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton_cancelar.pressed.connect(_on_cancelar_pressed)
	fila.add_child(boton_cancelar)


func _estilizar_label(etiqueta: Label, tamano: int, color: Color) -> void:
	etiqueta.add_theme_font_override("font", FUENTE)
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)


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
	boton.add_theme_color_override("font_disabled_color", Color(0.62, 0.345, 1.0, 0.4))

	boton.add_theme_stylebox_override("normal", _estilo(COLOR_FONDO, COLOR_BORDE, 3, 8))
	boton.add_theme_stylebox_override("hover", _estilo(COLOR_FONDO_HOVER, COLOR_TEXTO, 3, 8))
	boton.add_theme_stylebox_override("pressed", _estilo(COLOR_FONDO_PRESIONADO, COLOR_TEXTO, 3, 8))
	boton.add_theme_stylebox_override("focus", _estilo(COLOR_FONDO_HOVER, COLOR_TEXTO, 3, 8))
	boton.add_theme_stylebox_override("disabled", _estilo(COLOR_FONDO_OFF, COLOR_BORDE, 3, 8))

	return boton


func _estilo(fondo: Color, borde: Color, grosor: int, radio: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor)
	estilo.set_corner_radius_all(radio)
	estilo.set_content_margin_all(12)
	return estilo
