extends Resource
class_name PlayerInfusion

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var required_upgrade_ids: Array[String] = []

var applied: bool = false


func can_be_offered(
	stacks_by_upgrade_id: Dictionary,
	max_stack_by_upgrade_id: Dictionary,
	locked_upgrade_ids: Dictionary
) -> bool:
	if applied:
		return false

	if required_upgrade_ids.size() != 2:
		return false

	for upgrade_id in required_upgrade_ids:
		if bool(locked_upgrade_ids.get(upgrade_id, false)):
			return false

		var current_stack: int = int(stacks_by_upgrade_id.get(upgrade_id, 0))
		var required_stack: int = int(max_stack_by_upgrade_id.get(upgrade_id, 0))

		if required_stack <= 0:
			return false

		if current_stack < required_stack:
			return false

	return true


func apply(_player: Player) -> void:
	pass
