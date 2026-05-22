extends CanvasLayer
class_name UpgradeSelection

signal upgrade_selected(choice: Resource)

var background: ColorRect
var center_container: CenterContainer
var panel: PanelContainer
var menu_box: VBoxContainer
var title_label: Label
var buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	hide_selection()


func _create_ui() -> void:
	background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.78)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(background)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(background)

	center_container = CenterContainer.new()
	center_container.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center_container)
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(center_container)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(740.0, 430.0)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center_container.add_child(panel)

	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 14)
	menu_box.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(menu_box)

	title_label = Label.new()
	title_label.text = "Vyber upgrade"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color(0.86, 0.98, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_label.custom_minimum_size = Vector2(700.0, 64.0)
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_box.add_child(title_label)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.027, 0.040, 0.94)
	style.border_color = Color(0.20, 0.85, 1.0, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style


func show_choices(choices: Array[Resource]) -> void:
	_clear_buttons()

	for choice in choices:
		var button: Button = _create_choice_button(choice)
		buttons.append(button)
		menu_box.add_child(button)

	visible = true


func hide_selection() -> void:
	visible = false
	_clear_buttons()


func _create_choice_button(choice: Resource) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(700.0, 86.0)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.text = _get_choice_text(choice)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER

	if choice is PlayerInfusion:
		_apply_infusion_button_style(button)
	else:
		_apply_regular_button_style(button)

	button.mouse_entered.connect(_on_button_hovered)
	button.pressed.connect(_on_choice_button_pressed.bind(choice))
	return button


func _get_choice_text(choice: Resource) -> String:
	if choice is PlayerInfusion:
		var infusion: PlayerInfusion = choice as PlayerInfusion
		return "★ INFUZE: %s ★\n%s" % [
			infusion.title,
			infusion.description
		]

	if choice is PlayerUpgrade:
		var upgrade: PlayerUpgrade = choice as PlayerUpgrade
		return "%s\n%s" % [
			upgrade.title,
			upgrade.description
		]

	return "Neznámá volba"


func _apply_regular_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.04, 0.11, 0.15, 0.95), Color(0.20, 0.80, 1.0, 0.75), 1))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.06, 0.18, 0.23, 0.98), Color(0.30, 0.96, 1.0, 1.0), 2))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.17, 0.80, 1.0, 0.95), Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _apply_infusion_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.28))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.65))
	button.add_theme_color_override("font_pressed_color", Color(0.15, 0.08, 0.02))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.22, 0.10, 0.02, 0.96), Color(1.0, 0.70, 0.18, 0.88), 2))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.32, 0.16, 0.04, 0.98), Color(1.0, 0.92, 0.35, 1.0), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(1.0, 0.72, 0.14, 0.95), Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	return style


func _clear_buttons() -> void:
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()

	buttons.clear()


func _reset_offsets(control: Control) -> void:
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _on_button_hovered() -> void:
	AudioDirector.play_sfx("ui_hover", -13.0, 0.02)


func _on_choice_button_pressed(choice: Resource) -> void:
	upgrade_selected.emit(choice)
