class_name WeaponScene
extends Node3D

@export var id: String = ""
@export var weapon_name: String = ""
@export var type: String = "ranged"
@export var damage_type: String = "ranged"
@export var can_be_starting_weapon: bool = true
@export var tiers: Array[WeaponTierData] = []

func to_data_dict() -> Dictionary:
	var tiers_arr: Array = []
	for t in tiers:
		tiers_arr.append(t.to_dict())
	return {
		"id": id,
		"name": weapon_name,
		"type": type,
		"damage_type": damage_type,
		"can_be_starting_weapon": can_be_starting_weapon,
		"tiers": tiers_arr,
	}
