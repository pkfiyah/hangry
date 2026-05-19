class_name Mutation extends Node2D

@export var stats: MutationStats
var current_level: int = 1
var current_cooldown: float = 0.0
var owner_entity: Node2D

func _ready() -> void:
	# Search up the tree to find the root entity (CharacterBody2D)
	var p = get_parent()
	while p and not p is CharacterBody2D:
		p = p.get_parent()
	owner_entity = p

func _physics_process(delta: float) -> void:
	if current_cooldown > 0:
		current_cooldown -= delta

func level_up() -> void:
	if stats and current_level < stats.get_max_level():
		current_level += 1

# Called by the owner (e.g., the Kaiju) to attempt firing the mutation.
# Returns true if the mutation actually fired.
func trigger(manual: bool = false) -> bool:
	if stats == null:
		push_warning("Mutation has no stats assigned!")
		return false
		
	var level_data = stats.get_level_data(current_level)
	if level_data == null:
		return false

	if current_cooldown <= 0.0:
		execute()
		current_cooldown = level_data.cooldown
		return true
	return false

# Overridden by child classes to implement the actual attack logic
func execute() -> void:
	push_warning("execute() not implemented in base Mutation class!")
