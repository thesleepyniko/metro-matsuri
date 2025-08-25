extends Node2D

var card_scene = preload("res://main/scenes/card.tscn") # load the cards in first so we can work with them later

var card_choices
func _spawn_card(data: Dictionary):
	print("data is: " + str(data))
	var card = card_scene.instantiate() # create an instance of the card
	#var vbox = card.find_node("VBoxContainer", true, false)
	$"HUD/RootControl/Cards".add_child(card)
	#print("Children of card root:", card.get_children())
	#if card.has_node("MarginContainer/VBoxContainer"):
		#var card_obj = card.get_node("MarginContainer/VBoxContainer")
		#print("Found VBoxContainer:", card_obj)
		#card_obj.set_data("Station A", "Upgrade capacity by 20%", "res://icon.svg")
	#else:
		#print("VBoxContainer path not found inside card instance")
	#var card_obj = card.get_node("HUD/RootControl/Cards/Card/MarginContainer/VBoxContainer")
	card.set_data(data["title"], data["description"], data["image"]) # here is a placeholder for example

# Called when the node enters the scene tree for the first time.

func _get_random_card(list):
	var index = randi() % list.size()
	return list[index]
	
func _on_hide_ui_pressed() -> void: # will need to add more later prolly idk :3
	if $HUD/RootControl/Cards.visible == false:
		$HUD/RootControl/Cards.visible = true
		$HUD/RootControl/HideUI.text = "Hide UI"
	elif $HUD/RootControl/Cards.visible == true:
		$HUD/RootControl/Cards.visible = false
		$HUD/RootControl/HideUI.text = "Show UI"

#func _on_place_line_pressed() -> void:
	#if $HUD/RootControl/Cards.text == "Place Lines":
		#$HUD/RootControl/HideUI.visbile = false
	#elif $HUD/RootControl/Cards.visible == true:
		#$HUD/RootControl/Cards.visible = false
		#$HUD/RootControl/HideUI.text = "Show UI" # Replace with function body.

func _on_exit_pressed() -> void:
	print("exit was pressed")
	Bus.emit_signal("event", "exit_game", "") 

func _generate_nodes():
	pass

func _ready() -> void:
	var raw_json_file = FileAccess.open("res://main/resources/cards.json", FileAccess.READ)
	var text = raw_json_file.get_as_text()
	raw_json_file.close() # close it because for the remainder of the run we won't need it
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()]) # in case something is broken for debugging
		return
	var data = json.data
	_spawn_card(_get_random_card(data)) # first we want to spawn the cards


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
