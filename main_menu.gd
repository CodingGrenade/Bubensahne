extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_start_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://weapon_select.tscn")
