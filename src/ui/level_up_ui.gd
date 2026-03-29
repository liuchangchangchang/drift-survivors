extends Control
## Level-up upgrade choice screen. Shows 3 random upgrades with 3D previews.

signal upgrade_selected(upgrade: Dictionary)

var player_stats: PlayerStats
var _choices: Array[Dictionary] = []

@onready var choice_container: HBoxContainer = $Panel/VBoxContainer/ChoiceContainer
@onready var level_label: Label = $Panel/VBoxContainer/LevelLabel

func show_choices(level: int, choices: Array[Dictionary], stats: PlayerStats) -> void:
	player_stats = stats
	_choices = choices
	if level_label:
		level_label.text = tr("LEVELUP_TITLE") % level
	_build_choice_cards()
	visible = true
	if get_tree():
		get_tree().paused = true

func _build_choice_cards() -> void:
	if choice_container == null:
		return
	for child in choice_container.get_children():
		child.queue_free()
	for i in _choices.size():
		var upgrade: Dictionary = _choices[i]
		var card := _create_choice_card(i, upgrade)
		choice_container.add_child(card)

func _create_choice_card(index: int, upgrade: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 320)
	# Card style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	var rarity: String = upgrade.get("rarity", "common")
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
	vbox.add_theme_constant_override("separation", 8)

	# 3D Preview
	var preview := Item3DPreview.new()
	preview.setup(upgrade)
	preview.custom_minimum_size = Vector2(120, 100)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(preview)

	# Name
	var name_label := Label.new()
	name_label.text = upgrade.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	vbox.add_child(name_label)

	# Rarity
	var rarity_label := Label.new()
	rarity_label.text = "[%s]" % rarity.to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", _get_rarity_color(rarity))
	vbox.add_child(rarity_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = upgrade.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(desc_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Choose button
	var btn := Button.new()
	btn.text = tr("LEVELUP_CHOOSE")
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 16)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.35, 0.2, 1)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.3, 0.7, 0.4, 1)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.15, 0.5, 0.3, 1)
	btn.add_theme_stylebox_override("hover", btn_hover)
	btn.pressed.connect(_on_choice.bind(index))
	vbox.add_child(btn)

	card.add_child(vbox)
	return card

func _on_choice(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	var upgrade := _choices[index]
	upgrade_selected.emit(upgrade)
	visible = false
	if get_tree():
		get_tree().paused = false

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.6, 0.6, 0.7)
		"uncommon": return Color(0.2, 0.8, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"legendary": return Color(1.0, 0.7, 0.1)
	return Color(0.6, 0.6, 0.7)
