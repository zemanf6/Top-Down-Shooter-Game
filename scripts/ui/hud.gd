extends CanvasLayer
class_name Hud

@onready var health_label: Label = $HealthLabel
@onready var score_label: Label = $ScoreLabel
@onready var wave_label: Label = $WaveLabel

var panel_background: ColorRect
var health_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var xp_label: Label
var combo_label: Label
var message_label: Label
var message_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_style_existing_labels()
	_create_optional_labels()


func _style_existing_labels() -> void:
	for label in [health_label, score_label, wave_label]:
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.z_index = 12

	health_label.position = Vector2(26.0, 24.0)
	score_label.position = Vector2(26.0, 82.0)
	wave_label.position = Vector2(26.0, 116.0)


func _create_optional_labels() -> void:
	panel_background = ColorRect.new()
	panel_background.name = "HudPanel"
	panel_background.position = Vector2(12.0, 12.0)
	panel_background.size = Vector2(322.0, 200.0)
	panel_background.color = Color(0.015, 0.022, 0.032, 0.72)
	panel_background.z_index = 1
	add_child(panel_background)
	move_child(panel_background, 0)

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.position = Vector2(26.0, 52.0)
	health_bar.size = Vector2(284.0, 16.0)
	health_bar.show_percentage = false
	health_bar.z_index = 11
	_apply_bar_style(health_bar, Color(0.18, 1.0, 0.35, 0.92), Color(0.05, 0.10, 0.08, 0.95))
	add_child(health_bar)

	level_label = Label.new()
	level_label.position = Vector2(26.0, 150.0)
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	level_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80))
	level_label.add_theme_constant_override("shadow_offset_x", 2)
	level_label.add_theme_constant_override("shadow_offset_y", 2)
	level_label.z_index = 12
	add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.name = "XpBar"
	xp_bar.position = Vector2(26.0, 178.0)
	xp_bar.size = Vector2(284.0, 14.0)
	xp_bar.show_percentage = false
	xp_bar.z_index = 11
	_apply_bar_style(xp_bar, Color(0.20, 0.82, 1.0, 0.92), Color(0.04, 0.06, 0.10, 0.95))
	add_child(xp_bar)

	xp_label = Label.new()
	xp_label.position = Vector2(198.0, 146.0)
	xp_label.size = Vector2(120.0, 28.0)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_label.add_theme_font_size_override("font_size", 18)
	xp_label.add_theme_color_override("font_color", Color(0.72, 0.93, 1.0))
	xp_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80))
	xp_label.add_theme_constant_override("shadow_offset_x", 2)
	xp_label.add_theme_constant_override("shadow_offset_y", 2)
	xp_label.z_index = 12
	add_child(xp_label)

	combo_label = Label.new()
	combo_label.position = Vector2(390.0, 28.0)
	combo_label.size = Vector2(500.0, 38.0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.58, 0.18))
	combo_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	combo_label.add_theme_constant_override("shadow_offset_x", 2)
	combo_label.add_theme_constant_override("shadow_offset_y", 2)
	combo_label.visible = false
	combo_label.z_index = 20
	add_child(combo_label)

	message_label = Label.new()
	message_label.position = Vector2(240.0, 90.0)
	message_label.size = Vector2(800.0, 74.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0))
	message_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	message_label.add_theme_constant_override("shadow_offset_x", 3)
	message_label.add_theme_constant_override("shadow_offset_y", 3)
	message_label.visible = false
	message_label.process_mode = Node.PROCESS_MODE_ALWAYS
	message_label.z_index = 30
	add_child(message_label)

	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.wait_time = 2.4
	message_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	message_timer.timeout.connect(_on_message_timer_timeout)
	add_child(message_timer)

	update_level_and_xp(1, 0, 1)
	update_combo(0, 1.0, 0.0)


func _apply_bar_style(bar: ProgressBar, fill_color: Color, background_color: Color) -> void:
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = background_color
	background_style.border_color = Color(0.33, 0.85, 1.0, 0.45)
	background_style.set_border_width_all(1)
	background_style.set_corner_radius_all(3)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(3)

	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)


func update_health(current_health: int, max_health: int) -> void:
	health_label.text = "Životy: %d / %d" % [current_health, max_health]

	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health


func update_score(score: int) -> void:
	score_label.text = "Skóre: %d" % score


func update_wave(wave_number: int) -> void:
	wave_label.text = "Vlna: %d" % wave_number


func update_level_and_xp(level: int, current_xp: int, required_xp: int) -> void:
	if level_label == null or xp_label == null:
		return

	level_label.text = "Level: %d" % level
	xp_label.text = "XP %d/%d" % [current_xp, required_xp]

	if xp_bar != null:
		xp_bar.max_value = max(1, required_xp)
		xp_bar.value = current_xp


func update_combo(kill_streak: int, multiplier: float, seconds_left: float) -> void:
	if combo_label == null:
		return

	if kill_streak < 2 or seconds_left <= 0.0:
		combo_label.visible = false
		return

	combo_label.visible = true
	combo_label.text = "KOMBO %d  ×%.2f" % [kill_streak, multiplier]


func show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = true
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.visible = false
