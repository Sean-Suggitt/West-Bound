extends Node

# Game constants
const REVOLVER_DAMAGE = 50
const MAX_PLAYER_HP = 100
const MAX_BULLETS = 10

const HURT_SOUND = preload("res://Scenes/Sounds/hurt_sound.tscn")
var hurt_sound: AudioStreamPlayer2D

func _ready() -> void:
	hurt_sound = HURT_SOUND.instantiate()
	add_child(hurt_sound)


# Player states
var player_states = {
	"P1": {
		"hp": MAX_PLAYER_HP,
		"direction": 1,
		"alive": true,
		"score": 0
	},
	"P2": {
		"hp": MAX_PLAYER_HP,
		"direction": 1,
		"alive": true,
		"score": 0
	}
}

# Bullet management
var active_bullets: Dictionary = {}  # Use unique IDs instead of array
var bullet_counter: int = 0


func register_bullet(bullet_instance) -> int:
	bullet_counter += 1
	active_bullets[bullet_counter] = bullet_instance
	return bullet_counter

func unregister_bullet(bullet_id: int) -> void:
	active_bullets.erase(bullet_id)

func damage_player(player_name: String, damage: int) -> void:
	if player_states.has(player_name):
		player_states[player_name]["hp"] -= damage
		hurt_sound.play()
		if player_states[player_name]["hp"] <= 0:
			player_states[player_name]["alive"] = false
			player_states[player_name]["hp"] = 0

# Reset player state 
func reset_player(player_name: String) -> void:
	if player_states.has(player_name):
		player_states[player_name]["hp"] = MAX_PLAYER_HP
		player_states[player_name]["alive"] = true

# Get player health percentage 
func get_player_health_percentage(player_name: String) -> float:
	if player_states.has(player_name):
		return float(player_states[player_name]["hp"]) / float(MAX_PLAYER_HP)
	return 0.0

# Score management functions
func increment_score(player_name: String) -> void:
	if player_states.has(player_name):
		player_states[player_name]["score"] += 1
		print(player_name + " score: " + str(player_states[player_name]["score"]))

func get_score(player_name: String) -> int:
	if player_states.has(player_name):
		return player_states[player_name]["score"]
	return 0

func reset_scores() -> void:
	for player in player_states:
		player_states[player]["score"] = 0
