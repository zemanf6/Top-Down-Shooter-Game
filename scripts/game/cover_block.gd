extends StaticBody2D
class_name CoverBlock

const COVER_TEXTURE: Texture2D = preload("res://assets/textures/cover_block_panel.png")

@export var size: Vector2 = Vector2(120.0, 80.0)
@export var color: Color = Color(0.28, 0.24, 0.18)
@export var max_health: int = 9

var current_health: int = 0
var hit_tween: Tween = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	current_health = max_health
	_update_collision_shape()
	queue_redraw()


func _update_collision_shape() -> void:
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = size
	collision_shape.shape = rectangle_shape


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	_play_hit_effect()
	AudioDirector.play_positional_sfx("hit", global_position, -14.0, 0.05)
	FxDirector.impact(global_position, Color(0.72, 0.72, 0.82, 1.0), 8, 160.0)
	queue_redraw()

	if current_health == 0:
		_break_apart()


func _break_apart() -> void:
	AudioDirector.play_positional_sfx("cover_break", global_position, -6.0, 0.04)
	FxDirector.explosion(global_position, Color(0.85, 0.82, 0.66, 1.0), 24, 260.0)
	FxDirector.screen_shake(4.0, 0.16)
	queue_free()


func _play_hit_effect() -> void:
	if hit_tween != null:
		hit_tween.kill()

	modulate = Color(1.55, 1.55, 1.55)
	hit_tween = create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	var health_ratio: float = float(current_health) / float(max_health)
	var tint: Color = Color(1.0, 1.0, 1.0, 0.92)

	if health_ratio < 0.45:
		tint = Color(1.0, 0.70, 0.58, 0.92)

	if COVER_TEXTURE != null:
		draw_texture_rect(COVER_TEXTURE, rect, false, tint)
	else:
		draw_rect(rect, color)

	draw_rect(rect, Color(0.04, 0.05, 0.07, 0.90), false, 3.0)
	draw_rect(Rect2(rect.position + Vector2(5.0, 5.0), rect.size - Vector2(10.0, 10.0)), Color(0.28, 0.95, 1.0, 0.13), false, 1.0)

	_draw_cracks(health_ratio)


func _draw_cracks(health_ratio: float) -> void:
	if health_ratio > 0.78:
		return

	var crack_color := Color(0.02, 0.025, 0.03, 0.72)
	var crack_count: int = int(ceil((1.0 - health_ratio) * 8.0))

	for index in range(crack_count):
		var seed: float = float(index) * 37.0
		var start := Vector2(
			-sin(seed) * size.x * 0.32,
			-cos(seed * 0.7) * size.y * 0.32
		)
		var mid := start + Vector2(cos(seed * 1.4), sin(seed * 0.9)) * 18.0
		var end := mid + Vector2(cos(seed * 2.1), sin(seed * 1.7)) * 16.0
		draw_polyline(PackedVector2Array([start, mid, end]), crack_color, 2.0)
