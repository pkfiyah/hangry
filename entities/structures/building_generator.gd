extends Node2D
class_name BuildingGenerator

@export var tile_map_layer: TileMapLayer
@export var building_block_scene: PackedScene

# Stores instances of BuildingBlocks. Key: Vector2 (grid coordinates), Value: BuildingBlock
var blocks: Dictionary = {}

func _ready() -> void:
	if not tile_map_layer or not building_block_scene:
		push_error("BuildingGenerator is missing a TileMapLayer or BuildingBlockScene reference!")
		return
		
	_generate_blocks()
	_initialize_blocks()
	
	# Hide and disable the original tile map so it doesn't render or collide
	tile_map_layer.hide()
	tile_map_layer.process_mode = Node.PROCESS_MODE_DISABLED

func _generate_blocks() -> void:
	var used_cells = tile_map_layer.get_used_cells()
	
	for cell in used_cells:
		var block: BuildingBlock = building_block_scene.instantiate()
		
		# Set logical position data
		block.grid_position = cell
		# Optional: Read custom data from the tile to assign chunk_id or health
		# var tile_data = tile_map_layer.get_cell_tile_data(cell)
		# if tile_data: block.chunk_id = tile_data.get_custom_data("chunk_id")
		
		# Position the block in the world. 
		# map_to_local returns the center of the cell, which matches our block setup
		block.position = tile_map_layer.map_to_local(cell)
		
		# Add to scene tree and dictionary
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
