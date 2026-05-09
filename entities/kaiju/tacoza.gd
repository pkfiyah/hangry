extends Enemy
class_name Tacoza

var leap_timer: float = 0.0
var time_between_leaps: float = 3.0
var is_leaping: bool = false
var leap_velocity_x: float = 400.0
var leap_velocity_y: float = -600.0

func _ready() -> void:
	super._ready() # Call the base _ready
	
	# Tacoza allows landing on buildings (Layer 3, bit 3 -> value 4)
	# By default, CharacterBody2D collides with Layer 1 (Floor).
	# We set collision mask to include Buildings.
	# Make sure we don't physically collide with the Player (Layer 2)!
	set_collision_mask_value(3, true) # Buildings
	
	# Randomize first leap timer slightly so they don't all jump at once
	leap_timer = randf_range(0.5, time_between_leaps)
	
	# Override direction if we want them to leap towards player, 
	# but for now we just use the initialized direction from spawn.
	if is_instance_valid(visual):
		visual.flip_h = direction < 0

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		
		# In the air: fast animation, maintain leap velocity
		if is_instance_valid(visual):
			visual.speed_scale = 2.0
		if is_leaping:
			velocity.x = direction * leap_velocity_x
	
	if is_on_floor():
		# On the ground: slow twitchy animation
		if is_instance_valid(visual):
			visual.speed_scale = 0.5
			
		# Only zero out horizontal speed if we aren't starting a jump
		if velocity.y >= 0:
			velocity.x = 0 # Stay still on the ground
			is_leaping = false
		
		# Countdown for next leap
		leap_timer -= delta
		if leap_timer <= 0:
			perform_leap()
			leap_timer = time_between_leaps

	move_and_slide()

func perform_leap() -> void:
	is_leaping = true
	
	# Randomize leap velocities for varied arcs
	leap_velocity_x = randf_range(200.0, 500.0)
	leap_velocity_y = randf_range(-400.0, -700.0)
	
	# Leap in the current direction
	velocity.x = direction * leap_velocity_x
	velocity.y = leap_velocity_y
	
	if is_instance_valid(visual):
		visual.flip_h = direction < 0
