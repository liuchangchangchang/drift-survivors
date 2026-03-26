class_name ShopManager
extends RefCounted
## Generates shop offerings and handles purchases.

var current_items: Array[Dictionary] = []
var reroll_count: int = 0

## Generate 4 random shop items for the given wave
func generate_shop(wave: int, luck: float = 0.0) -> Array[Dictionary]:
	current_items.clear()
	reroll_count = 0
	var weights := WaveDifficulty.get_rarity_weights(wave)

	for i in 4:
		var item := _pick_random_item(weights, luck)
		if item.is_empty():
			continue
		var price := _calculate_price(item, wave)
		current_items.append({
			"item_data": item,
			"price": price,
			"slot": i,
			"locked": false,
		})
	return current_items

## Try to purchase an item at the given slot index.
func try_purchase(slot: int, economy: EconomyManager, inventory: Inventory, player_stats: PlayerStats) -> bool:
	if slot < 0 or slot >= current_items.size():
		return false
	var entry: Dictionary = current_items[slot]
	var price: int = entry.get("price", 0)
	if not economy.can_afford(price):
		return false
	var item_data: Dictionary = entry.get("item_data", {})
	var item_id: String = item_data.get("id", "")
	if not inventory.add_item(item_id):
		return false  # Max stack reached
	economy.spend_materials(price)
	# Apply stat modifiers
	var mods: Array = item_data.get("stat_modifiers", [])
	player_stats.add_modifiers_from_dict_array(mods, item_id)
	EventBus.item_purchased.emit(item_id)
	# Remove from shop
	current_items.remove_at(slot)
	return true

## Reroll the shop (costs materials)
func reroll(wave: int, luck: float, economy: EconomyManager) -> Array[Dictionary]:
	var cost := get_reroll_cost()
	if not economy.spend_materials(cost):
		return current_items
	reroll_count += 1
	# Keep locked items, regenerate unlocked ones
	var locked: Array[Dictionary] = []
	for entry in current_items:
		if entry.get("locked", false):
			locked.append(entry)
	current_items = locked
	var weights := WaveDifficulty.get_rarity_weights(wave)
	var needed := 4 - current_items.size()
	for i in needed:
		var item := _pick_random_item(weights, luck)
		if item.is_empty():
			continue
		var price := _calculate_price(item, wave)
		current_items.append({
			"item_data": item,
			"price": price,
			"slot": current_items.size(),
			"locked": false,
		})
	return current_items

func get_reroll_cost() -> int:
	var base: int = int(DataLoader.shop_pricing.get("base_reroll_cost", 5))
	var increment: int = int(DataLoader.shop_pricing.get("reroll_cost_increment", 2))
	return base + reroll_count * increment

func toggle_lock(slot: int) -> void:
	if slot >= 0 and slot < current_items.size():
		current_items[slot]["locked"] = not current_items[slot].get("locked", false)

func _pick_random_item(weights: Dictionary, luck: float) -> Dictionary:
	var rarity := ItemRarity.pick_rarity(weights, luck)
	var pool := ItemRarity.get_items_by_rarity(rarity)
	if pool.is_empty():
		pool = ItemRarity.get_items_by_rarity("common")
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]

func _calculate_price(item: Dictionary, wave: int) -> int:
	var base_price: float = item.get("base_price", 25)
	var wave_mult: float = DataLoader.shop_pricing.get("price_multiplier_per_wave", 1.08)
	return int(base_price * pow(wave_mult, wave - 1))
