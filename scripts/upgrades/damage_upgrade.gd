extends PlayerUpgrade
class_name DamageUpgrade


func _init() -> void:
	id = "damage"
	title = "Silnější střely"
	description = "+1 damage pro hráčovy projektily."
	max_stack = 5


func apply(player: Player) -> void:
	player.increase_projectile_damage(1)
