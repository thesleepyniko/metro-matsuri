# a better name for this might be grid gen but whatever
extends Node
@export var noise_height_text: NoiseTexture2D
var noise: Noise
enum types {empty=0, station=1}
var width: int = 20
var height: int = 20
var stations_array = []
var stations_target = 4
var min_station_dist = 5
var rngseed = randi()
@onready var tilemap = $TileMapLayer

var source_id_station = 1
var source_id_nothing = 0
var station_atlas = Vector2i(0, 0)
var nothing_atlas = Vector2i(0, 0)

func generate_map() -> void:
	for x in range(width):
		for y in range(height):
			var noise_val = noise.get_noise_2d(x, y)
			#noise_val_array.append(noise_val)
			if noise_val > 0.4:
				tilemap.set_cell(Vector2(x, y), source_id_station, station_atlas) # place station
			elif noise_val <= 0.4:
				tilemap.set_cell(Vector2(x, y), source_id_nothing, nothing_atlas) # place station
 # place nothing
			#print(noise_val)
	#print("highest", noise_val_array.max())
	#print("lowest", noise_val_array.min())
func _enter_tree() -> void:
	noise = noise_height_text.noise
	#noise_height_text.seed = rngseed # Replace with function body.
	generate_map()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
