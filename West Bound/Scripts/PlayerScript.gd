extends CharacterBody2D

#--------------------------------------------------------------------
#--------------------------- VARIABLES ------------------------------
#--------------------------------------------------------------------

	#References-------------------------------------------------------------------
@onready var revolver = load("res://Scenes/Revolver.tscn")  ##

@onready var item_spr = $Revolver_Sprite              ##
@onready var revolver_tip = $gun_tip
@onready var sprite = $AniPlayerSpr    # Get the animated sprite node

var bullet = preload("res://Scenes/bullet.tscn")


	# Item Pickup System
var holding_item: bool = false ##
var drop_pos: Vector2             ##
var items_in_range: Array = [] ##

	# General Movement
var speed = 200                      # Movement speed
var acceleration = 0.1                 # Movemennt acceleration
var deceleration = 0.1                 # Movement deceleration
var air_deceleration = 0.05           
const JUMP_VELOCITY = -400.0           # Jump force
var decelerate_on_jump_release = 0.01  # Used in variable jump height

	# Coyote Time & Jump Buffering System
var coyote_time = 0.11           # Grace period after leaving ground (in seconds)
var jump_buffer_time = 0.13      # How long to remember jump input (in seconds)d
var coyote_timer = 0.0           # Time since left ground
var jump_buffer_timer = 0.0      # Time since jump was pressed
var was_on_floor = false         # Track ground state changes

	# Air control physics
var air_acceleration = 350.0      # More responsive air acceleration
var air_friction = 145.0          # Base air resistance
var air_control_factor = 0.9      # 90% of ground control in air
var terminal_velocity = 600.0     # Max falling speed

	# Momentum system - multiple realistic intervals
var momentum_intervals = [
	{"speed_ratio": 0.0, "deceleration": 0.08},   # Stationary/very slow
	{"speed_ratio": 0.2, "deceleration": 0.065},  # Walking speed
	{"speed_ratio": 0.4, "deceleration": 0.05},   # Jogging speed
	{"speed_ratio": 0.6, "deceleration": 0.04},   # Running speed
	{"speed_ratio": 0.8, "deceleration": 0.032},  # Fast running
	{"speed_ratio": 1.0, "deceleration": 0.025}   # Maximum speed
]

#--------------------------------------------------------------------
#----------------------ENGINE FUNCTIONS------------------------------
#--------------------------------------------------------------------

func _ready() -> void:
	item_spr.hide() ##


# TODO: move all the constant update logic that is not
#       related to physics from _physics_process() into _process()
func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	
	# Track ground state for coyote time
	var currently_on_floor = is_on_floor()
	
	# Shooting
	if Input.is_action_just_pressed("P1_fire"):
		shoot()
	
	# Update coyote timer
	if currently_on_floor:
		coyote_timer = 0.0  # Reset when on ground
	elif was_on_floor and not currently_on_floor:
		coyote_timer = 0.0  # Just left ground, start coyote time
	else:
		coyote_timer += delta  # Count
	
	was_on_floor = currently_on_floor
	
	# Update jump buffer timer (countdown)
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Add gravity
	if not currently_on_floor:
		velocity += get_gravity() * delta
	# Enhanced jump logic with coyote time and jump buffering
	var can_coyote_jump = coyote_timer <= coyote_time
	var has_jump_buffered = jump_buffer_timer > 0
	
	# Handle jump input - store it in buffer
	if Input.is_action_just_pressed("P1_jump"):
		jump_buffer_timer = jump_buffer_time  # Store jump input for buffering
	
	# Execute jump if conditions are met
	if has_jump_buffered and (currently_on_floor or can_coyote_jump):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0  # Consume the buffered jump
		coyote_timer = coyote_time + 1  # Prevent multiple coyote jumps
		
		# Optional: Add visual/audio feedback here
		# print("Jump executed! Ground: ", currently_on_floor, " Coyote: ", can_coyote_jump)
	
	# Variable jump height
	if Input.is_action_just_released("P1_jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
	
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("P1_left", "P1_right") # returns -1(left) 1(right) 0(neither)
	
	if currently_on_floor:
		# Ground movement
		if direction:
			velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
			sprite.flip_h = direction < 0
			item_spr.flip_h = direction < 0
			item_spr.position.x = abs(item_spr.position.x) * direction
			drop_pos = Vector2(direction * 12, 13)
			sprite.play("run")
			
			# Calculate smooth momentum-based air deceleration
			var current_speed_ratio = abs(velocity.x) / speed
			air_deceleration = calculate_momentum_deceleration(current_speed_ratio)
			print(air_deceleration)
		else:
			velocity.x = move_toward(velocity.x, 0, speed * deceleration)
			sprite.play("idle")
	else:
		# Air movement with momentum preservation
		if direction:
			# Air acceleration with reduced control
			var target_speed = direction * speed * air_control_factor
			velocity.x = move_toward(velocity.x, target_speed, air_acceleration * delta)
		else:
			# Air friction based on current momentum
			var current_speed_ratio = abs(velocity.x) / speed
			var dynamic_friction = air_friction * (1.0 + current_speed_ratio * 0.5)
			velocity.x = move_toward(velocity.x, 0, dynamic_friction * delta)
		
		# Cap falling speed
		velocity.y = min(velocity.y, terminal_velocity)
		

	move_and_slide()


#--------------------------------------------------------------------
#----------------------NON-ENGINE FUNCTIONS------------------------------
#--------------------------------------------------------------------

# Calculate momentum-based air deceleration using smooth interpolation
func calculate_momentum_deceleration(speed_ratio: float) -> float:
	# Clamp speed ratio to reasonable bounds
	speed_ratio = clamp(speed_ratio, 0.0, 1.2)  # Allow slight overspeed
	
	# Find the two closest intervals for interpolation
	for i in range(momentum_intervals.size() - 1):
		var current_interval = momentum_intervals[i]
		var next_interval = momentum_intervals[i + 1]
		
		if speed_ratio <= next_interval.speed_ratio:
			# Interpolate between the two intervals
			var ratio_range = next_interval.speed_ratio - current_interval.speed_ratio
			if ratio_range == 0:
				return current_interval.deceleration
			
			var local_ratio = (speed_ratio - current_interval.speed_ratio) / ratio_range
			return lerp(current_interval.deceleration, next_interval.deceleration, local_ratio)
	
	# If speed exceeds all intervals, use the highest tier
	return momentum_intervals[-1].deceleration

# Pickup system functions
func pickup_item(item: Area2D):        ###
	item.queue_free()
	holding_item = true
	item_spr.show()


func drop_item():        ###
	item_spr.hide()
	var item = revolver.instantiate()
	item.position = position + drop_pos
	get_parent().add_child(item)
	holding_item = false


func _on_pickup_range_area_entered(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.append(area)
		print(items_in_range)


func _on_pickup_range_area_exited(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.erase(area)
		print(items_in_range)

# Pickup item event listener
func _input(event):
	if event.is_action_pressed("P1_pickup"):
		print("Pressed Pickup")
		if holding_item:
			drop_item()
		else:
			if !items_in_range.is_empty():
				pickup_item(items_in_range.pick_random())


func shoot():
	if holding_item:
		var temp_bullet = bullet.instantiate()
		temp_bullet.global_position = revolver_tip.global_position
		Global.bullets_in_scene.push_front(temp_bullet)
		get_parent().add_child(temp_bullet)
