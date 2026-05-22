extends PlayerUpgrade
class_name MovementSpeedUpgrade


func _init() -> void:
	id = "movement_speed"
	title = "Rychlejší pohyb"
	description = "+25 rychlost pohybu."
	max_stack = 5


func apply(player: Player) -> void:
	player.increase_movement_speed(25.0)
