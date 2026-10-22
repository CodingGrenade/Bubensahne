extends Projectile

const EXPLOSION_SCALE := 5.0
const EXPLOSION_SHAPE_SCALE := 6.0
const EXPLOSION_DURATION := 1.0

@onready var explosion_particles: GPUParticles2D = $GPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _exploded := false


func _ready() -> void:
	weapon_type = GameState.WeaponType.RPG


func _process(delta: float) -> void:
	if _exploded:
		trail_pivot.scale = Vector2.ZERO
	else:
		trail_pivot.scale.x += delta


func on_hit() -> void:
	# Jeder Gegner in der wachsenden Explosion ruft on_hit() erneut auf,
	# die Explosion selbst darf aber nur einmal starten.
	if _exploded:
		return
	_exploded = true

	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * EXPLOSION_SCALE, EXPLOSION_DURATION)
	tween.tween_property(collision_shape, "scale", Vector2.ONE * EXPLOSION_SHAPE_SCALE, EXPLOSION_DURATION)

	explosion_particles.restart()
	body_polygon.visible = false
	linear_velocity = Vector2.ZERO

	await get_tree().create_timer(EXPLOSION_DURATION).timeout
	queue_free()
