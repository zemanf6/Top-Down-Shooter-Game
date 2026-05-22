extends PlayerInfusion
class_name RailgunInfusion


func _init() -> void:
	id = "railgun"
	title = "Railgun Infusion"
	description = "Damage + Projectile Speed. Extrémně silné, rychlé a průrazné střely."
	required_upgrade_ids = ["damage", "projectile_speed"]


func apply(player: Player) -> void:
	player.increase_projectile_damage(4)
	player.increase_projectile_speed(450.0)
	player.increase_projectile_piercing(2)
