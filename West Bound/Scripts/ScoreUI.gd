extends CanvasLayer

# References to score sprites
@onready var p1_score_sprite: Sprite2D = $Container/P1Score/P1ScoreSprite
@onready var p2_score_sprite: Sprite2D = $Container/P2Score/P2ScoreSprite

# Track previous scores to detect changes
var previous_scores = {"P1": 0, "P2": 0}

func _ready() -> void:
	# hide score sprites initially
	p1_score_sprite.visible = false
	p2_score_sprite.visible = false
	
	# uupdate display with curent scores
	_update_score_display()

func _process(_delta: float) -> void:
	# check for score changes every frame
	_check_score_updates()

func _check_score_updates() -> void:
	# Check P1 score
	var p1_current = Global.get_score("P1")
	if p1_current != previous_scores["P1"]:
		previous_scores["P1"] = p1_current
		_update_player_score_display("P1", p1_current)
	
	# check P2 score
	var p2_current = Global.get_score("P2")
	if p2_current != previous_scores["P2"]:
		previous_scores["P2"] = p2_current
		_update_player_score_display("P2", p2_current)

func _update_player_score_display(player: String, score: int) -> void:
	var sprite = p1_score_sprite if player == "P1" else p2_score_sprite
	
	if score == 0:
		# Hide sprite
		sprite.visible = false
	else:
		# Show sprite and set frame (score 1 = frame 0, score 2 = frame 1, etc.)
		sprite.visible = true
		sprite.frame = clamp(score - 1, 0, 4)  # Ensure frame is between 0-4
		
		
		_animate_score_change(sprite)

func _animate_score_change(sprite: Sprite2D) -> void:
	# Create a simple pop animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# scale up then back to normal
	sprite.scale = Vector2(0.8, 0.8)
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)

func _update_score_display() -> void:
	# Initial updat on ready
	_update_player_score_display("P1", Global.get_score("P1"))
	_update_player_score_display("P2", Global.get_score("P2"))

# Public method to force refresh (useful for round resets)
func refresh_scores() -> void:
	previous_scores = {"P1": 0, "P2": 0}
	_update_score_display() 
