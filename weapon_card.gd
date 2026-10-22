extends Button

signal chosen(weapon: GameState.WeaponType)

# Pro Karte im Inspector einstellbar
@export_enum("Rifle:0", "Sniper:1", "RPG:2", "Shotgun:3") var weapon_id := 0
@export var display_name := "Waffe"
@export_multiline var weapon_description := ""
@export var weapon_icon: Texture2D

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel


func _ready() -> void:
	icon_rect.texture = weapon_icon
	name_label.text = display_name
	desc_label.text = weapon_description
	pressed.connect(func() -> void: chosen.emit(weapon_id as GameState.WeaponType))
