class_name HitboxHurtbox
extends Area3D
## Reusable hitbox/hurtbox component.

@export var damage: float = 0.0
@export var is_hitbox: bool = true

signal hit(target: Node3D, amount: float)
signal hurt(amount: float, source: Node3D)

func _ready() -> void:
	if is_hitbox:
		area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if not is_hitbox:
		return
	if area is HitboxHurtbox and not area.is_hitbox:
		var target := area.get_parent()
		if target and target.has_method("take_damage"):
			target.take_damage(damage)
			hit.emit(target, damage)
			area.hurt.emit(damage, get_parent())
