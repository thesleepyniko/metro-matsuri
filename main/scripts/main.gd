extends Node

var screens = ["res://main/scenes/menu.tscn", "res://main/scenes/game.tscn", "res://main/scenes/failed.tscn"]
enum enum_screens {menu=0, game=1, failed=2}
var curr_state # we want to know what state it is...duh...
var prev_state
var debug # set by the user to see any

@onready
var screen_host = get_node("ScreenHost")

func change_screen(state):
	for child in screen_host.get_children():
		child.queue_free() # clean up whatever screens were in the screen
	var screen_path = screens[state] # set new screen path (we passed state in right :D)
	var screen = load(screen_path).instantiate() #load it
	screen_host.add_child(screen) # add as a child
	

func change_state(new_state):
	prev_state = curr_state
	curr_state = new_state
	change_screen(curr_state)

func _handle_event_change(action, data):
	if action == "pressed":
		match data:
			"Quit":
				get_tree().quit()
				print("got quit signal, qutting")
			"Start":
				change_state(enum_screens.game) 
				print("starting game")
			"PlayAgain":
				change_state(enum_screens.game) 
	if action == "failed":
		change_screen(enum_screens.failed)
	if action == "exit_game":
		change_screen(enum_screens.menu)
			

func _on_bus_event(action, data):
	_handle_event_change(action, data)
	print("signal recieved: %s, %s" % [action, data])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bus.connect("event", Callable(self, "_on_bus_event"))
	change_state(enum_screens.menu)


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
