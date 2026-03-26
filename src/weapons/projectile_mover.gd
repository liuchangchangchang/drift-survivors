class_name ProjectileMover
extends Node
## Attached to Arena to move all projectile Area2D nodes each frame.

func _physics_process(delta: float) -> void:
	for child in get_parent().get_children():
		if child is Area2D and child.has_meta("speed"):
			var dir: Vector2 = child.get_meta("direction", Vector2.ZERO)
			var speed: float = child.get_meta("speed", 0.0)
			var range_left: float = child.get_meta("range_left", 0.0)
			child.position += dir * speed * delta
			range_left -= speed * delta
			child.set_meta("range_left", range_left)
			if range_left <= 0:
				child.queue_free()
