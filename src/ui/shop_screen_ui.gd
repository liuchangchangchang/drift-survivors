extends Control
## Between-wave shop screen. Shows 4 items to purchase with 3D previews.

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
		reroll_button.text = tr("SHOP_REROLL") % shop_manager.get_reroll_cost()
		reroll_button.disabled = not economy.can_afford(shop_manager.get_reroll_cost())
	if materials_label:
		materials_label.text = tr("SHOP_MATERIALS") % economy.materials

func _create_item_card(slot: int, item_data: Dictionary, price: int, locked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 350)
	# Card style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	var rarity: String = item_data.get("rarity", "common")
	style.border_color = _get_rarity_color(rarity)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	# 3D Preview
	var preview := Item3DPreview.new()
	preview.setup(item_data)
	preview.custom_minimum_size = Vector2(120, 100)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(preview)

	# Name
	var name_label := Label.new()
	name_label.text = item_data.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	vbox.add_child(name_label)

	# Rarity
	var rarity_label := Label.new()
	rarity_label.text = "[%s]" % rarity.to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(rarity))
	vbox.add_child(rarity_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(desc_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buy button
	var buy_btn := Button.new()
	buy_btn.text = tr("SHOP_BUY") % price
	buy_btn.custom_minimum_size = Vector2(0, 36)
	buy_btn.disabled = not economy.can_afford(price)
	buy_btn.add_theme_font_size_override("font_size", 14)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.35, 0.2, 1) if economy.can_afford(price) else Color(0.15, 0.15, 0.2, 1)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.3, 0.7, 0.4, 1)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_left = 5
	btn_style.corner_radius_bottom_right = 5
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.pressed.connect(_on_buy.bind(slot))
	vbox.add_child(buy_btn)

	# Lock button
	var lock_btn := Button.new()
	lock_btn.text = tr("SHOP_LOCKED") if locked else tr("SHOP_LOCK")
	lock_btn.custom_minimum_size = Vector2(0, 30)
	lock_btn.add_theme_font_size_override("font_size", 12)
	var lock_style := StyleBoxFlat.new()
	lock_style.bg_color = Color(0.25, 0.2, 0.05, 1) if locked else Color(0.1, 0.1, 0.15, 1)
	lock_style.corner_radius_top_left = 4
	lock_style.corner_radius_top_right = 4
	lock_style.corner_radius_bottom_left = 4
	lock_style.corner_radius_bottom_right = 4
	lock_btn.add_theme_stylebox_override("normal", lock_style)
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
	# Free all item cards (and their SubViewport previews) to prevent rendering leaks
	if item_container:
		for child in item_container.get_children():
			child.queue_free()
	visible = false
	shop_closed.emit()

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.6, 0.6, 0.7)
		"uncommon": return Color(0.2, 0.8, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"legendary": return Color(1.0, 0.7, 0.1)
	return Color(0.6, 0.6, 0.7)
