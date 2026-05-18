extends Node2D
class_name EnemySpawner

@export_category("Enemy Pools")
## Add your ground-based enemy scenes here (e.g. Tupis, Tacoza)
@export var ground_enemies: Array[PackedScene] = []
## Add your aerial enemy scenes here (e.g. Helo)
@export var aerial_enemies: Array[PackedScene] = []

@export_category("Spawn Settings")
@export var aerial_spawn_height_threshold: float = -400.0
@export var min_spawn_time: float = 3.0
@export var max_spawn_time: float = 6.0
@export var target: Node2D

var enemy_spawn_timer: float = 3.0

func _ready() -> void:
	enemy_spawn_timer = randf_range(min_spawn_time, max_spawn_time)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
		
	if ground_enemies.size() > 0 or aerial_enemies.size() > 0:
		enemy_spawn_timer -= delta
		if enemy_spawn_timer <= 0.0:
			spawn_enemy()
			enemy_spawn_timer = randf_range(min_spawn_time, max_spawn_time)

func spawn_enemy() -> void:
	var use_aerial = false
	if aerial_enemies.size() > 0 and target.global_position.y < aerial_spawn_height_threshold:
		use_aerial = true
		
	var pool = aerial_enemies if use_aerial else ground_enemies
	if pool.is_empty(): 
		# Fallback if a pool is empty
		pool = ground_enemies if use_aerial else aerial_enemies
		if pool.is_empty(): return
	
	var random_scene = pool.pick_random()
	if not random_scene:
		return
		
	var enemy = random_scene.instantiate()
	# Spawn either far left (-1) or far right (1)
	var spawn_dir = 1 if randf() > 0.5 else -1
	# Spawn 800 pixels away from the player (off screen)
	var spawn_x = target.global_position.x + (spawn_dir * 800)
	
	var spawn_y = -100
	if use_aerial:
		# Aerials spawn around the player's height (offset slightly)
		spawn_y = target.global_position.y - randf_range(50, 150)
	
	enemy.global_position = Vector2(spawn_x, spawn_y)
	# The enemy should move towards the player
	if "direction" in enemy:
		enemy.direction = -spawn_dir
	add_child(enemy)
