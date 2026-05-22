extends PlayerUpgrade
class_name FireRateUpgrade


func _init() -> void:
	id = "fire_rate"
	title = "Rychlejší střelba"
	description = "Zkrátí cooldown mezi výstřely."
	max_stack = 5


func apply(player: Player) -> void:
	player.multiply_fire_cooldown(0.9)
