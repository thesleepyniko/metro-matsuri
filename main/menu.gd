extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button in get_children():
		if button is Button:
			button.pressed.connect(Callable(self, "_on_button_pressed").bind(button))

func _on_button_pressed(button: Button):
	Bus.emit_signal("pressed", button.name)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
