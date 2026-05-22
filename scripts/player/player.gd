extends CharacterBody2D
class_name Player

signal health_changed(current_health: int, max_health: int)
signal died

const PLAYER_TEXTURE: Texture2D = preload("res://assets/textures/player_ship.png")

@export var speed: float = 280.0
@export var max_health: int = 5
@export var projectile_scene: PackedScene

@export_group("Projectile Stats")
@export var base_projectile_damage: int = 1
@export var base_projectile_speed: float = 700.0
@export var base_shoot_cooldown: float = 0.18
@export var min_shoot_cooldown: float = 0.055
@export var max_projectiles_per_shot: int = 5
@export var multishot_angle_step_degrees: float = 12.0

@export_group("Dash")
@export var dash_speed: float = 760.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.72
@export var dash_invulnerability: float = 0.25

var current_health: int = 0

var projectile_damage: int = 1
var projectile_speed: float = 700.0
var projectile_piercing: int = 0

var shoot_cooldown: float = 0.18
var projectiles_per_shot: int = 1

var missing_health_damage_bonus_per_hp: int = 0
var moving_fire_rate_multiplier: float = 1.0

var last_input_direction: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var afterimage_timer: float = 0.0
var hit_tween: Tween = null

var sprite: Sprite2D
var dash_timer: Timer
var dash_cooldown_timer: Timer
var invulnerability_timer: Timer

@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_cooldown_timer: Timer = $ShootCooldownTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("player")
	_create_visuals()
	_create_dash_timers()

	current_health = max_health

	projectile_damage = base_projectile_damage
	projectile_speed = base_projectile_speed
	shoot_cooldown = base_shoot_cooldown

	shoot_cooldown_timer.wait_time = shoot_cooldown

	health_changed.emit(current_health, max_health)


func _create_visuals() -> void:
	sprite = Sprite2D.new()
	sprite.name = "PixelShip"
	sprite.texture = PLAYER_TEXTURE
	sprite.scale = Vector2(0.76, 0.76)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 3
	add_child(sprite)


func _create_dash_timers() -> void:
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	add_child(dash_timer)

	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	add_child(dash_cooldown_timer)

	invulnerability_timer = Timer.new()
	invulnerability_timer.one_shot = true
	invulnerability_timer.wait_time = dash_invulnerability
	add_child(invulnerability_timer)


func _physics_process(delta: float) -> void:
	if current_health <= 0:
		return

	look_at(get_global_mouse_position())
	_handle_movement(delta)
	_handle_shooting()
	queue_redraw()


