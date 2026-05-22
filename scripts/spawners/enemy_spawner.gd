extends Node2D
class_name EnemySpawner

signal enemy_spawned(enemy: Enemy)
signal enemy_killed(
	score_value: int,
	xp_reward: int,
	death_position: Vector2,
	guaranteed_health_drop: bool,
	grants_upgrade_on_death: bool,
	is_boss: bool
)
signal wave_started(wave_number: int, enemies_in_wave: int)

@export var enemy_scene: PackedScene

@export_group("Arena")
@export var arena_rect: Rect2 = Rect2(80.0, 80.0, 1120.0, 560.0)
@export var spawn_clearance_radius: float = 32.0
@export var min_spawn_distance_from_player: float = 260.0
@export var max_spawn_attempts: int = 80

@export_group("Wave Settings")
@export var base_enemies_per_wave: int = 4
@export var extra_enemies_per_wave: int = 2
@export var wave_delay: float = 1.35

@export_group("Enemy Type Unlocks")
@export var runner_start_wave: int = 2
@export var tank_start_wave: int = 3
@export var shooter_start_wave: int = 4
@export var elite_start_wave: int = 7

@export_group("Boss")
@export var boss_wave_interval: int = 5
@export var boss_health_multiplier: float = 3.4
@export var boss_score_multiplier: int = 6
@export var boss_xp_multiplier: int = 5

@export_group("Spawn Timing")
@export var base_spawn_interval: float = 0.70
@export var min_spawn_interval: float = 0.24
@export var spawn_interval_reduction_per_wave: float = 0.035

@export_group("Difficulty Scaling")
@export var enemy_speed_bonus_per_wave: float = 6.0
@export var enemy_health_bonus_every_n_waves: int = 3
@export var enemy_health_bonus_amount: int = 1
@export var enemy_shoot_interval_reduction_per_wave: float = 0.055
@export var min_enemy_shoot_interval: float = 0.75
@export var score_bonus_per_wave: int = 2
@export var xp_bonus_every_n_waves: int = 2

var wave_number: int = 0
var enemies_left_to_spawn: int = 0
var alive_enemies: int = 0
var is_wave_spawning: bool = false
var boss_pending_for_current_wave: bool = false

var player: Player = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_delay_timer: Timer = $WaveDelayTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	rng.randomize()

	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	wave_delay_timer.one_shot = true
	wave_delay_timer.wait_time = wave_delay
	wave_delay_timer.timeout.connect(_start_next_wave)

	player = _find_player()

	if player == null:
		push_error("EnemySpawner could not find player in group 'player'.")
		return

	call_deferred("_start_next_wave")


func _find_player() -> Player:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return null

	return players[0] as Player


func _start_next_wave() -> void:
	if player == null:
		return

	if player.current_health <= 0:
		return

	wave_number += 1
	is_wave_spawning = true

	var minion_count: int = base_enemies_per_wave + ((wave_number - 1) * extra_enemies_per_wave)
	boss_pending_for_current_wave = _is_boss_wave()

	if boss_pending_for_current_wave:
		minion_count = maxi(3, minion_count - 1)
		enemies_left_to_spawn = minion_count + 1
	else:
		enemies_left_to_spawn = minion_count

	var current_spawn_interval: float = base_spawn_interval - (float(wave_number - 1) * spawn_interval_reduction_per_wave)
	current_spawn_interval = maxf(min_spawn_interval, current_spawn_interval)

	spawn_timer.wait_time = current_spawn_interval

	wave_started.emit(wave_number, enemies_left_to_spawn)
	call_deferred("_spawn_next_enemy_in_wave")


func _is_boss_wave() -> bool:
	if boss_wave_interval <= 0:
		return false

	return wave_number % boss_wave_interval == 0


func _spawn_next_enemy_in_wave() -> void:
	if player == null:
		return

	if player.current_health <= 0:
		return

	if enemies_left_to_spawn <= 0:
		is_wave_spawning = false
		_try_start_next_wave_after_delay()
		return

	var should_spawn_boss: bool = boss_pending_for_current_wave
	_spawn_enemy(should_spawn_boss)

	if should_spawn_boss:
		boss_pending_for_current_wave = false

	enemies_left_to_spawn -= 1

	if enemies_left_to_spawn > 0:
		spawn_timer.start()
	else:
		is_wave_spawning = false
		_try_start_next_wave_after_delay()


func _on_spawn_timer_timeout() -> void:
	_spawn_next_enemy_in_wave()


