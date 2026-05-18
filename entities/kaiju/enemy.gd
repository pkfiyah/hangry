class_name Enemy extends CharacterBody2D

@export var stats: EnemyStats

var current_health: int
var direction: int = 1 # 1 for right, -1 for left
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var hitbox: Area2D = $Hitbox
@onready var visual: AnimatedSprite2D = $Sprite2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

var despawn_timer: Timer

func _ready() -> void:
	if stats:
		current_health = stats.max_health
	else:
		push_warning("Enemy missing stats resource!")
		current_health = 1 # Fallback
		
	if is_instance_valid(hitbox):
		hitbox.set_collision_mask_value(1, false)
		hitbox.set_collision_mask_value(2, true)
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		
	# Setup despawn timer for off-screen grace period
	despawn_timer = Timer.new()
	despawn_timer.wait_time = 5.0 # Seconds before despawning off-screen
	despawn_timer.one_shot = true
	despawn_timer.timeout.connect(die)
	add_child(despawn_timer)
		
	if is_instance_valid(screen_notifier):
		screen_notifier.screen_exited.connect(_on_screen_exited)
		screen_notifier.screen_entered.connect(_on_screen_entered)

func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Move horizontally
	var current_speed = stats.speed if stats else 150.0
	velocity.x = direction * current_speed

	move_and_slide()
	
	# Flip the sprite to match movement direction
	if is_instance_valid(visual):
		visual.flip_h = direction < 0

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var dmg = stats.damage if stats else 15
		body.take_damage(dmg)

func take_damage(amount: int) -> void:
	current_health -= amount
	
	# Flash effect using modulate so it works on sprites
	if is_instance_valid(visual):
		visual.modulate = Color(10, 10, 10, 1) # Super bright white
	var timer = get_tree().create_timer(0.1)
	await timer.timeout
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		
	if current_health <= 0:
		die(true)

func die(award_exp: bool) -> void:
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.has_method("add_exp") && award_exp:
			var exp_val = stats.exp_reward if stats else 10
			player.add_exp(exp_val)
	queue_free()

func _on_screen_exited() -> void:
	# Start the grace period timer when leaving the screen
	despawn_timer.start()

func _on_screen_entered() -> void:
	# Cancel the despawn if it re-enters the screen
	despawn_timer.stop()
