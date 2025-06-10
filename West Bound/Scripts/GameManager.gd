extends Node2D

# Item spawn tracking
var item_spawn_positions: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Get reference to players
	var player1 = get_parent().get_node("Player")
	var player2 = get_parent().get_node("Player2")
	player1.connect("player_died", Callable(self, "_on_player_died"))
	player2.connect("player_died", Callable(self, "_on_player_died"))
	print(player1)
	print(player2)
	
	pass # Replace with function body.

var round_active = true

# Find all revolvers in the scene and store their positions
#var revolvers = get_tree().get_nodes_in_group("revolver_group")


func _on_player_died(player_id):
	print(player_id)
	if round_active:
		round_active = false;
		_start_round_end_sequence();

func _start_round_end_sequence():
	#fade to black
	await get_tree().create_timer(1.0).timeout;
	$FadeRect.modulate.a = 0.0
	$FadeRect.show()
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 1, 1.33)
	await get_tree().create_timer(2.0).timeout;
	_reset_round();

func _reset_round():
	# Reset both players
	Global.reset_player("P1")
	Global.reset_player("P2")
	
	var player1 = get_parent().get_node("Player")
	var player2 = get_parent().get_node("Player2")
	
	# Call the new reset method on both players to handle item clearing
	if player1.has_method("reset_for_new_round"):
		print("it has a method")
		player1.reset_for_new_round()
	if player2.has_method("reset_for_new_round"):
		print("it also has a method")
		player2.reset_for_new_round()
	
	
	# Respawn revolvers at their original positions
	await get_tree().process_frame  # Wait a frame to ensure old revolvers are freed
	#_respawn_items_at_spawn_positions()
	
	#Move players to spawn points
	var spawn_p1 = get_tree().get_nodes_in_group("spawn_P1")
	var spawn_p2 = get_tree().get_nodes_in_group("spawn_P2")
	
	if spawn_p1.size() > 0:
		player1.global_position = spawn_p1[0].global_position
		print(player1.global_position)
	if spawn_p2.size() > 0:
		player2.global_position = spawn_p2[0].global_position
		print(player2.global_position)
	
	player1.modulate.a = 1.0
	player2.modulate.a = 1.0
	player1.show()
	player2.show()
	
	#fade back
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 0, 0.5)
	await get_tree().create_timer(0.5).timeout
	$FadeRect.hide()
	round_active = true

#func _respawn_items_at_spawn_positions() -> void:
	## Respawn all items at their original positions
	#var revolver_scene = preload("res://Scenes/Revolver.tscn")
	#print(revolver_scene)
	#for spawn_data in item_spawn_positions:
		#var new_revolver = revolver_scene.instantiate()
		#new_revolver.position = spawn_data["position"]
		#get_parent().add_child(new_revolver)
		#print("Respawned revolver at: ", spawn_data["position"])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
