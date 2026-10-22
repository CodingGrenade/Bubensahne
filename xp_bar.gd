extends ProgressBar

signal level_up(level: float)
var xp_required_next : float
@onready var xp_text: Label = $XpText
@onready var xp_sound: AudioStreamPlayer2D = $XpSound
@onready var level_up_sound: AudioStreamPlayer2D = $LevelUpSound

func _ready() -> void:
	max_value = xp_needed()
	xp_text.text = "Level: 0"

func xp_needed() -> float:
	var xp_need := 10 + (GameState.level)*10
	return xp_need

func _process(delta: float) -> void:
	pass


func _collected(val: float):
	xp_sound.play()
	GameState.xp += val * GameState.xp_multiplier
	GameState.gold += val
	GameState.gold_changed.emit()

	while GameState.xp >= xp_needed():
		GameState.xp -= xp_needed()
		GameState.level += 1
		GameState.pending_level_ups += 1
		level_up.emit(GameState.level)
		level_up_sound.play()

	max_value = xp_needed()
	value = GameState.xp
	xp_text.text = "Level: " + str(GameState.level)
