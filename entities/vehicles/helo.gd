extends Enemy
class_name HeloEnemy

@export var min_distance_to_player: float = 200.0
@export var float_speed: float = 100.0
@export var vertical_follow_speed: float = 50.0

var target_node: Node2D

func _ready() -> void:
	super._ready() # Call parent setup (stats, hitbox, despawn timer)
	
	# Find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_node = players[0]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_node):
		# Fallback: Just fly straight if no player found
		velocity = Vector2(direction * float_speed, 0)
		move_and_slide()
		if is_instance_valid(visual):
			visual.flip_h = direction < 0
		return
		
	var to_player = target_node.global_position - global_position
	
	# Horizontal movement: Approach if further than min_distance
	var move_x = 0.0
	if abs(to_player.x) > min_distance_to_player:
		move_x = sign(to_player.x) * float_speed
		
	# Vertical movement: Try to stay slightly above the player
	var target_y = target_node.global_position.y - 150.0
	var move_y = 0.0
	if abs(global_position.y - target_y) > 10.0:
		move_y = sign(target_y - global_position.y) * vertical_follow_speed
		
	velocity = Vector2(move_x, move_y)
	move_and_slide()
	
	# Always face the player
	direction = -1 if to_player.x < 0 else 1
	if is_instance_valid(visual):
		visual.flip_h = direction < 0
		
	# (TODO) Shooting logic will go here
