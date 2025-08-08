class_name Knight
extends Node2D

@export var is_player: bool = true

# Visual elements
@onready var body_visual: ColorRect = $Body
@onready var shield_visual: ColorRect = $Shield
@onready var lance_mount: Marker2D = $LanceMount

signal knight_hit(impact_force: float)

func _ready():
	# Set colors based on player/opponent
	if is_player:
		body_visual.color = Color.LIGHT_BLUE
		shield_visual.color = Color.DARK_BLUE
	else:
		body_visual.color = Color.LIGHT_CORAL
		shield_visual.color = Color.DARK_RED
		# Flip for opponent
		scale.x = -1

func take_hit(impact_force: float):
	knight_hit.emit(impact_force)
	# Visual feedback
	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation", deg_to_rad(-15), 0.1)
	tween.tween_property(self, "rotation", 0, 0.3)
