extends PlayerInfusion
class_name BulletStormInfusion


func _init() -> void:
	id = "bullet_storm"
	title = "Bullet Storm Infusion"
	description = "Fire Rate + Multi Shot. Výrazně více projektilů a rychlejší střelba."
	required_upgrade_ids = ["fire_rate", "multi_shot"]


func apply(player: Player) -> void:
	player.increase_max_projectiles_per_shot(3)
	player.increase_projectiles_per_shot(3)
	player.multiply_fire_cooldown(0.65)
