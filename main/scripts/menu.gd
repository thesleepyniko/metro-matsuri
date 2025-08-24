extends Control

func _connect_buttons(node: Node):
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(Callable(self, "_on_button_pressed").bind(child))
		else:
			_connect_buttons(child)

func _ready() -> void:
	randomize() # randomize once per start
	_connect_buttons(self)

func _enter_tree() -> void:
	randomize() # if the user comes back to the menu, randomize again

func _on_button_pressed(button: Button):
	Bus.send_signal("pressed", button.name)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
