extends Control

var stars: Array[Vector2] = []
var time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_create_stars()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_create_stars()


func _create_stars() -> void:
	stars.clear()
	var draw_size: Vector2 = size

	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		draw_size = Vector2(1280.0, 720.0)

	for index in range(90):
		stars.append(Vector2(rng.randf_range(0.0, draw_size.x), rng.randf_range(0.0, draw_size.y)))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var draw_size: Vector2 = size

	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		draw_size = Vector2(1280.0, 720.0)

	_draw_stars(draw_size)
	_draw_perspective_grid(draw_size)
	_draw_scanlines(draw_size)
	_draw_vignette(draw_size)


func _draw_stars(draw_size: Vector2) -> void:
	for index in range(stars.size()):
		var star: Vector2 = stars[index]
		var flicker: float = 0.55 + 0.45 * sin(time * 2.0 + float(index) * 1.73)
		var color := Color(0.55, 0.94, 1.0, 0.20 + flicker * 0.40)
		draw_rect(Rect2(star, Vector2(2.0, 2.0)), color)


func _draw_perspective_grid(draw_size: Vector2) -> void:
	var horizon_y: float = draw_size.y * 0.52
	var bottom_y: float = draw_size.y
	var center_x: float = draw_size.x * 0.5
	var grid_color := Color(0.07, 0.85, 1.0, 0.24)
	var hot_color := Color(1.0, 0.16, 0.46, 0.26)

	for i in range(-14, 15):
		var x: float = center_x + float(i) * 70.0
		draw_line(Vector2(center_x, horizon_y), Vector2(x, bottom_y), grid_color, 1.0)

	for row in range(13):
		var t: float = float(row) / 12.0
		var y: float = lerpf(horizon_y, bottom_y, t * t)
		var color: Color = grid_color

		if row % 3 == 0:
			color = hot_color

		draw_line(Vector2(0.0, y), Vector2(draw_size.x, y), color, 1.0)

	var sun_center := Vector2(center_x, horizon_y - 92.0)
	for radius in [92.0, 72.0, 52.0, 32.0]:
		draw_arc(sun_center, radius, 0.0, TAU, 72, Color(1.0, 0.45, 0.20, 0.12), 3.0)


func _draw_scanlines(draw_size: Vector2) -> void:
	for y in range(0, int(draw_size.y), 6):
		draw_line(Vector2(0.0, float(y)), Vector2(draw_size.x, float(y)), Color(0.0, 0.0, 0.0, 0.10), 1.0)


func _draw_vignette(draw_size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(draw_size.x, 80.0)), Color(0.0, 0.0, 0.0, 0.24))
	draw_rect(Rect2(Vector2(0.0, draw_size.y - 120.0), Vector2(draw_size.x, 120.0)), Color(0.0, 0.0, 0.0, 0.32))
	draw_rect(Rect2(Vector2.ZERO, Vector2(90.0, draw_size.y)), Color(0.0, 0.0, 0.0, 0.18))
	draw_rect(Rect2(Vector2(draw_size.x - 90.0, 0.0), Vector2(90.0, draw_size.y)), Color(0.0, 0.0, 0.0, 0.18))
