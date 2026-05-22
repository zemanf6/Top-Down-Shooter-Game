extends Node
class_name UpgradeManager

signal xp_changed(current_xp: int, required_xp: int, level: int)
signal upgrade_choices_ready(choices: Array[Resource])
signal infusion_applied(infusion: PlayerInfusion, locked_upgrade_ids: Array[String])

@export var base_required_xp: int = 18
@export var required_xp_growth: int = 10
@export var choices_per_level: int = 3

var level: int = 1
var current_xp: int = 0
var required_xp: int = 18
var pending_upgrade_choices: int = 0
var is_waiting_for_choice: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var stacks_by_upgrade_id: Dictionary = {}
var locked_upgrade_ids: Dictionary = {}

var available_upgrades: Array[PlayerUpgrade] = []
var upgrades_by_id: Dictionary = {}
var max_stack_by_upgrade_id: Dictionary = {}

var infusion_manager: InfusionManager


func _ready() -> void:
	rng.randomize()

	required_xp = base_required_xp

	_create_upgrade_pool()
	_create_infusion_manager()

	xp_changed.emit(current_xp, required_xp, level)


func _create_upgrade_pool() -> void:
	available_upgrades = [
		MaxHealthUpgrade.new(),
		DamageUpgrade.new(),
		FireRateUpgrade.new(),
		MovementSpeedUpgrade.new(),
		ProjectileSpeedUpgrade.new(),
		MultiShotUpgrade.new()
	]

	upgrades_by_id.clear()
	max_stack_by_upgrade_id.clear()

	for upgrade in available_upgrades:
		upgrades_by_id[upgrade.id] = upgrade
		max_stack_by_upgrade_id[upgrade.id] = upgrade.max_stack


func _create_infusion_manager() -> void:
	infusion_manager = InfusionManager.new()
	infusion_manager.name = "InfusionManager"
	add_child(infusion_manager)

	infusion_manager.infusion_applied.connect(_on_infusion_applied)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount

	while current_xp >= required_xp:
		current_xp -= required_xp
		level += 1
		required_xp += required_xp_growth
		pending_upgrade_choices += 1

	xp_changed.emit(current_xp, required_xp, level)
	_try_emit_upgrade_choices()


func force_upgrade_choice() -> void:
	pending_upgrade_choices += 1
	_try_emit_upgrade_choices()


func apply_choice(choice: Resource, player: Player) -> void:
	if choice is PlayerUpgrade:
		_apply_regular_upgrade(choice as PlayerUpgrade, player)
		return

	if choice is PlayerInfusion:
		_apply_infusion(choice as PlayerInfusion, player)
		return

	is_waiting_for_choice = false
	_try_emit_upgrade_choices()


func _apply_regular_upgrade(upgrade: PlayerUpgrade, player: Player) -> void:
	if upgrade == null:
		return

	if not can_apply_upgrade(upgrade.id):
		is_waiting_for_choice = false
		_try_emit_upgrade_choices()
		return

	upgrade.apply(player)

	var current_stack_count: int = get_upgrade_stack(upgrade.id)
	stacks_by_upgrade_id[upgrade.id] = current_stack_count + 1

	is_waiting_for_choice = false
	xp_changed.emit(current_xp, required_xp, level)

	if pending_upgrade_choices > 0:
		call_deferred("_try_emit_upgrade_choices")


func _apply_infusion(infusion: PlayerInfusion, player: Player) -> void:
	if infusion == null:
		return

	if not infusion.can_be_offered(
		stacks_by_upgrade_id,
		max_stack_by_upgrade_id,
		locked_upgrade_ids
	):
		is_waiting_for_choice = false
		_try_emit_upgrade_choices()
		return

	infusion_manager.apply_infusion(player, infusion, locked_upgrade_ids)

	is_waiting_for_choice = false
	xp_changed.emit(current_xp, required_xp, level)

	if pending_upgrade_choices > 0:
		call_deferred("_try_emit_upgrade_choices")


func can_apply_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_locked(upgrade_id):
		return false

	if is_upgrade_maxed(upgrade_id):
		return false

	return true


func is_upgrade_locked(upgrade_id: String) -> bool:
	return bool(locked_upgrade_ids.get(upgrade_id, false))


func is_upgrade_maxed(upgrade_id: String) -> bool:
	var current_stack_count: int = get_upgrade_stack(upgrade_id)
	var max_stack: int = int(max_stack_by_upgrade_id.get(upgrade_id, 0))

	if max_stack <= 0:
		return true

	return current_stack_count >= max_stack


func get_upgrade_stack(upgrade_id: String) -> int:
	return int(stacks_by_upgrade_id.get(upgrade_id, 0))


func has_pending_choice() -> bool:
	return is_waiting_for_choice or pending_upgrade_choices > 0


func _try_emit_upgrade_choices() -> void:
	if is_waiting_for_choice:
		return

	if pending_upgrade_choices <= 0:
		return

	var choices: Array[Resource] = _get_random_choices(choices_per_level)

	if choices.is_empty():
		pending_upgrade_choices = 0
		return

	pending_upgrade_choices -= 1
	is_waiting_for_choice = true
	upgrade_choices_ready.emit(choices)


func _get_random_choices(count: int) -> Array[Resource]:
	var pool: Array[Resource] = []

	var regular_upgrades: Array[PlayerUpgrade] = _get_available_regular_upgrades()
	var available_infusions: Array[PlayerInfusion] = infusion_manager.get_available_infusions(
		stacks_by_upgrade_id,
		max_stack_by_upgrade_id,
		locked_upgrade_ids
	)

	regular_upgrades.shuffle()
	available_infusions.shuffle()

	for infusion in available_infusions:
		pool.append(infusion)

	for upgrade in regular_upgrades:
		pool.append(upgrade)

	var result: Array[Resource] = []
	var max_count: int = mini(count, pool.size())

	for index in range(max_count):
		result.append(pool[index])

	return result


func _get_available_regular_upgrades() -> Array[PlayerUpgrade]:
	var result: Array[PlayerUpgrade] = []

	for upgrade in available_upgrades:
		if not can_apply_upgrade(upgrade.id):
			continue

		result.append(upgrade)

	return result


func get_progress_summary_lines() -> PackedStringArray:
	var lines: PackedStringArray = []

	lines.append("UPGRADY")

	for upgrade in available_upgrades:
		var stack_count: int = get_upgrade_stack(upgrade.id)
		var max_stack: int = int(max_stack_by_upgrade_id.get(upgrade.id, upgrade.max_stack))
		var suffix: String = ""

		if is_upgrade_locked(upgrade.id):
			suffix = "  [UZAMČENO]"

		lines.append("%s: %d / %d%s" % [
			upgrade.title,
			stack_count,
			max_stack,
			suffix
		])

	lines.append("")
	lines.append("INFUZE")

	var has_any_infusion: bool = false

	for infusion in infusion_manager.infusions:
		if infusion.applied:
			has_any_infusion = true
			lines.append("✓ %s" % infusion.title)

	if not has_any_infusion:
		lines.append("Žádná infuze zatím není aktivní.")

	return lines


func _on_infusion_applied(
	infusion: PlayerInfusion,
	infusion_locked_upgrade_ids: Array[String]
) -> void:
	infusion_applied.emit(infusion, infusion_locked_upgrade_ids)
