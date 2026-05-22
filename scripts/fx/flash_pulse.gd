extends Node2D

var age: float = 0.0
var lifetime: float = 0.14
var base_color: Color = Color(1.0, 0.78, 0.25)
var radius: float = 22.0
var line_length: float = 32.0


func setup(
	world_position: Vector2,
	world_rotation: float,
	color: Color = Color(1.0, 0.78, 0.25),
	flash_radius: float = 22.0,
	duration: float = 0.14
) -> void:
	global_position = world_position
	rotation = world_rotation
	base_color = color
	radius = flash_radius
	line_length = flash_radius * 1.45
	lifetime = duration


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 80


func _process(delta: float) -> void:
	age += delta

	if age >= lifetime:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(1.0 - (age / lifetime), 0.0, 1.0)
	var color: Color = base_color
	color.a *= fade

	draw_circle(Vector2.ZERO, radius * (1.0 + age * 3.0), Color(color.r, color.g, color.b, color.a * 0.22))
	draw_line(Vector2.ZERO, Vector2(line_length, 0.0), color, 4.0)
	draw_line(Vector2(6.0, -6.0), Vector2(line_length * 0.72, -13.0), Color(color.r, color.g, color.b, color.a * 0.75), 2.0)
	draw_line(Vector2(6.0, 6.0), Vector2(line_length * 0.72, 13.0), Color(color.r, color.g, color.b, color.a * 0.75), 2.0)
