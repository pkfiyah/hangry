extends Control
class_name LevelUpMenu

signal upgrade_selected(upgrade_data: Dictionary)

@onready var button_container: HBoxContainer = $Panel/VBoxContainer/HBoxContainer
var upgrade_button_scene = preload("res://ui/upgrade_button.tscn")

# Disconnect old signals so we don't double fire when re-opening
var current_options: Array[Dictionary] = []

func _ready() -> void:
	# Hide by default
	hide()
	# Ensure the menu can still function while the game tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func display_options(options: Array[Dictionary]) -> void:
	current_options = options
	
	# Clear out old buttons
	for child in button_container.get_children():
		child.queue_free()
		
	# Create new buttons for each option
	for i in range(options.size()):
		var option = options[i]
		var btn = upgrade_button_scene.instantiate()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Format text: e.g., "Nuclear Glow (Lv 1)\nDamage: 10 -> 15"
		var btn_text = option.mutation_name
		if option.is_new:
			btn_text += " (New!)\n"
		else:
			btn_text += " (Lv " + str(option.next_level) + ")\n"
			
		btn_text += option.description
		
		var desc_label = btn.get_node("HBoxContainer/DescriptionLabel")
		if desc_label:
			desc_label.text = btn_text
			
		var stats: MutationStats = option.get("stats")
		var bg_rect = btn.get_node("HBoxContainer/IconBackground")
		if bg_rect:
			if stats:
				bg_rect.color = stats.icon_bg_color
			else:
				bg_rect.color = Color.WHITE
				
		var tex_rect = btn.get_node("HBoxContainer/IconBackground/IconTexture")
		if tex_rect:
			if stats and stats.mutation_icon:
				tex_rect.texture = stats.mutation_icon
			else:
				tex_rect.texture = null
		
		var actual_button = btn.get_node_or_null("Button")
		if actual_button:
			actual_button.pressed.connect(_on_button_pressed.bind(option))
		else:
			push_warning("UpgradeButton scene is missing its Button node!")
			
		button_container.add_child(btn)

	show()
	get_tree().paused = true

func _on_button_pressed(option_data: Dictionary) -> void:
	hide()
	get_tree().paused = false
	upgrade_selected.emit(option_data)
