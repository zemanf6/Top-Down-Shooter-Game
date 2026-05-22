extends Area2D
class_name Projectile

const PROJECTILE_TEXTURE: Texture2D = preload("res://assets/textures/projectile_player.png")

@export var speed: float = 700.0
@export var damage: int = 1
@export var lifetime: float = 1.4

var direction: Vector2 = Vector2.RIGHT
var remaining_pierces: int = 0
var trail_points: Array[Vector2] = []
var sprite: Sprite2D

@onready var lifetime_timer: Timer = $LifetimeTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	collision_layer = 1 << 3
	collision_mask = (1 << 0) | (1 << 2)

	_create_visuals()
	body_entered.connect(_on_body_entered)

	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.start()


func _create_visuals() -> void:
	sprite = Sprite2D.new()
	sprite.name = "ProjectileSprite"
	sprite.texture = PROJECTILE_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 6
	add_child(sprite)


func _physics_process(delta: float) -> void:
	trail_points.push_front(global_position)

	while trail_points.size() > 6:
		trail_points.pop_back()

	global_position += direction * speed * delta
	queue_redraw()


func setup(spawn_position: Vector2, target_position: Vector2) -> void:
	var raw_direction: Vector2 = target_position - spawn_position

	if raw_direction.length_squared() == 0.0:
		setup_direction(spawn_position, Vector2.RIGHT)
	else:
		setup_direction(spawn_position, raw_direction.normalized())


func setup_direction(spawn_position: Vector2, shot_direction: Vector2) -> void:
	global_position = spawn_position

	if shot_direction.length_squared() == 0.0:
		direction = Vector2.RIGHT
	else:
		direction = shot_direction.normalized()

	rotation = direction.angle()


func _draw() -> void:
	for index in range(trail_points.size()):
		var world_point: Vector2 = trail_points[index]
		var local_point: Vector2 = to_local(world_point)
		var alpha: float = 0.34 * (1.0 - (float(index) / 6.0))
		draw_circle(local_point, 5.0 - float(index) * 0.45, Color(1.0, 0.68, 0.12, alpha))

	if sprite == null or sprite.texture == null:
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.15))
		draw_line(Vector2(-4.0, 0.0), Vector2(7.0, 0.0), Color(1.0, 0.35, 0.05), 2.0)


func _on_body_entered(body: Node) -> void:
	FxDirector.impact(global_position, Color(1.0, 0.70, 0.18, 1.0), 7, 150.0)

	if body.has_method("take_damage"):
		body.take_damage(damage)

		if remaining_pierces > 0:
			remaining_pierces -= 1
			return

	queue_free()


func _on_lifetime_timer_timeout() -> void:
	queue_free()
