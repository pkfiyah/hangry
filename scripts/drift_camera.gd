extends Camera2D

@export var look_ahead_distance = 50.0
@export var smooth_speed = 5.0
@export var fixed_y_position = -160.0 # Adjusted to fit the 640x360 resolution and keep the ground visible

@onready var target = get_parent()

func _ready():
	# Detach the camera from the parent's transform so we can control its position manually
	# This prevents the camera from moving up and down when the Kaiju jumps
	top_level = true
	
	# Programmatically enforce 1x zoom and 0 offset.y for pixel art consistency.
	# This overrides any old editor settings that were meant for the old resolution.
	zoom = Vector2.ONE
	offset.y = 0
	
	# Set initial position
	if target:
		global_position.x = target.global_position.x
		global_position.y = fixed_y_position

func _process(delta):
	if not is_instance_valid(target):
		return
		
	# Instantly follow the target's X position
	global_position.x = target.global_position.x
	
	# Lock the Y position
	global_position.y = fixed_y_position
	
	var move_dir = Input.get_axis("ui_left", "ui_right")
	
	# Target position is the player's center + an offset in the direction they face
	var target_offset = move_dir * look_ahead_distance
	
	# Interpolate the camera's internal offset for a smooth "sliding" feel
	offset.x = lerp(offset.x, target_offset, smooth_speed * delta)
