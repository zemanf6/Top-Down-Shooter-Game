extends PlayerInfusion
class_name PhantomVelocityInfusion


func _init() -> void:
	id = "phantom_velocity"
	title = "Phantom Velocity"
	description = "Movement Speed + Projectile Speed. Rychlý glass-cannon styl."
	required_upgrade_ids = ["movement_speed", "projectile_speed"]


func apply(player: Player) -> void:
	player.increase_movement_speed(90.0)
	player.increase_projectile_speed(300.0)
	player.multiply_fire_cooldown(0.9)
