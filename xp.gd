extends Area2D

signal collected

var value: float

func _ready() -> void:
	add_to_group("xp")
	scale = scale * value 


var _taken := false

func _on_area_entered(area: Area2D) -> void:
	if _taken:
		return
	if area.get_parent().is_in_group("player"):
		_taken = true
		collected.emit(value)
		queue_free()
