# Player.gd - Unified player script
extends CharacterBody2D

# Player configuration
@export var player_id: String = "P1"  # Set in inspector
@export var input_map: Dictionary = {
	"left": "P1_left",
	"right": "P1_right",
	"jump": "P1_jump",
	"fire": "P1_fire",
	"pickup": "P1_pickup"
}

# Movement configuration
@export_group("Movement")
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 0.1
@export var deceleration: float = 0.1
@export var air_control_factor: float = 0.9
@export var air_acceleration: float = 350.0
@export var air_friction: float = 145.0
@export var terminal_velocity: float = 600.0

# Combat configuration
@export_group("Combat")
@export var max_health: int = 100
@export var respawn_time: float = 3.0

# Node references - will be set in _ready()
var sprite: AnimatedSprite2D
var item_sprite: Sprite2D
var gun_tip: Marker2D
var hurt_box: Area2D
var pickup_range: Area2D
var revolver_sound: AudioStreamPlayer2D

# Resources
var bullet_scene = preload("res://Scenes/bullet.tscn")
var revolver_scene = preload("res://Scenes/Revolver.tscn")

# State
var holding_item: bool = false
var items_in_range: Array = []
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var is_dead: bool = false

# Constants
const COYOTE_TIME: float = 0.11
const JUMP_BUFFER_TIME: float = 0.13
const JUMP_CUT_MULTIPLIER: float = 0.5

# Momentum system for smooth air control
var momentum_intervals = [
	{"speed_ratio": 0.0, "deceleration": 0.08},
	{"speed_ratio": 0.2, "deceleration": 0.065},
	{"speed_ratio": 0.4, "deceleration": 0.05},
	{"speed_ratio": 0.6, "deceleration": 0.04},
	{"speed_ratio": 0.8, "deceleration": 0.032},
	{"speed_ratio": 1.0, "deceleration": 0.025}
]

func _ready() -> void:
	# Get node references - use existing node names from PlayerScript.gd
	sprite = $AniPlayerSpr
	item_sprite = $Revolver_Sprite
	gun_tip = $gun_tip
	
	# Try to find other nodes that might exist
	if has_node("Hurtbox"):
		hurt_box = $Hurtbox
	elif has_node("PlayerHurtbox"):
		hurt_box = $PlayerHurtbox
	
	if has_node("PickupRange"):
		pickup_range = $PickupRange
	elif has_node("pickup_range"):
		pickup_range = $pickup_range
		
	if has_node("revolver_sound"):
		revolver_sound = $revolver_sound
	elif has_node("RevolverSound"):
		revolver_sound = $RevolverSound
	
	# Configure hurtbox group
	if hurt_box:
		hurt_box.add_to_group(player_id + "_Hurtbox")
	
	# Hide item sprite initially
	if item_sprite:
		item_sprite.hide()
	
	# Connect signals
	if pickup_range:
		if not pickup_range.area_entered.is_connected(_on_pickup_range_entered):
			pickup_range.area_entered.connect(_on_pickup_range_entered)
		if not pickup_range.area_exited.is_connected(_on_pickup_range_exited):
			pickup_range.area_exited.connect(_on_pickup_range_exited)
	
	# Initialize player in global state if not exists
	if not Global.player_states.has(player_id):
		Global.player_states[player_id] = {
			"hp": max_health,
			"direction": 1,
			"alive": true
		}
	
	# Set up input map for P2 if needed
	if player_id == "P2":
		input_map = {
			"left": "P2_left",
			"right": "P2_right",
			"jump": "P2_jump",
			"fire": "P2_fire",
			"pickup": "P2_pickup"
		}

func _process(_delta: float) -> void:
	# Check health
	if Global.player_states[player_id]["hp"] <= 0 and not is_dead:
		_handle_death()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	var currently_on_floor = is_on_floor()
	
	# Handle input
	if Input.is_action_just_pressed(input_map["fire"]):
		_shoot()
	
	if Input.is_action_just_pressed(input_map["pickup"]):
		_handle_pickup()
	
	# Jump handling
	_handle_jump(delta, currently_on_floor)
	
	# Apply gravity
	if not currently_on_floor:
		velocity += get_gravity() * delta
		velocity.y = min(velocity.y, terminal_velocity)
	
	# Movement
	var direction = Input.get_axis(input_map["left"], input_map["right"])
	_handle_movement(direction, currently_on_floor, delta)
	
	# Update global direction
	if direction != 0:
		Global.player_states[player_id]["direction"] = int(direction)
	
	move_and_slide()

func _handle_movement(direction: float, on_floor: bool, delta: float) -> void:
	if on_floor:
		if direction:
			velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
			_update_visuals(direction)
			sprite.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, speed * deceleration)
			sprite.play("idle")
	else:
		# Air movement with momentum
		if direction:
			var target_speed = direction * speed * air_control_factor
			velocity.x = move_toward(velocity.x, target_speed, air_acceleration * delta)
		else:
			# Dynamic air friction based on speed
			var current_speed_ratio = abs(velocity.x) / speed
			var dynamic_friction = air_friction * (1.0 + current_speed_ratio * 0.5)
			velocity.x = move_toward(velocity.x, 0, dynamic_friction * delta)
		
		# Play jump animation if available
		if sprite.has_animation("jump"):
			sprite.play("jump")

