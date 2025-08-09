class_name Horse
extends CharacterBody2D

# Horse movement parameters
@export_group("Movement")
@export var base_speed: float = 300.0
@export var walk_speed: float = 150.0
@export var canter_speed: float = 350.0
@export var gallop_speed: float = 550.0
@export var acceleration: float = 50.0

@export_group("Timing")
@export var walk_duration: float = 3.0
@export var canter_duration: float = 3.0

# Horse attributes (expandable for Phase 2+)
@export_group("Attributes")
@export var temperament: String = "steady"  # steady, spirited, veteran
@export var excitement: float = 0.0
@export var fatigue: float = 0.0

# Internal variables
var current_speed: float = 0.0
var target_speed: float = 0.0
var phase_timer: float = 0.0
var is_player: bool = true
var direction: int = 1  # 1 for right, -1 for left

# Node references
@onready var sprite: Sprite2D = $Sprite
@onready var state_machine: StateMachine = $StateMachine
@onready var debug_label: Label = $DebugLabel

# Signals for future extension
signal speed_changed(new_speed: float)
signal phase_changed(phase_name: String)
signal approached_opponent(distance: float)

func _ready():
	# Initialize debug display
	if debug_label:
		debug_label.position = Vector2(-100, -80)

func _physics_process(delta):
	# Smooth speed transitions
	if current_speed < target_speed:
		current_speed = min(current_speed + acceleration * delta, target_speed)
	elif current_speed > target_speed:
		current_speed = max(current_speed - acceleration * 2 * delta, target_speed)
	
	# Apply movement in the correct direction
	velocity.x = current_speed * direction
	move_and_slide()
	
	# Update debug info
	if debug_label:
		var state_name = "None"
		if state_machine and state_machine.current_state:
			state_name = state_machine.current_state.name
		debug_label.text = "Speed: %d\nState: %s" % [current_speed, state_name]
		# Keep label readable regardless of flip
		debug_label.scale.x = abs(debug_label.scale.x) 
	
	speed_changed.emit(current_speed)
	
func setup_for_pass(is_player_horse: bool, facing: int):
	"""Properly configure horse for its side"""
	is_player = is_player_horse
	direction = facing

	# Flip sprite based on facing direction
	sprite.flip_h = (facing == -1)  # Flip if facing left

	print("Horse setup - Player: %s, Direction: %d, Flipped: %s" % 
		[is_player, direction, sprite.flip_h])

func start_charge():
	state_machine.current_state.transitioned.emit(state_machine.current_state, "Walking")

func get_speed_percentage() -> float:
	return current_speed / gallop_speed

# Player input influence (subtle speed control)
func apply_player_input(input_strength: float):
	# Only works for player horse and with limited effectiveness
	if !is_player:
		return
	
	# Influence decreases with excitement (Phase 2)
	var influence = clamp(input_strength, -0.15, 0.10)
	current_speed *= (1.0 + influence)
