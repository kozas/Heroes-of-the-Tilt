class_name KnightAssembly
extends Node2D

@export var is_player: bool = true
@export var start_position: Vector2 = Vector2.ZERO
@export var sprite_scale: float = 0.6  # Adjust this to tune size

# Component references
@onready var horse: Horse = $Horse
@onready var knight: Knight = $Knight
@onready var lance: Lance = $Lance

# Assembly state
var is_charging: bool = false
var opponent: KnightAssembly
var facing_direction: int = 1  # 1 = right, -1 = left

# Signals
signal assembly_ready()
signal hit_registered(impact_data: Dictionary)

func _ready():
	# Apply scale to all sprites
	horse.sprite.scale = Vector2(sprite_scale, sprite_scale)
	knight.body_sprite.scale = Vector2(sprite_scale, sprite_scale)
	knight.shield_sprite.scale = Vector2(sprite_scale, sprite_scale)
	lance.sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	# Set facing direction based on side
	facing_direction = 1 if is_player else -1
	
	# Initialize all components with proper orientation
	_setup_components()
	
	# Set starting position
	global_position = start_position
	
	# Connect signals
	lance.lance_impact.connect(_on_lance_impact)
	
	# Add to groups for collision detection
	if is_player:
		add_to_group("player")
		horse.add_to_group("player")
		lance.add_to_group("player_lance")
	else:
		add_to_group("opponent")
		horse.add_to_group("opponent")
		lance.add_to_group("opponent_lance")
	
	assembly_ready.emit()

func _setup_components():
	"""Properly configure all components for their side"""
	horse.setup_for_pass(is_player, facing_direction)
	knight.setup_for_pass(is_player, facing_direction)
	lance.setup_for_pass(is_player, facing_direction)

	# Position knight on horse (same for both sides)
	knight.position = Vector2(0, -48 * sprite_scale)

	# Position lance relative to knight based on facing
	if facing_direction == 1:  # Player facing right
		lance.position = Vector2(30, -50)
	else:  # Opponent facing left
		lance.position = Vector2(-30, -50)

func _physics_process(delta):
	# Keep knight and lance following horse
	if horse:
		knight.global_position = horse.global_position + Vector2(0, -48)
		
		# Lance follows knight with proper offset
		var lance_x_offset = 40 * facing_direction
		lance.global_position = knight.global_position + Vector2(lance_x_offset, -12)

func _unhandled_input(event):
	if !is_player or !is_charging:
		return
	
	# Horse speed influence
	if event.is_action_pressed("horse_urge"):  # W key
		horse.apply_player_input(0.1)
	elif event.is_action_pressed("horse_steady"):  # S key
		horse.apply_player_input(-0.15)
	
	# Lance couching
	if event.is_action_pressed("couch_lance"):  # Space
		couch_lance()


func start_charge():
	is_charging = true
	horse.start_charge()

func couch_lance():
	if lance.current_state == Lance.LanceState.CARRIED:
		lance.start_couch()

func _on_lance_impact(target: Node2D, impact_point: Vector2):
	var impact_force = calculate_impact_force()
	
	var impact_data = {
		"attacker": self,
		"target": target,
		"impact_point": impact_point,
		"force": impact_force,
		"horse_speed": horse.current_speed
	}
	
	hit_registered.emit(impact_data)
	
	if target.has_method("take_hit"):
		target.take_hit(impact_force)

func calculate_impact_force() -> float:
	var speed_factor = horse.get_speed_percentage()
	var couch_bonus = 1.2 if lance.current_state == Lance.LanceState.COUCHED else 0.5
	return speed_factor * couch_bonus * 100.0

func reset():
	is_charging = false
	horse.state_machine.current_state.transitioned.emit(
		horse.state_machine.current_state, "Idle"
	)
	lance.reset_lance()
