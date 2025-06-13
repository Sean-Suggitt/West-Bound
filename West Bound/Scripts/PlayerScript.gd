extends CharacterBody2D

#--------------------------------------------------------------------
#--------------------------- CONFIGURATION --------------------------
#--------------------------------------------------------------------

# Player identification
@export var player_id: String = "P1"  # Set in inspector: "P1" or "P2"

# Input configuration - automatically set based on player_id
@export var input_map: Dictionary = {
	"left": "P1_left",
	"right": "P1_right", 
	"jump": "P1_jump",
	"fire": "P1_fire",
	"pickup": "P1_pickup",
	"roll": "P1_roll"
}

signal player_died(player_id)

# Movement configuration
@export_group("Movement")
@export var speed: float = 100
@export var jump_velocity: float = -300.0
@export var roll_speed = 200
@export var roll_duration = 0.3
@export var roll_cooldown = 1
@export var jump_start_timer_duration = 0.2
@export var acceleration: float = 0.1
@export var deceleration: float = 0.1
@export var air_control_factor: float = 0.9
@export var air_acceleration: float = 350.0
@export var air_friction: float = 145.0
@export var terminal_velocity: float = 600.0
@export var jump_cut_multiplier: float = 0.01  # Variable jump height
@export var revolver_counter = 1
# Combat configuration
@export_group("Combat")
@export var max_health: int = 100
@export var respawn_time: float = 3.0
@export var revolver_firerate: float = 0.5

# Coyote Time & Jump Buffer configuration
@export_group("Jump Mechanics")
@export var coyote_time: float = 0.11  # Grace period after leaving ground
@export var jump_buffer_time: float = 0.13  # How long to remember jump input

#--------------------------------------------------------------------
#--------------------------- VARIABLES ------------------------------
#--------------------------------------------------------------------

# Shooting
var can_shoot: bool = true

# Node references - will be set in _ready()
var sprite: AnimatedSprite2D
var item_sprite: Sprite2D
var gun_tip: Node2D
var hurt_box: Area2D
var pickup_range: Area2D
var revolver_sound: AudioStreamPlayer2D
var Roll_Timer: Timer
var Roll_Cooldown_Timer: Timer
var Jump_Animation_Start_Timer: Timer
var Revolver_Firerate_Timer: Timer
var Player_Collision_Shape: CollisionShape2D


# Resources
var bullet_scene = preload("res://Scenes/Items/bullet.tscn")
var revolver_scene = preload("res://Scenes/Items/Revolver.tscn")

# Item Pickup System
var holding_item: bool = false
var drop_pos: Vector2
var items_in_range: Array = []

# rolling 
var is_rolling: bool = false
var can_roll: bool = true

# Jump state tracking
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

var can_start_jump_ani: bool = false

# Death/Respawn system
var is_dead: bool = false

# Momentum system for smooth air control
var momentum_intervals = [
	{"speed_ratio": 0.0, "deceleration": 0.08},
	{"speed_ratio": 0.2, "deceleration": 0.065},
	{"speed_ratio": 0.4, "deceleration": 0.05},
	{"speed_ratio": 0.6, "deceleration": 0.04},
	{"speed_ratio": 0.8, "deceleration": 0.032},
	{"speed_ratio": 1.0, "deceleration": 0.025}
]

#--------------------------------------------------------------------
#----------------------ENGINE FUNCTIONS------------------------------
#--------------------------------------------------------------------

func _ready() -> void:
	# Set up input map based on player_id
	if player_id == "P2":
		input_map = {
			"left": "P2_left",
			"right": "P2_right",
			"jump": "P2_jump",
			"fire": "P2_fire",
			"pickup": "P2_pickup",
			"roll": "P2_roll"
		}
	
	# Get node references with proper error handling
	_setup_node_references()

	if Jump_Animation_Start_Timer == null:
		print("Timer is null!")
		
		
	# Initialize player in global system
	if not Global.player_states.has(player_id):
		Global.player_states[player_id] = {
			"hp": max_health,
			"direction": 1,
			"alive": true
		}
	
	# Configure hurtbox group
	if hurt_box:
		hurt_box.add_to_group(player_id + "_Hurtbox")
	
	# Hide item sprite initially
	if item_sprite:
		item_sprite.hide()
	
	# Connect pickup range signals
	if pickup_range:
		if not pickup_range.area_entered.is_connected(_on_pickup_range_area_entered):
			pickup_range.area_entered.connect(_on_pickup_range_area_entered)
		if not pickup_range.area_exited.is_connected(_on_pickup_range_area_exited):
			pickup_range.area_exited.connect(_on_pickup_range_area_exited)

	#Move to spawn point on game start
	_move_to_spawn_point()

