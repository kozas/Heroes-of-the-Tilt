class_name Lance
extends Area2D

enum LanceState { CARRIED, TRANSITIONING, COUCHED, IMPACT }

@export_group("Lance Properties")
@export var couch_angle: float = 0.0  # Horizontal when couched
@export var carried_angle: float = 75.0  # Near vertical when carried
@export var transition_time: float = 1.5

# State management
var current_state: LanceState = LanceState.CARRIED
var transition_progress: float = 0.0
var can_hit: bool = false
var has_hit: bool = false

# Visual elements
@onready var visual: ColorRect = $ColorRect
@onready var tip_marker: Marker2D = $TipMarker

# Signals
signal lance_couched()
signal lance_impact(target: Node2D, impact_point: Vector2)

func _ready():
	rotation_degrees = carried_angle
	visual.color = Color.SADDLE_BROWN
	
	# Set collision monitoring
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	match current_state:
		LanceState.TRANSITIONING:
			_handle_transition(delta)
		LanceState.COUCHED:
			_handle_couched_state(delta)

func start_couch():
	if current_state == LanceState.CARRIED:
		current_state = LanceState.TRANSITIONING
		transition_progress = 0.0

func _handle_transition(delta):
	transition_progress += delta / transition_time
	
	if transition_progress >= 1.0:
		transition_progress = 1.0
		current_state = LanceState.COUCHED
		can_hit = true
		lance_couched.emit()
	
	# Lerp rotation from carried to couched
	var target_rotation = lerp_angle(
		deg_to_rad(carried_angle), 
		deg_to_rad(couch_angle), 
		transition_progress
	)
	rotation = target_rotation

func _handle_couched_state(_delta):
	# Ready for impact
	# Phase 2 will add wobble here
	pass

func _on_body_entered(body):
	if !can_hit or has_hit:
		return
	
	# Check if we hit opponent knight or horse
	if body.is_in_group("opponent"):
		_register_hit(body)

func _on_area_entered(area):
	if !can_hit or has_hit:
		return
	
	# Check for lance-on-lance collision
	if area.is_in_group("opponent_lance"):
		_register_hit(area)

func _register_hit(target):
	has_hit = true
	can_hit = false
	current_state = LanceState.IMPACT
	
	var impact_point = tip_marker.global_position
	lance_impact.emit(target, impact_point)
	
	# Visual feedback - lance breaks or bounces
	var tween = get_tree().create_tween()
	tween.tween_property(visual, "modulate:a", 0.5, 0.1)
	tween.tween_property(visual, "modulate:a", 1.0, 0.2)

func reset_lance():
	current_state = LanceState.CARRIED
	rotation_degrees = carried_angle
	has_hit = false
	can_hit = false
	transition_progress = 0.0
