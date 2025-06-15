extends Control


func _ready():
	$MainMenuBtn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	print("yoooo")
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