func _spawn_enemy(should_spawn_boss: bool) -> void:
	if enemy_scene == null:
		push_error("EnemySpawner cannot spawn because enemy_scene is not assigned.")
		return

	var created_node: Node = enemy_scene.instantiate()
	var enemy: Enemy = created_node as Enemy

	if enemy == null:
		created_node.queue_free()
		push_error("Assigned enemy_scene is not an Enemy scene.")
		return

	enemy.global_position = _get_valid_spawn_position()

	if should_spawn_boss:
		_apply_boss_variant(enemy)
	else:
		_apply_minion_variant(enemy)

	_apply_wave_scaling(enemy, should_spawn_boss)

	enemy.died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(enemy)

	alive_enemies += 1
	enemy_spawned.emit(enemy)


func _apply_minion_variant(enemy: Enemy) -> void:
	var archetype: Enemy.Archetype = _choose_minion_archetype()
	enemy.archetype = archetype

	match archetype:
		Enemy.Archetype.RUNNER:
			enemy.speed = 185.0
			enemy.max_health = 2
			enemy.score_value = 12
			enemy.xp_reward = 6
			enemy.shoot_interval = 2.0
			enemy.body_radius = 15.0
			enemy.body_color = Color(1.0, 0.35, 0.12)
			enemy.eye_color = Color(0.45, 0.08, 0.02)

		Enemy.Archetype.TANK:
			enemy.speed = 82.0
			enemy.max_health = 8
			enemy.contact_damage = 2
			enemy.score_value = 22
			enemy.xp_reward = 10
			enemy.shoot_interval = 2.3
			enemy.body_radius = 24.0
			enemy.body_color = Color(0.55, 0.1, 0.1)
			enemy.eye_color = Color(0.18, 0.01, 0.01)

		Enemy.Archetype.SHOOTER:
			enemy.speed = 105.0
			enemy.max_health = 3
			enemy.score_value = 18
			enemy.xp_reward = 9
			enemy.shooting_range = 620.0
			enemy.shoot_interval = 1.15
			enemy.projectile_speed = 390.0
			enemy.body_radius = 17.0
			enemy.body_color = Color(0.75, 0.15, 0.95)
			enemy.eye_color = Color(0.22, 0.02, 0.35)

		Enemy.Archetype.ELITE:
			enemy.speed = 145.0
			enemy.max_health = 7
			enemy.contact_damage = 2
			enemy.score_value = 34
			enemy.xp_reward = 16
			enemy.shooting_range = 580.0
			enemy.shoot_interval = 0.95
			enemy.projectile_speed = 430.0
			enemy.body_radius = 21.0
			enemy.body_color = Color(0.95, 0.45, 0.05)
			enemy.eye_color = Color(0.30, 0.08, 0.0)

		_:
			enemy.speed = 120.0
			enemy.max_health = 3
			enemy.score_value = 10
			enemy.xp_reward = 5
			enemy.shoot_interval = 1.7
			enemy.body_radius = 18.0
			enemy.body_color = Color(0.9, 0.15, 0.15)
			enemy.eye_color = Color(0.35, 0.02, 0.02)


func _choose_minion_archetype() -> Enemy.Archetype:
	var roll: float = rng.randf()

	if wave_number >= elite_start_wave and roll < 0.16:
		return Enemy.Archetype.ELITE

	if wave_number >= shooter_start_wave and roll < 0.36:
		return Enemy.Archetype.SHOOTER

	if wave_number >= tank_start_wave and roll < 0.56:
		return Enemy.Archetype.TANK

	if wave_number >= runner_start_wave and roll < 0.76:
		return Enemy.Archetype.RUNNER

	return Enemy.Archetype.GRUNT


