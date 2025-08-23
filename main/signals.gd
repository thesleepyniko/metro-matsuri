extends Node

signal pressed(action)

func button_press(action): # specifically for the menu to trigger
	emit_signal("pressed", action)
