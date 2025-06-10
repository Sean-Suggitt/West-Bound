extends Node2D


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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
