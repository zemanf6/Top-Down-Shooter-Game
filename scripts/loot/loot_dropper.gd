extends Node
class_name LootDropper

@export var health_pickup_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var normal_health_drop_chance: float = 0.16
@export var normal_health_amount: int = 1
@export var boss_health_amount: int = 2

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func try_drop_health(position: Vector2, guaranteed: bool, is_boss: bool) -> void:
	if health_pickup_scene == null:
		return

	if not guaranteed and rng.randf() > normal_health_drop_chance:
		return

	var created_node: Node = health_pickup_scene.instantiate()
	var pickup: HealthPickup = created_node as HealthPickup

	if pickup == null:
		created_node.queue_free()
		return

	if is_boss:
		pickup.heal_amount = boss_health_amount
	else:
		pickup.heal_amount = normal_health_amount

	get_tree().current_scene.add_child(pickup)
	pickup.global_position = position
