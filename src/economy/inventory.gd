class_name Inventory
extends RefCounted
## Tracks the player's owned items with stack counts.

var items: Dictionary = {}  # item_id -> count

func add_item(item_id: String) -> bool:
	var item_data := DataLoader.get_item_data(item_id)
	if item_data.is_empty():
		return false
	var max_stack := int(item_data.get("max_stack", 99))
	var current: int = items.get(item_id, 0)
	if current >= max_stack:
		return false
	items[item_id] = current + 1
	return true

func get_count(item_id: String) -> int:
	return items.get(item_id, 0)

func has_item(item_id: String) -> bool:
	return items.get(item_id, 0) > 0

func remove_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	items[item_id] -= 1
	if items[item_id] <= 0:
		items.erase(item_id)
	return true

func get_all_items() -> Dictionary:
	return items.duplicate()

func clear() -> void:
	items.clear()

func get_total_item_count() -> int:
	var total := 0
	for count in items.values():
		total += count
	return total
