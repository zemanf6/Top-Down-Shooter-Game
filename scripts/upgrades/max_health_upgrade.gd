extends PlayerUpgrade
class_name MaxHealthUpgrade


func _init() -> void:
	id = "max_health"
	title = "Více životů"
	description = "+1 maximální HP a zároveň se vyléčíš o 1 HP."
	max_stack = 5


func apply(player: Player) -> void:
	player.increase_max_health(1)
