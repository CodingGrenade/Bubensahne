class_name EnemySeparation
extends Node

const MAX_OVERLAP := 0.2    # share of the smaller enemy's diameter that may overlap
const CELL_SIZE := 220.0    # should be >= the biggest possible (radius A + radius B)
const SIDESTEP := 0.35      # small sideways bias so enemies slide around blockers


func _physics_process(_delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemy_body")
	if enemies.size() < 2:
		return

	# Spatial grid: only compare enemies in neighbouring cells
	var grid := {}
	for e in enemies:
		var key := Vector2i((e.global_position / CELL_SIZE).floor())
		if not grid.has(key):
			grid[key] = []
		grid[key].append(e)

	for e in enemies:
		var cell := Vector2i((e.global_position / CELL_SIZE).floor())
		var correction := Vector2.ZERO

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var bucket = grid.get(cell + Vector2i(dx, dy))
				if bucket == null:
					continue
				for o in bucket:
					if o == e or not o.dominates(e):
						continue   # only yield to enemies that outrank me

					var ra: float = e.radius()
					var rb: float = o.radius()
					var min_dist := ra + rb - MAX_OVERLAP * 2.0 * minf(ra, rb)
					var diff: Vector2 = e.global_position - o.global_position
					var dist := diff.length()
					if dist >= min_dist:
						continue

					var dir := diff / dist if dist > 0.001 else Vector2.from_angle(randf() * TAU)
					var side := 1.0 if e.get_instance_id() % 2 == 0 else -1.0
					dir = (dir + dir.orthogonal() * side * SIDESTEP).normalized()
					correction += dir * (min_dist - dist)

		if correction != Vector2.ZERO:
			e.global_position += correction
