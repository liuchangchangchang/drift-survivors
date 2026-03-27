extends CanvasLayer
## In-game HUD showing HP, wave timer, materials, nitro gauge, weapon slots.

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var hp_label: Label = $TopBar/HPLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var timer_label: Label = $TopBar/TimerLabel
@onready var material_label: Label = $BottomBar/MaterialLabel
@onready var nitro_bar: ProgressBar = $BottomBar/NitroBar
@onready var speed_bar: ProgressBar = $BottomBar/SpeedBar
@onready var xp_bar: ProgressBar = $TopBar/XPBar

func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_timer_tick.connect(_on_timer_tick)
	EventBus.car_damaged.connect(_on_car_damaged)
	EventBus.car_healed.connect(_on_car_healed)
	EventBus.material_changed.connect(_on_material_changed)
	EventBus.nitro_gauge_changed.connect(_on_nitro_changed)

func _on_wave_started(wave: int) -> void:
	if wave_label:
		wave_label.text = "Wave %d/20" % wave

func _on_timer_tick(time_remaining: float) -> void:
	if timer_label:
		var minutes := int(time_remaining) / 60
		var seconds := int(time_remaining) % 60
		timer_label.text = "%d:%02d" % [minutes, seconds]

func _on_car_damaged(_amount: float, _source: Node3D) -> void:
	_update_hp()

func _on_car_healed(_amount: float) -> void:
	_update_hp()

func _on_material_changed(total: int) -> void:
	if material_label:
		material_label.text = "Materials: %d" % total

func _on_nitro_changed(normalized: float) -> void:
	if nitro_bar:
		nitro_bar.value = normalized * 100.0

func update_hp(current: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current
	if hp_label:
		hp_label.text = "%d/%d" % [int(current), int(max_hp)]

func update_speed(normalized: float) -> void:
	if speed_bar:
		speed_bar.value = normalized * 100.0

func update_xp(progress: float) -> void:
	if xp_bar:
		xp_bar.value = progress * 100.0

func _update_hp() -> void:
	# Will be called by game arena with actual car reference
	pass
