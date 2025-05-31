extends CharacterBody2D

# Player identification
var player_id: String = "P2"

# References
@onready var sprite = $AnimatedSprite2D
@onready var gun_point = $GunPoint

# Resources
var bullet_scene = preload("res://Scenes/bullet.tscn")
var revolver_scene = preload("res://Scenes/Revolver.tscn")

# Movement variables
var speed = 300.0
var acceleration = 0.1
var deceleration = 0.1
const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

# Item system
var holding_item: bool = false
var items_in_range: Array = []

# Death/Respawn system
var is_dead: bool = false
var respawn_time: float = 3.0
var max_health: int = 100

func _ready() -> void:
	# Initialize player in global system
	if not Global.player_states.has(player_id):
		Global.player_states[player_id] = {
			"hp": max_health,
			"direction": 1,
			"alive": true
		}
	
	# Set up hurtbox if exists
	if has_node("Hurtbox"):
		$Hurtbox.add_to_group(player_id + "_Hurtbox")
	
	# Connect pickup range if exists
	if has_node("PickupRange"):
		$PickupRange.area_entered.connect(_on_pickup_range_entered)
		$PickupRange.area_exited.connect(_on_pickup_range_exited)
	
	# Don't spawn gun automatically anymore, wait for pickup
	if has_node("GunPoint/P2Gun"):
		$GunPoint/P2Gun.queue_free()

func _process(_delta: float) -> void:
	# Check health
	if Global.player_states[player_id]["hp"] <= 0 and not is_dead:
		_handle_death()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 
	# Handle jump.
	if Input.is_action_just_pressed("P2_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("P2_jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
	
	# Handle shooting
	if Input.is_action_just_pressed("P2_fire"):
		_shoot()
	
	# Handle pickup
	if Input.is_action_just_pressed("P2_pickup"):
		_handle_pickup()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("P2_left", "P2_right")

	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		sprite.flip_h = direction < 0
		
		# Update global direction
		Global.player_states[player_id]["direction"] = int(direction)
		
		# Update gun position
		if direction == 1:
			gun_point.position.x = abs(gun_point.position.x)
		if direction == -1:
			gun_point.position.x = abs(gun_point.position.x) * -1

		sprite.play("run")
		
	elif direction != 0:
		sprite.play("jump")
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		sprite.play("idle")

	move_and_slide()

func _shoot() -> void:
	if not holding_item:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = gun_point.global_position
	bullet.setup(player_id, Global.player_states[player_id]["direction"])
	get_parent().add_child(bullet)
	
	print("Player 2 shot! HP: ", Global.player_states[player_id]["hp"])

func _handle_pickup() -> void:
	if holding_item:
		_drop_item()
	elif not items_in_range.is_empty():
		_pickup_item(items_in_range[0])

func _pickup_item(item: Area2D) -> void:
	item.queue_free()
	holding_item = true
	# Show gun visual if we have one
	_spawn_gun_visual()
	items_in_range.erase(item)

func _drop_item() -> void:
	holding_item = false
	# Remove gun visual
	if has_node("GunPoint/P2Gun"):
		$GunPoint/P2Gun.queue_free()
	
	var item = revolver_scene.instantiate()
	var drop_direction = Global.player_states[player_id]["direction"]
	item.position = global_position + Vector2(drop_direction * 20, 10)
	get_parent().add_child(item)

func _spawn_gun_visual():
	# Only spawn if we don't already have one
	if has_node("GunPoint/P2Gun"):
		return
		
	# Create visual gun (if gun.tscn exists)
	if ResourceLoader.exists("res://Scenes/gun.tscn"):
		var gunScene = preload("res://Scenes/gun.tscn")
		var gunInstance = gunScene.instantiate()
		gunInstance.name = "P2Gun"
		gun_point.add_child(gunInstance)

func _on_pickup_range_entered(area: Area2D) -> void:
	if area.is_in_group("revolver_group"):
		items_in_range.append(area)

func _on_pickup_range_exited(area: Area2D) -> void:
	items_in_range.erase(area)

func _handle_death() -> void:
	is_dead = true
	
	# Visual feedback
	sprite.modulate.a = 0.5
	
	# Disable collisions
	set_collision_layer_value(1, false)
	if has_node("Hurtbox"):
		$Hurtbox.set_deferred("monitoring", false)
	
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
	if has_node("Hurtbox"):
		$Hurtbox.set_deferred("monitoring", true)
	
	# Reset position to spawn point
	var spawn_points = get_tree().get_nodes_in_group("spawn_" + player_id)
	if spawn_points.size() > 0:
		global_position = spawn_points[0].global_position
	else:
		# Fallback position
		global_position = Vector2(900, 300)
	
	# Reset visuals
	sprite.modulate.a = 1.0
	sprite.show()
	sprite.play("idle")
	
	# Reset physics
	velocity = Vector2.ZERO
