extends Control
class_name LevelUpMenu

signal upgrade_selected(upgrade_id: String)

@onready var button_container: HBoxContainer = $Panel/VBoxContainer/HBoxContainer

func _ready() -> void:
	# Hide by default
	hide()
	# Ensure the menu can still function while the game tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals for all child buttons dynamically based on their names
	for button in button_container.get_children():
		if button is Button:
			button.pressed.connect(_on_button_pressed.bind(button.name))
			
func display_options() -> void:
	show()
	get_tree().paused = true

func _on_button_pressed(upgrade_name: String) -> void:
	print("Selected Upgrade: ", upgrade_name)
	# TODO: We will add the logic to apply the upgrade in the next phase
	
	hide()
	get_tree().paused = false
	upgrade_selected.emit(upgrade_name)
