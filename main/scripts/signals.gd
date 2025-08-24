extends Node

signal event(action, data)

func send_signal(action, data): # specifically for the menu to trigger
	emit_signal("event", action, data)
	print("signal emitted: %s, %s" % [action, data])
