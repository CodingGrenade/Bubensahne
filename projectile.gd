class_name Projectile
extends RigidBody2D

var weapon_type: GameState.WeaponType
var damage: float

@onready var body_polygon: Polygon2D = $Body
@onready var trail_pivot: Node2D = $Trail
@onready var trail_polygon: Polygon2D = $Trail/Polygon2D
@onready var timer: Timer = $Timer



func set_color(color: Color) -> void:
	body_polygon.color = color
	trail_polygon.color = color

func setup(weapon: WeaponData, spawn_transform: Transform2D) -> void:
	weapon_type = weapon.weapon_type
	damage = GameState.compute_damage(weapon.damage, weapon.scaling_factor)
	global_transform = spawn_transform
	scale = Vector2.ONE * weapon.projectile_scale
	set_color(weapon.color)
	apply_central_impulse(spawn_transform.x * weapon.impulse)
	if weapon.lifetime > 0.0:
		timer.start(weapon.lifetime)

func on_hit() -> void:
	queue_free()


func _on_timer_timeout() -> void:
	queue_free()
