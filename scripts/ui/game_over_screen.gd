extends CanvasLayer
class_name GameOverScreen

signal restart_requested
signal main_menu_requested

@onready var background: ColorRect = $Background
@onready var title_label: Label = $TitleLabel
@onready var score_label: Label = $ScoreLabel
@onready var restart_button: Button = $RestartButton
@onready var main_menu_button: Button = $MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS

	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	restart_button.mouse_entered.connect(_on_button_hovered)
	main_menu_button.mouse_entered.connect(_on_button_hovered)

	_apply_layout()
	visible = false


func _apply_layout() -> void:
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(background)
	background.color = Color(0.0, 0.0, 0.0, 0.86)

	title_label.position = Vector2(0.0, 92.0)
	title_label.size = Vector2(1280.0, 90.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.45))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.90))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.text = "SIGNÁL ZTRACEN"

	score_label.position = Vector2(0.0, 200.0)
	score_label.size = Vector2(1280.0, 120.0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0))
	score_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	score_label.add_theme_constant_override("shadow_offset_x", 3)
	score_label.add_theme_constant_override("shadow_offset_y", 3)

	restart_button.position = Vector2(520.0, 350.0)
	restart_button.size = Vector2(240.0, 58.0)
	restart_button.text = "Restart"
	_style_button(restart_button, Color(0.04, 0.22, 0.28, 0.96), Color(0.22, 0.92, 1.0, 1.0))

	main_menu_button.position = Vector2(520.0, 428.0)
	main_menu_button.size = Vector2(240.0, 58.0)
	main_menu_button.text = "Hlavní menu"
	_style_button(main_menu_button, Color(0.18, 0.07, 0.12, 0.96), Color(1.0, 0.30, 0.55, 1.0))


func _style_button(button: Button, normal_color: Color, border_color: Color) -> void:
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.10))
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color, border_color, 2))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.15), border_color.lightened(0.10), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(border_color, Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	return style


func _reset_offsets(control: Control) -> void:
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func show_game_over(score: int, best_score: int, is_new_best_score: bool) -> void:
	if is_new_best_score:
		score_label.text = "Skóre: %d\nNové nejlepší skóre!" % score
	else:
		score_label.text = "Skóre: %d\nNejlepší skóre: %d" % [score, best_score]

	AudioDirector.play_sfx("player_hit", -2.0, 0.0)
	visible = true


func _on_button_hovered() -> void:
	AudioDirector.play_sfx("ui_hover", -13.0, 0.02)


func _on_restart_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -8.0, 0.02)
	restart_requested.emit()


func _on_main_menu_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -8.0, 0.02)
	main_menu_requested.emit()
