extends Node

# Game constants
const REVOLVER_DAMAGE = 50
const MAX_PLAYER_HP = 100
const MAX_BULLETS = 10

# Player states
var player_states = {
	"P1": {
		"hp": MAX_PLAYER_HP,
		"direction": 1,
		"alive": true
	},
	"P2": {
		"hp": MAX_PLAYER_HP,
		"direction": 1,
		"alive": true
	}
}

# Bullet management
var active_bullets: Dictionary = {}  # Use unique IDs instead of array
var bullet_counter: int = 0

# Remove the _process function - direction should be updated by players themselves
func register_bullet(bullet_instance) -> int:
	bullet_counter += 1
	active_bullets[bullet_counter] = bullet_instance
	return bullet_counter

func unregister_bullet(bullet_id: int) -> void:
	active_bullets.erase(bullet_id)

func damage_player(player_name: String, damage: int) -> void:
	if player_states.has(player_name):
		player_states[player_name]["hp"] -= damage
		if player_states[player_name]["hp"] <= 0:
			player_states[player_name]["alive"] = false
			player_states[player_name]["hp"] = 0

# Reset player state (useful for respawning)
func reset_player(player_name: String) -> void:
	if player_states.has(player_name):
		player_states[player_name]["hp"] = MAX_PLAYER_HP
		player_states[player_name]["alive"] = true

# Get player health percentage (useful for UI)
func get_player_health_percentage(player_name: String) -> float:
	if player_states.has(player_name):
		return float(player_states[player_name]["hp"]) / float(MAX_PLAYER_HP)
	return 0.0

# Define general classes such as item and entity
# Manage loading levels
# 		Note: levels should have similar scripts to 
# 		      handle spawning players, items, and resetting the level.
# Manage player score
# Manage 
