class_name TiltController
extends Node

@onready var player: KnightAssembly = $"PlayerKnight"
@onready var opponent: KnightAssembly = $"OpponentKnight"
@onready var player_start_point: Marker2D = $"PlayerStartPoint"
@onready var opponent_start_point: Marker2D = $"OpponentStartPoint"

# Joust state
var tilt_active: bool = false
var round_number: int = 1

# Signals
signal tilt_started()
signal tilt_ended(winner: String)
signal impact_occurred(impact_data: Dictionary)

func _ready():
	# Position assemblies at start markers
	player.global_position = player_start_point.global_position
	opponent.global_position = opponent_start_point.global_position
	
	await get_tree().process_frame
	
	# Set opponents
	player.opponent = opponent
	opponent.opponent = player
	
	# Connect signals
	player.hit_registered.connect(_on_hit_registered)
	opponent.hit_registered.connect(_on_hit_registered)
	
	# Start after 1 second
	await get_tree().create_timer(1.0).timeout
	start_tilt()

func start_tilt():
	print("Starting tilt round %d!" % round_number)
	tilt_active = true
	tilt_started.emit()
	
	# Start both horses charging
	player.start_charge()
	opponent.start_charge()
	
	# AI couches lance automatically (simple timing for Phase 1)
	_schedule_ai_couch()

func _schedule_ai_couch():
	# Simple AI: couch at optimal time
	await get_tree().create_timer(4.0).timeout
	if tilt_active:
		opponent.couch_lance()

func _on_hit_registered(impact_data: Dictionary):
	impact_occurred.emit(impact_data)
	
	# Check for pass completion
	_check_tilt_end()

func _check_tilt_end():
	# Simple check: if horses have passed each other
	if player.global_position.x > opponent.global_position.x:
		end_tilt()

func end_tilt():
	tilt_active = false
	
	# Determine winner (Phase 1: whoever hit wins)
	var winner = "Draw"
	if player.lance.has_hit and !opponent.lance.has_hit:
		winner = "Player"
	elif opponent.lance.has_hit and !player.lance.has_hit:
		winner = "Opponent"
	
	print("Tilt ended! Winner: %s" % winner)
	tilt_ended.emit(winner)
	
	# Reset after delay
	await get_tree().create_timer(2.0).timeout
	reset_tilt()

func reset_tilt():
	# Reset positions
	player.global_position = player_start_point.global_position
	opponent.global_position = opponent_start_point.global_position
	
	# Reset assemblies
	player.reset()
	opponent.reset()
	
	# Increment round and restart
	round_number += 1
	await get_tree().create_timer(1.0).timeout
	start_tilt()
