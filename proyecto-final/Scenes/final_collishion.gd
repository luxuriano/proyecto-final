extends Area2D



func _on_body_entered(body: CharacterBody2D) -> void:
	if body.name == "Lyn Personaje":
		get_tree().change_scene_to_file("res://Scenes/final.tscn")
