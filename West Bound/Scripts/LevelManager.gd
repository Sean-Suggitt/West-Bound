extends Node2D
class_name LevelManager

@export var levels: Array[PackedScene] = []
@export var sequential: bool = true

var current_level_index: int = -1
var current_level_instance: Node = null

func load_level(index: int) -> void:
	#Remove old level if exists
	if current_level_instance and is_instance_valid(current_level_instance):
		current_level_instance.queue_free()
	
	await get_tree().process_frame
	
	#Load next level
	current_level_index = index
	current_level_instance = levels[index].instantiate()
	add_child(current_level_instance)

func next_level() -> void:
	if levels.is_empty():
		push_error("No levels configured in LevelManager")
		return
	
	var next_index: int
	if sequential:
		next_index = (current_level_index + 1) % levels.size()
	else:
		next_index = randi() % levels.size()
		if levels.size() > 1 and next_index == current_level_index:
			next_level()  # Recursive call to get a different level
			return
	
	load_level(next_index)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not levels.is_empty():
		load_level(0)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
