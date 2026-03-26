extends Control
## Car selection screen. Shows available cars with stats preview.

signal car_selected(car_id: String)

var car_buttons: Array[Button] = []

func _ready() -> void:
	_build_car_list()

func _build_car_list() -> void:
	var container := $ScrollContainer/VBoxContainer as VBoxContainer
	# Clear existing children (except header)
	for child in container.get_children():
		if child.name != "Header":
			child.queue_free()

	for car_data in DataLoader.cars:
		var car_id: String = car_data.get("id", "")
		var car_name: String = car_data.get("name", "")
		var stats: Dictionary = car_data.get("base_stats", {})

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn := Button.new()
		btn.text = car_name
		btn.custom_minimum_size = Vector2(200, 60)
		btn.pressed.connect(_on_car_pressed.bind(car_id))
		car_buttons.append(btn)
		hbox.add_child(btn)

		# Stats label
		var label := Label.new()
		label.text = "HP:%d SPD:%d POW:%d NITRO:%d SLOTS:%d" % [
			int(stats.get("max_hp", 0)),
			int(stats.get("max_speed", 0)),
			int(stats.get("engine_power", 0)),
			int(stats.get("nitro_max", 0)),
			int(stats.get("weapon_slots", 4)),
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		container.add_child(hbox)

func _on_car_pressed(car_id: String) -> void:
	car_selected.emit(car_id)
	GameManager.select_car(car_id)
