extends StaticBody2D
class_name BuildingBlock

var grid_position: Vector2i
var health: int = 100

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

func destroy() -> void:
	# The building generator will listen to this or we can emit a signal
	# For now, we'll just queue_free. Phase 3 of the plan will expand this
	# to notify the generator to update neighbors and spawn debris.
	queue_free()
