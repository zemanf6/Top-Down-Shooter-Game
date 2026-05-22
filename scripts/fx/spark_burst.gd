extends Node2D

var sparks: Array[Dictionary] = []
var age: float = 0.0
var lifetime: float = 0.34
var base_color: Color = Color(1.0, 0.8, 0.25)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(
	world_position: Vector2,
	color: Color = Color(1.0, 0.8, 0.25),
	count: int = 12,
	power: float = 180.0,
	duration: float = 0.34
) -> void:
	global_position = world_position
	base_color = color
	lifetime = duration
	rng.randomize()
	sparks.clear()

	for index in range(count):
		var angle: float = rng.randf_range(0.0, TAU)
		var speed: float = rng.randf_range(power * 0.28, power)
		var velocity: Vector2 = Vector2.RIGHT.rotated(angle) * speed
		var length: float = rng.randf_range(4.0, 14.0)
		sparks.append({
			"position": Vector2.ZERO,
			"velocity": velocity,
			"length": length
		})


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 70


func _process(delta: float) -> void:
	age += delta

	if age >= lifetime:
		queue_free()
		return

	for spark in sparks:
		var velocity: Vector2 = spark["velocity"]
		var position: Vector2 = spark["position"]
		velocity *= 0.90
		position += velocity * delta
		spark["velocity"] = velocity
		spark["position"] = position

	queue_redraw()


func _draw() -> void:
	var fade: float = clampf(1.0 - (age / lifetime), 0.0, 1.0)
	var draw_color: Color = base_color
	draw_color.a *= fade

	for spark in sparks:
		var position: Vector2 = spark["position"]
		var velocity: Vector2 = spark["velocity"]
		var length: float = float(spark["length"])
		var tail: Vector2 = position - velocity.normalized() * length
		draw_line(tail, position, draw_color, 2.0)
