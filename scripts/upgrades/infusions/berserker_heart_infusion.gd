extends PlayerInfusion
class_name BerserkerHeartInfusion


func _init() -> void:
	id = "berserker_heart"
	title = "Berserker Heart Infusion"
	description = "Max Health + Damage. Více HP a bonus damage podle chybějícího zdraví."
	required_upgrade_ids = ["max_health", "damage"]


func apply(player: Player) -> void:
	player.increase_max_health(3)
	player.increase_projectile_damage(2)
	player.increase_missing_health_damage_bonus(1)
