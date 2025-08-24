extends Button

@onready var title_obj = $"MarginContainer/VBoxContainer/Title"
@onready var desc_obj = $"MarginContainer/VBoxContainer/Description"
@onready var image_obj = $"MarginContainer/VBoxContainer/TextureRect"

func set_data(title: String, description: String, image: String):
	title_obj.text = title
	desc_obj.text = description
	image_obj.texture = load(image)
	
func get_data(): # we want this so that we can check some info if needed (and to get the last used card)
	return [title_obj.text, desc_obj.text, image_obj.texture]
