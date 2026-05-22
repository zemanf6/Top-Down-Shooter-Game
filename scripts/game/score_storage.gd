extends Node
class_name ScoreStorage

const SAVE_PATH: String = "user://score.save"

var best_score: int = 0


func _ready() -> void:
	load_best_score()


func submit_score(score: int) -> bool:
	if score <= best_score:
		return false

	best_score = score
	save_best_score()
	return true


func load_best_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		best_score = 0
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		best_score = 0
		return

	var loaded_value: Variant = file.get_var()
	file.close()

	if loaded_value is int:
		best_score = loaded_value
	else:
		best_score = 0


func save_best_score() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_warning("Could not save best score.")
		return

	file.store_var(best_score)
	file.close()


func reset_best_score() -> void:
	best_score = 0
	save_best_score()
