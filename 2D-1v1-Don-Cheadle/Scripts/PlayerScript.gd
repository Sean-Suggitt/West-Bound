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

const JUMP_VELOCITY = -400.0
var decelerate_on_jump_release = 0.01

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

	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, speed * acceleration)
		sprite.flip_h = direction < 0
		item_spr.flip_h = direction < 0
		item_spr.position.x = abs(item_spr.position.x) * direction
		drop_pos = Vector2(direction * 12, 13)
		sprite.play("run")
	elif direction != 0:
		sprite.play("jump")
	else:
		velocity.x = move_toward(velocity.x, 0, speed * deceleration)
		sprite.play("idle")
		

	move_and_slide()

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
