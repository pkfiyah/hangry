extends Camera2D

@export var look_ahead_distance = 50.0
@export var smooth_speed = 5.0
@export var bottom_limit = -160.0 # Replaces fixed_y_position to prevent seeing underground
@export var vertical_offset = -80.0 # How far above the player the camera should aim when climbing
@export var vertical_smooth_speed = 5.0 # Speed of vertical camera follow

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
		
		# Calculate initial y position based on target, but clamped to bottom_limit
		var target_y = min(bottom_limit, target.global_position.y + vertical_offset)
		global_position.y = target_y

func _process(delta):
	if not is_instance_valid(target):
		return
		
	# Instantly follow the target's X position
	global_position.x = target.global_position.x
	
	# Calculate desired Y position (follow player, but don't go below bottom_limit)
	var target_y = min(bottom_limit, target.global_position.y + vertical_offset)
	
	# Smoothly interpolate the Y position
	global_position.y = lerp(global_position.y, target_y, vertical_smooth_speed * delta)
	
	var move_dir = Input.get_axis("ui_left", "ui_right")
	
	# Target position is the player's center + an offset in the direction they face
	var target_offset = move_dir * look_ahead_distance
	
	# Interpolate the camera's internal offset for a smooth "sliding" feel
	offset.x = lerp(offset.x, target_offset, smooth_speed * delta)
