class_name State
extends Node

signal transitioned(state: State, new_state_name: String)

var state_machine: StateMachine

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
 
