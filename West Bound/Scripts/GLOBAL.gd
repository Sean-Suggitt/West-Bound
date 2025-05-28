extends Node2D

	# Bullet System
var bullets_in_scene: Array = [] 
var revolver_damage = 50

	# Player 1
var P1_direction = 0
var P1_HP = 100

	# Player 2

	# Player 1 movement
func _process(delta: float) -> void:
	
	# get direction P1 is facing globally available
	var direction = Input.get_axis("P1_left", "P1_right")
	#print(direction)
	if direction < 0:
		P1_direction = -1
	elif direction > 0:
		P1_direction = 1
	
	#print(P1_direction)

# Define general classes such as item and entity
# Manage loading levels
# 		Note: levels should have similar scripts to 
# 		      handle spawning players, items, and resetting the level.
# Manage player score
# Manage 
