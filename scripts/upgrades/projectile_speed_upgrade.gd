extends PlayerUpgrade
class_name ProjectileSpeedUpgrade


func _init() -> void:
	id = "projectile_speed"
	title = "Rychlejší projektily"
	description = "+80 rychlost hráčových střel."
	max_stack = 5


func apply(player: Player) -> void:
	player.increase_projectile_speed(80.0)
