class_name HorseCanteringState
extends State

var timer: float = 0.0

func enter():
	if owner is Horse:
		var horse = owner as Horse
		horse.target_speed = horse.canter_speed
		horse.phase_changed.emit("Cantering")
		timer = 0.0

func physics_update(delta):
	if owner is Horse:
		var horse = owner as Horse
		timer += delta
		
		if timer >= horse.canter_duration:
			transitioned.emit(self, "Galloping")
