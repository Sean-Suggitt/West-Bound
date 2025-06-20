# Scenes/main_menu.gd   (attach to the root "MainMenu" node)
extends Control

@export var game_scene_path := "res://Scenes/MAIN.tscn"  # point at your game world

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)
	$ExitButton.pressed.connect(func(): get_tree().quit())
	$main_menu_music.play()

func _on_start_pressed() -> void:
	print("Start pressed, loading: ", game_scene_path)
	$main_menu_music.stop()
	Global.reset_player("P1")
	Global.reset_player("P2")
	Global.reset_scores()
	
	get_tree().change_scene_to_file(game_scene_path)
