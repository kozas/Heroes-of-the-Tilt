class_name HUD
extends Control

@onready var speed_label: Label = $TopPanel/SpeedLabel
@onready var state_label: Label = $TopPanel/StateLabel
@onready var round_label: Label = $TopPanel/RoundLabel
@onready var instruction_label: Label = $BottomPanel/InstructionLabel
@onready var center_message: Label = $CenterMessage

var player: KnightAssembly
var tilt_controller: TiltController

func _ready():
	# Get references
	player = get_node("/root/JoustingArena/PlayerAssembly")
	tilt_controller = get_node("/root/JoustingArena/GameManager")
	
	# Connect signals
	if player:
		player.horse.speed_changed.connect(_on_speed_changed)
		player.horse.phase_changed.connect(_on_phase_changed)
		player.lance.lance_couched.connect(_on_lance_couched)
	
	if tilt_controller:
		tilt_controller.impact_occurred.connect(_on_impact)
		tilt_controller.joust_ended.connect(_on_joust_ended)
	
	# Set initial instructions
	instruction_label.text = "W: Urge Forward | S: Steady Horse | SPACE: Couch Lance"
	center_message.visible = false

func _on_speed_changed(speed: float):
	speed_label.text = "Speed: %d" % speed

func _on_phase_changed(phase: String):
	state_label.text = "Phase: %s" % phase

func _on_lance_couched():
	show_center_message("Lance Couched!", 1.0)

func _on_impact(impact_data: Dictionary):
	if impact_data.attacker == player:
		show_center_message("HIT! Force: %d" % impact_data.force, 2.0)
	else:
		show_center_message("You've been hit!", 2.0)

func _on_joust_ended(winner: String):
	show_center_message("%s Wins the Pass!" % winner, 3.0)

func show_center_message(text: String, duration: float):
	center_message.text = text
	center_message.visible = true
	
	await get_tree().create_timer(duration).timeout
	center_message.visible = false