func _update_visuals(direction: float) -> void:
	sprite.flip_h = direction < 0
	
	if item_sprite:
		item_sprite.flip_h = direction < 0
		var x_offset = abs(item_sprite.position.x)
		item_sprite.position.x = x_offset * sign(direction)
	
	if gun_tip:
		gun_tip.position.x = abs(gun_tip.position.x) * sign(direction)

func _handle_jump(delta: float, currently_on_floor: bool) -> void:
	# Update coyote timer
	if currently_on_floor:
		coyote_timer = 0.0
	elif was_on_floor and not currently_on_floor:
		coyote_timer = 0.0  # Just left ground
	else:
		coyote_timer += delta
	
	was_on_floor = currently_on_floor
	
	# Update jump buffer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Store jump input
	if Input.is_action_just_pressed(input_map["jump"]):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Execute jump
	var can_coyote_jump = coyote_timer <= COYOTE_TIME
	var has_jump_buffered = jump_buffer_timer > 0
	
	if has_jump_buffered and (currently_on_floor or can_coyote_jump):
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = COYOTE_TIME + 1  # Prevent multiple coyote jumps
	
	# Variable jump height
	if Input.is_action_just_released(input_map["jump"]) and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func _shoot() -> void:
	if not holding_item:
		return
		
	var bullet = bullet_scene.instantiate()
	if gun_tip:
		bullet.global_position = gun_tip.global_position
	else:
		bullet.global_position = global_position
	
	bullet.setup(player_id, Global.player_states[player_id]["direction"])
	get_parent().add_child(bullet)
	
	# Play sound
	if revolver_sound:
		revolver_sound.play()

func _handle_pickup() -> void:
	if holding_item:
		_drop_item()
	elif not items_in_range.is_empty():
		_pickup_item(items_in_range[0])

func _pickup_item(item: Area2D) -> void:
	item.queue_free()
	holding_item = true
	if item_sprite:
		item_sprite.show()
	items_in_range.erase(item)

func _drop_item() -> void:
	holding_item = false
	if item_sprite:
		item_sprite.hide()
	
	var item = revolver_scene.instantiate()
	var drop_direction = Global.player_states[player_id]["direction"]
	item.position = global_position + Vector2(drop_direction * 20, 10)
	get_parent().add_child(item)

func _handle_death() -> void:
	is_dead = true
	
	# Play death animation or hide
	if sprite.has_animation("death"):
		sprite.play("death")
	else:
		sprite.modulate.a = 0.5  # Make semi-transparent
	
	# Disable collisions
	set_collision_layer_value(1, false)
	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
	
	# Drop item if holding
	if holding_item:
		_drop_item()
	
	# Start respawn timer
	await get_tree().create_timer(respawn_time).timeout
	_respawn()

func _respawn() -> void:
	# Reset state
	Global.reset_player(player_id)
	is_dead = false
	
	# Re-enable collisions
	set_collision_layer_value(1, true)
	if hurt_box:
		hurt_box.set_deferred("monitoring", true)
	
	# Reset position to spawn point
	var spawn_points = get_tree().get_nodes_in_group("spawn_" + player_id)
	if spawn_points.size() > 0:
		global_position = spawn_points[0].global_position
	else:
		# Fallback: reset to starting position
		if player_id == "P1":
			global_position = Vector2(100, 0)
		else:
			global_position = Vector2(900, 0)
	
	# Reset visuals
	sprite.modulate.a = 1.0
	sprite.show()
	sprite.play("idle")
	
	# Reset physics
	velocity = Vector2.ZERO

func _on_pickup_range_entered(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.append(area)

func _on_pickup_range_exited(area: Area2D) -> void:
	items_in_range.erase(area)

# Input handling for pickup
func _input(event: InputEvent) -> void:
	# This provides backward compatibility with the original pickup system
	if event.is_action_pressed(input_map["pickup"]):
		print("Player " + player_id + " pressed pickup")

# Calculate momentum-based deceleration (from original PlayerScript)
func calculate_momentum_deceleration(speed_ratio: float) -> float:
	speed_ratio = clamp(speed_ratio, 0.0, 1.2)
	
	for i in range(momentum_intervals.size() - 1):
		var current = momentum_intervals[i]
		var next = momentum_intervals[i + 1]
		
		if speed_ratio <= next.speed_ratio:
			var ratio_range = next.speed_ratio - current.speed_ratio
			if ratio_range == 0:
				return current.deceleration
			
			var local_ratio = (speed_ratio - current.speed_ratio) / ratio_range
			return lerp(current.deceleration, next.deceleration, local_ratio)
	
	return momentum_intervals[-1].deceleration 