func _handle_movement(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	last_input_direction = input_direction

	if input_direction.length_squared() > 0.0:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = Vector2.RIGHT.rotated(rotation)

	if Input.is_action_just_pressed("dash") and _can_dash():
		_start_dash()

	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		_emit_dash_afterimage(delta)
		return

	velocity = input_direction * speed
	move_and_slide()


func _handle_shooting() -> void:
	if Input.is_action_pressed("shoot") and shoot_cooldown_timer.is_stopped():
		shoot()
		_start_shoot_cooldown()


func _can_dash() -> bool:
	return not is_dashing and dash_cooldown_timer.is_stopped()


func _start_dash() -> void:
	is_dashing = true
	dash_timer.start(dash_duration)
	dash_cooldown_timer.start(dash_cooldown)
	invulnerability_timer.start(dash_invulnerability)
	afterimage_timer = 0.0

	AudioDirector.play_positional_sfx("dash", global_position, -5.0, 0.07)
	FxDirector.muzzle_flash(global_position - dash_direction * 16.0, dash_direction.angle() + PI, Color(0.25, 0.85, 1.0, 1.0), 20.0)
	FxDirector.screen_shake(2.2, 0.08)


func _emit_dash_afterimage(delta: float) -> void:
	afterimage_timer -= delta

	if afterimage_timer > 0.0:
		return

	afterimage_timer = 0.035
	FxDirector.impact(global_position - dash_direction * 18.0, Color(0.2, 0.9, 1.0, 0.75), 4, 95.0)


func _on_dash_timer_timeout() -> void:
	is_dashing = false


func _start_shoot_cooldown() -> void:
	var final_cooldown: float = shoot_cooldown

	if last_input_direction.length_squared() > 0.0:
		final_cooldown *= moving_fire_rate_multiplier

	shoot_cooldown_timer.wait_time = maxf(min_shoot_cooldown, final_cooldown)
	shoot_cooldown_timer.start()


func shoot() -> void:
	if projectile_scene == null:
		push_warning("Player cannot shoot because projectile_scene is not assigned.")
		return

	var base_direction: Vector2 = muzzle.global_position.direction_to(get_global_mouse_position())

	if base_direction.length_squared() == 0.0:
		base_direction = Vector2.RIGHT.rotated(rotation)

	var total_spread: float = float(projectiles_per_shot - 1) * multishot_angle_step_degrees
	var start_angle: float = -total_spread / 2.0

	for index in range(projectiles_per_shot):
		var angle_offset: float = deg_to_rad(start_angle + (float(index) * multishot_angle_step_degrees))
		var shot_direction: Vector2 = base_direction.rotated(angle_offset)
		_spawn_projectile(shot_direction)

	AudioDirector.play_positional_sfx("shoot", muzzle.global_position, -6.5, 0.08)
	FxDirector.muzzle_flash(muzzle.global_position, base_direction.angle(), Color(1.0, 0.78, 0.25, 1.0), 19.0)


func _spawn_projectile(direction: Vector2) -> void:
	var projectile_node: Node = projectile_scene.instantiate()
	var projectile: Projectile = projectile_node as Projectile

	if projectile == null:
		projectile_node.queue_free()
		push_error("Assigned projectile_scene is not a Projectile scene.")
		return

	projectile.damage = _get_current_projectile_damage()
	projectile.speed = projectile_speed
	projectile.remaining_pierces = projectile_piercing

	get_tree().current_scene.add_child(projectile)
	projectile.setup_direction(muzzle.global_position, direction)


func _get_current_projectile_damage() -> int:
	var missing_health: int = max_health - current_health
	var bonus_damage: int = missing_health * missing_health_damage_bonus_per_hp

	return projectile_damage + bonus_damage


func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	if not invulnerability_timer.is_stopped():
		FxDirector.impact(global_position, Color(0.35, 0.85, 1.0, 1.0), 8, 140.0)
		return

	current_health = max(current_health - amount, 0)
	_play_hit_effect()
	AudioDirector.play_positional_sfx("player_hit", global_position, -3.0, 0.04)
	FxDirector.impact(global_position, Color(1.0, 0.15, 0.18, 1.0), 16, 220.0)
	FxDirector.screen_shake(7.5, 0.20)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		FxDirector.explosion(global_position, Color(0.25, 0.85, 1.0, 1.0), 32, 320.0)
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return

	if current_health <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	FxDirector.floating_text("+%d HP" % amount, global_position, Color(0.35, 1.0, 0.45, 1.0))
	health_changed.emit(current_health, max_health)


func increase_max_health(amount: int) -> void:
	max_health += amount
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func increase_projectile_damage(amount: int) -> void:
	projectile_damage += amount


func increase_projectile_speed(amount: float) -> void:
	projectile_speed += amount


func increase_projectile_piercing(amount: int) -> void:
	projectile_piercing += amount


func increase_movement_speed(amount: float) -> void:
	speed += amount


func multiply_fire_cooldown(multiplier: float) -> void:
	shoot_cooldown = maxf(min_shoot_cooldown, shoot_cooldown * multiplier)
	shoot_cooldown_timer.wait_time = shoot_cooldown


func increase_projectiles_per_shot(amount: int) -> void:
	projectiles_per_shot = mini(projectiles_per_shot + amount, max_projectiles_per_shot)


func increase_max_projectiles_per_shot(amount: int) -> void:
	max_projectiles_per_shot += amount


func increase_missing_health_damage_bonus(amount: int) -> void:
	missing_health_damage_bonus_per_hp += amount


func enable_moving_fire_rate_bonus(multiplier: float) -> void:
	moving_fire_rate_multiplier = minf(moving_fire_rate_multiplier, multiplier)


func _play_hit_effect() -> void:
	if hit_tween != null:
		hit_tween.kill()

	modulate = Color(1.0, 0.25, 0.25)

	hit_tween = create_tween()
	hit_tween.tween_property(self, "modulate", Color.WHITE, 0.18)


func _draw() -> void:
	var engine_alpha: float = 0.24 + (sin(Time.get_ticks_msec() * 0.025) * 0.08)
	draw_circle(Vector2(-25.0, 0.0), 11.0, Color(0.08, 0.75, 1.0, engine_alpha))

	if is_dashing:
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 36, Color(0.2, 0.9, 1.0, 0.65), 3.0)
	elif not invulnerability_timer.is_stopped():
		var alpha: float = 0.32 + (sin(Time.get_ticks_msec() * 0.045) * 0.18)
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 36, Color(0.45, 0.95, 1.0, alpha), 2.0)

	if sprite == null or sprite.texture == null:
		draw_circle(Vector2.ZERO, 16.0, Color(0.15, 0.55, 1.0))
		draw_rect(Rect2(Vector2(0.0, -5.0), Vector2(32.0, 10.0)), Color(0.05, 0.2, 0.45))
		draw_circle(Vector2.ZERO, 5.0, Color(0.9, 0.95, 1.0))
