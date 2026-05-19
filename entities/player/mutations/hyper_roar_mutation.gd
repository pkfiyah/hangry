class_name HyperRoarMutation extends Mutation

@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	super._ready()
	# The mutation should be added as a child of the Kaiju, so it moves with it.
	# The actual Area2D needs to be a child of this node in the scene.

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_instance_valid(owner_entity) and is_instance_valid(attack_area):
		var facing = 1
		if "facing_direction" in owner_entity:
			facing = owner_entity.facing_direction
			
		# Continuously update position so Godot's physics engine has the correct
		# overlaps calculated before execute() is ever called.
		attack_area.position.x = facing * 40
		attack_area.position.y = -50

func execute() -> void:
	if not is_instance_valid(owner_entity) or not is_instance_valid(attack_area) or stats == null:
		return
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return
		
	# Visual feedback
	var roar = ColorRect.new()
	roar.color = Color.RED
	roar.size = Vector2(80, 100)
	roar.position = Vector2(-40, -50)
	attack_area.add_child(roar)
	
	var tween = create_tween()
	tween.tween_property(roar, "modulate:a", 0.0, 0.2)
	tween.tween_callback(roar.queue_free)

	# Apply damage
	var damage_amount = level_data.damage
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
