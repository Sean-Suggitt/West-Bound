extends CharacterBody2D

var projectile_speed = 700

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = Vector2(projectile_speed, 0)
	var motion = velocity
	move_and_slide()



func _on_area_2d_body_entered(body: Node2D) -> void:
	Global.bullets_in_scene.pop_back()
	queue_free()
