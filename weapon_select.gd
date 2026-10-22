extends Control

@export_file("*.tscn") var menu_scene := "res://main_menu.tscn"
@export_file("*.tscn") var level_scene := "res://level.tscn"

@onready var cards: HBoxContainer = %Cards
@onready var back_button: Button = %BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for card in cards.get_children():
		card.chosen.connect(_on_weapon_chosen)
	back_button.pressed.connect(_on_back)


func _on_weapon_chosen(weapon: GameState.WeaponType) -> void:
	GameState.reset(weapon)            # gewählte Waffe startet auf Level 1
	get_tree().paused = false
	get_tree().change_scene_to_file(level_scene)


func _on_back() -> void:
	get_tree().change_scene_to_file(menu_scene)
