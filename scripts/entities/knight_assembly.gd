class_name KnightAssembly
extends Node2D

@export var is_player: bool = true

# Component references
@onready var horse: Horse = $Horse
@onready var knight: Knight = $Knight
@onready var lance: Lance = $Lance

# Assembly state
var is_charging: bool = false
var opponent: KnightAssembly
var facing_direction: int = 1

# Signals
signal assembly_ready()
signal hit_registered(impact_data: Dictionary)

func _ready():
	# Determine facing
	facing_direction = 1 if is_player else -1
	
	# Setup components
	horse.setup_for_pass(is_player, facing_direction)
	knight.setup_for_pass(is_player, facing_direction)
	lance.setup_for_pass(is_player, facing_direction)
	
	# CRITICAL: Setup the RemoteTransform2D connections
	await get_tree().process_frame  # Wait for nodes to be ready
	horse.setup_mounts(knight.get_path(), lance.get_path())
	
	# Connect signals
	lance.lance_impact.connect(_on_lance_impact)
	
	# Add to collision groups
	if is_player:
		add_to_group("player")
		horse.add_to_group("player")
		lance.add_to_group("player_lance")
	else:
		add_to_group("opponent")
		horse.add_to_group("opponent")
		lance.add_to_group("opponent_lance")
	
	assembly_ready.emit()

func start_charge():
	is_charging = true
	horse.start_charge()

func couch_lance():
	lance.start_couch()

func reset():
	"""Full reset for new joust"""
	is_charging = false
	horse.state_machine.current_state.transitioned.emit(
		horse.state_machine.current_state, "Idle"
	)
	lance.reset_lance()

# Input handling
func _unhandled_input(event):
	if !is_player or !is_charging:
		return
	
	if event.is_action_pressed("horse_urge"):
		horse.apply_player_input(0.1)
	elif event.is_action_pressed("horse_steady"):
		horse.apply_player_input(-0.15)
	
	if event.is_action_pressed("couch_lance"):
		couch_lance()

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
	
	# Apply impact to target
	var target_assembly = target.get_parent()
	if target_assembly.has_method("take_impact"):
		target_assembly.take_impact(impact_force, impact_point)

func calculate_impact_force() -> float:
	var speed_factor = horse.get_speed_percentage()
	var couch_bonus = 1.2 if lance.current_state == Lance.LanceState.COUCHED else 0.5
	return speed_factor * couch_bonus * 100.0
