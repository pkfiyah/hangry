extends CharacterBody2D

const SPEED = 200.0
const CLIMB_SPEED = 150.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, CLIMBING }
var current_state = State.NORMAL

var left_ray: RayCast2D
var right_ray: RayCast2D

var attack_area: Area2D
var facing_direction: int = 1
var attack_timer: float = 0.0

var health: int = 100
var max_health: int = 100
var invulnerable_timer: float = 0.0

var current_exp: int = 0
var level: int = 1
var exp_to_next_level: int = 100

func _ready():
	# Programmatically create RayCasts for wall detection so we don't
	# need to edit the .tscn file directly.
	left_ray = RayCast2D.new()
	left_ray.position = Vector2(0, -12) # Center of the kaiju
	left_ray.target_position = Vector2(-20, 0) # Slightly wider than half-width (32)
	left_ray.collision_mask = 4 # Layer 3 (Buildings)
	add_child(left_ray)
	
	right_ray = RayCast2D.new()
	right_ray.position = Vector2(0, -12)
	right_ray.target_position = Vector2(20, 0)
	right_ray.collision_mask = 4 # Layer 3 (Buildings)
	add_child(right_ray)

	# Programmatically create the attack hitbox
	attack_area = Area2D.new()
	# Hitbox detects Layer 3 (Buildings, bit 3 -> value 4) and Layer 4 (Enemies, bit 4 -> value 8)
	attack_area.collision_mask = 4 | 8 
	var attack_shape = CollisionShape2D.new()
	var attack_rect = RectangleShape2D.new()
	attack_rect.size = Vector2(80, 100) # Hitbox size
	attack_shape.shape = attack_rect
	attack_area.add_child(attack_shape)
	add_child(attack_area)

func _physics_process(delta):
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		# Flicker effect while invulnerable
		visible = fmod(invulnerable_timer, 0.2) > 0.1
	else:
		visible = true

	match current_state:
		State.NORMAL:
			process_normal(delta)
		State.CLIMBING:
			process_climbing(delta)

signal health_changed(new_health)
signal exp_changed(new_exp)
signal level_up(new_level)

func add_exp(amount: int):
	current_exp += amount
	
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		emit_signal("level_up", level)
		print("Level Up! New Level: ", level)
		
	print("Kaiju EXP: ", current_exp)
	emit_signal("exp_changed", current_exp)

func take_damage(amount: int):
	if invulnerable_timer > 0:
		return
	health -= amount
	invulnerable_timer = 1.0 # 1 second of i-frames
	print("Kaiju Health: ", health)
	emit_signal("health_changed", health)
	if health <= 0:
		print("Game Over!")
		get_tree().reload_current_scene()

func process_normal(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# If standing on a building roof, pressing down drops you through it
	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		position.y += 5

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		facing_direction = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Update attack hitbox position based on facing direction
	attack_area.position.x = facing_direction * 40
	attack_area.position.y = -50

	# Attack logic
	if attack_timer > 0:
		attack_timer -= delta
		
	if Input.is_key_pressed(KEY_Z) and attack_timer <= 0:
		attack_timer = 0.5 # Attack cooldown
		perform_attack()

	# Check if we should start climbing
	var vert_direction = Input.get_axis("ui_up", "ui_down")
	if vert_direction != 0:
		if left_ray.is_colliding():
			current_state = State.CLIMBING
			velocity = Vector2.ZERO
			global_position.x = left_ray.get_collision_point().x + 16
		elif right_ray.is_colliding():
			current_state = State.CLIMBING
			velocity = Vector2.ZERO
			global_position.x = right_ray.get_collision_point().x - 16

	move_and_slide()

func perform_attack():
	# Create a brief visual indicator for the attack
	var slash = ColorRect.new()
	slash.color = Color.RED
	slash.size = Vector2(80, 100)
	slash.position = Vector2(-40, -50)
	attack_area.add_child(slash)
	
	# Animate the slash fading out so we can see it
	var tween = create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(slash.queue_free)

	# Check what buildings are in the hitbox and damage them
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			# Buildings take 25 damage per hit (4 hits to destroy)
			body.take_damage(25)

func process_climbing(delta):
	var wall_direction = 0
	
	if left_ray.is_colliding():
		wall_direction = -1 # Wall is to our left
	elif right_ray.is_colliding():
		wall_direction = 1  # Wall is to our right
	else:
		# We've climbed past the top or bottom of the building
		current_state = State.NORMAL
		return

	# Vertical movement (ui_up is negative, ui_down is positive)
	var vert_direction = Input.get_axis("ui_up", "ui_down")
	velocity.y = vert_direction * CLIMB_SPEED
	
	# Horizontal movement is locked while climbing unless detaching/jumping
	velocity.x = 0
	
	var horiz_direction = Input.get_axis("ui_left", "ui_right")
	
	if Input.is_action_just_pressed("ui_accept"):
		# Jump off the wall (away from it)
		velocity.y = JUMP_VELOCITY
		# Jump in opposite direction of the wall
		velocity.x = -wall_direction * SPEED 
		current_state = State.NORMAL
	elif (wall_direction == -1 and horiz_direction > 0) or \
		 (wall_direction == 1 and horiz_direction < 0):
		# Detach by pressing away from the wall
		current_state = State.NORMAL
		
	# Attack while climbing (optional, but fun!)
	if attack_timer > 0:
		attack_timer -= delta
	if Input.is_key_pressed(KEY_Z) and attack_timer <= 0:
		attack_timer = 0.5
		# Turn to face the wall to attack it
		facing_direction = wall_direction
		attack_area.position.x = facing_direction * 40
		attack_area.position.y = -50
		perform_attack()
		
	move_and_slide()
