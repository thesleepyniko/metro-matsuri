# a better name for this might be grid gen but whatever
#this list is getting ridiculous :waa:
extends Node
@export var noise_height_text: NoiseTexture2D
enum cell { BLANK, LINE, STATION }
var noise: Noise
var width: int = 20
var height: int = 20
#var stations_array = []
var stations_target = 4
var min_station_dist = 4
var blocked = []
var candidates = []
var lines_and_stations = []
var components = []
var map_dirty: bool = false
var threshold = 0.4
var accepted: Array[Vector2i] = []
var is_placing = false
var is_dragging = false
var is_deleting = false
var already_deleting = false
var initial_pos := Vector2.ZERO
var already_placing = false
var active_by_cid: Array[bool] = []
var station_by_cell = {}
var stations_in_comp = []
var failed = false
var tick_counter: float = 0.0
var sim_accum: float = 0.0
const BASE_THROUGHPUT_PER_COMP = 6.0
@onready var edit_mode = $"../HUD/RootControl/VBoxContainer/EditMode"
@onready var place_line = $"../HUD/RootControl/VBoxContainer/PlaceLine"
@onready var delete_line = $"../HUD/RootControl/VBoxContainer/DeleteLine"
@onready var stop_edit = $"../HUD/RootControl/VBoxContainer/StopEdit"
@onready var tilemap = $TileMapLayer
#@onready var stylebox = place_line.get_theme_stylebox()
const SECONDS_PER_TICK = 0.2
const FAIL_THRESHOLD = 10
var k_speed_global = 1.0 # this needs to be able to changed due to cards
var source_id_line = 2
var source_id_station = 1
var source_id_nothing = 0
var line_atlas = Vector2i(0, 0)
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
	var r: int = min_station_dist - 1
	blocked = []
	candidates = []
	accepted = []
	lines_and_stations = []
	components = []
	components.resize(width)
	for i in range(width):
		var temp_comps = []
		temp_comps.resize(height)
		temp_comps.fill(-1)
		components[i] = temp_comps
	lines_and_stations.resize(width)
	for i in range(width):
		var temp_lines = []
		temp_lines.resize(height)
		temp_lines.fill(cell.BLANK)
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
			lines_and_stations[p.x][p.y] = cell.STATION
			_paint_block(p, r)
			if accepted.size() == stations_target:
				break
	_paint_free_cells()
	for p in accepted:
		tilemap.set_cell(p, source_id_station, station_atlas)
	for x in range(width):
		for y in range(height):
			if lines_and_stations[x][y] == cell.STATION:
				pass
			else:
				lines_and_stations[x][y] = cell.BLANK
	station_by_cell.clear()
	relabel_components()



				#tilemap.set_cell(Vector2i(x, y), source_id_station, station_atlas) # place station
			#elif noise_val <= 0.4:
				#tilemap.set_cell(Vector2i(x, y), source_id_nothing, nothing_atlas) # place station
# place nothing
			#print(noise_val)
	#print("highest", noise_val_array.max())
	#print("lowest", noise_val_array.min())

func relabel_components() -> void:
	# reset labels
	for x in range(width):
		for y in range(height):
			components[x][y] = -1

	var next_id := 0
	var counts: Array[int] = []
	var queue: Array[Vector2i] = []
	var tmp_groups: Array = []

	# scan the grid
	for x in range(width):
		for y in range(height):
			if components[x][y] != -1: 
				continue
			if not _cell_passable(x, y):
				continue

			# start BFS for this component
			var cid := next_id
			next_id += 1
			queue.clear()
			queue.append(Vector2i(x, y))
			components[x][y] = cid
			var stations_here: Array[Vector2i] = []

			var station_count := 0

			while queue.size() > 0:
				var c = queue.pop_front()
				if lines_and_stations[c.x][c.y] == cell.STATION:
					station_count += 1
					stations_here.append(c)

				for n in _neighbors4(c.x, c.y):
					if not _in_bounds(n.x, n.y):
						continue
					if components[n.x][n.y] != -1:
						continue
					if not _cell_passable(n.x, n.y):
						continue
					components[n.x][n.y] = cid
					queue.append(n)

			counts.append(station_count)
			tmp_groups.append(stations_here)

	# derive activity: “works” if component has >= 2 stations
	active_by_cid.clear()
	for count in counts:
		active_by_cid.append(count >= 2)
	stations_in_comp = tmp_groups
	var current_set = {}
	for cid in range(stations_in_comp.size()):
		for station in stations_in_comp[cid]:
			var rec = station_by_cell.get(station)
			if rec == null:
				# first time we see this station in the registry
				rec = {
					"passengers": 0,
					"spawn_rate": 0.8,
					"carry": 0.0,
					"comp_id": cid,
				}
				station_by_cell[station] = rec
			else:
				# keep its queue, just update which component it belongs to
				rec["comp_id"] = cid
			current_set[station] = true
	#some pruning to get rid of nonexistant stations
	var to_remove: Array = []
	for k in station_by_cell.keys():
		if not current_set.has(k):
			to_remove.append(k)
	for k in to_remove:
		station_by_cell.erase(k)

