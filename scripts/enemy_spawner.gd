extends Node2D
class_name EnemySpawner

@export var aerial_spawn_height_threshold: float = -400.0

var enemy_spawn_timer: float = 3.0
var enemy_scenes: Array[PackedScene] = []
var aerial_enemy_scenes: Array[PackedScene] = []
var target: Node2D

func _ready() -> void:
	# Load available ground enemy scenes
	if ResourceLoader.exists("uid://cqkp8rxqc7tyk"): # tupis
		enemy_scenes.append(load("uid://cqkp8rxqc7tyk"))
	if ResourceLoader.exists("uid://vt6l3144axrt"): # tacoza
		enemy_scenes.append(load("uid://vt6l3144axrt"))
		
	# Try loading the helicopter if the user has created the scene
	var helo_path = "res://entities/vehicles/helo.tscn"
	if ResourceLoader.exists(helo_path):
		aerial_enemy_scenes.append(load(helo_path))

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
		
	if enemy_scenes.size() > 0 or aerial_enemy_scenes.size() > 0:
		enemy_spawn_timer -= delta
		if enemy_spawn_timer <= 0.0:
			spawn_enemy()
			enemy_spawn_timer = randf_range(3.0, 6.0)

func spawn_enemy() -> void:
	var use_aerial = false
	if aerial_enemy_scenes.size() > 0 and target.global_position.y < aerial_spawn_height_threshold:
		use_aerial = true
		
	var pool = aerial_enemy_scenes if use_aerial else enemy_scenes
	if pool.is_empty(): 
		# Fallback if a pool is empty
		pool = enemy_scenes if use_aerial else aerial_enemy_scenes
		if pool.is_empty(): return
	
	var random_scene = pool.pick_random()
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
