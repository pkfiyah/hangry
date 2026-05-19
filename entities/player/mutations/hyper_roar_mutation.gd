class_name HyperRoarMutation extends Mutation

@onready var attack_area: Area2D = $AttackArea

@onready var collision_shape: CollisionShape2D = $AttackArea/CollisionShape2D

func _ready() -> void:
	super._ready()
	_update_area_size()

func level_up() -> void:
	super.level_up()
	_update_area_size()

func _update_area_size() -> void:
	if not is_instance_valid(collision_shape) or stats == null:
		return
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return
		
	# Ensure the shape is unique so scaling it doesn't affect other instances
	if not collision_shape.shape.resource_local_to_scene:
		collision_shape.shape = collision_shape.shape.duplicate()
		
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = Vector2(level_data.radius, level_data.radius)
	elif collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = level_data.radius / 2.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_instance_valid(owner_entity) and is_instance_valid(attack_area):
		var facing = 1
		if "facing_direction" in owner_entity:
			facing = owner_entity.facing_direction
			
		# Continuously update position so Godot's physics engine has the correct
		# overlaps calculated before execute() is ever called.
		var size_mod = stats.get_level_data(current_level).radius/2
		attack_area.position.x = facing * size_mod
		attack_area.position.y = -size_mod

func execute() -> void:
	if not is_instance_valid(owner_entity) or not is_instance_valid(attack_area) or stats == null:
		return
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return
		
	# Prototype Visual feedback
	var roar = ColorRect.new()
	roar.color = Color.RED
	roar.size = Vector2(level_data.radius, level_data.radius)
	roar.position = Vector2(-level_data.radius/2, -level_data.radius/2)
	attack_area.add_child(roar)
	
	var tween = create_tween()
	tween.tween_property(roar, "modulate:a", 0.0, 0.2)
	tween.tween_callback(roar.queue_free)

	# Adjust size and position based on level

	# Apply damage
	var damage_amount = level_data.damage
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
