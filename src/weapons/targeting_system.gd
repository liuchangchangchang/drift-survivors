class_name TargetingSystem
extends Node
## Finds the nearest enemy within range for weapon auto-targeting.

## Find the nearest enemy node within the given range from origin.
## Enemies must be in the "enemies" group.
static func find_nearest_enemy(origin: Vector2, weapon_range: float, tree: SceneTree) -> Node2D:
	if tree == null:
		return null
	var enemies := tree.get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := weapon_range * weapon_range  # Compare squared distances
	for enemy in enemies:
		if not enemy is Node2D:
			continue
		if not enemy.visible:
			continue
		# Skip dead enemies (if they have is_alive property)
		if "is_alive" in enemy and not enemy.is_alive:
			continue
		var dist_sq := origin.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist:
			nearest_dist = dist_sq
			nearest = enemy
	return nearest

## Find all enemies within range (for AoE weapons)
static func find_enemies_in_range(origin: Vector2, weapon_range: float, tree: SceneTree) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if tree == null:
		return result
	var enemies := tree.get_nodes_in_group("enemies")
	var range_sq := weapon_range * weapon_range
	for enemy in enemies:
		if not enemy is Node2D:
			continue
		if not enemy.visible:
			continue
		if "is_alive" in enemy and not enemy.is_alive:
			continue
		if origin.distance_squared_to(enemy.global_position) <= range_sq:
			result.append(enemy)
	return result
