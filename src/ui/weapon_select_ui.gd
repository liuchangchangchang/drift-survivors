extends Control
## Starting weapon selection screen.

signal weapon_selected(weapon_id: String)

func _ready() -> void:
	_build_weapon_list()

func _build_weapon_list() -> void:
	var container := $ScrollContainer/VBoxContainer as VBoxContainer
	for child in container.get_children():
		if child.name != "Header":
			child.queue_free()

	for weapon_data in DataLoader.weapons:
		if not weapon_data.get("can_be_starting_weapon", false):
			continue
		var weapon_id: String = weapon_data.get("id", "")
		var weapon_name: String = weapon_data.get("name", "")
		var tiers: Array = weapon_data.get("tiers", [])
		var tier1: Dictionary = tiers[0] if tiers.size() > 0 else {}

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn := Button.new()
		btn.text = weapon_name
		btn.custom_minimum_size = Vector2(200, 60)
		btn.pressed.connect(_on_weapon_pressed.bind(weapon_id))
		hbox.add_child(btn)

		var label := Label.new()
		label.text = "DMG:%d RATE:%.1f RNG:%d" % [
			int(tier1.get("damage", 0)),
			tier1.get("fire_rate", 0),
			int(tier1.get("range", 0)),
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		container.add_child(hbox)

func _on_weapon_pressed(weapon_id: String) -> void:
	weapon_selected.emit(weapon_id)
	GameManager.select_weapon(weapon_id)
