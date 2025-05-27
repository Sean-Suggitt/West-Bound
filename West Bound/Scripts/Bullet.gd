extends CharacterBody2D

var projectile_speed = 700

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var motion = Vector2(projectile_speed, 0)
	var collision = move_and_collide(motion) 

	if collision:
		var temp = Global.bullets_in_scene.pop_back()
		temp.queue_free()
