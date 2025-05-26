extends CharacterBody2D
#References------------------------
@onready var revolver = load("res://Scenes/Revolver.tscn")  ##
@onready var item_spr = $Revolver_Sprite              ##
@onready var player_spr = $AniPlayerSpr                ##

#Variables_________________________
var speed = 300.0
var acceleration = 0.1
var deceleration = 0.1
var holding_item: bool = false ##
var drop_pos: Vector2             ##
var items_in_range: Array = [] ##
var air_deceleration = 0.05

const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

# Air control physics
var air_acceleration = 350.0      # More responsive air acceleration
var air_friction = 145.0          # Base air resistance
var air_control_factor = 0.9     # 90% of ground control in air
var terminal_velocity = 600.0     # Max falling speed

# Momentum system - multiple realistic intervals
var momentum_intervals = [
	{"speed_ratio": 0.0, "deceleration": 0.08},   # Stationary/very slow
	{"speed_ratio": 0.2, "deceleration": 0.065}, # Walking speed
	{"speed_ratio": 0.4, "deceleration": 0.05},  # Jogging speed
	{"speed_ratio": 0.6, "deceleration": 0.04},  # Running speed
	{"speed_ratio": 0.8, "deceleration": 0.032}, # Fast running
	{"speed_ratio": 1.0, "deceleration": 0.025}  # Maximum speed
]

func _ready() -> void:
	item_spr.hide() ##

func _physics_process(delta: float) -> void:

	# Get the animated sprite node
	var sprite = $AniPlayerSpr
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 
	# Handle jump.
	if Input.is_action_just_pressed("P1_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("P1_jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("P1_left", "P1_right") # returns -1(left) 1(right) 0(neither)

	if is_on_floor():
		# Ground movement (your existing logic)
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

func _input(event):
	if event.is_action_pressed("P1_pickup"):
		if holding_item:
			drop_item()
		else:
			if !items_in_range.is_empty():
				pickup_item(items_in_range.pick_random())
