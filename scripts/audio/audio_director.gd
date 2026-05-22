extends Node

const MENU_MUSIC_PATH: String = "res://assets/audio/neon_menu_loop.wav"
const GAME_MUSIC_PATH: String = "res://assets/audio/neon_arena_loop.wav"

var sfx_paths: Dictionary = {
	"shoot": "res://assets/audio/shoot.wav",
	"enemy_shoot": "res://assets/audio/enemy_shoot.wav",
	"hit": "res://assets/audio/hit.wav",
	"enemy_die": "res://assets/audio/enemy_die.wav",
	"player_hit": "res://assets/audio/player_hit.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"dash": "res://assets/audio/dash.wav",
	"upgrade": "res://assets/audio/upgrade.wav",
	"ui_hover": "res://assets/audio/ui_hover.wav",
	"ui_select": "res://assets/audio/ui_select.wav",
	"wave_start": "res://assets/audio/wave_start.wav",
	"cover_break": "res://assets/audio/cover_break.wav",
	"boss_warning": "res://assets/audio/boss_warning.wav"
}

var music_player: AudioStreamPlayer
var current_music_path: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = -11.0
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)


func play_menu_music() -> void:
	play_music(MENU_MUSIC_PATH, -13.0)


func play_game_music() -> void:
	play_music(GAME_MUSIC_PATH, -10.5)


func play_music(path: String, volume_db: float = -11.0) -> void:
	if current_music_path == path and music_player.playing:
		return

	var stream: AudioStream = load(path) as AudioStream

	if stream == null:
		push_warning("Could not load music stream: %s" % path)
		return

	current_music_path = path
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()


func stop_music() -> void:
	current_music_path = ""
	music_player.stop()


func play_sfx(key: String, volume_db: float = -2.0, pitch_variation: float = 0.04) -> void:
	var stream: AudioStream = _load_sfx(key)

	if stream == null:
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = _get_pitch(pitch_variation)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_positional_sfx(
	key: String,
	world_position: Vector2,
	volume_db: float = -2.0,
	pitch_variation: float = 0.04
) -> void:
	var stream: AudioStream = _load_sfx(key)

	if stream == null:
		return

	var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = _get_pitch(pitch_variation)
	player.global_position = world_position
	player.max_distance = 900.0
	player.attenuation = 0.65

	var parent: Node = get_tree().current_scene

	if parent == null:
		parent = self

	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _load_sfx(key: String) -> AudioStream:
	var path: String = String(sfx_paths.get(key, ""))

	if path.is_empty():
		push_warning("Unknown SFX key: %s" % key)
		return null

	var stream: AudioStream = load(path) as AudioStream

	if stream == null:
		push_warning("Could not load SFX stream: %s" % path)

	return stream


func _get_pitch(variation: float) -> float:
	if variation <= 0.0:
		return 1.0

	return 1.0 + rng.randf_range(-variation, variation)


func _on_music_finished() -> void:
	if current_music_path.is_empty():
		return

	music_player.play()
