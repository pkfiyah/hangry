extends StaticBody2D

@onready var color_rect = $ColorRect
@onready var collision_shape = $CollisionShape2D

var max_health: int = 100
var current_health: int = 100
var base_color: Color

func _ready():
	randomize_building()

func randomize_building():
	# Pick a random size for the building
	var b_width = randf_range(90.0, 180.0)
	var b_height = randf_range(180.0, 300.0)
	
	# Update ColorRect visually
	color_rect.custom_minimum_size = Vector2(b_width, b_height)
	color_rect.size = Vector2(b_width, b_height)
	
	# Position the ColorRect so its bottom-center is at (0, 0)
	color_rect.position = Vector2(-b_width / 2.0, -b_height)
	
	# Update CollisionShape size
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(b_width, b_height)
	collision_shape.shape = rect_shape
	
	# Position the CollisionShape so its bottom-center is also at (0, 0)
	collision_shape.position = Vector2(0, -b_height / 2.0)
	
	# Give the building a random grey/concrete color
	var shade = randf_range(0.3, 0.7)
	base_color = Color(shade, shade, shade, 1.0)
	color_rect.color = base_color
	
	# Add a roof for the player to stand on
	var roof_body = StaticBody2D.new()
	roof_body.collision_layer = 1 # World layer
	roof_body.collision_mask = 0
	
	var roof_shape = CollisionShape2D.new()
	var roof_rect = RectangleShape2D.new()
	roof_rect.size = Vector2(b_width, 10)
	roof_shape.shape = roof_rect
	roof_shape.one_way_collision = true
	roof_shape.position = Vector2(0, -b_height + 5) # Top of the building
	
	roof_body.add_child(roof_shape)
	add_child(roof_body)

func take_damage(amount: int):
	current_health -= amount
	
	var health_ratio = float(current_health) / float(max_health)
	
	# Darken/redden color based on health
	color_rect.color = base_color.lerp(Color.DARK_RED, 1.0 - health_ratio)
	
	if current_health <= 0:
		spawn_destruction_effect()
		queue_free()

func spawn_destruction_effect():
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 0.6
	particles.direction = Vector2(0, -1)
	particles.spread = 90.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 300.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 15.0
	particles.color = base_color
	
	# Position the explosion at the center of the building
	particles.global_position = global_position + Vector2(0, -color_rect.size.y / 2.0)
	
	# Add to the main scene so it survives the building being freed
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# Clean up particles after they finish
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
