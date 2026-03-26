extends Control
## Level-up upgrade choice screen. Shows 3 random upgrades.

signal upgrade_selected(upgrade: Dictionary)

var player_stats: PlayerStats
var _choices: Array[Dictionary] = []

@onready var choice_container: HBoxContainer = $Panel/VBoxContainer/ChoiceContainer
@onready var level_label: Label = $Panel/VBoxContainer/LevelLabel

func show_choices(level: int, choices: Array[Dictionary], stats: PlayerStats) -> void:
	player_stats = stats
	_choices = choices
	if level_label:
		level_label.text = "Level Up! (Level %d)" % level
	_build_choice_cards()
	visible = true
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
	card.custom_minimum_size = Vector2(250, 200)

	var vbox := VBoxContainer.new()

	var name_label := Label.new()
	name_label.text = upgrade.get("name", "???")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var rarity_label := Label.new()
	rarity_label.text = "[%s]" % upgrade.get("rarity", "common").to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(rarity_label)

	var desc_label := Label.new()
	desc_label.text = upgrade.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)

	var btn := Button.new()
	btn.text = "Choose"
	btn.custom_minimum_size = Vector2(0, 40)
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
	get_tree().paused = false
