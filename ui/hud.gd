extends CanvasLayer

@onready var health_bar: ProgressBar = $PlayerStats/VBoxContainer/HealthBar
@onready var exp_bar: ProgressBar = $PlayerStats/VBoxContainer/ExpBar

@onready var controls_panel = $ControlsPanel
@onready var controls_button = $ControlsButton

@onready var level_up_menu: LevelUpMenu = $LevelUpMenu

@onready var active_mutations_container = $ActiveMutationsContainer
var mutation_icon_scene = preload("res://ui/mutation_hud_icon.tscn")
var mutation_ui_elements: Dictionary = {}

func _ready():
	# Ensure the HUD continues to process input when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	controls_button.pressed.connect(_on_controls_button_pressed)
	
	# Find the Kaiju and connect health updates
	var kaiju = get_tree().current_scene.get_node_or_null("Kaiju")
	if kaiju:
		# Set initial health and exp values
		health_bar.max_value = kaiju.max_health
		health_bar.value = kaiju.health
		
		exp_bar.max_value = kaiju.exp_to_next_level
		exp_bar.value = kaiju.current_exp
		
		if not kaiju.has_signal("health_changed"):
			kaiju.add_user_signal("health_changed")
		kaiju.connect("health_changed", _on_health_changed)
		
		if not kaiju.has_signal("exp_changed"):
			kaiju.add_user_signal("exp_changed")
		kaiju.connect("exp_changed", _on_exp_changed)
		
		if not kaiju.has_signal("level_up"):
			kaiju.add_user_signal("level_up")
		kaiju.connect("level_up", _on_level_up)
		
		if not kaiju.has_signal("mutation_added"):
			kaiju.add_user_signal("mutation_added")
		kaiju.connect("mutation_added", _on_mutation_added)
		
		# Add existing mutations to the HUD
		var mutations_node = kaiju.get_node_or_null("Mutations")
		if mutations_node:
			for child in mutations_node.get_children():
				if child is Mutation:
					_on_mutation_added(child)

func _process(delta: float) -> void:
	# Update cooldown sweeps for all active mutation UI elements
	for mutation in mutation_ui_elements.keys():
		var icon = mutation_ui_elements[mutation]
		if not is_instance_valid(mutation):
			icon.queue_free()
			mutation_ui_elements.erase(mutation)
			continue
			
		var sweep = icon.get_node_or_null("IconBackground/IconTexture/CooldownSweep")
		if sweep and mutation.stats:
			var max_cd = 1.0
			var level_data = mutation.stats.get_level_data(mutation.current_level)
			if level_data:
				max_cd = level_data.cooldown
				
			if max_cd > 0:
				sweep.value = mutation.current_cooldown / max_cd
			else:
				sweep.value = 0.0

func _on_mutation_added(mutation: Mutation) -> void:
	if not active_mutations_container:
		return
		
	var icon = mutation_icon_scene.instantiate()
	active_mutations_container.add_child(icon)
	
	var stats: MutationStats = mutation.stats
	var bg_rect = icon.get_node_or_null("IconBackground")
	var tex_rect = icon.get_node_or_null("IconBackground/IconTexture")
	
	if stats:
		if bg_rect:
			bg_rect.color = stats.icon_bg_color
		if tex_rect and stats.mutation_icon:
			tex_rect.texture = stats.mutation_icon
			
	mutation_ui_elements[mutation] = icon

func _on_health_changed(new_health):
	# Animate the health bar shrinking
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.2)

func _on_exp_changed(new_exp):
	# Animate the exp bar
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", new_exp, 0.2)

func _on_level_up(new_level: int):
	# Scale up the required EXP for the next level
	var kaiju = get_tree().current_scene.get_node_or_null("Kaiju")
	if kaiju:
		exp_bar.max_value = kaiju.exp_to_next_level
		exp_bar.value = 0 # Visual reset

func _on_controls_button_pressed():
	toggle_pause()

func toggle_pause():
	controls_panel.visible = not controls_panel.visible
	get_tree().paused = controls_panel.visible

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()
