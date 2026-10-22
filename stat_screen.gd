class_name StatScreen
extends Control

signal upgrade_chosen(upgrade: GameState.Upgrade)

var title_text := "Level Up!"

@onready var title_label: Label = %TitleLabel
@onready var options_row: HBoxContainer = %OptionsRow
@onready var gold_label: Label = %GoldLabel
@onready var reroll_button: Button = %RerollButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = title_text
	reroll_button.pressed.connect(_on_reroll)
	GameState.gold_changed.connect(_refresh_reroll)
	_fill_options()
	_refresh_reroll()


func _fill_options() -> void:
	var upgrades := GameState.roll_stat_options()
	var buttons := options_row.get_children()
	for i in buttons.size():
		var b := buttons[i] as Button
		for c in b.pressed.get_connections():
			b.pressed.disconnect(c["callable"])
		if i < upgrades.size():
			b.visible = true
			b.text = _label(upgrades[i])
			b.pressed.connect(_choose.bind(upgrades[i]))
		else:
			b.visible = false   # überzählige Buttons ausblenden


func _refresh_reroll() -> void:
	gold_label.text = "Gold: %d" % int(GameState.gold)
	reroll_button.text = "Reroll – %d Gold" % GameState.reroll_price()
	reroll_button.disabled = not GameState.can_reroll()


func _on_reroll() -> void:
	if GameState.buy_reroll():   # löst gold_changed → _refresh_reroll aus
		_fill_options()


func _label(upgrade: GameState.Upgrade) -> String:
	match upgrade:
		GameState.Upgrade.DAMAGE:
			return "Schaden +10 %%\n(aktuell x%.1f)" % GameState.damage_multiplier
		GameState.Upgrade.RANGED_DAMAGE:
			return "Fernschaden +%d\n(aktuell +%d)" % [int(GameState.RANGED_DAMAGE_STEP), int(GameState.ranged_damage)]
		GameState.Upgrade.SPEED:
			return "Tempo +100 %%\n(aktuell %d)" % int(GameState.speed)
		GameState.Upgrade.RANGE:
			return "Reichweite +100 %%\n(aktuell %d)" % int(GameState.attack_range)
		GameState.Upgrade.MAX_HP:
			return "Max. HP +%d\n(aktuell %d)" % [GameState.MAX_HP_UPGRADE, GameState.max_hp]
		GameState.Upgrade.PICKUP_RANGE:
			return "Pickup-Reichweite +75 %%\n(aktuell %d)" % int(GameState.pickup_range)
		GameState.Upgrade.XP_GAIN:
			return "XP-Gewinn +15 %%\n(aktuell x%.2f)" % GameState.xp_multiplier
	return ""


func _choose(upgrade: GameState.Upgrade) -> void:
	upgrade_chosen.emit(upgrade)
	queue_free()
