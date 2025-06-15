extends Node

func _ready() -> void:
	Global.hurt_sound = Global.HURT_SOUND.instantiate()
	add_child(Global.hurt_sound)
