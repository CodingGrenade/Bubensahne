extends HBoxContainer

# Pro Instanz im Inspector einstellbar
@export_enum("Rifle:0", "Sniper:1", "RPG:2", "Shotgun:3") var weapon_id := 0
@export var display_name := "Waffe"
@export var icon: Texture2D

@onready var icon_rect: TextureRect = %Icon
@onready var info_label: Label = %InfoLabel
@onready var buy_button: Button = %BuyButton

var weapon: GameState.WeaponType


func _ready() -> void:
	weapon = weapon_id as GameState.WeaponType
	icon_rect.texture = icon
	buy_button.pressed.connect(_on_buy)
	GameState.gold_changed.connect(refresh)
	refresh()


func refresh() -> void:
	var lvl := GameState.weapon_level_of(weapon)
	if lvl == 0:
		info_label.text = "%s (nicht gekauft)" % display_name
	else:
		info_label.text = "%s  Lv %d  (Cooldown -%d%%)" % [
			display_name, lvl,
			roundi((1.0 - GameState.weapon_cooldown_factor(weapon)) * 100.0)]

	if lvl >= GameState.MAX_WEAPON_LEVEL:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		var action := "Kaufen" if lvl == 0 else "Upgrade"
		buy_button.text = "%s – %d Gold" % [action, GameState.weapon_price(weapon)]
		buy_button.disabled = not GameState.can_buy(weapon)


func _on_buy() -> void:
	GameState.buy_weapon(weapon)   # löst gold_changed → refresh aus
