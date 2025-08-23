extends Control

func _connect_buttons(node: Node):
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(Callable(self, "_on_button_pressed").bind(child))
		else:
			_connect_buttons(child)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_connect_buttons(self)

func _on_button_pressed(button: Button):
	Bus.send_signal("pressed", button.name)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
