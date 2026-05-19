extends CharacterBody2D

const SPEED = 200.0
const CLIMB_SPEED = 150.0
const JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { NORMAL, CLIMBING }
var current_state = State.NORMAL

@onready var left_ray: RayCast2D = $LeftRay
@onready var right_ray: RayCast2D = $RightRay
@onready var player_area: CollisionShape2D = $CollisionShape2D

# The container node where all active mutations will be added as children
@onready var mutations_container: Node2D = $Mutations

@export var manual_attack_enabled: bool = true

# Database of all available mutations in the game
@export var mutation_database: MutationDatabase

var facing_direction: int = 1

var health: int = 100
var max_health: int = 100
var invulnerable_timer: float = 0.0

var state_change_cooldown_timer: float = 0.0

var current_exp: int = 0
var level: int = 1
var exp_to_next_level: int = 10

signal health_changed(new_health)
signal exp_changed(new_exp)
signal level_up(new_level)
signal mutation_added(mutation)

func _ready():
	# Ensure the UI connects to our signal
	var ui_menu = get_tree().get_first_node_in_group("level_up_menu")
	if ui_menu and ui_menu is LevelUpMenu:
		ui_menu.upgrade_selected.connect(_on_upgrade_selected)

func _change_state(new_state:State): 
	if state_change_cooldown_timer <= 0.0:
		current_state = new_state
		state_change_cooldown_timer = 0.3;
		

func _physics_process(delta):
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		# Flicker effect while invulnerable
		visible = fmod(invulnerable_timer, 0.2) > 0.1
	else:
		visible = true
		
	if state_change_cooldown_timer > 0:
		state_change_cooldown_timer -= delta

	match current_state:
		State.NORMAL:
			process_normal(delta)
		State.CLIMBING:
			process_climbing(delta)

func add_exp(amount: int):
	current_exp += amount
	
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		# Scale up the required EXP for the next level (e.g., 20% more each level)
		exp_to_next_level = int(exp_to_next_level * 1.2)
		
		emit_signal("level_up", level)
		print("Level Up! New Level: ", level)
		_trigger_level_up_menu()
		
	print("Kaiju EXP: ", current_exp)
	emit_signal("exp_changed", current_exp)
	
func _trigger_level_up_menu() -> void:
	var ui_menu = get_tree().get_first_node_in_group("level_up_menu")
	if not ui_menu or not ui_menu is LevelUpMenu or not mutation_database:
		push_warning("LevelUpMenu or MutationDatabase is missing!")
		return
		
	var options = _generate_level_up_options(3)
	if options.is_empty():
		return
		
	ui_menu.display_options(options)

func _generate_level_up_options(count: int) -> Array[Dictionary]:
	var available_options: Array[Dictionary] = []
	
	# Check existing mutations for upgrades
	for child in mutations_container.get_children():
		if child is Mutation and child.stats:
			if child.current_level < child.stats.get_max_level():
				var next_lvl = child.current_level + 1
				var lvl_data = child.stats.get_level_data(next_lvl)
				available_options.append({
					"mutation_id": child.name, # Using the node name as a rough ID for existing ones
					"mutation_name": child.stats.mutation_name,
					"is_new": false,
					"next_level": next_lvl,
					"description": child.stats.mutation_description,
					"existing_node": child,
					"stats": child.stats
				})
				
	# Check database for new mutations not yet acquired
	for m_id in mutation_database.mutation_scenes.keys():
		var has_mutation = false
		for child in mutations_container.get_children():
			# We assume the scene instantiates with the exact m_id or we track it.
			# For simplicity, we just check if a node with this m_id exists
			if child.name.to_lower() == str(m_id).to_lower():
				has_mutation = true
				break
				
		if not has_mutation:
			var scene: PackedScene = mutation_database.mutation_scenes[m_id]
			# To get the name/description, we might need to instantiate it temporarily 
			# or we assume a separate Data structure. For now, instantiate to read stats:
			var temp_instance = scene.instantiate() as Mutation
			if temp_instance and temp_instance.stats:
				var lvl_data = temp_instance.stats.get_level_data(1)
				available_options.append({
					"mutation_id": m_id,
					"mutation_name": temp_instance.stats.mutation_name,
					"is_new": true,
					"next_level": 1,
					"description": lvl_data.description,
					"scene": scene,
					"stats": temp_instance.stats
				})
			temp_instance.free()
			
	# Shuffle and pick 'count' options
	available_options.shuffle()
	return available_options.slice(0, min(count, available_options.size()))

func _on_upgrade_selected(option_data: Dictionary) -> void:
	if option_data.is_new:
		var scene: PackedScene = option_data.scene
		var new_mutation = scene.instantiate()
		new_mutation.name = option_data.mutation_id
		mutations_container.add_child(new_mutation)
		emit_signal("mutation_added", new_mutation)
	else:
		var existing: Mutation = option_data.existing_node
		if existing:
			existing.level_up()

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

	# Trigger active mutations
	_trigger_mutations()

	# Check if we should start climbing
	var vert_direction = Input.get_axis("ui_up", "ui_down")
	if vert_direction != 0:
		if left_ray.is_colliding():
			_change_state(State.CLIMBING)
			velocity = Vector2.ZERO
			global_position.x = left_ray.get_collision_point().x + player_area.shape.get_rect().size.x/2
		elif right_ray.is_colliding():
			_change_state(State.CLIMBING)
			velocity = Vector2.ZERO
			global_position.x = right_ray.get_collision_point().x - player_area.shape.get_rect().size.x/2

	move_and_slide()

func _trigger_mutations() -> void:
	if not is_instance_valid(mutations_container):
		return
		
	var want_to_manual_attack = manual_attack_enabled and Input.is_key_pressed(KEY_Z)
	
	for mutation in mutations_container.get_children():
		if mutation is Mutation:
			# If manual is disabled, mutations fire automatically on cooldown.
			# If manual is enabled, we only fire if the user presses the key.
			if not manual_attack_enabled or want_to_manual_attack:
				mutation.trigger(want_to_manual_attack)

func process_climbing(delta):
	var wall_direction = 0
	
	if left_ray.is_colliding():
		wall_direction = -1 # Wall is to our left
	elif right_ray.is_colliding():
		wall_direction = 1  # Wall is to our right
	else:
		# We've climbed past the top or bottom of the building
		_change_state(State.NORMAL)
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
		_change_state(State.NORMAL)
		
	elif (wall_direction == -1 and horiz_direction > 0) or \
		 (wall_direction == 1 and horiz_direction < 0):
		# Detach by pressing away from the wall
		_change_state(State.NORMAL)
		
	# Update facing direction towards the wall for climbing attacks
	facing_direction = wall_direction
	_trigger_mutations()
		
	move_and_slide()
