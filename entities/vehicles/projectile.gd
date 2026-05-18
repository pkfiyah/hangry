extends Area2D
class_name Projectile

@export var speed: float = 300.0
@export var damage: int = 15
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Destroy the projectile after lifetime expires
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	
	body_entered.connect(_on_body_entered)
	
	# Ensure the Area2D only collides with the player (assuming player is on collision layer 2 or we just check groups)
	# For safety, just checking group in body_entered is fine, but setting masks is better.
	collision_mask = 2 # Assuming layer 2 is player
	collision_layer = 0 # It doesn't need to be on any layer itself

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _draw() -> void:
	# Simple circle debug shape
	draw_circle(Vector2.ZERO, 6.0, Color.RED)
	draw_circle(Vector2.ZERO, 4.0, Color.YELLOW)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
