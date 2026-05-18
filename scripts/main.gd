extends Node2D

const CHUNK_WIDTH = 640.0
const SPAWN_RADIUS = 3 # How many chunks to keep visible around the player

var chunk_scene = preload("uid://bgjxwxruwafd2")
var current_chunk_index = 0
var active_chunks: Dictionary = {}

@onready var kaiju = $Kaiju
@onready var chunk_container = $ChunkContainer

func _ready():
	# Initial spawn around the starting position
	update_chunks(0)

func _unhandled_input(event):
	# Toggle fullscreen with F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta):
	# Calculate which chunk index the Kaiju is currently standing in
	var kaiju_chunk_pos = floor(kaiju.global_position.x / CHUNK_WIDTH)
	
	# If the player changes chunks, update what's spawned
	if kaiju_chunk_pos != current_chunk_index:
		current_chunk_index = kaiju_chunk_pos
		update_chunks(current_chunk_index)

func update_chunks(center_index: int):
	# Spawn required chunks within the radius
	for i in range(center_index - SPAWN_RADIUS, center_index + SPAWN_RADIUS + 1):
		if not active_chunks.has(i):
			spawn_chunk(i)
			
	# Despawn old chunks that are now out of range
	var chunks_to_remove = []
	for i in active_chunks.keys():
		if i < center_index - SPAWN_RADIUS or i > center_index + SPAWN_RADIUS:
			chunks_to_remove.append(i)
			
	for i in chunks_to_remove:
		active_chunks[i].queue_free()
		active_chunks.erase(i)

func spawn_chunk(index: int):
	var new_chunk = chunk_scene.instantiate()
	# Position the chunk purely based on its index and width
	new_chunk.global_position.x = index * CHUNK_WIDTH
	chunk_container.add_child(new_chunk)
	active_chunks[index] = new_chunk
