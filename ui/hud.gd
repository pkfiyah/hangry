extends CanvasLayer

@onready var health_bar = $HealthBar

func _ready():
	# Find the Kaiju and connect health updates
	var kaiju = get_tree().current_scene.get_node_or_null("Kaiju")
	if kaiju:
		# Set initial health values
		health_bar.max_value = kaiju.max_health
		health_bar.value = kaiju.health
		
		# Connect to a signal (we'll add this to Kaiju in a moment)
		if not kaiju.has_signal("health_changed"):
			kaiju.add_user_signal("health_changed")
		kaiju.connect("health_changed", _on_health_changed)

func _on_health_changed(new_health):
	# Animate the health bar shrinking
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.2)
