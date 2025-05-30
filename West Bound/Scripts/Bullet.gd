extends CharacterBody2D

var projectile_speed = 700
var shoot_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	projectile_speed = abs(projectile_speed) * Global.P1_direction
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = Vector2(projectile_speed, 0)
	move_and_slide()


func _on_world_collision_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("World"):
		Global.bullets_in_scene.pop_back()
		queue_free()
		print("bullet hit wall")


func _on_player_collision_detection_area_entered(area: Area2D) -> void:
	print("cccooolided")
	if area.is_in_group("Player1Hurtbox"):
		Global.P1_HP -= Global.revolver_damage
		Global.bullets_in_scene.pop_back()
		queue_free()
		print(Global.P1_HP)
