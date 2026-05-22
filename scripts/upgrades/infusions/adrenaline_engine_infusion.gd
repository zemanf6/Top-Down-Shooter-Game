extends PlayerInfusion
class_name AdrenalineEngineInfusion


func _init() -> void:
	id = "adrenaline_engine"
	title = "Adrenaline Engine"
	description = "Movement Speed + Fire Rate. Při pohybu střílíš ještě rychleji."
	required_upgrade_ids = ["movement_speed", "fire_rate"]


func apply(player: Player) -> void:
	player.increase_movement_speed(60.0)
	player.enable_moving_fire_rate_bonus(0.72)
