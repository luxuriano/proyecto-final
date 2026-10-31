# SaveManager.gd (Autoload)
extends Node

const SAVE_PATH_BASE := "user://save_slot_"

var current_slot: int = 1 # Slot seleccionado en el menú (1, 2 o 3)
var current_checkpoint_pos: Vector2 = Vector2.ZERO # Posición del checkpoint activo
var current_scene_path: String = "res://scenes/levels/level_1.tscn"

# Guardar partida actual en el slot activo
func save_current_progress(player: Node2D, extra_data: Dictionary = {}) -> bool:
	if current_slot < 1 or current_slot > 3:
		printerr("No hay un slot válido seleccionado (1-3).")
		return false
	
	current_checkpoint_pos = player.global_position
	current_scene_path = get_tree().current_scene.scene_file_path
	
	var data_to_save: Dictionary = {
		"level": current_scene_path,
		"checkpoint_x": current_checkpoint_pos.x,
		"checkpoint_y": current_checkpoint_pos.y,
		"timestamp": Time.get_datetime_string_from_system(false, true)
	}
	
	# Agregar datos extras si los tienen (monedas, items, etc.)
	for key in extra_data:
		data_to_save[key] = extra_data[key]

	var file := FileAccess.open(SAVE_PATH_BASE + str(current_slot) + ".json", FileAccess.WRITE)
	if not file:
		return false
		
	file.store_string(JSON.stringify(data_to_save, "\t"))
	file.close()
	print("Progreso guardado automáticamente en Slot ", current_slot)
	return true

# Cargar partida desde un slot
func load_slot(slot: int) -> bool:
	var path := SAVE_PATH_BASE + str(slot) + ".json"
	if not FileAccess.file_exists(path):
		return false
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
		
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data: Dictionary = json.data
		current_slot = slot
		current_scene_path = data.get("level", "res://scenes/levels/level_1.tscn")
		current_checkpoint_pos = Vector2(
			data.get("checkpoint_x", 0.0),
			data.get("checkpoint_y", 0.0)
		)
		file.close()
		return true
	
	file.close()
	return false