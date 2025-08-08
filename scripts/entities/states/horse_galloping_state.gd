class_name HorseGallopingState
extends State

func enter():
	if owner is Horse:
		var horse = owner as Horse
		horse.target_speed = horse.gallop_speed
		horse.phase_changed.emit("Galloping")

func physics_update(_delta):
	# Maintain gallop until impact or end of tilt
	pass
