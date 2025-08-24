extends Camera2D

@export var map_width: int
@export var map_height: int
@export var tile_size: int
var zoom_min_in = 0.25
var target_zoom := 1.0
var zoom_step := 1.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_zoom_out"):
		target_zoom /= 1.1 
	elif Input.is_action_just_pressed("ui_zoom_in"):
		target_zoom *= 1.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var viewport = get_viewport().size
	
	#find how tall and wide our window is (no zoom)
	var world_w = viewport.x
	var world_h = viewport.y
	

	# get half of that so we can clamp later
	var half_w = (viewport.x * zoom.x) / 2
	var half_h = (viewport.y * zoom.y) / 2
	
	# compute the minimum zoom-out needed so the entire map fits in the view
	var fit_x = world_w / viewport.x
	var fit_y = world_h / viewport.y
	#var fit_zoom = max(fit_x, fit_y)    
	var fit_zoom = 1.0
	target_zoom = clamp(target_zoom, zoom_min_in, fit_zoom)
	zoom = Vector2(target_zoom, target_zoom)
	#clamping the zoom so that it can't go further than the window but can't zoom closer than 4x
	#var z = clamp(zoom.x, zoom_min_in, fit_zoom)
	#zoom = Vector2(z, z)
	
	#find how large the view is (with zoom) is currently
	var view_w = viewport.x * zoom.x
	var view_h = viewport.y * zoom.y
	
	#clamp the camera position so that you cant leave the map
	position.x = clamp(position.x, half_w, world_w - half_w)
	position.y = clamp(position.y, half_h, world_h - half_h)
