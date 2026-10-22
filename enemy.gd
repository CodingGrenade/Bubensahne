class_name Enemy
extends Area2D

signal died(death_position: Vector2, amount_xp: int)
signal touched_player(reason: String)

# Higher value = harder to displace. Remove entries for kinds you don't have.
const PUSH_PRIORITY := {
	Waves.EnemyKind.SWARM_BAT: 0,
	Waves.EnemyKind.SCOUT: 0,
	Waves.EnemyKind.SHOOTER: 1,
	Waves.EnemyKind.CHARGER: 1,
	Waves.EnemyKind.TANK: 2,
	Waves.EnemyKind.BOSS: 3,
}
const KIND_COLORS := {
	Waves.EnemyKind.SCOUT: Color.YELLOW,
	Waves.EnemyKind.TANK: Color.SKY_BLUE,
	Waves.EnemyKind.SHOOTER: Color.SALMON,
	Waves.EnemyKind.BOSS: Color.BLUE_VIOLET,
	Waves.EnemyKind.CHARGER: Color.DARK_ORANGE,
	Waves.EnemyKind.SWARM_BAT: Color.INDIGO,
}
const SHOOT_DISTANCE := 625.0
const DISPLAY_OFFSET := Vector2(0.0, -80.0)

@export var bullet_scene: PackedScene
@export var base_radius := 0.0

var kind: Waves.EnemyKind
var health: float
var max_health: float
var speed: float
var amount_xp: float
var _stats: Dictionary
var _moving := true
var _is_dead := false
var _charge_state := 0          # 0 = walking, 1 = windup, 2 = dash
var _charge_timer := 0.0
var _dash_dir := Vector2.ZERO
var push_priority := 0

const CHARGE_INTERVAL := 3.0
const WINDUP_TIME := 0.6
const DASH_TIME := 1
const DASH_SPEED_FACTOR := 5

@onready var shot_cooldown: Timer = $ShotCooldown
@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_display: Label = $DamageDisplay
@onready var player: Node2D = get_tree().get_first_node_in_group("player")


## Vor add_child() aufrufen. Die Werte kommen aus Waves.pick_enemy().
func setup(stats: Dictionary) -> void:
	_stats = stats


func _ready() -> void:
	if _stats.is_empty():
		_stats = Waves.pick_enemy(1)  # Fallback, wenn die Szene allein mit F6 läuft
	_apply_stats()
	_measure_radius()
	push_priority = _stats.get("push_priority", PUSH_PRIORITY.get(kind, 1))
	add_to_group("enemy_body")
	damage_display.visible = false
	add_to_group("enemy")
	add_to_group("enemy_moving")
	polygon_2d.color.s = 0.5
	create_tween().tween_property(polygon_2d, "scale", Vector2.ONE, 0.2).from(Vector2(1.5, 1.5))
	_charge_timer = randf_range(1.0, CHARGE_INTERVAL)
func _measure_radius() -> void:
	if base_radius > 0.0:
		return
	base_radius = 40.0   # fallback
	for child in get_children():
		if child is CollisionShape2D and child.shape != null:
			var s: Shape2D = child.shape
			if s is CircleShape2D:
				base_radius = s.radius
			elif s is CapsuleShape2D:
				base_radius = maxf(s.radius, s.height / 2.0)
			elif s is RectangleShape2D:
				base_radius = maxf(s.size.x, s.size.y) / 2.0
			return


## Current radius including scale (bosses, and the shrink from taking damage).
func radius() -> float:
	return base_radius * absf(scale.x)


## True if this enemy must NOT be displaced by `other`.
func dominates(other: Enemy) -> bool:
	if push_priority != other.push_priority:
		return push_priority > other.push_priority
	return get_instance_id() < other.get_instance_id()

func _apply_stats() -> void:
	kind = _stats["kind"]
	health = _stats["health"]
	max_health = health
	speed = _stats["speed"]
	amount_xp = _stats["xp_amount"]
	scale *= _stats.get("scale", 1.0)
	health_bar.max_value = max_health
	health_bar.show_percentage = kind == Waves.EnemyKind.BOSS
	polygon_2d.color = KIND_COLORS[kind]



func _process(delta: float) -> void:
	health_bar.value = health
	match kind:
		Waves.EnemyKind.CHARGER: _process_charger(delta)
		_: _process_default(delta)

func _process_default(delta: float) -> void:
	look_at(player.global_position)
	if _moving:
		global_position += global_transform.x * speed * delta
	if shot_cooldown.is_stopped() and kind == Waves.EnemyKind.SHOOTER \
			and global_position.distance_to(player.global_position) <= SHOOT_DISTANCE:
		shot_cooldown.start(1)
		_moving = false
func _process_charger(delta: float) -> void:
	_charge_timer -= delta
	match _charge_state:
		0:  # walking
			look_at(player.global_position)
			global_position += global_transform.x * speed * delta
			if _charge_timer <= 0.0:
				_charge_state = 1
				_charge_timer = WINDUP_TIME
				polygon_2d.modulate = Color.RED       # warning
		1:  # aiming, standing still
			look_at(player.global_position)
			if _charge_timer <= 0.0:
				_charge_state = 2
				_charge_timer = DASH_TIME
				_dash_dir = global_transform.x        # direction is locked
		2:  # dash
			global_position += _dash_dir * speed * DASH_SPEED_FACTOR * delta
			if _charge_timer <= 0.0:
				_charge_state = 0
				_charge_timer = CHARGE_INTERVAL
				polygon_2d.modulate = Color.WHITE

func _on_shot_cooldown_timeout() -> void:
	var bullet := bullet_scene.instantiate() as Projectile
	add_child(bullet)
	bullet.add_to_group("enemy")
	bullet.add_to_group("enemy_bullet")
	bullet.global_transform = global_transform
	bullet.damage = 1
	bullet.timer.wait_time = 10
	bullet.collision_mask = 0
	bullet.collision_layer = 4
	bullet.apply_central_impulse(global_transform.x * 300.0)
	bullet.global_position.x += 35
	bullet.trail_pivot.visible = false
	bullet.set_color(Color.AQUA)
	_moving = true


func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if body is Projectile and not body.is_in_group("enemy"):
		_take_hit(body)
	elif body is CharacterBody2D:
		touched_player.emit("Enemy came too close for comfort")


func _take_hit(projectile: Projectile) -> void:
	var damage := projectile.damage
	projectile.on_hit()

	polygon_2d.modulate = Color.INDIAN_RED
	create_tween().tween_property(polygon_2d, "modulate", Color.WHITE, 0.1)

	health -= damage
	scale = scale * (0.9 + 0.1 * health / max_health)

	var display := damage_display.duplicate()
	get_tree().current_scene.add_child(display)
	display.show_damage(damage, global_position + DISPLAY_OFFSET)

	if health <= 0:
		_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	collision_mask = 0
	_play_death_sound()
	died.emit(global_position, amount_xp)
	queue_free()


func _play_death_sound() -> void:
	audio_stream_player_2d.reparent(get_tree().current_scene)
	audio_stream_player_2d.finished.connect(audio_stream_player_2d.queue_free)
	audio_stream_player_2d.play()
