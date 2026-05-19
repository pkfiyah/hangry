class_name NuclearGlowMutation extends Mutation

@onready var glow_area: Area2D = $GlowArea
@onready var glow_visual: ColorRect = $GlowArea/GlowVisual

func _ready() -> void:
	super._ready()
	# Ensure the glow visual is invisible initially or has some base transparency
	if is_instance_valid(glow_visual):
		glow_visual.modulate.a = 0.3
		
	# The scale/radius needs to be updated when we level up, 
	# but we can do it in _physics_process or via a level_up signal later.
	_update_radius()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if not is_instance_valid(glow_area):
		return
		
	# Follow the center of the entity. Since it's a child of the mutation,
	# and the mutation is a child of the Kaiju, it will naturally follow.
	# But we'll ensure its local position is 0,0 relative to the mutation.
	glow_area.position = Vector2.ZERO

func _update_radius() -> void:
	if stats == null or not is_instance_valid(glow_area):
		return
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return
		
	var r = level_data.radius
	
	# Try to find a CollisionShape2D or CollisionPolygon2D
	for child in glow_area.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			child.shape.radius = r
			
	if is_instance_valid(glow_visual):
		glow_visual.size = Vector2(r * 2, r * 2)
		glow_visual.position = Vector2(-r, -r)
		glow_visual.pivot_offset = Vector2(r, r)

# Called when current_level changes
func level_up() -> void:
	super.level_up()
	_update_radius()

func execute() -> void:
	if not is_instance_valid(owner_entity) or not is_instance_valid(glow_area) or stats == null:
		return
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return
		
	var damage_amount = level_data.damage
	
	# Visual pulse effect
	if is_instance_valid(glow_visual):
		var tween = create_tween()
		tween.tween_property(glow_visual, "modulate:a", 0.8, 0.1)
		tween.tween_property(glow_visual, "modulate:a", 0.3, 0.2)
	
	# Apply damage to overlapping bodies
	var bodies = glow_area.get_overlapping_bodies()
	for body in bodies:
		# Don't hurt ourselves
		if body == owner_entity:
			continue
			
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
