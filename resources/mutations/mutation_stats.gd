class_name MutationStats extends Resource

@export var mutation_name: String = "Unknown Mutation"
## Array of level data. Index 0 is Level 1, Index 1 is Level 2, etc.
@export var levels: Array[MutationLevelData] = []

func get_max_level() -> int:
	return levels.size()

func get_level_data(level: int) -> MutationLevelData:
	if levels.is_empty():
		return null
	
	# Ensure the level maps to a valid index (1-based level maps to 0-based index)
	var index: int = clampi(level - 1, 0, levels.size() - 1)
	return levels[index]
