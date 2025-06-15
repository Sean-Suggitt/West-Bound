# Scenes/main_menu.gd   (attach to the root "MainMenu" node)
extends Control

@export var game_scene_path := "res://Scenes/MAIN.tscn"  # point at your game world

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)
	$ExitButton.pressed.connect(func(): get_tree().quit())

func _on_start_pressed() -> void:
	print("Start pressed, loading: ", game_scene_path)
	get_tree().change_scene_to_file(game_scene_path)
