class_name Knight
extends Node2D

@export var is_player: bool = true
var facing_direction: int = 1

@onready var body_sprite: Sprite2D = $BodySprite
@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var lance_mount: Marker2D = $LanceMount

signal knight_hit(impact_force: float)

func setup_for_pass(is_player_knight: bool, facing: int):
	"""Configure knight for proper side with sprites"""
	is_player = is_player_knight
	facing_direction = facing
	
	# Flip sprites based on facing
	body_sprite.flip_h = (facing == -1)
	shield_sprite.flip_h = (facing == -1)
	
	# Position shield on correct side
	if facing == 1:  # Facing right
		shield_sprite.position = Vector2(-30, 0)  # Shield on left
	else:  # Facing left
		shield_sprite.position = Vector2(30, 0)  # Shield on right

func take_hit(impact_force: float):
	knight_hit.emit(impact_force)
	# Visual feedback - lean back from impact
	var tween = get_tree().create_tween()
	var lean_direction = -facing_direction  # Lean away from hit
	tween.tween_property(self, "rotation", deg_to_rad(15 * lean_direction), 0.1)
	tween.tween_property(self, "rotation", 0, 0.3)
