extends StaticBody2D
class_name BuildingBlock

var grid_position: Vector2i
var max_health: int = 100
var health: int = 100

signal block_destroyed(cell: Vector2i)

@onready var sprite: Sprite2D = $Sprite2D
@onready var top_climb: Area2D = $TopClimbArea
@onready var bottom_climb: Area2D = $BottomClimbArea
@onready var left_climb: Area2D = $LeftClimbArea
@onready var right_climb: Area2D = $RightClimbArea
@onready var platform_collision: CollisionShape2D = $PlatformBody/CollisionShape2D

var climb_top_enabled: bool = false
var climb_right_enabled: bool = false
var climb_bottom_enabled: bool = false
var climb_left_enabled: bool = false

var current_damage_tint: Color = Color.WHITE

var is_falling: bool = false
var fall_velocity: float = 0.0
var gravity: float = 580.0 # Default gravity

const TILE_MAP: Dictionary = {
	0: Vector2(0, 0), # No neighbors (e.g., top-left corner of image)
	1: Vector2(2, 3), # Top neighbor only 
	2: Vector2(1, 2), # Right neighbor only
	3: Vector2(0, 2), # Top & Right neighbors (Bottom-Left edge of building)
	4: Vector2(2, 3), # Bottom Middle
	5: Vector2(0, 1), # 
	6: Vector2(1, 0),  # Top Left Corner
	7: Vector2(1, 2),  # Left Side
	8: Vector2(2, 3),  # Currently Unused
	9: Vector2(3, 3),  # Bottom Right Corner
	10: Vector2(2, 3),  # Currently Unused
	11: Vector2(2, 3), # Bottom Middle
	12: Vector2(3, 0), # Top-Right Corner
	13: Vector2(3, 2), # Right-Side
	14: Vector2(2, 0), # Top Middle
	15: Vector2(0, 0),  # Center / Inside
}

func _ready() -> void:
	set_physics_process(false) # Disable physics process until it needs to fall
	
	# Make sure the texture is an AtlasTexture and is unique to this instance
	# so we don't change the region for every block simultaneously.
	if sprite.texture is AtlasTexture:
		# duplicate(true) ensures we get a unique copy of the resource
		sprite.texture = sprite.texture.duplicate(true)

## Updates the AtlasTexture region based on a 4-way bitmask.
## Bit values: Top=1, Right=2, Bottom=4, Left=8
func update_texture(bitmask: int) -> void:
	if not sprite.texture is AtlasTexture:
		return
		
	var atlas: AtlasTexture = sprite.texture as AtlasTexture
	
	# Fallback to (0,0) if bitmask somehow isn't in the dictionary
	var atlas_coords: Vector2 = TILE_MAP.get(bitmask, Vector2.ZERO) 
	
	# Multiply the column (x) and row (y) by the size of your tiles (16)
	atlas.region = Rect2(atlas_coords.x * 16.0, atlas_coords.y * 16.0, 16.0, 16.0)

## Enables or disables climbable areas based on whether adjacent cells are empty
func update_climbable(top_empty: bool, right_empty: bool, bottom_empty: bool, left_empty: bool) -> void:
	climb_top_enabled = top_empty
	climb_right_enabled = right_empty
	climb_bottom_enabled = bottom_empty
	climb_left_enabled = left_empty

	# Enable the climb area if the adjacent space is empty
	_set_area_enabled(top_climb, top_empty)
	_set_area_enabled(right_climb, right_empty)
	_set_area_enabled(bottom_climb, bottom_empty)
	_set_area_enabled(left_climb, left_empty)
	
	platform_collision.set_deferred("disabled", not top_empty)
	
	queue_redraw()

func _set_area_enabled(area: Area2D, is_enabled: bool) -> void:
	# Deferring this safely handles updates during physics steps
	for child in area.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not is_enabled)

func _draw() -> void:
	# Draw debug visuals for climb areas
	var c = Color(0.0, 1.0, 0.0, 0.4) # Semi-transparent green
	
	if climb_top_enabled:
		draw_rect(Rect2(-8, -10, 16, 2), c)
	if climb_bottom_enabled:
		draw_rect(Rect2(-8, 8, 16, 2), c)
	if climb_left_enabled:
		draw_rect(Rect2(-10, -8, 2, 16), c)
	if climb_right_enabled:
		draw_rect(Rect2(8, -8, 2, 16), c)

func take_damage(amount: int) -> void:
	health -= amount
	
	if health <= 0:
		destroy()
	else:
		_update_damage_visuals()
		
		# Flash white on hit
		if is_instance_valid(sprite):
			sprite.modulate = Color(10, 10, 10, 1)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(sprite):
				sprite.modulate = current_damage_tint

func _update_damage_visuals() -> void:
	var health_percent: float = float(health) / float(max_health)
	# Darken and slightly tint red as health decreases
	var shade: float = lerp(0.3, 1.0, health_percent)
	var red_tint: float = lerp(0.7, 1.0, health_percent)
	
	current_damage_tint = Color(red_tint, shade, shade, 1.0)
	if is_instance_valid(sprite):
		sprite.modulate = current_damage_tint

func destroy() -> void:
	if not is_falling:
		block_destroyed.emit(grid_position)
	queue_free()

func start_falling() -> void:
	is_falling = true
	# Disable climb areas so player doesn't try to grab a falling block
	update_climbable(false, false, false, false)
	# Also disable the static collision so it doesn't get stuck in the air
	# The raycast will handle dynamic collision check
	platform_collision.set_deferred("disabled", true)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_falling:
		return
		
	fall_velocity += gravity * delta
	var move_dist = fall_velocity * delta
	
	var space_state = get_world_2d().direct_space_state
	# Raycast from bottom center of the block downwards
	var query = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 8), global_position + Vector2(0, move_dist + 8.0))
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Align position with surface hit, minus offset
		global_position.y = result.position.y - 8.0

		# If it hits another block or entity, damage it (but exclude the player)
		var collider = result.collider
		if is_instance_valid(collider) and collider.has_method("take_damage") and not collider.is_in_group("player"):
			collider.take_damage(10) # Fall damage

		# Destroy this falling block upon impact
		destroy()
	else:
		global_position.y += move_dist
		
	# Despawn if it falls completely out of bounds
	if global_position.y > 2000.0:
		queue_free()
