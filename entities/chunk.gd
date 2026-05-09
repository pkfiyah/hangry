extends Node2D

var building_scene = preload("uid://dgb8vtqwrrfbi")

func _ready():
	# Randomize so each run is different
	randomize()
	
	# Decide how many buildings to spawn in this chunk (1 to 3)
	var num_buildings = randi_range(1, 3)
	
	for i in range(num_buildings):
		var b = building_scene.instantiate()
		
		# Place building randomly along the chunk's width.
		# A chunk is 800 wide. We keep them away from the very edges.
		b.position.x = randf_range(100.0, 540.0)
		b.position.y = 0 # Top of the floor is at y=0
		
		add_child(b)
