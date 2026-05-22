extends Node2D

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/MainMenu.tscn"
const COMBO_TIMEOUT: float = 2.65
const MAX_COMBO_MULTIPLIER: float = 3.0

var score: int = 0
var last_player_health: int = 0

var combo_streak: int = 0
var combo_timer: float = 0.0
var combo_multiplier: float = 1.0

var camera: Camera2D
var shake_time_left: float = 0.0
var shake_duration: float = 0.0
var shake_amount: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var player: Player = $Player
@onready var hud: Hud = $Hud
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var upgrade_selection: UpgradeSelection = $UpgradeSelection
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var loot_dropper: LootDropper = $LootDropper
@onready var upgrade_manager: UpgradeManager = $UpgradeManager
@onready var score_storage: ScoreStorage = $ScoreStorage


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	rng.randomize()
	_create_camera()
	AudioDirector.play_game_music()

	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy_spawner.process_mode = Node.PROCESS_MODE_PAUSABLE
	last_player_health = player.current_health

	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

	game_over_screen.restart_requested.connect(_on_restart_requested)
	game_over_screen.main_menu_requested.connect(_on_main_menu_requested)

	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.main_menu_requested.connect(_on_main_menu_requested)

	upgrade_selection.upgrade_selected.connect(_on_upgrade_selected)

	enemy_spawner.wave_started.connect(_on_wave_started)
	enemy_spawner.enemy_killed.connect(_on_enemy_killed)

	upgrade_manager.xp_changed.connect(_on_xp_changed)
	upgrade_manager.upgrade_choices_ready.connect(_on_upgrade_choices_ready)
	upgrade_manager.infusion_applied.connect(_on_infusion_applied)

	hud.update_score(score)
	hud.update_health(player.current_health, player.max_health)
	hud.update_wave(0)
	hud.update_level_and_xp(upgrade_manager.level, upgrade_manager.current_xp, upgrade_manager.required_xp)
	hud.update_combo(0, 1.0, 0.0)
	hud.show_message("WASD pohyb • Myš střelba • Mezerník dash")


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position = Vector2(640.0, 360.0)
	camera.enabled = true
	camera.ignore_rotation = true
	add_child(camera)


func _process(delta: float) -> void:
	if not get_tree().paused:
		_update_combo(delta)

	_update_screen_shake(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()


func _toggle_pause() -> void:
	if game_over_screen.visible:
		return

	if upgrade_selection.visible:
		return

	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()


func _pause_game() -> void:
	get_tree().paused = true
	pause_menu.show_pause(
		upgrade_manager.get_progress_summary_lines(),
		score,
		score_storage.best_score
	)


func _resume_game() -> void:
	pause_menu.hide_pause()
	get_tree().paused = false


func _on_resume_requested() -> void:
	_resume_game()


func _on_wave_started(wave_number: int, enemies_in_wave: int) -> void:
	hud.update_wave(wave_number)

	if enemy_spawner.boss_wave_interval > 0 and wave_number % enemy_spawner.boss_wave_interval == 0:
		hud.show_message("⚠ BOSS VLNA %d ⚠" % wave_number)
		AudioDirector.play_sfx("boss_warning", -4.0, 0.0)
		add_screen_shake(5.5, 0.28)
	else:
		hud.show_message("VLNA %d  •  %d cílů" % [wave_number, enemies_in_wave])
		AudioDirector.play_sfx("wave_start", -8.0, 0.02)


func _on_enemy_killed(
	score_value: int,
	xp_reward: int,
	death_position: Vector2,
	guaranteed_health_drop: bool,
	grants_upgrade_on_death: bool,
	is_boss: bool
) -> void:
	_register_combo_kill(is_boss)
	var earned_score: int = maxi(1, int(round(float(score_value) * combo_multiplier)))
	score += earned_score
	hud.update_score(score)
	hud.update_combo(combo_streak, combo_multiplier, combo_timer)
	FxDirector.floating_text("+%d" % earned_score, death_position + Vector2(0.0, -18.0), Color(1.0, 0.78, 0.22, 1.0))

	loot_dropper.try_drop_health(death_position, guaranteed_health_drop, is_boss)
	upgrade_manager.add_xp(xp_reward)

	if grants_upgrade_on_death:
		upgrade_manager.force_upgrade_choice()


func _register_combo_kill(is_boss: bool) -> void:
	if combo_timer <= 0.0:
		combo_streak = 0

	combo_streak += 3 if is_boss else 1
	combo_timer = COMBO_TIMEOUT + (0.55 if is_boss else 0.0)
	combo_multiplier = minf(MAX_COMBO_MULTIPLIER, 1.0 + (float(combo_streak - 1) * 0.07))


func _update_combo(delta: float) -> void:
	if combo_timer <= 0.0:
		return

	combo_timer -= delta

	if combo_timer <= 0.0:
		_reset_combo()
	else:
		hud.update_combo(combo_streak, combo_multiplier, combo_timer)


func _reset_combo() -> void:
	combo_streak = 0
	combo_timer = 0.0
	combo_multiplier = 1.0
	hud.update_combo(combo_streak, combo_multiplier, combo_timer)


func _on_xp_changed(current_xp: int, required_xp: int, level: int) -> void:
	hud.update_level_and_xp(level, current_xp, required_xp)


func _on_upgrade_choices_ready(choices: Array[Resource]) -> void:
	pause_menu.hide_pause()
	AudioDirector.play_sfx("upgrade", -5.0, 0.0)
	get_tree().paused = true
	upgrade_selection.show_choices(choices)


func _on_upgrade_selected(choice: Resource) -> void:
	AudioDirector.play_sfx("ui_select", -8.0, 0.02)
	upgrade_selection.hide_selection()
	upgrade_manager.apply_choice(choice, player)

	if not upgrade_manager.has_pending_choice():
		get_tree().paused = false


func _on_infusion_applied(
	infusion: PlayerInfusion,
	_locked_upgrade_ids: Array[String]
) -> void:
	hud.show_message("INFUZE: %s" % infusion.title)
	AudioDirector.play_sfx("upgrade", -3.0, 0.0)
	add_screen_shake(6.0, 0.22)


func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if current_health < last_player_health:
		_reset_combo()

	last_player_health = current_health
	hud.update_health(current_health, max_health)


func _on_player_died() -> void:
	var is_new_best_score: bool = score_storage.submit_score(score)

	pause_menu.hide_pause()
	upgrade_selection.hide_selection()
	game_over_screen.show_game_over(score, score_storage.best_score, is_new_best_score)
	get_tree().paused = true


func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_requested() -> void:
	get_tree().paused = false

	var error: int = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

	if error != OK:
		push_error("Could not return to main menu: %s" % MAIN_MENU_SCENE_PATH)


func add_screen_shake(amount: float, duration: float) -> void:
	if camera == null:
		return

	shake_amount = maxf(shake_amount, amount)
	shake_duration = maxf(shake_duration, duration)
	shake_time_left = maxf(shake_time_left, duration)


func _update_screen_shake(delta: float) -> void:
	if camera == null:
		return

	if shake_time_left <= 0.0:
		camera.offset = Vector2.ZERO
		shake_amount = 0.0
		shake_duration = 0.0
		return

	shake_time_left -= delta
	var ratio: float = 1.0

	if shake_duration > 0.0:
		ratio = clampf(shake_time_left / shake_duration, 0.0, 1.0)

	camera.offset = Vector2(
		rng.randf_range(-shake_amount, shake_amount),
		rng.randf_range(-shake_amount, shake_amount)
	) * ratio