func _process(_delta: float) -> void:
	# Check health
	if Global.player_states[player_id]["hp"] <= 0 and not is_dead:
		_handle_death()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	var currently_on_floor = is_on_floor()
	
	# dodge roll
	if Input.is_action_just_pressed(input_map["roll"]):
		_roll_start(roll_duration)
		if _is_rolling():
			velocity.x = 0
			velocity.x += roll_speed * Global.player_states[player_id]["direction"]
		else: 
			pass
	
	# Handle shooting
	if Input.is_action_just_pressed(input_map["fire"]):
		_shoot()
	
	# Handle pickup
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

func _setup_node_references() -> void:
	# Get sprite node (try multiple common names)
	
	Roll_Timer = get_node("%s_Roll_Timer" % player_id) 
	Roll_Cooldown_Timer = get_node("%s_Roll_Cooldown_Timer" % player_id)
	Jump_Animation_Start_Timer = get_node("%s_Jump_Animation_Start_Timer" % player_id)
	Player_Collision_Shape = get_node("%s_CollisionShape2D" % player_id)
	Revolver_Firerate_Timer = get_node("%s_Revolver_Firerate_Timer" % player_id)
	
	if has_node("AniPlayerSpr"):
		sprite = $AniPlayerSpr
	elif has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D
	else:
		push_warning("No animated sprite found for player " + player_id)
	
	# Get item sprite
	if has_node("Revolver_Sprite"):
		item_sprite = $Revolver_Sprite
	elif has_node("ItemSprite"):
		item_sprite = $ItemSprite
	
	# Get gun tip marker
	if has_node("gun_tip"):
		gun_tip = $gun_tip
	elif has_node("GunTip"):
		gun_tip = $GunTip
	elif has_node("GunPoint"):
		gun_tip = $GunPoint
	
	# Get hurtbox
	if has_node("Hurtbox"):
		hurt_box = $Hurtbox
	elif has_node("PlayerHurtbox"):
		hurt_box = $PlayerHurtbox
	
	# Get pickup range
	if has_node("pickup_range"):
		pickup_range = $pickup_range
	elif has_node("PickupRange"):
		pickup_range = $PickupRange
	
	# Get sound player
	if has_node("revolver_sound"):
		revolver_sound = $revolver_sound
	elif has_node("RevolverSound"):
		revolver_sound = $RevolverSound

#--------------------------------------------------------------------
#---------------------- MOVEMENT FUNCTIONS --------------------------
#--------------------------------------------------------------------

func _handle_movement(direction: float, on_floor: bool, delta: float) -> void:
	if on_floor:
		if _is_rolling():
			sprite.play("roll")
		# Ground movement
		elif direction:
			velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
			_update_visuals(direction)
			if sprite and !is_rolling:
				sprite.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, speed * deceleration)
			if sprite and !is_rolling:
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
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("jump"):
			if !is_rolling:
				sprite.play("jump")

func _update_visuals(direction: float) -> void: 
	if sprite:
		sprite.flip_h = direction < 0
	
	if item_sprite:
		item_sprite.flip_h = direction < 0
		var x_offset = abs(item_sprite.position.x)
		item_sprite.position.x = x_offset * sign(direction)
	
	if gun_tip:
		gun_tip.position.x = abs(gun_tip.position.x) * sign(direction)
	
	# Update drop position
	drop_pos = Vector2(direction * 20, 10)

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
		jump_buffer_timer = jump_buffer_time
	
	# Execute jump
	var can_coyote_jump = coyote_timer <= coyote_time
	var has_jump_buffered = jump_buffer_timer > 0
	
	if has_jump_buffered and (currently_on_floor or can_coyote_jump):
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = coyote_time + 1  # Prevent multiple coyote jumps
	
	# Variable jump height
	if Input.is_action_just_released(input_map["jump"]) and velocity.y < 0:
		velocity.y *= jump_cut_multiplier

# Calculate momentum-based deceleration (kept for backward compatibility)
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

#--------------------------------------------------------------------
#----------------------- COMBAT FUNCTIONS ---------------------------
#--------------------------------------------------------------------

func _shoot() -> void:
	print(player_id + " tried to shoot. ")
	if holding_item and can_shoot:
		can_shoot = false
		
		Revolver_Firerate_Timer.wait_time = revolver_firerate
		Revolver_Firerate_Timer.start()
		
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
		
		print("Player ", player_id, " shot! HP: ", Global.player_states[player_id]["hp"])

func _on_p_1_revolver_firerate_timer_timeout() -> void:
	can_shoot = true

func _on_p_2_revolver_firerate_timer_timeout() -> void:
	can_shoot = true

