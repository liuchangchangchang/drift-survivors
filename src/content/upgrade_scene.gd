class_name UpgradeScene
extends Node3D

@export var id: String = ""
@export var upgrade_name: String = ""
@export_multiline var description: String = ""
@export var rarity: String = "common"
@export var weight: float = 10.0
@export var stat_modifiers: Array[StatModifierData] = []

func to_data_dict() -> Dictionary:
	var mods: Array = []
	for m in stat_modifiers:
		mods.append(m.to_dict())
	return {
		"id": id,
		"name": upgrade_name,
		"description": description,
		"rarity": rarity,
		"weight": weight,
		"stat_modifiers": mods,
	}
