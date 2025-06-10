# HealthUI.gd - Simple health display script
extends Label

@export var player_id: String = "P1"  # Which player's health to display
@export var display_format: String = "P%s HP: %d/%d"  # Format string for display

func _ready() -> void:
	# Initial update
	_update_health_display()

func _process(_delta: float) -> void:
	# Update health display every frame
	_update_health_display()

func _update_health_display() -> void:
	if Global.player_states.has(player_id):
		var current_hp = Global.player_states[player_id]["hp"]
		var max_hp = Global.MAX_PLAYER_HP
		var player_num = player_id.substr(1)  # Extract number from P1/P2
		
		text = display_format % [player_num, current_hp, max_hp]
		
		# Optional: Change color based on health percentage
		var health_percent = float(current_hp) / float(max_hp)
		if health_percent > 0.6:
			modulate = Color.GREEN
		elif health_percent > 0.3:
			modulate = Color.YELLOW
		else:
			modulate = Color.RED
	else:
		text = "Player %s not found" % player_id 