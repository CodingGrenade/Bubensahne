class_name ShopScreen
extends Control

signal closed

@onready var gold_label: Label = %GoldLabel
@onready var next_button: Button = %NextButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	next_button.pressed.connect(_on_next)
	GameState.gold_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	gold_label.text = "Gold: %d" % int(GameState.gold)


func _on_next() -> void:
	closed.emit()
	queue_free()