func _apply_boss_variant(enemy: Enemy) -> void:
	var boss_index: int = int(wave_number / boss_wave_interval) % 3

	enemy.is_boss = true
	enemy.guaranteed_health_drop = true
	enemy.grants_upgrade_on_death = true

	match boss_index:
		0:
			enemy.archetype = Enemy.Archetype.BOSS_BRUTE
			enemy.speed = 95.0
			enemy.max_health = 20
			enemy.contact_damage = 3
			enemy.score_value = 100
			enemy.xp_reward = 45
			enemy.shoot_interval = 1.35
			enemy.projectile_damage = 2
			enemy.body_radius = 32.0
			enemy.body_color = Color(0.65, 0.05, 0.05)
			enemy.eye_color = Color(0.15, 0.0, 0.0)

		1:
			enemy.archetype = Enemy.Archetype.BOSS_STORM
			enemy.speed = 135.0
			enemy.max_health = 15
			enemy.contact_damage = 2
			enemy.score_value = 115
			enemy.xp_reward = 50
			enemy.shooting_range = 660.0
			enemy.shoot_interval = 0.75
			enemy.projectile_speed = 470.0
			enemy.projectile_damage = 1
			enemy.body_radius = 29.0
			enemy.body_color = Color(0.55, 0.05, 0.85)
			enemy.eye_color = Color(0.15, 0.0, 0.30)

		_:
			enemy.archetype = Enemy.Archetype.BOSS_JUGGERNAUT
			enemy.speed = 70.0
			enemy.max_health = 30
			enemy.contact_damage = 3
			enemy.score_value = 130
			enemy.xp_reward = 55
			enemy.shoot_interval = 1.6
			enemy.projectile_damage = 2
			enemy.body_radius = 36.0
			enemy.body_color = Color(0.45, 0.38, 0.12)
			enemy.eye_color = Color(0.12, 0.08, 0.0)


func _apply_wave_scaling(enemy: Enemy, should_spawn_boss: bool) -> void:
	var wave_index: int = wave_number - 1

	enemy.speed += float(wave_index) * enemy_speed_bonus_per_wave

	if enemy_health_bonus_every_n_waves > 0:
		var health_steps: int = int(floor(float(wave_index) / float(enemy_health_bonus_every_n_waves)))
		enemy.max_health += health_steps * enemy_health_bonus_amount

	enemy.score_value += wave_index * score_bonus_per_wave

	if xp_bonus_every_n_waves > 0:
		enemy.xp_reward += int(floor(float(wave_index) / float(xp_bonus_every_n_waves)))

	var scaled_shoot_interval: float = enemy.shoot_interval - (float(wave_index) * enemy_shoot_interval_reduction_per_wave)
	enemy.shoot_interval = maxf(min_enemy_shoot_interval, scaled_shoot_interval)

	if should_spawn_boss:
		enemy.max_health = int(ceil(float(enemy.max_health) * boss_health_multiplier))
		enemy.score_value *= boss_score_multiplier
		enemy.xp_reward *= boss_xp_multiplier


func _get_valid_spawn_position() -> Vector2:
	for attempt_index in range(max_spawn_attempts):
		var candidate: Vector2 = _get_random_position_inside_arena()

		if candidate.distance_to(player.global_position) < min_spawn_distance_from_player:
			continue

		if not _is_spawn_position_clear(candidate):
			continue

		return candidate

	return _get_fallback_spawn_position()


func _get_random_position_inside_arena() -> Vector2:
	var x: float = rng.randf_range(arena_rect.position.x, arena_rect.position.x + arena_rect.size.x)
	var y: float = rng.randf_range(arena_rect.position.y, arena_rect.position.y + arena_rect.size.y)

	return Vector2(x, y)


func _is_spawn_position_clear(position: Vector2) -> bool:
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = spawn_clearance_radius

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform = Transform2D(0.0, position)
	query.collision_mask = (1 << 0) | (1 << 1) | (1 << 2)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var collisions: Array = get_world_2d().direct_space_state.intersect_shape(query, 1)
	return collisions.is_empty()


func _get_fallback_spawn_position() -> Vector2:
	var direction: Vector2 = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	var candidate: Vector2 = player.global_position + (direction * min_spawn_distance_from_player)

	var min_x: float = arena_rect.position.x
	var max_x: float = arena_rect.position.x + arena_rect.size.x
	var min_y: float = arena_rect.position.y
	var max_y: float = arena_rect.position.y + arena_rect.size.y

	candidate.x = clampf(candidate.x, min_x, max_x)
	candidate.y = clampf(candidate.y, min_y, max_y)

	return candidate


func _on_enemy_died(
	score_value: int,
	xp_reward: int,
	death_position: Vector2,
	guaranteed_health_drop: bool,
	grants_upgrade_on_death: bool,
	is_boss: bool
) -> void:
	alive_enemies = maxi(alive_enemies - 1, 0)

	enemy_killed.emit(
		score_value,
		xp_reward,
		death_position,
		guaranteed_health_drop,
		grants_upgrade_on_death,
		is_boss
	)

	_try_start_next_wave_after_delay()


func _try_start_next_wave_after_delay() -> void:
	if is_wave_spawning:
		return

	if enemies_left_to_spawn > 0:
		return

	if alive_enemies > 0:
		return

	if not wave_delay_timer.is_stopped():
		return

	wave_delay_timer.wait_time = wave_delay
	wave_delay_timer.start()
