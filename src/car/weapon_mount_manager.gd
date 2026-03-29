class_name WeaponMountManager
extends Node3D
## Manages all weapon mount points on the car.

var mounts: Array[WeaponMount] = []
var max_slots: int = 4

const MOUNT_POSITIONS := [
	Vector3(1.2, 0.7, -0.75),   # Front-right
	Vector3(-1.2, 0.7, -0.75),  # Front-left
	Vector3(1.2, 0.7, 0.75),    # Rear-right
	Vector3(-1.2, 0.7, 0.75),   # Rear-left
	Vector3(0, 0.7, -1.25),     # Front center
	Vector3(0, 0.7, 1.0),       # Rear center
	Vector3(0.8, 0.9, 0),       # Top-right
	Vector3(-0.8, 0.9, 0),      # Top-left
]

func _ready() -> void:
	_create_mounts(max_slots)

func _create_mounts(count: int) -> void:
	for i in count:
		_add_mount_at(i)

func _add_mount_at(index: int) -> WeaponMount:
	var mount := WeaponMount.new()
	mount.slot_index = index
	if index < MOUNT_POSITIONS.size():
		mount.position = MOUNT_POSITIONS[index]
	else:
		# Generate position on a circle around the car
		var angle := TAU * float(index) / 8.0
		mount.position = Vector3(cos(angle) * 1.0, 0.9, sin(angle) * 0.8)
	mount.name = "Mount%d" % index
	add_child(mount)
	mounts.append(mount)
	return mount

func add_slot() -> bool:
	var new_index := mounts.size()
	_add_mount_at(new_index)
	max_slots += 1
	return true

func equip_weapon(weapon: WeaponBase) -> int:
	for i in mounts.size():
		if mounts[i].is_empty():
			mounts[i].equip(weapon)
			return i
	return -1

func equip_weapon_at(slot: int, weapon: WeaponBase) -> WeaponBase:
	if slot < 0 or slot >= mounts.size():
		return null
	return mounts[slot].equip(weapon)

func unequip_weapon_at(slot: int) -> WeaponBase:
	if slot < 0 or slot >= mounts.size():
		return null
	return mounts[slot].unequip()

func get_equipped_count() -> int:
	var count := 0
	for mount in mounts:
		if not mount.is_empty():
			count += 1
	return count

func get_slot_count() -> int:
	return mounts.size()

func get_empty_slot_count() -> int:
	return get_slot_count() - get_equipped_count()

func try_auto_merge() -> int:
	var merges := 0
	var merged := true
	while merged:
		merged = false
		for i in mounts.size():
			if mounts[i].is_empty():
				continue
			for j in range(i + 1, mounts.size()):
				if mounts[j].is_empty():
					continue
				if WeaponFactory.can_merge(mounts[i].weapon, mounts[j].weapon):
					var new_weapon := WeaponFactory.merge_weapons(
						mounts[i].weapon, mounts[j].weapon
					)
					if new_weapon:
						mounts[i].equip(new_weapon)
						mounts[j].unequip()
						merges += 1
						merged = true
						break
			if merged:
				break
	return merges

func get_weapon_summary() -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for mount in mounts:
		if not mount.is_empty():
			summary.append({
				"slot": mount.slot_index,
				"id": mount.get_weapon_id(),
				"tier": mount.get_weapon_tier(),
			})
	return summary
