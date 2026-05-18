extends Enemy
class_name HeloEnemy

@export var min_distance_to_player: float = 120.0
@export var float_speed: float = 100.0
@export var vertical_follow_speed: float = 50.0
@export var max_tilt_angle: float = 15.0 # Degrees to tilt when moving
@export var tilt_speed: float = 5.0 # Degrees to tilt when moving

@export_category("Combat")
@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.5 # Seconds between shots
@export var attack_range: float = 350.0

var target_node: Node2D
var fire_cooldown: float = 0.0

func _ready() -> void:
	super._ready() # Call parent setup (stats, hitbox, despawn timer)
	
	# Find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_node = players[0]

func _physics_process(delta: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= delta

	if not is_instance_valid(target_node):
		# Fallback: Just fly straight if no player found
		velocity = Vector2(direction * float_speed, 0)
		move_and_slide()
		if is_instance_valid(visual):
			visual.flip_h = direction < 0
		return
		
	var to_player = target_node.global_position - global_position
	var distance_to_player = to_player.length()
	
	# Horizontal movement: Approach if further than min_distance, Retreat otherwise
	var move_x = 0.0
	if abs(to_player.x) > min_distance_to_player:
		move_x = sign(to_player.x) * float_speed
	elif abs(to_player.x) < min_distance_to_player - 40.0:
		move_x = -1 * sign(to_player.x) * float_speed;
		
	# Vertical movement: Try to stay slightly above the player
	var target_y = target_node.global_position.y - 80.0
	var move_y = 0.0
	if abs(global_position.y - target_y) > 10.0:
		move_y = sign(target_y - global_position.y) * vertical_follow_speed
		
	velocity = Vector2(move_x, move_y)
	move_and_slide()
	
	# Always face the player
	direction = -1 if to_player.x < 0 else 1
	if is_instance_valid(visual):
		visual.flip_h = direction < 0
		
		# Tilt based on horizontal movement
		var target_rotation = 0.0
		if move_x != 0:
			target_rotation = sign(move_x) * deg_to_rad(max_tilt_angle)
		
		visual.rotation = lerp(visual.rotation, target_rotation, tilt_speed * delta)
		
	# Shooting logic
	if distance_to_player <= attack_range and fire_cooldown <= 0.0:
		shoot(to_player.normalized())

func shoot(shoot_direction: Vector2) -> void:
	if not projectile_scene:
		push_warning("HeloEnemy has no projectile_scene assigned!")
		fire_cooldown = fire_rate # Prevent spamming warnings
		return
		
	fire_cooldown = fire_rate
	
	var proj = projectile_scene.instantiate() as Projectile
	if proj:
		proj.global_position = global_position
		proj.direction = shoot_direction
		if stats:
			proj.damage = stats.damage
		
		# Add projectile to the main scene tree, not as a child of the enemy
		get_tree().current_scene.add_child(proj)
