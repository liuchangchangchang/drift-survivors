class_name ItemScene
extends Node3D

@export var id: String = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var rarity: String = "common"
@export var base_price: int = 25
@export var max_stack: int = 10
@export var category: String = "utility"
@export var stat_modifiers: Array[StatModifierData] = []

func to_data_dict() -> Dictionary:
	var mods: Array = []
	for m in stat_modifiers:
		mods.append(m.to_dict())
	return {
		"id": id,
		"name": item_name,
		"description": description,
		"rarity": rarity,
		"base_price": base_price,
		"max_stack": max_stack,
		"category": category,
		"stat_modifiers": mods,
	}
