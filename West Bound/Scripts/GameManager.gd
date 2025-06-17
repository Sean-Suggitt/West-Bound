extends Node2D


# Called when the node enters the scene tree for the first time.
#Preload revlover scene
var revolver_scene = preload("res://Scenes/Items/Revolver.tscn")
@onready var level_manager: LevelManager = $"../LevelManager"
var players_connected := false

func _ready() -> void:
	print("Im here suckas")
	
	# Give the LevelManager time to load the level
	await get_tree().process_frame
	
	# Wait for players to exist and connect signals
	await _wait_for_players_and_connect()
	
	# Print game start message
	print("=================================")
	print("WEST BOUND - Score Attack Mode")
	print("First player to reach 5 points wins!")
	print("Press SPACE to restart after game over.")
	print("=================================")
	
	# Spawn initial revolvers at gun holders
	await get_tree().process_frame
	var gun_count = _count_gun_holders()
	if gun_count > 0:  # Fix: was checking == 0
		_spawn_revolvers(gun_count)
		print("Initial revolvers spawned at gun holders")

func _wait_for_players_and_connect() -> void:
	var max_attempts = 60  # Try for about 1 second at 60fps
	var attempts = 0
	
	while attempts < max_attempts and not players_connected:
		var player1_nodes = get_tree().get_nodes_in_group("player1")
		var player2_nodes = get_tree().get_nodes_in_group("player2")
		
		if not player1_nodes.is_empty() and not player2_nodes.is_empty():
			# Players found, connect signals
			var player1 = player1_nodes[0]
			var player2 = player2_nodes[0]
			
			if player1.connect("player_died", Callable(self, "_on_player_died")) == OK:
				print("Successfully connected to player1 death signal")
			else:
				push_error("Failed to connect to player1 death signal!")
			
			if player2.connect("player_died", Callable(self, "_on_player_died")) == OK:
				print("Successfully connected to player2 death signal")
			else:
				push_error("Failed to connect to player2 death signal!")
			
			print("Connected to player1: ", player1.get_path())
			print("Connected to player2: ", player2.get_path())
			players_connected = true
			return
		
		# Wait another frame and try again
		await get_tree().process_frame
		attempts += 1
	
	if not players_connected:
		push_error("Players not found after waiting! Check if levels contain player nodes in groups 'player1' and 'player2'")


var round_active = true
var game_over = false  # Track if the game has ended

func _on_player_died(player_id):
	print("=== PLAYER DIED SIGNAL RECEIVED ===")
	print("Player ", player_id, " has died!")
	print("Round active: ", round_active, ", Game over: ", game_over)
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
	
	game_over = true
	
	# Hide the score UI before changing scenes
	await get_tree().create_timer(2.0).timeout
	var score_ui = get_tree().current_scene.get_node_or_null("ScoreUI")
	if score_ui:
		score_ui.hide()
	
	Global.reset_scores()
	
	#Change to endgame scene
	
	var endgame_scene := "res://Scenes/endgame.tscn"
	get_tree().change_scene_to_file(endgame_scene)
	
	# Game stays in this state - no reset

func _start_round_end_sequence():
	#fade to black
	await get_tree().create_timer(1.0).timeout;
	$FadeRect.modulate.a = 0.0
	$FadeRect.show()
	$FadeLight.energy = 0
	$FadeLight.create_tween().tween_property($FadeLight, "energy", 1, 1.33 )
	$FadeRect.create_tween().tween_property($FadeRect, "modulate:a", 1, 1.33)
	print("Screen Faded")
	await get_tree().create_timer(2.0).timeout;
	_reset_round();

func _reset_round():
	# Reset both players
	Global.reset_player("P1")
	Global.reset_player("P2")
	
	# Switch to next level
	level_manager.next_level()
	await get_tree().process_frame
	
	# Find players using groups 
	var player1_nodes = get_tree().get_nodes_in_group("player1")
	var player2_nodes = get_tree().get_nodes_in_group("player2")
	
	if player1_nodes.is_empty() or player2_nodes.is_empty():
		push_error("Players not found during reset!")
		return
		
	var player1 = player1_nodes[0]
	var player2 = player2_nodes[0]
	
	# Reconnect signals to new player instances
	if not player1.is_connected("player_died", Callable(self, "_on_player_died")):
		player1.connect("player_died", Callable(self, "_on_player_died"))
		print("Reconnected to player1 death signal after level change " + str(player1.global_position))
	
	if not player2.is_connected("player_died", Callable(self, "_on_player_died")):
		player2.connect("player_died", Callable(self, "_on_player_died"))
		print("Reconnected to player2 death signal after level change")
	
	
	# Call the new reset method on both players to handle item clearing
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
		
		# Find the dynamic package to add revolvers to the same container as other items
		var dynamic_packages = get_tree().get_nodes_in_group("dynamic_package")
		var spawn_parent = get_parent() # fallback to parent if no dynamic package
		
		if not dynamic_packages.is_empty():
			spawn_parent = dynamic_packages[0]
		
		#add to appropriate parent
		spawn_parent.add_child(new_revolver)
		
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
	pass
