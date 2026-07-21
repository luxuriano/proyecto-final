extends Camera2D

@export var look_distance := 25.0
@export var look_speed := 4.0

var target_offset_y := 0.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_down"):
		target_offset_y = look_distance
	elif Input.is_action_pressed("ui_up"):
		target_offset_y = -look_distance
	else:
		target_offset_y = 0.0
	offset.y = lerp(offset.y, target_offset_y, look_speed * delta)
