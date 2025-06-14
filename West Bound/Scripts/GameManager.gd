extends Node2D


# Called when the node enters the scene tree for the first time.
#Preload revlover scene
var revolver_scene = preload("res://Scenes/Items/Revolver.tscn")

func _ready() -> void:
	#Get reference to players
	var player1 = get_parent().get_node("Player")
	var player2 = get_parent().get_node("Player2")
	player1.connect("player_died", Callable(self, "_on_player_died"))
	player2.connect("player_died", Callable(self, "_on_player_died"))
	print(player1)
	print(player2)
	
	# Print game start message
	print("=================================")
	print("WEST BOUND - Score Attack Mode")
	print("First player to reach 5 points wins!")
	print("Press SPACE to restart after game over.")
	print("=================================")
	
	pass # Replace with function body.

var round_active = true
var game_over = false  # Track if the game has ended

func _on_player_died(player_id):
	print(player_id + " died!")
	if round_active and not game_over:
		round_active = false;
		
		# Determine the winner of this round
		var winner = "P2" if player_id == "P1" else "P1"
		Global.increment_score(winner)
		
		# Check for game win condition
		if Global.get_score(winner) >= 5:
			game_over = true
			_handle_game_win(winner)
		else:
			# Show current scores in console
			print("Current Scores:")
			print("P1: " + str(Global.get_score("P1")))
			print("P2: " + str(Global.get_score("P2")))
			_start_round_end_sequence()

func _handle_game_win(winner: String):
	print("=================================")
	print("GAME OVER!")
	print("Player " + winner + " has won!")
	print("Final Scores:")
	print("P1: " + str(Global.get_score("P1")))
	print("P2: " + str(Global.get_score("P2")))
	print("=================================")
	
	# Fade to black and stay black
	await get_tree().create_timer(1.0).timeout;
	$FadeRect.modulate.a = 0.0
	$FadeRect.show()
	$FadeLight.energy = 0
	$FadeLight.create_tween().tween_property($FadeLight, "energy", 1, 1.33)
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 1, 1.33)
	# Game stays in this state - no reset

func _start_round_end_sequence():
	#fade to black
	await get_tree().create_timer(1.0).timeout;
	$FadeRect.modulate.a = 0.0
	$FadeRect.show()
	$FadeLight.energy = 0
	$FadeLight.create_tween().tween_property($FadeLight, "energy", 1, 1.33 )
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 1, 1.33)
	await get_tree().create_timer(2.0).timeout;
	_reset_round();

func _reset_round():
	# Reset both players
	Global.reset_player("P1")
	Global.reset_player("P2")
	
	var player1 = get_parent().get_node("Player")
	var player2 = get_parent().get_node("Player2")
	
	# Call the new reset method on both players to handle item clearingAdd commentMore actions
	if player1.has_method("reset_for_new_round"):
		player1.reset_for_new_round()
	if player2.has_method("reset_for_new_round"):
		player2.reset_for_new_round()

	
	#Move players to spawn points
	var spawn_p1 = get_tree().get_nodes_in_group("spawn_P1")
	var spawn_p2 = get_tree().get_nodes_in_group("spawn_P2")
	
	if spawn_p1.size() > 0:
		player1.global_position = spawn_p1[0].global_position
		print(player1.global_position)
	if spawn_p2.size() > 0:
		player2.global_position = spawn_p2[0].global_position
		print(player2.global_position)


	await get_tree().process_frame
	_clear_revolvers()

	var gun_count = _count_gun_holders()
	var spawned_revolvers: Array = _spawn_revolvers(gun_count)

	
	player1.modulate.a = 1.0
	player2.modulate.a = 1.0
	player1.show()
	player2.show()
	
	#fade back
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 0, 0.5)
	$FadeLight.create_tween().tween_property($FadeLight, "energy", 0, 0.5 )
	await get_tree().create_timer(0.5).timeout
	$FadeRect.hide()
	round_active = true

#--------------------------------------------------------------------
#---------------------- REVOLVER RESPAWN FUNCTIONS ------------------
#--------------------------------------------------------------------
func _clear_revolvers() -> void:
	var existing_revolvers = get_tree().get_nodes_in_group("revolver_group")
	print("Clearing ", existing_revolvers.size(), " existing revolvers")
	
	for revolver in existing_revolvers:
		print(revolver)
		if is_instance_valid(revolver):
			revolver.queue_free()

func _count_gun_holders() -> int:
	var gun_holders = get_tree().get_nodes_in_group("GunHolders")
	print("Found ", gun_holders.size(), " gun holders")
	return gun_holders.size()

func _spawn_revolvers(count: int) -> Array:
	var spawned_revolvers = []
	var gun_holders = get_tree().get_nodes_in_group("GunHolders")
	
	# Safety check
	if gun_holders.size() < count:
		push_warning("Not enough gun holders! Found ", gun_holders.size(), " but need ", count)
		count = gun_holders.size()
	
	for i in range(count):
		#instantiate new revolver
		var new_revolver = revolver_scene.instantiate()
		
		#set Unique Name/ID
		new_revolver.name = "Revolver" + str(i)
		
		#add to group
		new_revolver.add_to_group("revolver_group")
		
		#add to main as child
		get_parent().add_child(new_revolver)
		
		#Store Reference
		spawned_revolvers.append(new_revolver)
		print("Spawned ", new_revolver.name)
		
		spawned_revolvers[i].global_position = gun_holders[i].global_position
	
	return spawned_revolvers

#func _position_revolvers(revolver: Node2D) -> void:
	#var gun_holders = get_tree().get_nodes_in_group("GroupHolders")
	##
	###Ensure to not go out of bounds
	##var count = min(revolvers.size(), gun_holders.size())
		#if is_instance_valid(revolver)
			#revolver.global_position = gun_holders[i].global_position
			#print("Positioned ", revolvers[i].name, " at ", gun_holders[i].global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Allow game restart when game is over
	if game_over and Input.is_action_just_pressed("ui_select"):
		_restart_game()
	pass

func _restart_game():
	print("Restarting game...")
	game_over = false
	round_active = true
	Global.reset_scores()
	_reset_round()
	
	# Fade back in
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 0, 0.5)
	$FadeLight.create_tween().tween_property($FadeLight, "energy", 0, 0.5)
	await get_tree().create_timer(0.5).timeout
	$FadeRect.hide()
	
	print("Game restarted! Scores reset to 0.")
	print("First to 5 wins!")
