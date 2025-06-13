extends CharacterBody2D

# Configuration
@export var speed: float = 700.0
@export var lifetime: float = 5.0  # Despawn after 5 seconds

# Internal state
var direction: Vector2
var owner_player: String
var bullet_id: int
var time_alive: float = 0.0

func setup(player_name: String, shoot_direction: int) -> void:
	owner_player = player_name
	direction = Vector2(shoot_direction, 0)
	velocity = direction * speed
	
	# Register with global system
	bullet_id = Global.register_bullet(self)
	
	# Set collision exceptions to prevent hitting own player
	if has_node("PlayerCollisionDetection"):
		var area = $PlayerCollisionDetection
		area.set_collision_mask_value(get_player_layer(player_name), false)

func _ready() -> void:
	# Add to bullet group for easy identification
	add_to_group("bullets")
	
	# Connect signals if not connected in editor
	if not $WorldCollisionDetection.body_entered.is_connected(_on_world_collision):
		$WorldCollisionDetection.body_entered.connect(_on_world_collision)
	if not $PlayerCollisionDetection.area_entered.is_connected(_on_player_collision):
		$PlayerCollisionDetection.area_entered.connect(_on_player_collision)

func _physics_process(delta: float) -> void:
	# Update lifetime
	time_alive += delta
	if time_alive >= lifetime:
		_destroy_bullet()
		return
	
	# Move bullet
	move_and_slide()

func _on_world_collision(body: Node2D) -> void:
	if body.is_in_group("World"):
		_destroy_bullet()

func _on_player_collision(area: Area2D) -> void:
	# Check which player was hit
	for player_name in ["P1", "P2"]:
		if area.is_in_group(player_name + "_Hurtbox") and player_name != owner_player:
			Global.damage_player(player_name, Global.REVOLVER_DAMAGE)
			print("Bullet hit ", player_name, " for ", Global.REVOLVER_DAMAGE, " damage. HP: ", Global.player_states[player_name]["hp"])
			_destroy_bullet()
			break

func _destroy_bullet() -> void:
	Global.unregister_bullet(bullet_id)
	queue_free()

func get_player_layer(player_name: String) -> int:
	# Return appropriate collision layer based on player
	return 2 if player_name == "P1" else 3
