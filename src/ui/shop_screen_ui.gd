extends Control
## Between-wave shop screen. Shows 4 items to purchase, reroll, and continue.

signal shop_closed

var shop_manager: ShopManager
var economy: EconomyManager
var inventory: Inventory
var player_stats: PlayerStats
var current_wave: int = 1

@onready var item_container: HBoxContainer = $Panel/VBoxContainer/ItemContainer
@onready var reroll_button: Button = $Panel/VBoxContainer/BottomBar/RerollButton
@onready var continue_button: Button = $Panel/VBoxContainer/BottomBar/ContinueButton
@onready var materials_label: Label = $Panel/VBoxContainer/BottomBar/MaterialsLabel

func _ready() -> void:
	if reroll_button:
		reroll_button.pressed.connect(_on_reroll)
	if continue_button:
		continue_button.pressed.connect(_on_continue)

func open_shop(wave: int, sm: ShopManager, econ: EconomyManager, inv: Inventory, stats: PlayerStats) -> void:
	shop_manager = sm
	economy = econ
	inventory = inv
	player_stats = stats
	current_wave = wave
	var luck := stats.get_stat("luck", 0.0)
	shop_manager.generate_shop(wave, luck)
	_refresh_display()
	visible = true

func _refresh_display() -> void:
	if item_container == null:
		return
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()

	for i in shop_manager.current_items.size():
		var entry: Dictionary = shop_manager.current_items[i]
		var item_data: Dictionary = entry.get("item_data", {})
		var price: int = entry.get("price", 0)
		var locked: bool = entry.get("locked", false)

		var card := _create_item_card(i, item_data, price, locked)
		item_container.add_child(card)

	if reroll_button:
		reroll_button.text = "Reroll (%d)" % shop_manager.get_reroll_cost()
		reroll_button.disabled = not economy.can_afford(shop_manager.get_reroll_cost())
	if materials_label:
		materials_label.text = "Materials: %d" % economy.materials

func _create_item_card(slot: int, item_data: Dictionary, price: int, locked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 300)

	var vbox := VBoxContainer.new()

	var name_label := Label.new()
	name_label.text = item_data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = "[%s]" % item_data.get("rarity", "common").to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	var desc_label := Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy (%d)" % price
	buy_btn.disabled = not economy.can_afford(price)
	buy_btn.pressed.connect(_on_buy.bind(slot))
	vbox.add_child(buy_btn)

	var lock_btn := Button.new()
	lock_btn.text = "Locked" if locked else "Lock"
	lock_btn.pressed.connect(_on_lock.bind(slot))
	vbox.add_child(lock_btn)

	card.add_child(vbox)
	return card

func _on_buy(slot: int) -> void:
	if shop_manager.try_purchase(slot, economy, inventory, player_stats):
		_refresh_display()

func _on_lock(slot: int) -> void:
	shop_manager.toggle_lock(slot)
	_refresh_display()

func _on_reroll() -> void:
	var luck := player_stats.get_stat("luck", 0.0)
	shop_manager.reroll(current_wave, luck, economy)
	_refresh_display()

func _on_continue() -> void:
	visible = false
	shop_closed.emit()
	GameManager.close_shop()
