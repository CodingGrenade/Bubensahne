extends Node2D
@export var xp_scene: PackedScene
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound
@onready var timer: Timer = $WaveTimer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var score: Label = $CanvasLayer/Score2
@onready var death_message: Label = $CanvasLayer/Death
@export var enemy_scene: PackedScene
@onready var wave: int = 1
@onready var wave_label: Label = $CanvasLayer/Wave
@onready var spawning: bool = true
@onready var exists: int = 0
@onready var player_health := 3
@export var upgrade_screen_scene: PackedScene 
@onready var damage_particles: GPUParticles2D = $Spieler/DamageParticles

var kills := 0 
var hp_bar: ProgressBar
var hp_label: Label
var _invulnerable := false

const LEFTOVER_XP_FACTOR := 0.65
const STAT_SCREEN := preload("res://stat_screen.tscn")
const SHOP := preload("res://shop.tscn")

func _ready() -> void:
	death_message.visible = false
	wave_label.text = ("Wave: " + str(wave))
	add_child(EnemySeparation.new())
	_setup_hp_bar()
	GameState.hp_changed.connect(_update_hp_bar)
	
	$Spieler.hit.connect(damage_player)
	$WaveTimer.wait_time = Waves.length_of(wave)
	$WaveTimer.start()
	
	$EnemySpawnInterval.wait_time = Waves.spawn_interval_of(wave)
	$EnemySpawnInterval.start()


func _on_upgrade_chosen(upgrade: GameState.Upgrade) -> void:
	GameState.apply_upgrade(upgrade)
	get_tree().paused = false
	resume_game()

func add_kill():
	exists -= 1
	kills += 1
	score.text = "Kills: " + str(int(kills))
	var wave_length := Waves.length_of(wave)

func resume_game() -> void:
	spawning = true
	_start_wave_timer()
	$EnemySpawnInterval.start(Waves.spawn_interval_of(wave))

func _start_wave_timer() -> void:
	var length := Waves.length_of(wave)
	if length == Waves.ENDLESS:
		$WaveTimer.stop()
	else:
		$WaveTimer.start(length)

func _on_wave_timer_timeout() -> void:
	_end_wave()

func _end_wave() -> void:
	spawning = false
	get_tree().call_group("enemy", "queue_free")   # Gegner + Gegnerkugeln weg

	# Übrige XP automatisch einsammeln (wie in Brotato)
	for x in get_tree().get_nodes_in_group("xp"):
		x.collected.emit(x.value * LEFTOVER_XP_FACTOR)
		x.queue_free()

	get_tree().paused = true

	# 1) Pro Level-Up ein Stat-Upgrade
	var total := GameState.pending_level_ups
	var done := 0
	while GameState.pending_level_ups > 0:
		done += 1
		var screen := STAT_SCREEN.instantiate() as StatScreen
		screen.title_text = "Level Up %d / %d" % [done, total]
		$CanvasLayer.add_child(screen)
		var upgrade: GameState.Upgrade = await screen.upgrade_chosen
		GameState.apply_upgrade(upgrade)
		GameState.pending_level_ups -= 1

	var shop := SHOP.instantiate() as ShopScreen
	$CanvasLayer.add_child(shop)
	await shop.closed

	

	# 3) Nächste Welle
	wave += 1
	wave_label.text = "Wave: " + str(wave)
	GameState.heal_full()                 # HP-Reset pro Runde
	GameState.rerolls_this_wave = 0       # Reroll-Preis zurücksetzen
	get_tree().paused = false
	resume_game()

func new_wave(wave_number: int) -> void:
	spawning = false
	wave = wave_number
	wave_label.text = "Wave: " + str(wave)
	var upgrade_screen := upgrade_screen_scene.instantiate()
	upgrade_screen.upgrade_chosen.connect(_on_upgrade_chosen)
	$CanvasLayer.add_child(upgrade_screen)
	get_tree().paused = true
	
	
func _spawn_enemy(at_position: Vector2) -> void:
	var enemy := enemy_scene.instantiate()  
	enemy.setup(Waves.pick_enemy(wave)) 
	add_child(enemy)
	enemy.global_position = at_position
	enemy.died.connect(_on_enemy_died)
	enemy.touched_player.connect(damage_player)



func _on_enemy_died(death_position: Vector2, xp_amount: float) -> void:
	var xp := xp_scene.instantiate()
	xp.value = xp_amount
	var xp_bar = $CanvasLayer/XpBar
	xp.collected.connect(xp_bar._collected)
	xp.position = death_position
	add_child.call_deferred(xp)
	add_kill()
	
func _setup_hp_bar() -> void:
	var box := $CanvasLayer/HBoxContainer
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(300, 32)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.1, 0.1)
	hp_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(hp_bar)

	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_bar.add_child(hp_label)
	hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_update_hp_bar()


func _update_hp_bar() -> void:
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	hp_label.text = "%d / %d" % [GameState.hp, GameState.max_hp]

func damage_player(reason: String, amount: float = 1) -> void:
	if _invulnerable or GameState.is_dead():
		return
	_invulnerable = true
	hurt_sound.play()
	#spieler.damage_particles.restart()
	get_tree().create_timer(0.25).timeout.connect(func() -> void: _invulnerable = false)
	
	


	GameState.take_damage(amount)
	if GameState.is_dead():
		death_message.visible = true
		death_message.text = "Game Over\n" + reason
		get_tree().paused = true

func randvalue(rangeMin: float, rangeMax: float):
	var value = randf_range(rangeMin, rangeMax)
	if value >-600.0 && value < 600.0:
		return randvalue(rangeMin, rangeMax)
		 
	else:
		return value

func _on_timer_timeout() -> void:
	if not spawning:
		return

	var wave_at_start := wave
	$EnemySpawnInterval.start(Waves.spawn_interval_of(wave))

	var redx = sprite_2d.duplicate()
	add_child(redx)
	redx.visible = true
	redx.global_position = $Spieler.global_position + Vector2(
		randvalue(-1000, 1000),
		randvalue(-1000, 1000)
	)
	redx.global_position.x = clamp(redx.global_position.x, -2700, 2700)
	redx.global_position.y = clamp(redx.global_position.y, -1600, 1600)

	var spawn_pos: Vector2 = redx.global_position   # Position merken, bevor gewartet wird
	await get_tree().create_timer(1).timeout

	redx.queue_free()   # rotes X immer aufräumen
	if spawning and wave == wave_at_start:
		_spawn_enemy(spawn_pos)
		exists += 1