func _is_active_at(x: int, y: int) -> bool:
	var cid = components[x][y]
	return cid >= 0 and cid < active_by_cid.size() and active_by_cid[cid]


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

func _cell_passable(x: int, y: int) -> bool:
	return lines_and_stations[x][y] == cell.LINE or lines_and_stations[x][y] == cell.STATION

func _neighbors4(x: int, y: int) -> Array[Vector2i]:
	return [
		Vector2i(x + 1, y), # right
		Vector2i(x - 1, y), # left
		Vector2i(x, y + 1), # top
		Vector2i(x, y - 1), # bottom
	]

func sim_tick(dt: float) -> void:
	for rec in station_by_cell.values():
		var want = rec["spawn_rate"] * dt + rec["carry"]
		var arrivals := int(floor(want))
		rec["carry"] = want - float(arrivals)
		rec["passengers"] += arrivals

	for cid in range(active_by_cid.size()):
		if not active_by_cid[cid]:
			continue

		var budget = BASE_THROUGHPUT_PER_COMP * k_speed_global * dt  # float
		if budget < 1.0:
			continue  # not enough capacity to move a whole passenger this tick

		# build list of stations in this component that actually have passengers
		var S: Array = []
		for p in stations_in_comp[cid]:
			var rec = station_by_cell.get(p)
			if rec != null and rec["passengers"] > 0:
				S.append(p)

		# equal-share draining until budget is spent or all queues are empty
		while budget >= 1.0 and S.size() > 0:
			var per := int(floor(budget / float(S.size())))
			if per < 1:
				per = 1
			var spent := 0
			for p in S:
				var rec2 = station_by_cell[p]
				var take = min(per, rec2["passengers"])
				rec2["passengers"] -= take
				spent += take
			budget -= float(spent)

			# recompute S with only stations still > 0
			var nextS: Array = []
			for p in S:
				if station_by_cell[p]["passengers"] > 0:
					nextS.append(p)
			S = nextS

	for rec in station_by_cell.values():
		if rec["passengers"] > FAIL_THRESHOLD:
			failed = true
			break

	tick_counter += dt
	if tick_counter >= 1.0:
		tick_counter = 0.0
		# quick visibility of state
		for p in station_by_cell.keys():
			var r = station_by_cell[p]
			var cid = r["comp_id"]
			prints("station", p, "cid", cid, "active", (cid >= 0 and cid < active_by_cid.size() and active_by_cid[cid]), "q", r["passengers"])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if failed:
		Bus.emit_signal("event", "failed", "")
	if not failed:
		sim_accum += delta
		var ticks := 0
		while sim_accum >= SECONDS_PER_TICK and ticks < 5: # cap to avoid spiral-of-death
			sim_accum -= SECONDS_PER_TICK
			sim_tick(SECONDS_PER_TICK)
			ticks += 1
	if is_placing == true and is_dragging == true:
		var current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
		if not _in_bounds(current_cell.x, current_cell.y):
			return
		if lines_and_stations[current_cell.x][current_cell.y] != cell.STATION:
			lines_and_stations[current_cell.x][current_cell.y] = cell.LINE
			tilemap.set_cell(current_cell, source_id_line, Vector2i(0,0))
			map_dirty = true 

	elif is_deleting == true and is_dragging == true:
		var current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
		if not _in_bounds(current_cell.x, current_cell.y):
			return
		if lines_and_stations[current_cell.x][current_cell.y] != cell.STATION:
			lines_and_stations[current_cell.x][current_cell.y] = cell.BLANK
			tilemap.set_cell(current_cell, source_id_nothing, Vector2i(0,0))
			map_dirty = true
			
	if map_dirty and not is_dragging:
		relabel_components()
		map_dirty = false
		

func _on_edit_mode_pressed() -> void:
	# first we hide the "Edit lines" button and make the editor stuff visible
	edit_mode.visible = false
	place_line.visible = true
	delete_line.visible = true
	stop_edit.visible = true
	# next we set the default mode (is placing)
	is_placing = true
	already_placing = true
	is_deleting = false
	already_deleting = false
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

func _on_place_line_pressed() -> void:
	is_placing = true
	already_placing = true
	is_deleting = false
	already_deleting = false
	delete_line.remove_theme_color_override("font_color")
	delete_line.remove_theme_color_override("font_focus_color")
	place_line.add_theme_color_override("font_color", Color.DODGER_BLUE)
	place_line.add_theme_color_override("font_focus_color", Color.DODGER_BLUE)

func _on_stop_edit_pressed() -> void:
	edit_mode.visible = true
	place_line.visible = false
	delete_line.visible = false
	stop_edit.visible = false
	is_placing = false
	already_placing = false
