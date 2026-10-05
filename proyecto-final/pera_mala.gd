extends CharacterBody2D

const VELOCIDAD = 100.0
const GRAVEDAD = 980.0

const TIEMPO_PREPARACION_ATAQUE = 0.8
const TIEMPO_COOLDOWN_ATAQUE = 1.0
const DANIO = 1

const VIDA_MAXIMA = 5
const TIEMPO_DANO = 0.5
const TIEMPO_MUERTE = 3.0

const ITEM_CURACION = preload("res://Scenes/item_curacion.tscn")

var vida = VIDA_MAXIMA

var lyn_actual = null

var preparando_ataque = false
var tiempo_preparacion = 0.0

var en_cooldown = false
var tiempo_cooldown = 0.0

var punto_ataque_actual = null

var mirando_derecha = false
var atacando = false

var recibiendo_dano = false
var tiempo_dano = 0.0

var flip_dano = false

var golpe_ya_recibido = false

var esta_muerto = false


func _ready() -> void:

	if name in GameState.virus_derrotados:
		queue_free()
		return

	$PuntoAtaqueIzq.monitoring = true
	$PuntoAtaqueDer.monitoring = true

	$RangoPegar.monitoring = true
	$RangoPegar.monitorable = true

	$AnimatedSprite2D.play("Virusquieto")
	$AnimatedSprite2D.flip_h = false


func _physics_process(delta: float) -> void:

	if esta_muerto:

		velocity = Vector2.ZERO

		move_and_slide()

		return


	if not is_on_floor():
		velocity.y += GRAVEDAD * delta
	else:
		velocity.y = 0


	if recibiendo_dano:

		velocity = Vector2.ZERO

		tiempo_dano -= delta

		$AnimatedSprite2D.flip_h = flip_dano

		if tiempo_dano <= 0:

			recibiendo_dano = false

			actualizar_animacion()

		move_and_slide()

		return


	buscar_lyn()
	actualizar_cooldown(delta)

	comprobar_dano_de_lyn()


	if recibiendo_dano:

		move_and_slide()

		return


	if lyn_actual != null:

		actualizar_punto_ataque()

		if not preparando_ataque and not en_cooldown and not atacando:

			var direccion = sign(lyn_actual.global_position.x - global_position.x)

			velocity.x = direccion * VELOCIDAD

			if direccion > 0:
				mirando_derecha = true
			elif direccion < 0:
				mirando_derecha = false

		else:

			velocity.x = 0

	else:

		velocity.x = 0


	actualizar_ataque(delta)


	if not atacando:
		actualizar_animacion()


	move_and_slide()


func buscar_lyn() -> void:

	lyn_actual = null

	var areas_detectadas = $RangoVision.get_overlapping_areas()

	for area in areas_detectadas:

		if area.name == "DetectorVirus":

			var lyn = area.get_parent()

			if lyn.has_method("recibir_dano"):

				if "esta_derrotado" in lyn and lyn.esta_derrotado:
					return

				lyn_actual = lyn

			break


func actualizar_punto_ataque() -> void:

	if lyn_actual == null:
		return


	if "esta_derrotado" in lyn_actual and lyn_actual.esta_derrotado:

		$PuntoAtaqueIzq.monitoring = false
		$PuntoAtaqueDer.monitoring = false

		punto_ataque_actual = null

		return


	if lyn_actual.global_position.x < global_position.x:

		punto_ataque_actual = $PuntoAtaqueIzq

		$PuntoAtaqueIzq.monitoring = true
		$PuntoAtaqueDer.monitoring = false

		mirando_derecha = false

	else:

		punto_ataque_actual = $PuntoAtaqueDer

		$PuntoAtaqueIzq.monitoring = false
		$PuntoAtaqueDer.monitoring = true

		mirando_derecha = true


func actualizar_cooldown(delta: float) -> void:

	if en_cooldown:

		tiempo_cooldown -= delta

		if tiempo_cooldown <= 0:

			tiempo_cooldown = 0
			en_cooldown = false


func comprobar_dano_de_lyn() -> void:

	var areas_detectadas = $RangoPegar.get_overlapping_areas()

	var hay_ataque_de_lyn = false


	for area in areas_detectadas:

		if area.name == "PegarIzq" or area.name == "PegarDer":

			hay_ataque_de_lyn = true

			break


	if not hay_ataque_de_lyn:

		golpe_ya_recibido = false

		return


	if recibiendo_dano or esta_muerto:
		return


	if golpe_ya_recibido:
		return


	for area in areas_detectadas:

		if area.name == "PegarIzq":

			golpe_ya_recibido = true

			recibir_dano_de_lyn(true)

			return


		if area.name == "PegarDer":

			golpe_ya_recibido = true

			recibir_dano_de_lyn(false)

			return


