extends CharacterBody2D

signal hit(reason: String)

func _ready() -> void:
	_build_weapon_slots()

	print("Hello world!")
	await get_tree().create_timer(3).timeout
	enemy_initialized = true

	print("Hello world!")
	await get_tree().create_timer(3).timeout
	enemy_initialized = true

const WEAPON_SCALE := 0.2
const PULL_SPEED := 700.0
@export var rifle: WeaponData
@export var sniper: WeaponData
@export var rpg: WeaponData
@export var shotgun: WeaponData

@onready var shotgun_cooldown := _make_cooldown_timer()
@onready var rifle_cooldown: Timer = $RifleCooldown
@onready var sniper_cooldown: Timer = $SniperCooldown
@onready var rpg_cooldown: Timer = $RpgCooldown
@onready var enemy_initialized := false
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var area_2d: Area2D = $Area2D
@onready var sprite: Sprite2D = $PlayerSprite
var target: Node2D
var weapon_slots := {}

signal weapon_fired(weapon: GameState.WeaponType, cooldown: float)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D && body.is_in_group("enemy_bullet"):
		body.queue_free()
		hit.emit("Hit by bullet")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func get_closest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_distance := INF
	for enemy: Node2D in get_tree().get_nodes_in_group("enemy_moving"):
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_distance:
			closest = enemy
			closest_distance = dist
	return closest


func _process(_delta: float) -> void:
	target = get_closest_enemy()
	if target == null:
		_aim_weapons(get_global_mouse_position())
		return

	_aim_weapons(target.global_position)
	var distance := global_position.distance_to(target.global_position)
	_try_fire(rifle, rifle_cooldown, distance)
	_try_fire(sniper, sniper_cooldown, distance)
	_try_fire(rpg, rpg_cooldown, distance)
	_try_fire(shotgun, shotgun_cooldown, distance)

func _attract_xp(delta: float) -> void:
	for orb: Node2D in get_tree().get_nodes_in_group("xp"):
		if global_position.distance_to(orb.global_position) < GameState.pickup_range:
			orb.global_position = orb.global_position.move_toward(global_position, PULL_SPEED * delta)


func _try_fire(weapon: WeaponData, cooldown_timer: Timer, distance: float) -> void:
	if not GameState.is_unlocked(weapon.weapon_type):
		return
	if distance >= GameState.attack_range * weapon.range_factor:
		return
	if not cooldown_timer.is_stopped():
		return

	var cooldown := weapon.cooldown * GameState.weapon_cooldown_factor(weapon.weapon_type)
	cooldown_timer.start(cooldown)
	weapon_fired.emit(weapon.weapon_type, cooldown)

	var parts: Dictionary = weapon_slots[weapon.weapon_type]
	var slot: Node2D = parts["slot"]
	var weapon_muzzle: Marker2D = parts["muzzle"]
	var count := maxi(weapon.pellets, 1)
	var spread := deg_to_rad(weapon.spread_degrees)
	var fired: Array[Projectile] = []

	for i in count:
		var angle_offset := 0.0
		if count > 1:
			angle_offset = spread * (float(i) / (count - 1) - 0.5)   # gleichmäßiger Fächer
			angle_offset += randf_range(-0.15, 0.15) * spread         # leichte Zufallsstreuung
		var spawn := Transform2D(slot.global_rotation + angle_offset, weapon_muzzle.global_position)

		var projectile := weapon.projectile_scene.instantiate() as Projectile
		add_child(projectile)
		projectile.setup(weapon, spawn)

		# Schrotkugeln starten an derselben Stelle und dürfen sich nicht gegenseitig wegstoßen
		for other in fired:
			projectile.add_collision_exception_with(other)
			other.add_collision_exception_with(projectile)
		fired.append(projectile)

	audio_stream_player_2d.play()

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if direction.x != 0:
		var facing_left := direction.x < 0
		sprite.flip_h = facing_left
		area_2d.scale.x = -1.0 if facing_left else 1.0   # only needed if your hitbox is asymmetric

	velocity = direction.normalized() * GameState.speed
	move_and_slide()
	_attract_xp(delta)

func _build_weapon_slots() -> void:
	# size = Bildgröße, tip = Mündung im Bild (px), tilt = leichte Schräglage im Bild (Grad),
	# offset = Position der Waffe relativ zum Spieler
	var visuals := {
		GameState.WeaponType.RIFLE: {
			"texture": "res://weapons/rifle.png",
			"size": Vector2(297, 224), "tip": Vector2(296, 52),
			"tilt": 0.0, "offset": Vector2(60, 30),
		},
		GameState.WeaponType.SNIPER: {
			"texture": "res://weapons/sniper.png",
			"size": Vector2(598, 199), "tip": Vector2(597, 51.5),
			"tilt": 7.0, "offset": Vector2(-60, -50),
		},
		GameState.WeaponType.RPG: {
			"texture": "res://weapons/rpg.png",
			"size": Vector2(569, 202), "tip": Vector2(568, 45),
			"tilt": 7.0, "offset": Vector2(-55, 55),
		},
		GameState.WeaponType.SHOTGUN: {
			"texture": "res://weapons/shotgun.png",
			"size": Vector2(613, 117), "tip": Vector2(400, 20.5),
			"tilt": 0.0, "offset": Vector2(65, -45),
		},
	}

	for type in visuals:
		var v: Dictionary = visuals[type]
		var tilt := deg_to_rad(v["tilt"])

		var slot := Node2D.new()
		slot.position = v["offset"]
		slot.visible = GameState.is_unlocked(type)
		add_child(slot)

		var sprite_node := Sprite2D.new()
		sprite_node.texture = load(v["texture"])
		sprite_node.scale = Vector2.ONE * WEAPON_SCALE
		sprite_node.rotation = tilt          # gleicht die Schräglage im Bild aus
		slot.add_child(sprite_node)

		var weapon_muzzle := Marker2D.new()
		weapon_muzzle.position = (v["tip"] - v["size"] / 2.0).rotated(tilt) * WEAPON_SCALE
		slot.add_child(weapon_muzzle)

		weapon_slots[type] = {"slot": slot, "muzzle": weapon_muzzle}

	GameState.weapon_unlocked.connect(
		func(weapon: GameState.WeaponType) -> void:
			weapon_slots[weapon]["slot"].visible = true
	)

func _make_cooldown_timer() -> Timer:
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	return t

func _aim_weapons(aim_point: Vector2) -> void:
	for type in weapon_slots:
		var slot: Node2D = weapon_slots[type]["slot"]
		if not slot.visible:
			continue
		var angle := (aim_point - slot.global_position).angle()
		slot.rotation = angle
		slot.scale.y = -1.0 if absf(angle) > PI / 2.0 else 1.0   # nach links: spiegeln
