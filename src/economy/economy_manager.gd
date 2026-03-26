class_name EconomyManager
extends Node
## Tracks player's material (currency + XP) count.

var materials: int = 0

func add_materials(amount: int) -> void:
	materials += amount
	EventBus.material_changed.emit(materials)

func spend_materials(amount: int) -> bool:
	if materials < amount:
		return false
	materials -= amount
	EventBus.material_spent.emit(amount)
	EventBus.material_changed.emit(materials)
	return true

func can_afford(amount: int) -> bool:
	return materials >= amount

func reset() -> void:
	materials = 0
	EventBus.material_changed.emit(0)