func recibir_dano_de_lyn(reflejar: bool) -> void:

	if recibiendo_dano or esta_muerto:
		return


	vida -= DANIO

	vida = max(vida, 0)


	if vida <= 0:

		morir()

		return


	recibiendo_dano = true
	tiempo_dano = TIEMPO_DANO


	preparando_ataque = false
	tiempo_preparacion = 0

	en_cooldown = false
	tiempo_cooldown = 0

	atacando = false

	velocity = Vector2.ZERO

	flip_dano = reflejar

	$AnimatedSprite2D.flip_h = flip_dano
	$AnimatedSprite2D.play("Virusdaño")


func morir() -> void:

	if esta_muerto:
		return


	esta_muerto = true

	if name not in GameState.virus_derrotados:
		GameState.virus_derrotados.append(name)

	collision_layer = 0
	collision_mask = 0

	recibiendo_dano = false
	preparando_ataque = false
	atacando = false
	en_cooldown = false

	tiempo_dano = 0
	tiempo_preparacion = 0
	tiempo_cooldown = 0

	velocity = Vector2.ZERO

	lyn_actual = null
	punto_ataque_actual = null

	$PuntoAtaqueIzq.monitoring = false
	$PuntoAtaqueDer.monitoring = false

	$RangoVision.monitoring = false
	$RangoPegar.monitoring = false

	if mirando_derecha:

		$AnimatedSprite2D.flip_h = true

	else:

		$AnimatedSprite2D.flip_h = false

	$AnimatedSprite2D.play("Virusmuerte")


	if randf() <= 0.25:

		var item = ITEM_CURACION.instantiate()

		get_parent().add_child(item)

		item.global_position = global_position

		item.es_dropeado = true
		item.velocity.y = -250.0


	await get_tree().create_timer(TIEMPO_MUERTE).timeout

	queue_free()


func actualizar_ataque(delta: float) -> void:

	if lyn_actual == null:

		preparando_ataque = false
		tiempo_preparacion = 0

		return


	if "esta_derrotado" in lyn_actual and lyn_actual.esta_derrotado:

		preparando_ataque = false
		tiempo_preparacion = 0

		atacando = false

		punto_ataque_actual = null

		$PuntoAtaqueIzq.monitoring = false
		$PuntoAtaqueDer.monitoring = false

		return


	if punto_ataque_actual == null:
		return


	var areas_en_ataque = punto_ataque_actual.get_overlapping_areas()

	var lyn_en_ataque = false


	for area in areas_en_ataque:

		if area.name == "DetectorVirus":

			var lyn_detectado = area.get_parent()

			if "esta_derrotado" in lyn_detectado and lyn_detectado.esta_derrotado:

				lyn_en_ataque = false

				break

			lyn_en_ataque = true

			break


	if not lyn_en_ataque:

		preparando_ataque = false
		tiempo_preparacion = 0

		if atacando:

			atacando = false
			actualizar_animacion()

		return


	if en_cooldown:
		return


	if not preparando_ataque:

		preparando_ataque = true
		tiempo_preparacion = TIEMPO_PREPARACION_ATAQUE
		atacando = true
		velocity.x = 0


		if punto_ataque_actual == $PuntoAtaqueDer:

			mirando_derecha = true
			$AnimatedSprite2D.flip_h = true

		else:

			mirando_derecha = false
			$AnimatedSprite2D.flip_h = false


		$AnimatedSprite2D.play("Virusataque")


	tiempo_preparacion -= delta


	if tiempo_preparacion <= 0:

		atacar()


func atacar() -> void:

	if lyn_actual == null:
		return


	if "esta_derrotado" in lyn_actual and lyn_actual.esta_derrotado:

		preparando_ataque = false
		tiempo_preparacion = 0
		atacando = false

		return


	if punto_ataque_actual == null:
		return


	var areas_en_ataque = punto_ataque_actual.get_overlapping_areas()


	for area in areas_en_ataque:

		if area.name == "DetectorVirus":

			var lyn_detectado = area.get_parent()

			if "esta_derrotado" in lyn_detectado and lyn_detectado.esta_derrotado:
				return


			if lyn_actual.has_method("recibir_dano"):

				if punto_ataque_actual == $PuntoAtaqueDer:

					lyn_actual.recibir_dano(DANIO, true)

				else:

					lyn_actual.recibir_dano(DANIO, false)

			break


	preparando_ataque = false
	tiempo_preparacion = 0

	en_cooldown = true
	tiempo_cooldown = TIEMPO_COOLDOWN_ATAQUE


	await $AnimatedSprite2D.animation_finished


	if esta_muerto:
		return


	atacando = false

	actualizar_animacion()


func actualizar_animacion() -> void:

	if esta_muerto:
		return


	if velocity.x != 0:

		$AnimatedSprite2D.play("Virusmover")

	else:

		$AnimatedSprite2D.play("Virusquieto")


	if mirando_derecha:

		$AnimatedSprite2D.flip_h = true

	else:

		$AnimatedSprite2D.flip_h = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass
