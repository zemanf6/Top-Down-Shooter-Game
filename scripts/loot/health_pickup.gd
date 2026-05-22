extends Area2D
class_name HealthPickup

const HEALTH_TEXTURE: Texture2D = preload("res://assets/textures/health_pickup.png")

@export var heal_amount: int = 1
@export var lifetime: float = 12.0
@export var magnet_radius: float = 170.0
@export var magnet_speed: float = 270.0

var life_timer: Timer
var player: Player = null
var sprite: Sprite2D
var pulse_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	collision_layer = 1 << 5
	collision_mask = 1 << 1

	_create_visuals()
	_find_player()
	body_entered.connect(_on_body_entered)

	life_timer = Timer.new()
	life_timer.one_shot = true
	life_timer.wait_time = lifetime
	life_timer.timeout.connect(queue_free)
	add_child(life_timer)
	life_timer.start()

	queue_redraw()


func _create_visuals() -> void:
	sprite = Sprite2D.new()
	sprite.name = "HealthPickupSprite"
	sprite.texture = HEALTH_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 4
	add_child(sprite)


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if not players.is_empty():
		player = players[0] as Player


func _physics_process(delta: float) -> void:
	pulse_time += delta

	if player != null and is_instance_valid(player) and player.current_health > 0:
		var distance: float = global_position.distance_to(player.global_position)

		if distance < magnet_radius:
			var direction: Vector2 = global_position.direction_to(player.global_position)
			var strength: float = 1.0 - (distance / magnet_radius)
			global_position += direction * magnet_speed * strength * delta

	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(pulse_time * 6.0)
	draw_circle(Vector2.ZERO, 18.0 + pulse * 2.0, Color(0.16, 1.0, 0.34, 0.13 + pulse * 0.08))

	if sprite == null or sprite.texture == null:
		draw_circle(Vector2.ZERO, 14.0, Color(0.1, 0.9, 0.25))
		draw_rect(Rect2(Vector2(-3.0, -9.0), Vector2(6.0, 18.0)), Color.WHITE)
		draw_rect(Rect2(Vector2(-9.0, -3.0), Vector2(18.0, 6.0)), Color.WHITE)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		var target_player: Player = body as Player
		target_player.heal(heal_amount)
		AudioDirector.play_positional_sfx("pickup", global_position, -4.0, 0.03)
		FxDirector.impact(global_position, Color(0.35, 1.0, 0.45, 1.0), 14, 180.0)
		queue_free()
