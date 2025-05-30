extends CharacterBody2D


var speed = 300.0
var acceleration = 0.1
var deceleration = 0.1
@onready var GunPoint = $GunPoint
const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

func spawnGun():
	#preload gun scene then create an instance of it
	var gunScene = preload("res://Scenes/gun.tscn")
	var gunInstance = gunScene.instantiate()
	
	gunInstance.name = "P2Gun"
	
	#add the new gun instance as a child to the player node
	GunPoint.add_child(gunInstance)
	

func _physics_process(delta: float) -> void:

	# Get the animated sprite node
	var sprite = $AnimatedSprite2D
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
 
	# Handle jump.
	if Input.is_action_just_pressed("P2_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("P2_jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("P2_left", "P2_right") # returns -1(left) 1(right) 0(neither)

	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		sprite.flip_h = direction < 0
		
		if direction == 1:
			GunPoint.position.x = abs(GunPoint.position.x)
		if direction == -1:
			GunPoint.position.x = abs(GunPoint.position.x) * -1


		sprite.play("run")
		
	elif direction != 0:
		sprite.play("jump")
		
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		sprite.play("idle")
		

	move_and_slide()



# called when the node first enters the scene
func _ready() -> void:
	spawnGun()
