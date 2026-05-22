extends Label

var age: float = 0.0
var lifetime: float = 0.78
var velocity: Vector2 = Vector2(0.0, -42.0)
var base_color: Color = Color.WHITE


func setup(message: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	text = message
	global_position = world_position + Vector2(-34.0, -26.0)
	base_color = color
	modulate = base_color


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 100
	custom_minimum_size = Vector2(90.0, 32.0)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)


func _process(delta: float) -> void:
	age += delta

	if age >= lifetime:
		queue_free()
		return

	global_position += velocity * delta
	var fade: float = clampf(1.0 - (age / lifetime), 0.0, 1.0)
	modulate = Color(base_color.r, base_color.g, base_color.b, fade)
