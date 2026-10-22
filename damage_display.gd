extends Label

const START_SCALE := Vector2(4, 4)
const END_SCALE := Vector2(1.2, 1.2)
const FADE_DURATION := 0.7
const X_OFFSET := -50.0

func show_damage(damage: float, world_position : Vector2, ) -> void:
	global_position = world_position + Vector2(X_OFFSET, 0.0)
	scale = START_SCALE
	text = str(int(round(damage)))
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.parallel().tween_property(self, "scale", END_SCALE, FADE_DURATION)
	await tween.finished
	queue_free()
