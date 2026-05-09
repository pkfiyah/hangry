extends CanvasLayer

@onready var health_bar: ProgressBar = $PlayerStats/VBoxContainer/HealthBar
@onready var exp_bar: ProgressBar = $PlayerStats/VBoxContainer/ExpBar

@onready var controls_panel = $ControlsPanel
@onready var controls_button = $ControlsButton

func _ready():
	# Ensure the HUD continues to process input when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	controls_button.pressed.connect(_on_controls_button_pressed)
	
	# Find the Kaiju and connect health updates
	var kaiju = get_tree().current_scene.get_node_or_null("Kaiju")
	if kaiju:
		# Set initial health values
		health_bar.max_value = kaiju.max_health
		health_bar.value = kaiju.health
		
		if not kaiju.has_signal("health_changed"):
			kaiju.add_user_signal("health_changed")
		kaiju.connect("health_changed", _on_health_changed)
		
		if not kaiju.has_signal("exp_changed"):
			kaiju.add_user_signal("exp_changed")
		kaiju.connect("exp_changed", _on_exp_changed)

func _on_health_changed(new_health):
	# Animate the health bar shrinking
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.2)

func _on_exp_changed(new_exp):
	# Animate the health bar shrinking
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", new_exp, 0.2)

func _on_controls_button_pressed():
	toggle_pause()

func toggle_pause():
	controls_panel.visible = not controls_panel.visible
	get_tree().paused = controls_panel.visible

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()
