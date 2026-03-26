class_name LevelUpManager
extends Node
## Manages XP thresholds and level-up upgrade choices.

signal level_up_ready(level: int, choices: Array[Dictionary])

var current_level: int = 0
var current_xp: int = 0
var xp_to_next_level: int = 10

const XP_BASE := 10
const XP_GROWTH := 1.15  # Each level needs 15% more XP

func _ready() -> void:
	EventBus.xp_gained.connect(_on_xp_gained)

func _on_xp_gained(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		_level_up()

func _level_up() -> void:
	current_level += 1
	xp_to_next_level = int(XP_BASE * pow(XP_GROWTH, current_level))
	var choices := _generate_choices()
	EventBus.level_up.emit(current_level)
	level_up_ready.emit(current_level, choices)

func _generate_choices(count: int = 3) -> Array[Dictionary]:
	var all_upgrades := DataLoader.upgrades.duplicate()
	all_upgrades.shuffle()
	var choices: Array[Dictionary] = []
	for upgrade in all_upgrades:
		if choices.size() >= count:
			break
		choices.append(upgrade)
	return choices

func apply_upgrade(upgrade: Dictionary, player_stats: PlayerStats) -> void:
	var upgrade_id: String = upgrade.get("id", "")
	var mods: Array = upgrade.get("stat_modifiers", [])
	player_stats.add_modifiers_from_dict_array(mods, "upgrade_" + upgrade_id)
	# +1 Max HP always on level up (Brotato style)
	var hp_mod := StatModifier.create("max_hp", "flat", 1.0, "level_up_%d" % current_level)
	player_stats.add_modifier(hp_mod)
	EventBus.upgrade_chosen.emit(upgrade_id)

func get_xp_progress() -> float:
	if xp_to_next_level <= 0:
		return 0.0
	return float(current_xp) / float(xp_to_next_level)

func reset() -> void:
	current_level = 0
	current_xp = 0
	xp_to_next_level = XP_BASE
