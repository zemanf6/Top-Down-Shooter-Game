extends CanvasLayer
class_name PauseMenu

signal resume_requested
signal restart_requested
signal main_menu_requested

var background: ColorRect
var center_container: CenterContainer
var menu_box: VBoxContainer
var title_label: Label
var score_label: Label
var upgrades_label: Label
var resume_button: Button
var restart_button: Button
var main_menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	_connect_signals()
	hide_pause()


func _create_ui() -> void:
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.0, 0.0, 0.0, 0.76)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(background)

	center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center_container)
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(center_container)

	menu_box = VBoxContainer.new()
	menu_box.name = "MenuBox"
	menu_box.custom_minimum_size = Vector2(600.0, 635.0)
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.add_theme_constant_override("separation", 14)
	menu_box.process_mode = Node.PROCESS_MODE_ALWAYS
	center_container.add_child(menu_box)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "PAUZA"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(600.0, 58.0)
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_label(title_label, 44, Color(0.85, 0.98, 1.0))
	menu_box.add_child(title_label)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = ""
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.custom_minimum_size = Vector2(600.0, 62.0)
	score_label.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_label(score_label, 22, Color(1.0, 0.78, 0.30))
	menu_box.add_child(score_label)

	upgrades_label = Label.new()
	upgrades_label.name = "UpgradesLabel"
	upgrades_label.text = ""
	upgrades_label.custom_minimum_size = Vector2(600.0, 275.0)
	upgrades_label.process_mode = Node.PROCESS_MODE_ALWAYS
	_style_label(upgrades_label, 18, Color(0.78, 0.90, 0.95))
	menu_box.add_child(upgrades_label)

	resume_button = _create_button("Pokračovat", Color(0.04, 0.26, 0.31, 0.95), Color(0.26, 0.95, 1.0, 1.0))
	menu_box.add_child(resume_button)

	restart_button = _create_button("Restart", Color(0.20, 0.12, 0.05, 0.95), Color(1.0, 0.72, 0.24, 1.0))
	menu_box.add_child(restart_button)

	main_menu_button = _create_button("Hlavní menu", Color(0.18, 0.07, 0.13, 0.95), Color(1.0, 0.30, 0.55, 1.0))
	menu_box.add_child(main_menu_button)


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _create_button(text_value: String, normal_color: Color, border_color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(280.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.10))
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color, border_color, 2))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.15), border_color.lightened(0.10), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(border_color, Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _make_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	return style


func _connect_signals() -> void:
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	resume_button.mouse_entered.connect(_on_button_hovered)
	restart_button.mouse_entered.connect(_on_button_hovered)
	main_menu_button.mouse_entered.connect(_on_button_hovered)


func _reset_offsets(control: Control) -> void:
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func show_pause(
	upgrade_summary_lines: PackedStringArray = PackedStringArray(),
	current_score: int = 0,
	best_score: int = 0
) -> void:
	score_label.text = "Aktuální skóre: %d\nNejlepší skóre: %d" % [
		current_score,
		best_score
	]

	if upgrade_summary_lines.is_empty():
		upgrades_label.text = "Zatím nejsou nasbírané žádné upgrady."
	else:
		upgrades_label.text = "\n".join(upgrade_summary_lines)

	visible = true


func hide_pause() -> void:
	visible = false


func _on_button_hovered() -> void:
	AudioDirector.play_sfx("ui_hover", -13.0, 0.02)


func _on_resume_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -9.0, 0.02)
	resume_requested.emit()


func _on_restart_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -9.0, 0.02)
	restart_requested.emit()


func _on_main_menu_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -9.0, 0.02)
	main_menu_requested.emit()
