extends Projectile

const MAX_TRAIL_LENGTH := 3.5
const TRAIL_GROW_SPEED := 6.0
const SNIPER_PIERCE := 3

var pierce := SNIPER_PIERCE


func _process(delta: float) -> void:
	if trail_pivot.scale.x < MAX_TRAIL_LENGTH:
		trail_pivot.scale.x += delta * TRAIL_GROW_SPEED


func on_hit() -> void:
	if weapon_type == GameState.WeaponType.SNIPER:
		pierce -= 1
		if pierce <= 0:
			queue_free()
	else:
		queue_free()
