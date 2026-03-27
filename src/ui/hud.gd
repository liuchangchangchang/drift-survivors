extends CanvasLayer
## In-game HUD with styled panels.

@onready var hp_bar: ProgressBar = $TopBar/HBox/HPBar
@onready var hp_label: Label = $TopBar/HBox/HPLabel
@onready var wave_label: Label = $TopBar/HBox/WaveLabel
@onready var timer_label: Label = $TopBar/HBox/TimerLabel
@onready var material_label: Label = $BottomBar/HBox/MaterialLabel
@onready var nitro_bar: ProgressBar = $BottomBar/HBox/NitroBar
@onready var speed_bar: ProgressBar = $BottomBar/HBox/SpeedBar
@onready var xp_bar: ProgressBar = $TopBar/HBox/XPBar
@onready var drift_charge_bar: ProgressBar = $BottomBar/HBox/DriftChargeBar

func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_timer_tick.connect(_on_timer_tick)
	EventBus.car_damaged.connect(_on_car_damaged)
	EventBus.car_healed.connect(_on_car_healed)
	EventBus.material_changed.connect(_on_material_changed)
	EventBus.nitro_gauge_changed.connect(_on_nitro_changed)
	EventBus.drift_charge_changed.connect(_on_drift_charge_changed)

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
		material_label.text = "%d" % total

func _on_nitro_changed(normalized: float) -> void:
	if nitro_bar:
		nitro_bar.value = normalized * 100.0

func _on_drift_charge_changed(normalized: float) -> void:
	if drift_charge_bar:
		drift_charge_bar.value = normalized * 100.0
		if normalized >= 1.0:
			drift_charge_bar.modulate = Color(1.0, 0.8, 0.0)
		elif normalized >= 0.5:
			drift_charge_bar.modulate = Color(0.3, 0.8, 1.0)
		else:
			drift_charge_bar.modulate = Color.WHITE

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
	pass
