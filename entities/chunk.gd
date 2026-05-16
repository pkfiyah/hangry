extends Node2D

var building_scene = preload("uid://dgb8vtqwrrfbi")

func _ready():
	# Randomize so each run is different
	randomize()
	
	# Decide how many buildings to spawn in this chunk (1 to 3)
	var num_buildings = randi_range(1, 3)
	var spawned_buildings = []
	
	for i in range(num_buildings):
		var b = building_scene.instantiate()
		
		var width_blocks = randi_range(4, 12)
		var height_blocks = randi_range(5, 20)
		var b_width_pixels = width_blocks * 16.0
		
		var valid_position = false
		var pos_x = 0.0
		var max_attempts = 10
		
		for attempt in range(max_attempts):
			# A chunk is 800 wide. We keep them away from the very edges.
			pos_x = randf_range(100.0, 700.0 - b_width_pixels)
			
			var overlap = false
			for other in spawned_buildings:
				var other_x = other["x"]
				var other_w = other["w"]
				var padding = 32.0 # Minimum distance between buildings
				if pos_x < other_x + other_w + padding and pos_x + b_width_pixels + padding > other_x:
					overlap = true
					break
					
			if not overlap:
				valid_position = true
				break
				
		if valid_position:
			# Pass dimensions to BuildingGenerator before adding to tree
			if b.has_method("setup"):
				b.setup(width_blocks, height_blocks)
			
			b.position.x = pos_x
			b.position.y = 0 # Top of the floor is at y=0
			add_child(b)
			spawned_buildings.append({"x": pos_x, "w": b_width_pixels})
		else:
			b.queue_free()
