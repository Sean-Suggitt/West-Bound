extends CharacterBody2D
#References------------------------
@onready var item = load("res://Scenes/Revolver.tscn")  ##
@onready var item_spr = $Revolver_Sprite              ##
@onready var player_spr = $AniPlayerSpr                ##

#Variables_________________________
var speed = 300.0
var acceleration = 0.1
var deceleration = 0.1
var holding_item: bool = false ##
var drop_pos: Vector2             ##
var items_in_range: Array = [] ##

const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

func _ready() -> void:
	item_spr.hide() ##

func _physics_process(delta: float) -> void:

	# Get the animated sprite node
	var sprite = $AnimatedSprite2D
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

	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		sprite.flip_h = direction < 0
		item_spr.flip_h = direction < 0
		drop_pos = Vector2(direction * 12, 13)
		sprite.play("run")
	elif direction != 0:
		sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		sprite.play("idle")
		

	move_and_slide()
