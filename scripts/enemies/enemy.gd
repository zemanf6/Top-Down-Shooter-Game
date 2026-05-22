extends CharacterBody2D
class_name Enemy

signal died(
	score_value: int,
	xp_reward: int,
	death_position: Vector2,
	guaranteed_health_drop: bool,
	grants_upgrade_on_death: bool,
	is_boss: bool
)

enum Archetype {
	GRUNT,
	RUNNER,
	TANK,
	SHOOTER,
	ELITE,
	BOSS_BRUTE,
	BOSS_STORM,
	BOSS_JUGGERNAUT
}

const TEXTURE_GRUNT: Texture2D = preload("res://assets/textures/enemy_grunt.png")
const TEXTURE_RUNNER: Texture2D = preload("res://assets/textures/enemy_runner.png")
const TEXTURE_TANK: Texture2D = preload("res://assets/textures/enemy_tank.png")
const TEXTURE_SHOOTER: Texture2D = preload("res://assets/textures/enemy_shooter.png")
const TEXTURE_ELITE: Texture2D = preload("res://assets/textures/enemy_elite.png")
const TEXTURE_BOSS_BRUTE: Texture2D = preload("res://assets/textures/enemy_boss_brute.png")
const TEXTURE_BOSS_STORM: Texture2D = preload("res://assets/textures/enemy_boss_storm.png")
const TEXTURE_BOSS_JUGGERNAUT: Texture2D = preload("res://assets/textures/enemy_boss_juggernaut.png")

@export var archetype: Archetype = Archetype.GRUNT

@export var speed: float = 120.0
@export var max_health: int = 3
@export var contact_damage: int = 1
@export var attack_range: float = 34.0
@export var score_value: int = 10
@export var xp_reward: int = 5

@export_group("Visual")
@export var body_radius: float = 18.0
@export var body_color: Color = Color(0.9, 0.15, 0.15)
@export var eye_color: Color = Color(0.35, 0.02, 0.02)

@export_group("Boss")
@export var is_boss: bool = false
@export var guaranteed_health_drop: bool = false
@export var grants_upgrade_on_death: bool = false

@export_group("Shooting")
@export var enemy_projectile_scene: PackedScene
@export var shooting_range: float = 500.0
@export var shoot_interval: float = 1.7
@export var projectile_spawn_offset: float = 24.0
@export var projectile_damage: int = 1
@export var projectile_speed: float = 330.0

var current_health: int = 0
var player: Player = null
var hit_tween: Tween = null
var sprite: Sprite2D
var strafe_sign: float = 1.0
var pulse_time: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_cooldown_timer: Timer = $DamageCooldownTimer
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	collision_layer = 1 << 2
	collision_mask = (1 << 0) | (1 << 1)

	strafe_sign = -1.0 if int(get_instance_id()) % 2 == 0 else 1.0
	_create_visuals()
	_update_collision_shape()

	current_health = max_health
	add_to_group("enemies")

	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	shoot_timer.start()

	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		push_warning("Enemy could not find player in group 'player'.")
		return

	player = players[0] as Player


func _process(delta: float) -> void:
	pulse_time += delta

	if is_boss or current_health < max_health:
		queue_redraw()


func _create_visuals() -> void:
	sprite = Sprite2D.new()
	sprite.name = "EnemySprite"
	sprite.texture = _get_texture_for_archetype()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 3
	add_child(sprite)
	_update_sprite_scale()


func _get_texture_for_archetype() -> Texture2D:
	match archetype:
		Archetype.RUNNER:
			return TEXTURE_RUNNER
		Archetype.TANK:
			return TEXTURE_TANK
		Archetype.SHOOTER:
			return TEXTURE_SHOOTER
		Archetype.ELITE:
			return TEXTURE_ELITE
		Archetype.BOSS_BRUTE:
			return TEXTURE_BOSS_BRUTE
		Archetype.BOSS_STORM:
			return TEXTURE_BOSS_STORM
		Archetype.BOSS_JUGGERNAUT:
			return TEXTURE_BOSS_JUGGERNAUT
		_:
			return TEXTURE_GRUNT


func _update_sprite_scale() -> void:
	if sprite == null or sprite.texture == null:
		return

	var texture_size: Vector2 = sprite.texture.get_size()
	var target_size: float = body_radius * 2.55
	var scale_factor: float = target_size / maxf(texture_size.x, texture_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)


func _update_collision_shape() -> void:
	var shape: CircleShape2D = collision_shape.shape as CircleShape2D

	if shape == null:
		shape = CircleShape2D.new()
		collision_shape.shape = shape

	shape.radius = body_radius


func _physics_process(_delta: float) -> void:
	if player == null or player.current_health <= 0:
		velocity = Vector2.ZERO
		return

	_chase_player()
	_try_damage_player()


func _chase_player() -> void:
	var to_player: Vector2 = player.global_position - global_position
	var distance_to_player: float = to_player.length()
	var direction: Vector2 = Vector2.ZERO

	if distance_to_player > 0.0:
		direction = to_player / distance_to_player
	else:
		direction = Vector2.RIGHT

	if _prefers_strafing() and distance_to_player < shooting_range * 0.62:
		var away: Vector2 = -direction
		var side: Vector2 = direction.orthogonal() * strafe_sign
		direction = (away * 0.58 + side * 0.82).normalized()
	elif archetype == Archetype.RUNNER:
		var weave: float = sin((Time.get_ticks_msec() * 0.006) + float(get_instance_id() % 37)) * 0.24
		direction = (direction + direction.orthogonal() * weave).normalized()
	elif archetype == Archetype.TANK and distance_to_player < attack_range * 2.0:
		direction = (direction * 1.15).normalized()

	velocity = direction * speed
	move_and_slide()
	look_at(player.global_position)


