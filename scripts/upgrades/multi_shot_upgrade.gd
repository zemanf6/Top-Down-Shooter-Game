extends PlayerUpgrade
class_name MultiShotUpgrade


func _init() -> void:
	id = "multi_shot"
	title = "Multi-shot"
	description = "Přidá další střelu do jednoho výstřelu."
	max_stack = 5


func apply(player: Player) -> void:
	player.increase_projectiles_per_shot(1)
