extends PlayerInfusion
class_name JuggernautBarrageInfusion


func _init() -> void:
	id = "juggernaut_barrage"
	title = "Juggernaut Barrage"
	description = "Max Health + Multi Shot. Tank build s obrannými salvami."
	required_upgrade_ids = ["max_health", "multi_shot"]


func apply(player: Player) -> void:
	player.increase_max_health(4)
	player.increase_max_projectiles_per_shot(2)
	player.increase_projectiles_per_shot(2)
	player.increase_projectile_damage(1)
