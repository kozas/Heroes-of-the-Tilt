class_name Lance
extends Area2D

enum LanceState { CARRIED, TRANSITIONING, COUCHED, IMPACT }

@export var couch_angle: float = 0.0  # Horizontal when couched
@export var carried_angle: float = -75.0  # Default for right-facing
@export var transition_time: float = 1.5

var current_state: LanceState = LanceState.CARRIED
var transition_progress: float = 0.0
var can_hit: bool = false
var has_hit: bool = false
var facing_direction: int = 1

@onready var sprite: Sprite2D = $Sprite
@onready var tip_marker: Marker2D = $TipMarker

signal lance_couched()
signal lance_impact(target: Node2D, impact_point: Vector2)

func setup_for_pass(is_player_lance: bool, facing: int):
	"""Configure lance with proper sprite flipping"""
	facing_direction = facing
	
	# Flip the sprite, not the whole node
	sprite.flip_h = (facing == -1)
	
	# Set angles based on facing
	if facing == 1:  # Facing right
		carried_angle = -75.0
		couch_angle = 0.0
	else:  # Facing left
		carried_angle = -105.0
		couch_angle = 180.0
	
	rotation_degrees = carried_angle

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func start_couch():
	if current_state == LanceState.CARRIED:
		current_state = LanceState.TRANSITIONING
		transition_progress = 0.0

func _process(delta):
	match current_state:
		LanceState.TRANSITIONING:
			_handle_transition(delta)
		LanceState.COUCHED:
			_handle_couched_state(delta)

func _handle_transition(delta):
	transition_progress += delta / transition_time
	
	if transition_progress >= 1.0:
		transition_progress = 1.0
		current_state = LanceState.COUCHED
		can_hit = true
		lance_couched.emit()
	
	# Smoothly rotate from carried to couched angle
	var target_rotation = lerp_angle(
		deg_to_rad(carried_angle), 
		deg_to_rad(couch_angle), 
		transition_progress
	)
	rotation = target_rotation

func _handle_couched_state(_delta):
	# Ready for impact
	pass

func _on_body_entered(body):
	if !can_hit or has_hit:
		return
	
	# Check collision based on groups
	if body.is_in_group("opponent" if facing_direction == 1 else "player"):
		_register_hit(body)

func _on_area_entered(area):
	if !can_hit or has_hit:
		return
	
	# Check for lance-on-lance collision
	var target_group = "opponent_lance" if facing_direction == 1 else "player_lance"
	if area.is_in_group(target_group):
		_register_hit(area)

func _register_hit(target):
	has_hit = true
	can_hit = false
	current_state = LanceState.IMPACT
	
	var impact_point = tip_marker.global_position
	lance_impact.emit(target, impact_point)
	
	# Visual feedback
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.5, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)

func reset_lance():
	current_state = LanceState.CARRIED
	rotation_degrees = carried_angle
	has_hit = false
	can_hit = false
	transition_progress = 0.0
