extends CharacterBody2D


var speed = 300.0
var acceleration = 0.1
var deceleration = 0.1

const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

func _physics_process(delta: float) -> void:


	var sprite = $AnimatedSprite2D    # Get the animated sprite node
	
	if not is_on_floor():             # Add the gravity.
		velocity += get_gravity() * delta
 
	if Input.is_action_just_pressed("P1_jump") and is_on_floor(): 	# Handle jump.
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("P1_jump") and velocity.y < 0: # variable jump height
		velocity.y *= decelerate_on_jump_release

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("P1_left", "P1_right") # returns -1(left) 1(right) 0(neither)

	# 
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		sprite.flip_h = direction < 0
		sprite.play("run")
	elif direction != 0:
		sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		sprite.play("idle")
		

	move_and_slide()


# func pickup()
# if itemheld == false && "theres an item in range"
# 	Remove the item node from the main scene
#   Add the item as a child of the player node

# func RemoveItem
# if itemHeld == true
# 	Remove the item from 

# func throw(item node)
# 	spawns item at players position
# 	sets

# func drop(item node)
# 	spawns item at players position 
