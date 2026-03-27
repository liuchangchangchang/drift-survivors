class_name LootMagnet
extends Area3D
## Auto-collects nearby loot drops. Attach to the player car.

@export var base_range: float = 5.0
var range_multiplier: float = 1.0

func _ready() -> void:
	_update_collision_shape()
	area_entered.connect(_on_area_entered)

func _update_collision_shape() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
	var shape := SphereShape3D.new()
	shape.radius = base_range * range_multiplier
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

func set_range_multiplier(mult: float) -> void:
	range_multiplier = mult
	_update_collision_shape()

func _on_area_entered(area: Area3D) -> void:
	if area is LootDrop:
		area.collect()
