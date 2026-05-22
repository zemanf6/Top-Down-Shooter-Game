extends Node

const SparkBurstScript: Script = preload("res://scripts/fx/spark_burst.gd")
const FlashPulseScript: Script = preload("res://scripts/fx/flash_pulse.gd")
const FloatingTextScript: Script = preload("res://scripts/fx/floating_text.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func impact(
	world_position: Vector2,
	color: Color = Color(1.0, 0.8, 0.25),
	count: int = 10,
	power: float = 180.0
) -> void:
	var burst: Node2D = SparkBurstScript.new() as Node2D
	_add_to_current_scene(burst)
	burst.call("setup", world_position, color, count, power, 0.28)


func explosion(
	world_position: Vector2,
	color: Color = Color(1.0, 0.36, 0.12),
	count: int = 24,
	power: float = 280.0
) -> void:
	var burst: Node2D = SparkBurstScript.new() as Node2D
	_add_to_current_scene(burst)
	burst.call("setup", world_position, color, count, power, 0.48)


func muzzle_flash(
	world_position: Vector2,
	world_rotation: float,
	color: Color = Color(1.0, 0.78, 0.25),
	flash_radius: float = 18.0
) -> void:
	var flash: Node2D = FlashPulseScript.new() as Node2D
	_add_to_current_scene(flash)
	flash.call("setup", world_position, world_rotation, color, flash_radius, 0.13)


func floating_text(message: String, world_position: Vector2, color: Color = Color.WHITE) -> void:
	var label: Label = FloatingTextScript.new() as Label
	_add_to_current_scene(label)
	label.call("setup", message, world_position, color)


func screen_shake(amount: float = 6.0, duration: float = 0.16) -> void:
	var scene: Node = get_tree().current_scene

	if scene != null and scene.has_method("add_screen_shake"):
		scene.call("add_screen_shake", amount, duration)


func _add_to_current_scene(node: Node) -> void:
	var scene: Node = get_tree().current_scene

	if scene == null:
		add_child(node)
		return

	scene.add_child(node)