func _handle_death() -> void:
	is_dead = true
	emit_signal("player_died", player_id)
	# Visual feedback
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
			sprite.play("death")
		else:
			sprite.modulate.a = 0.5  # Make semi-transparent
	
	# Disable collisions
	set_collision_mask_value(2, false)
	set_collision_layer_value(2, false)
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
	set_collision_mask_value(2, true)
	set_collision_layer_value(2, true)
	if hurt_box:
		hurt_box.set_deferred("monitoring", true)
	
	# Reset position to spawn point
	var spawn_points = get_tree().get_nodes_in_group("spawn_" + player_id)
	if spawn_points.size() > 0:
		global_position = spawn_points[0].global_position
	else:
		# Fallback: reset to starting position
		if player_id == "P1":
			global_position = Vector2(100, 300)
		else:
			global_position = Vector2(900, 300)
	
	# Reset visuals
	if sprite:
		sprite.modulate.a = 1.0
		sprite.show()
		sprite.play("idle")
	
	# Reset physics
	velocity = Vector2.ZERO

func _move_to_spawn_point() -> void:
	await get_tree().process_frame
	var spawn_points = get_tree().get_nodes_in_group("spawn_" + player_id)
		
	if spawn_points.size() > 0:
		global_position = spawn_points[0].global_position
	else:
		#fallback positions if spawn points arent found
		if player_id == "P1":
			global_position = Vector2(-105, -64)
		elif player_id == "P2":
			global_position = Vector2(51, -30) 

#--------------------------------------------------------------------
#---------------------- ROLLING FUNCTIONS ---------------------------
#--------------------------------------------------------------------

func _dodge_roll() -> void:
	pass

func _roll_start(duration: float) -> void:
	if !_is_rolling() and is_on_floor() and can_roll:
		
		# disable hurtbox to creat I-frames
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)
		set_collision_mask_value(2, false)
		set_collision_layer_value(2, false)

		
		# Set states
		is_rolling = true
		can_roll = false
		
		# Handle Timers
		Roll_Timer.wait_time = duration
		Roll_Cooldown_Timer.wait_time = roll_cooldown
		Roll_Timer.start()
		Roll_Cooldown_Timer.start() 

func _is_rolling():
	return !Roll_Timer.is_stopped()

func roll_timer_timeout() -> void:
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	set_collision_mask_value(2, true)
	set_collision_layer_value(2, true)
	is_rolling = false

func _on_p_1_roll_timer_timeout() -> void:
	roll_timer_timeout()

func _on_p_2_roll_timer_timeout() -> void:
	roll_timer_timeout()

func roll_cooldown_timer_timeout() -> void:
	can_roll = true

func _on_p_1_roll_cooldown_timer_timeout() -> void:
	roll_cooldown_timer_timeout()

func _on_p_2_roll_cooldown_timer_timeout() -> void:
	roll_cooldown_timer_timeout()

#--------------------------------------------------------------------
#---------------------- PICKUP FUNCTIONS ----------------------------
#--------------------------------------------------------------------

func _handle_pickup() -> void:
	print("Player ", player_id, " pressed pickup")
	if holding_item:
		_drop_item()
	elif not items_in_range.is_empty():
		_pickup_item(items_in_range.pick_random())

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

func _on_pickup_range_area_entered(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.append(area)
		print(player_id, " items in range: ", items_in_range)

func _on_pickup_range_area_exited(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.erase(area)
		print(player_id, " items in range: ", items_in_range)

#--------------------------------------------------------------------
#----------------------- ROUND RESET FUNCTIONS ----------------------
#--------------------------------------------------------------------

# Public method for external round resets
func reset_for_new_round() -> void:
	"""Called by GameManager when a round resets. Handles clearing item state and other round-specific resets."""
	
	# Clear item holding state without dropping (items will respawn at their original positions)
	if holding_item:
		holding_item = false
		if item_sprite:
			item_sprite.hide()
	# Clear any items that might be in range
	items_in_range.clear()
	
	# Reset visual state
	if sprite:
		sprite.modulate.a = 1.0
		sprite.show()
		sprite.play("idle")
	
	# Reset physics
	velocity = Vector2.ZERO
	is_dead = false
	
	# Re-enable collisions in case they were disabled
	set_collision_mask_value(2, true)
	set_collision_layer_value(2, true)
	if hurt_box:
		hurt_box.set_deferred("monitoring", true)

#--------------------------------------------------------------------
#----------------------- LEGACY FUNCTIONS ---------------------------
#--------------------------------------------------------------------
# These functions are kept for backward compatibility

func jump_handler(delta: float, currently_on_floor: bool) -> void:
	_handle_jump(delta, currently_on_floor)

func shoot() -> void:
	_shoot()

func pickup_item(item: Area2D) -> void:
	_pickup_item(item)

func drop_item() -> void:
	_drop_item()

# Input handling - now integrated into main physics process
func _input(_event: InputEvent) -> void:
	# Kept for compatibility but functionality moved to _physics_process
	pass

# Legacy node references for backward compatibility
# These need to be set after _ready() runs
var item_spr: Sprite2D :
	get:
		return item_sprite
var revolver_tip: Node2D :
	get:
		return gun_tip
var rev_sound: AudioStreamPlayer2D :
	get:
		return revolver_sound
