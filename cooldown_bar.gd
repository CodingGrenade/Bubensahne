extends ProgressBar

# Pro Leiste im Inspektor einstellen, statt drei Skripte zu haben
@export var weapon: GameState.WeaponType

const READY_COLOR := Color(0.255, 0.761, 0.0, 0.784)
const COOLDOWN_COLOR := Color(0.655, 0.0, 0.0, 0.784)

var _style := StyleBoxFlat.new()
var _tween: Tween


func _ready() -> void:
	add_theme_stylebox_override("background", _style)
	_style.bg_color = READY_COLOR
	value = 0.0

	visible = GameState.is_unlocked(weapon)
	GameState.weapon_unlocked.connect(_on_weapon_unlocked)
	get_tree().get_first_node_in_group("player").weapon_fired.connect(_on_weapon_fired)


func _on_weapon_unlocked(unlocked_weapon: GameState.WeaponType) -> void:
	if unlocked_weapon == weapon:
		visible = true


func _on_weapon_fired(fired_weapon: GameState.WeaponType, cooldown: float) -> void:
	if fired_weapon != weapon:
		return

	if _tween:
		_tween.kill()

	max_value = cooldown
	value = cooldown
	_style.bg_color = COOLDOWN_COLOR

	_tween = create_tween()
	_tween.tween_property(self, "value", 0.0, cooldown)
	_tween.tween_callback(func() -> void: _style.bg_color = READY_COLOR)
