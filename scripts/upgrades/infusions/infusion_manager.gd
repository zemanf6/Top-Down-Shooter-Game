extends Node
class_name InfusionManager

signal infusion_applied(infusion: PlayerInfusion, locked_upgrade_ids: Array[String])

var infusions: Array[PlayerInfusion] = []


func _ready() -> void:
	_create_infusions()


func _create_infusions() -> void:
	infusions = [
		RailgunInfusion.new(),
		BulletStormInfusion.new(),
		BerserkerHeartInfusion.new(),
		PhantomVelocityInfusion.new(),
		AdrenalineEngineInfusion.new(),
		JuggernautBarrageInfusion.new()
	]


func get_available_infusions(
	stacks_by_upgrade_id: Dictionary,
	max_stack_by_upgrade_id: Dictionary,
	locked_upgrade_ids: Dictionary
) -> Array[PlayerInfusion]:
	var available_infusions: Array[PlayerInfusion] = []

	for infusion in infusions:
		if infusion.can_be_offered(
			stacks_by_upgrade_id,
			max_stack_by_upgrade_id,
			locked_upgrade_ids
		):
			available_infusions.append(infusion)

	return available_infusions


func apply_infusion(
	player: Player,
	infusion: PlayerInfusion,
	locked_upgrade_ids: Dictionary
) -> void:
	if infusion == null:
		return

	if infusion.applied:
		return

	infusion.apply(player)
	infusion.applied = true

	for upgrade_id in infusion.required_upgrade_ids:
		locked_upgrade_ids[upgrade_id] = true

	infusion_applied.emit(infusion, infusion.required_upgrade_ids)
