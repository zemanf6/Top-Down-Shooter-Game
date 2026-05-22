extends Node2D

const FLOOR_TEXTURE: Texture2D = preload("res://assets/textures/floor_tile.png")

var scanline_offset: float = 0.0
var pulse: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = -100

	var background: CanvasItem = get_node_or_null("Background") as CanvasItem

	if background != null:
		background.visible = false

	queue_redraw()


func _process(delta: float) -> void:
	scanline_offset = fmod(scanline_offset + delta * 22.0, 8.0)
	pulse += delta
	queue_redraw()


func _draw() -> void:
	var arena_rect := Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	draw_rect(arena_rect, Color(0.025, 0.034, 0.047))

	if FLOOR_TEXTURE != null:
		for y in range(0, 720, 64):
			for x in range(0, 1280, 64):
				draw_texture_rect(FLOOR_TEXTURE, Rect2(float(x), float(y), 64.0, 64.0), false, Color(0.72, 0.83, 0.90, 1.0))

	_draw_grid()
	_draw_decorative_circuits()
	_draw_border_glow()
	_draw_scanlines()


func _draw_grid() -> void:
	for x in range(0, 1281, 64):
		var color := Color(0.12, 0.26, 0.30, 0.40)

		if x % 256 == 0:
			color = Color(0.20, 0.55, 0.62, 0.62)

		draw_line(Vector2(float(x), 0.0), Vector2(float(x), 720.0), color, 1.0)

	for y in range(0, 721, 64):
		var color := Color(0.12, 0.26, 0.30, 0.40)

		if y % 256 == 0:
			color = Color(0.20, 0.55, 0.62, 0.62)

		draw_line(Vector2(0.0, float(y)), Vector2(1280.0, float(y)), color, 1.0)


func _draw_decorative_circuits() -> void:
	var glow_alpha: float = 0.22 + (sin(pulse * 2.2) * 0.06)
	var circuit_color := Color(0.1, 0.85, 0.90, glow_alpha)
	var warning_color := Color(1.0, 0.34, 0.50, 0.20)

	var points: Array[Vector2] = [
		Vector2(120.0, 126.0), Vector2(250.0, 126.0), Vector2(250.0, 220.0), Vector2(360.0, 220.0),
		Vector2(930.0, 118.0), Vector2(1035.0, 118.0), Vector2(1035.0, 210.0), Vector2(1130.0, 210.0),
		Vector2(145.0, 598.0), Vector2(290.0, 598.0), Vector2(290.0, 515.0), Vector2(380.0, 515.0),
		Vector2(915.0, 605.0), Vector2(1110.0, 605.0), Vector2(1110.0, 515.0), Vector2(1190.0, 515.0)
	]

	for index in range(0, points.size(), 4):
		draw_polyline(PackedVector2Array([points[index], points[index + 1], points[index + 2], points[index + 3]]), circuit_color, 3.0)
		draw_circle(points[index + 3], 5.0, Color(circuit_color.r, circuit_color.g, circuit_color.b, circuit_color.a * 1.7))

	for x in range(96, 1220, 224):
		draw_line(Vector2(float(x), 46.0), Vector2(float(x + 70), 46.0), warning_color, 4.0)
		draw_line(Vector2(float(x), 674.0), Vector2(float(x + 70), 674.0), warning_color, 4.0)


func _draw_border_glow() -> void:
	var outer := Rect2(Vector2(20.0, 20.0), Vector2(1240.0, 680.0))
	var inner := Rect2(Vector2(36.0, 36.0), Vector2(1208.0, 648.0))
	draw_rect(outer, Color(0.0, 0.0, 0.0, 0.0), false, 8.0)
	draw_rect(inner, Color(0.05, 0.90, 1.0, 0.28), false, 2.0)
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(1280.0, 40.0)), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(Vector2(0.0, 680.0), Vector2(1280.0, 40.0)), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(40.0, 720.0)), Color(0.0, 0.0, 0.0, 0.28))
	draw_rect(Rect2(Vector2(1240.0, 0.0), Vector2(40.0, 720.0)), Color(0.0, 0.0, 0.0, 0.28))


func _draw_scanlines() -> void:
	for y in range(-8, 728, 8):
		var line_y: float = float(y) + scanline_offset
		draw_line(Vector2(0.0, line_y), Vector2(1280.0, line_y), Color(0.0, 0.0, 0.0, 0.10), 1.0)
