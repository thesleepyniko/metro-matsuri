# a better name for this might be grid gen but whatever
extends Node
@export var noise_height_text: NoiseTexture2D
var noise: Noise
var width: int = 20
var height: int = 20
var stations_array = []
var stations_target = 4
var min_station_dist = 4
var blocked = []
var stations = []
var candidates = []
var lines_and_stations = []
var threshold = 0.4
var accepted: Array[Vector2i] = []
var r = min_station_dist - 1
var is_placing = false
var is_dragging = false
var is_deleting = false
var already_deleting = false
var initial_pos := Vector2.ZERO
var already_placing = false
@onready var edit_mode = $"../HUD/RootControl/VBoxContainer/EditMode"
@onready var place_line = $"../HUD/RootControl/VBoxContainer/PlaceLine"
@onready var delete_line = $"../HUD/RootControl/VBoxContainer/DeleteLine"
@onready var stop_edit = $"../HUD/RootControl/VBoxContainer/StopEdit"
@onready var tilemap = $TileMapLayer
#@onready var stylebox = place_line.get_theme_stylebox()


var source_id_station = 1
var source_id_nothing = 0
var station_atlas = Vector2i(0, 0)
var nothing_atlas = Vector2i(0, 0)

# make sure we're painting in bounds!
func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func _paint_free_cells():
	for x in range(width):
		for y in range(height):
			tilemap.set_cell(Vector2i(x, y), source_id_nothing, nothing_atlas)

func _paint_block(center: Vector2i, r_local: int) -> void:
	for dx in range(-r_local, r_local + 1):
		for dy in range(-r_local, r_local + 1):
			#using chebyshev distance to check distance
			#https://en.wikipedia.org/wiki/Chebyshev_distance
			if max(abs(dx), abs(dy)) <= r_local:
				var nx = center.x + dx
				var ny = center.y + dy
				if _in_bounds(nx, ny):
					blocked[nx][ny] = true
					#tilemap.set_cell(Vector2i(nx, ny), source_id_nothing, nothing_atlas)
					#tilemap.set_cell()

func generate_map() -> void:
	#clear blocked
	stations = []
	blocked = []
	candidates = []
	accepted = []
	lines_and_stations = []
	lines_and_stations.resize(width)
	for i in range(width):
		var temp_lines = []
		temp_lines.resize(height)
		temp_lines.fill(null)
		lines_and_stations[i]=temp_lines
	blocked.resize(width)
	for i in range(width):
		var temp_blocked = []
		temp_blocked.resize(height)
		temp_blocked.fill(false)
		blocked[i] = temp_blocked
	if tilemap:
		tilemap.clear()
	for x in range(width):
		for y in range(height):
			var noise_val = noise.get_noise_2d(x, y)
			#noise_val_array.append(noise_val)
			if noise_val > threshold:
				candidates.append({
				"v": noise_val,
				"p": Vector2i(x, y)
			})
	print(candidates.size())
	if candidates.size() < stations_target * 2:
		randomize()
		noise.seed = randi() % 1000 + 1
		generate_map()
	candidates.sort_custom(func(a, b):
		return a["v"] > b["v"]   # descending by noise value
	)
	for item in candidates:
		var p: Vector2i = item["p"]
		if not blocked[p.x][p.y]:
			accepted.append(p)
			lines_and_stations[p.x][p.y] = "station"
			_paint_block(p, r)
			if accepted.size() == stations_target:
				break
	_paint_free_cells()
	for p in accepted:
		tilemap.set_cell(p, source_id_station, station_atlas)
	for x in lines_and_stations:
		for y in x:
			if y == "station":
				pass
			else:
				x[y] = "blank"
				#tilemap.set_cell(Vector2i(x, y), source_id_station, station_atlas) # place station
			#elif noise_val <= 0.4:
				#tilemap.set_cell(Vector2i(x, y), source_id_nothing, nothing_atlas) # place station
# place nothing
			#print(noise_val)
	#print("highest", noise_val_array.max())
	#print("lowest", noise_val_array.min())

func _on_cell_clicked(cell: Vector2i) -> void:
	var sid = tilemap.get_cell_source_id(cell)
	if sid == source_id_station: # check what cell was clicked
		print("clicked station at ", cell)
	else:
		print("clicked non-station at ", cell)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			initial_pos = event.position
			is_dragging = true
			print("click event started")
		elif event.is_released():
			var distance = event.position.distance_to(initial_pos)
			if distance < 10: # Click
				is_dragging = false
				print("Click")
			else: # Drag
				print("Dragging")
				is_dragging = false
				
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell: Vector2i = tilemap.local_to_map(tilemap.get_local_mouse_position())
		if _in_bounds(cell.x, cell.y):
			_on_cell_clicked(cell)
	
func _ready() -> void:
	noise = noise_height_text.noise
	noise.seed = randi() % 1000 + 1
	#noise_height_text.seed = rngseed # Replace with function body.
	generate_map()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_placing == true and is_dragging == true:
		var current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
		if current_cell in accepted:
			pass
		elif not _in_bounds(current_cell.x, current_cell.y):
			pass
		else:
			tilemap.set_cell(current_cell, 2, Vector2i(0, 0)) # stop players from painting over stations
	elif is_deleting == true and is_dragging == true:
		var current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
		if current_cell in accepted:
			pass
		elif not _in_bounds(current_cell.x, current_cell.y):
			pass
		else:
			lines_and_stations[current_cell.x]
			tilemap.set_cell(current_cell, 0, Vector2i(0, 0)) # stop players from painting over stations
func _on_edit_mode_pressed() -> void:
	# first we hide the "Edit lines" button and make the editor stuff visible
	edit_mode.visible = false
	place_line.visible = true
	delete_line.visible = true
	stop_edit.visible = true
	# next we set the default mode (is placing)
	is_placing = true
	already_placing = true
	#var new_stylebox = stylebox
	#new_stylebox.icon_normal_color = Color.WEB_GREEN
	place_line.add_theme_color_override("font_color", Color.DODGER_BLUE)
	place_line.add_theme_color_override("font_focus_color", Color.DODGER_BLUE)
	delete_line.remove_theme_color_override("font_color")
	delete_line.remove_theme_color_override("font_focus_color")

func _on_delete_line_pressed() -> void:
	is_placing = false
	already_placing = false
	is_deleting = true
	already_deleting = true
	place_line.remove_theme_color_override("font_color")
	place_line.remove_theme_color_override("font_focus_color")
	delete_line.add_theme_color_override("font_color", Color.DODGER_BLUE)
	delete_line.add_theme_color_override("font_focus_color", Color.DODGER_BLUE)
	
func _on_stop_edit_pressed() -> void:
	edit_mode.visible = true
	place_line.visible = false
	delete_line.visible = false
	stop_edit.visible = false
	is_placing = false
	already_placing = false
