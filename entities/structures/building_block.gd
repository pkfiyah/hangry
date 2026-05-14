extends StaticBody2D
class_name BuildingBlock

var grid_position: Vector2i
var chunk_id: int
var health: int = 100

@onready var sprite: Sprite2D = $Sprite2D
@onready var top_climb: Area2D = $TopClimbArea
@onready var bottom_climb: Area2D = $BottomClimbArea
@onready var left_climb: Area2D = $LeftClimbArea
@onready var right_climb: Area2D = $RightClimbArea

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
	# Assuming a 16x16 grid on the atlas, where the bitmask value (0-15) 
	# corresponds to a specific tile index.
	# You may need to adjust this math depending on how your atlas is laid out.
	var columns: int = 4
	var row: int = bitmask / columns
	var col: int = bitmask % columns
	
	atlas.region = Rect2(col * 16.0, row * 16.0, 16.0, 16.0)

## Enables or disables climbable areas based on whether adjacent cells are empty
func update_climbable(top_empty: bool, right_empty: bool, bottom_empty: bool, left_empty: bool) -> void:
	# Enable the climb area if the adjacent space is empty
	_set_area_enabled(top_climb, top_empty)
	_set_area_enabled(right_climb, right_empty)
	_set_area_enabled(bottom_climb, bottom_empty)
	_set_area_enabled(left_climb, left_empty)

func _set_area_enabled(area: Area2D, is_enabled: bool) -> void:
	# Deferring this safely handles updates during physics steps
	for child in area.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not is_enabled)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		destroy()

func destroy() -> void:
	# The building generator will listen to this or we can emit a signal
	# For now, we'll just queue_free. Phase 3 of the plan will expand this
	# to notify the generator to update neighbors and spawn debris.
	queue_free()