func _prefers_strafing() -> bool:
	return archetype == Archetype.SHOOTER or archetype == Archetype.ELITE or archetype == Archetype.BOSS_STORM


func _try_damage_player() -> void:
	var distance_to_player: float = global_position.distance_to(player.global_position)

	if distance_to_player > attack_range:
		return

	if not damage_cooldown_timer.is_stopped():
		return

	player.take_damage(contact_damage)
	damage_cooldown_timer.start()


func _on_shoot_timer_timeout() -> void:
	if player == null:
		return

	if player.current_health <= 0:
		return

	if enemy_projectile_scene == null:
		return

	var distance_to_player: float = global_position.distance_to(player.global_position)

	if distance_to_player > shooting_range:
		return

	if not _has_line_of_sight_to_player():
		return

	_shoot_at_player()


func _shoot_at_player() -> void:
	var direction_to_player: Vector2 = global_position.direction_to(player.global_position)
	var spawn_position: Vector2 = global_position + (direction_to_player * projectile_spawn_offset)

	if archetype == Archetype.BOSS_STORM:
		for angle in [-12.0, 0.0, 12.0]:
			_spawn_projectile_direction(spawn_position, direction_to_player.rotated(deg_to_rad(angle)))
	elif archetype == Archetype.BOSS_JUGGERNAUT:
		for angle in [-20.0, -10.0, 0.0, 10.0, 20.0]:
			_spawn_projectile_direction(spawn_position, direction_to_player.rotated(deg_to_rad(angle)))
	else:
		_spawn_projectile_direction(spawn_position, direction_to_player)

	AudioDirector.play_positional_sfx("enemy_shoot", global_position, -8.0 if not is_boss else -4.0, 0.06)
	FxDirector.muzzle_flash(spawn_position, direction_to_player.angle(), Color(1.0, 0.16, 0.28, 1.0), 15.0 if not is_boss else 24.0)


func _spawn_projectile_direction(spawn_position: Vector2, shot_direction: Vector2) -> void:
	var created_node: Node = enemy_projectile_scene.instantiate()
	var projectile: EnemyProjectile = created_node as EnemyProjectile

	if projectile == null:
		created_node.queue_free()
		push_error("Assigned enemy_projectile_scene is not an EnemyProjectile scene.")
		return

	projectile.damage = projectile_damage
	projectile.speed = projectile_speed

	get_tree().current_scene.add_child(projectile)
	projectile.setup_direction(spawn_position, shot_direction)


func _has_line_of_sight_to_player() -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position
	)

	query.exclude = [get_rid()]
	query.collision_mask = (1 << 0) | (1 << 1)

	var hit: Dictionary = space_state.intersect_ray(query)

	if hit.is_empty():
		return true

	var collider: Object = hit.get("collider")
	return collider == player


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	current_health = max(current_health - amount, 0)
	_play_hit_effect()
	AudioDirector.play_positional_sfx("hit", global_position, -12.0, 0.09)
	FxDirector.floating_text(str(amount), global_position, Color(1.0, 0.82, 0.25, 1.0))
	queue_redraw()

	if current_health == 0:
		_die()


func _die() -> void:
	AudioDirector.play_positional_sfx("enemy_die", global_position, -5.0 if not is_boss else -1.0, 0.06)
	FxDirector.explosion(global_position, body_color.lightened(0.25), 20 if not is_boss else 42, 260.0 if not is_boss else 420.0)
	FxDirector.screen_shake(3.0 if not is_boss else 10.0, 0.13 if not is_boss else 0.34)
	died.emit(
		score_value,
		xp_reward,
		global_position,
		guaranteed_health_drop,
		grants_upgrade_on_death,
		is_boss
	)
	queue_free()


func _play_hit_effect() -> void:
	if hit_tween != null:
		hit_tween.kill()

	modulate = Color(2.2, 2.2, 2.2)

	hit_tween = create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func _draw() -> void:
	var pulse_alpha: float = 0.16 + sin(pulse_time * 4.0) * 0.05
	draw_circle(Vector2.ZERO, body_radius + 7.0, Color(body_color.r, body_color.g, body_color.b, pulse_alpha))

	if sprite == null or sprite.texture == null:
		draw_circle(Vector2.ZERO, body_radius, body_color)
		draw_circle(Vector2(body_radius * 0.45, 0.0), body_radius * 0.32, eye_color)

	if is_boss:
		var ring_alpha: float = 0.55 + sin(pulse_time * 5.0) * 0.18
		draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 64, Color(1.0, 0.65, 0.1, ring_alpha), 4.0)

	_draw_health_bar()


func _draw_health_bar() -> void:
	if max_health <= 0:
		return

	if current_health >= max_health and not is_boss:
		return

	var health_ratio: float = float(current_health) / float(max_health)
	var bar_width: float = body_radius * 2.35
	var filled_width: float = bar_width * health_ratio
	var y: float = -body_radius - 16.0

	draw_rect(
		Rect2(Vector2(-bar_width / 2.0, y), Vector2(bar_width, 6.0)),
		Color(0.03, 0.04, 0.05, 0.85)
	)

	draw_rect(
		Rect2(Vector2(-bar_width / 2.0, y), Vector2(filled_width, 6.0)),
		Color(0.2, 0.95, 0.32, 0.95)
	)

	draw_rect(
		Rect2(Vector2(-bar_width / 2.0, y), Vector2(bar_width, 6.0)),
		Color(0.75, 1.0, 0.78, 0.55),
		false,
		1.0
	)
