extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
@onready var wave_timer: Timer = get_parent().get_parent().get_node("WaveTimer")

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(_delta: float) -> void:
	visible = not wave_timer.is_stopped()
	if visible:
		text = "Wave Time Left: " + str(int(ceil(wave_timer.time_left)))
