class_name HorseIdleState
extends State

func enter():
	if owner is Horse:
		var horse = owner as Horse
		horse.target_speed = 0
		horse.current_speed = 0

func physics_update(_delta):
	# Wait for signal to start charge
	pass
