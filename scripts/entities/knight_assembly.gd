class_name KnightAssembly
extends Node2D

@export var is_player: bool = true
@export var start_position: Vector2 = Vector2.ZERO

# Component references
@onready var horse: Horse = $Horse
@onready var knight: Knight = $Knight
@onready var lance: Lance = $Lance

# Assembly state
var is_charging: bool = false
var opponent: KnightAssembly

# Signals for game manager
signal assembly_ready()
signal hit_registered(impact_data: Dictionary)

func _ready():
	# Debug: Verify all components are loaded
	print("Horse node: ", horse)
	print("Horse has start_charge: ", horse.has_method("start_charge"))
	print("Knight node: ", knight)
	print("Lance node: ", lance)
	
	# Configure based on player/opponent
	horse.is_player = is_player
	knight.is_player = is_player
	
	# Position knight on horse
	knight.position = Vector2(0, -40)
	
	# Attach lance to knight's mount point
	lance.position = knight.position + Vector2(20 if is_player else -20, -10)
	
	# Connect signals
	lance.lance_impact.connect(_on_lance_impact)
	
	# Set starting position
	global_position = start_position
	
	# Add to appropriate groups
	if is_player:
		add_to_group("player")
		horse.add_to_group("player")
		lance.add_to_group("player_lance")
	else:
		add_to_group("opponent")
		horse.add_to_group("opponent")
		lance.add_to_group("opponent_lance")
	
	assembly_ready.emit()

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
		print("Player couching lance...")

func _on_lance_impact(target: Node2D, impact_point: Vector2):
	# Calculate impact force
	var impact_force = calculate_impact_force()
	
	# Create impact data
	var impact_data = {
		"attacker": self,
		"target": target,
		"impact_point": impact_point,
		"force": impact_force,
		"horse_speed": horse.current_speed
	}
	
	hit_registered.emit(impact_data)
	
	# Apply impact to target if it's a knight
	if target.has_method("take_hit"):
		target.take_hit(impact_force)

func calculate_impact_force() -> float:
	# Basic calculation for Phase 1
	var speed_factor = horse.get_speed_percentage()
	var couch_bonus = 1.2 if lance.current_state == Lance.LanceState.COUCHED else 0.5
	
	return speed_factor * couch_bonus * 100.0  # Base force of 100

func reset():
	is_charging = false
	horse.state_machine.current_state.transitioned.emit(
		horse.state_machine.current_state, "Idle"
	)
	lance.reset_lance()
