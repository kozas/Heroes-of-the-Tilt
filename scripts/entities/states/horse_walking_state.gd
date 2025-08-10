class_name HorseWalkingState
extends State

var timer: float = 0.0

func enter():
	if owner is Horse:
		var horse = owner as Horse
		horse.target_speed = horse.walk_speed
		horse.phase_changed.emit("Walking")
		timer = 0.0
		
		horse.animated_sprite.play("walking")

func physics_update(delta):
	if owner is Horse:
		var horse = owner as Horse
		timer += delta
		
		if timer >= horse.walk_duration:
			transitioned.emit(self, "Cantering")
