class_name WeaponMount
extends Marker2D
## A single weapon slot on the car. Holds one WeaponBase.

var weapon: WeaponBase = null
var slot_index: int = 0

func equip(new_weapon: WeaponBase) -> WeaponBase:
	var old_weapon := weapon
	if old_weapon:
		remove_child(old_weapon)
	weapon = new_weapon
	if weapon:
		add_child(weapon)
		weapon.position = Vector2.ZERO
		EventBus.weapon_equipped.emit(slot_index, weapon.data.id)
	return old_weapon

func unequip() -> WeaponBase:
	var old_weapon := weapon
	if weapon:
		remove_child(weapon)
		EventBus.weapon_unequipped.emit(slot_index)
	weapon = null
	return old_weapon

func is_empty() -> bool:
	return weapon == null

func get_weapon_id() -> String:
	if weapon and weapon.data:
		return weapon.data.id
	return ""

func get_weapon_tier() -> int:
	if weapon and weapon.data:
		return weapon.data.tier
	return 0
