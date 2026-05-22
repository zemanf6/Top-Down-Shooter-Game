extends Resource
class_name PlayerUpgrade

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var max_stack: int = 5


func apply(_player: Player) -> void:
	pass
