extends Node2D
class_name BuildingGenerator

@export var building_block_scene: PackedScene
@export var block_size: int = 16

# Stores instances of BuildingBlocks. Key: Vector2 (grid coordinates), Value: BuildingBlock
var blocks: Dictionary = {}

# Dimensions in blocks
var grid_width: int = 5
var grid_height: int = 10

func setup(width: int, height: int) -> void:
	grid_width = width
	grid_height = height

func _ready() -> void:
	if not building_block_scene:
		push_error("BuildingGenerator is missing a BuildingBlockScene reference!")
		return
		
	_generate_blocks()
	_initialize_blocks()

func _generate_blocks() -> void:
	# Generate a rectangle of blocks based on grid dimensions
	# Y goes up into negative values. Bottom-left is (0, -1) so it sits exactly on Y=0.
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, -(y + 1))
			
			var block: BuildingBlock = building_block_scene.instantiate()
			block.grid_position = cell
			
			# Map to local position (center of the cell)
			block.position = Vector2(cell.x * block_size + (block_size / 2.0), cell.y * block_size + (block_size / 2.0))
			
			add_child(block)
			blocks[cell] = block

func _initialize_blocks() -> void:
	# Now that all blocks exist, calculate their bitmasks and climbable surfaces
	for cell in blocks.keys():
		_update_block_state(cell)

func _update_block_state(cell: Vector2i) -> void:
	if not blocks.has(cell):
		return
		
	var block: BuildingBlock = blocks[cell]
	var bitmask: int = 0
	
	# Check 4 cardinal neighbors (Top=1, Right=2, Bottom=4, Left=8)
	var has_top = blocks.has(cell + Vector2i.UP)
	var has_right = blocks.has(cell + Vector2i.RIGHT)
	var has_bottom = blocks.has(cell + Vector2i.DOWN)
	var has_left = blocks.has(cell + Vector2i.LEFT)
	
	if has_top: bitmask += 1
	if has_right: bitmask += 2
	if has_bottom: bitmask += 4
	if has_left: bitmask += 8
	
	# Update the texture based on neighbors
	block.update_texture(bitmask)
	
	# Empty space means it IS climbable
	block.update_climbable(not has_top, not has_right, not has_bottom, not has_left)

## Call this function when a block is destroyed (Phase 3 functionality)
func remove_block(cell: Vector2i) -> void:
	if blocks.has(cell):
		blocks.erase(cell)
		
		# Update the 4 neighbors so their textures and climb surfaces adapt
		_update_block_state(cell + Vector2i.UP)
		_update_block_state(cell + Vector2i.RIGHT)
		_update_block_state(cell + Vector2i.DOWN)
		_update_block_state(cell + Vector2i.LEFT)
