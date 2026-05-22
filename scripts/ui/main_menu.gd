extends Control
class_name MainMenu

const RetroBackgroundFxScript: Script = preload("res://scripts/ui/retro_background_fx.gd")
const LOGO_TEXTURE: Texture2D = preload("res://assets/textures/reticle_logo.png")

@export var game_scene_path: String = "res://scenes/game/Game.tscn"

@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $CenterContainer
@onready var menu_box: VBoxContainer = $CenterContainer/MenuBox
@onready var title_label: Label = $CenterContainer/MenuBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/MenuBox/SubtitleLabel
@onready var start_button: Button = $CenterContainer/MenuBox/StartButton
@onready var quit_button: Button = $CenterContainer/MenuBox/QuitButton

var background_fx: Control
var logo: TextureRect


func _ready() -> void:
	get_tree().paused = false
	AudioDirector.play_menu_music()

	_apply_layout()
	_apply_content()
	_connect_signals()


func _apply_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(self)

	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(background)
	background.color = Color(0.015, 0.020, 0.035)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_background_fx()

	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(center_container)

	menu_box.custom_minimum_size = Vector2(620.0, 430.0)
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.add_theme_constant_override("separation", 16)

	_create_logo()

	_style_label(title_label, 54, Color(0.78, 0.98, 1.0))
	title_label.custom_minimum_size = Vector2(620.0, 72.0)

	_style_label(subtitle_label, 22, Color(1.0, 0.70, 0.30))
	subtitle_label.custom_minimum_size = Vector2(620.0, 58.0)

	start_button.custom_minimum_size = Vector2(320.0, 58.0)
	quit_button.custom_minimum_size = Vector2(320.0, 58.0)

	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	_style_button(start_button, Color(0.05, 0.30, 0.37, 0.95), Color(0.20, 0.95, 1.0, 1.0))
	_style_button(quit_button, Color(0.18, 0.08, 0.13, 0.95), Color(1.0, 0.28, 0.52, 1.0))


func _create_background_fx() -> void:
	if background_fx != null:
		return

	background_fx = RetroBackgroundFxScript.new() as Control
	background_fx.name = "RetroBackgroundFX"
	background_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reset_offsets(background_fx)
	add_child(background_fx)
	move_child(background_fx, 1)


func _create_logo() -> void:
	if logo != null:
		return

	logo = TextureRect.new()
	logo.name = "ReticleLogo"
	logo.texture = LOGO_TEXTURE
	logo.custom_minimum_size = Vector2(128.0, 128.0)
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_box.add_child(logo)
	menu_box.move_child(logo, 0)


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)


func _style_button(button: Button, normal_color: Color, border_color: Color) -> void:
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.12))
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color, border_color, 2))
	button.add_theme_stylebox_override("hover", _make_button_style(normal_color.lightened(0.14), border_color.lightened(0.12), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(border_color, Color.WHITE, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style


func _apply_content() -> void:
	title_label.text = "NEON GRID: EXTERMINATOR"
	subtitle_label.text = "Retro aréna • WASD + myš • Mezerník = dash"

	start_button.text = "SPUSTIT MISI"
	quit_button.text = "KONEC"


func _connect_signals() -> void:
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	if not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)

	if not start_button.mouse_entered.is_connected(_on_button_hovered):
		start_button.mouse_entered.connect(_on_button_hovered)

	if not quit_button.mouse_entered.is_connected(_on_button_hovered):
		quit_button.mouse_entered.connect(_on_button_hovered)


func _reset_offsets(control: Control) -> void:
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _on_button_hovered() -> void:
	AudioDirector.play_sfx("ui_hover", -13.0, 0.02)


func _on_start_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -8.0, 0.02)
	var error: Error = get_tree().change_scene_to_file(game_scene_path)

	if error != OK:
		push_error("Could not load game scene: %s" % game_scene_path)


func _on_quit_button_pressed() -> void:
	AudioDirector.play_sfx("ui_select", -8.0, 0.02)
	get_tree().quit()
