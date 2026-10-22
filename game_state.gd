extends Node

signal weapon_unlocked(weapon: WeaponType)
signal gold_changed
signal hp_changed

enum WeaponType { RIFLE, SNIPER, RPG, SHOTGUN }
enum Upgrade { DAMAGE, RANGED_DAMAGE, SPEED, RANGE, MAX_HP, PICKUP_RANGE, XP_GAIN }

const BASE_PICKUP_RANGE := 150
const UPGRADE_PICKUP := 75
const UPGRADE_XP := 0.15
const BASE_SPEED := 500.0
const BASE_ATTACK_RANGE := 600.0
const UPGRADE_SPEED := 100
const UPGRADE_RANGE := 150
const UPGRADE_DAMAGE := 0.1
const BASE_MAX_HP := 5
const MAX_HP_UPGRADE := 1
const STAT_OPTIONS := 3
const REROLL_BASE_PRICE := 5
const REROLL_STEP := 5
const MAX_WEAPON_LEVEL := 4
const DAMAGE_PERCENT_STEP := 0.1      # +10 % pro Upgrade
const RANGED_DAMAGE_STEP := 10       # +2 flacher Schaden pro Upgrade
const COOLDOWN_LEVEL_FACTOR := 0.80   # jedes Waffen-Level: Cooldown x0.85
const WEAPON_BASE_PRICE := {
	WeaponType.RIFLE: 30,
	WeaponType.SNIPER: 40,
	WeaponType.RPG: 40,
	WeaponType.SHOTGUN: 30,
}

var xp: float
var level: int
var gold: float
var pending_level_ups: int
var speed: float
var attack_range: float
var damage_multiplier: float
var weapon_levels: Dictionary
var max_hp: int
var hp: int
var pickup_range: float
var xp_multiplier: float
var rerolls_this_wave: int
var ranged_damage := 0.0


func _ready() -> void:
	reset()


func reset(start_weapon: WeaponType = WeaponType.RIFLE) -> void:
	speed = BASE_SPEED
	attack_range = BASE_ATTACK_RANGE
	damage_multiplier = 1.0
	ranged_damage = 0.0
	level = 0
	xp = 0
	gold = 0
	pending_level_ups = 0
	max_hp = BASE_MAX_HP
	hp = max_hp
	rerolls_this_wave = 0
	pickup_range = BASE_PICKUP_RANGE
	xp_multiplier = 1.0
	weapon_levels = {
		WeaponType.RIFLE: 0,
		WeaponType.SNIPER: 0,
		WeaponType.RPG: 0,
		WeaponType.SHOTGUN: 0,
	}
	weapon_levels[start_weapon] = 1

# ---------- HP ----------
func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit()


func heal_full() -> void:
	hp = max_hp
	hp_changed.emit()


func is_dead() -> bool:
	return hp <= 0


# ---------- Stats ----------
func apply_upgrade(upgrade: Upgrade) -> void:
	match upgrade:
		Upgrade.DAMAGE:        damage_multiplier += DAMAGE_PERCENT_STEP
		Upgrade.RANGED_DAMAGE: ranged_damage += RANGED_DAMAGE_STEP
		Upgrade.SPEED:  speed += UPGRADE_SPEED
		Upgrade.RANGE:  attack_range += UPGRADE_RANGE
		Upgrade.PICKUP_RANGE: pickup_range += UPGRADE_PICKUP
		Upgrade.XP_GAIN:      xp_multiplier += UPGRADE_XP
		Upgrade.MAX_HP:
			max_hp += MAX_HP_UPGRADE
			hp += MAX_HP_UPGRADE
			hp_changed.emit()


## Zieht zufällig ein paar verschiedene Stat-Upgrades.
func roll_stat_options() -> Array:
	var pool: Array = Upgrade.values()
	pool.shuffle()
	return pool.slice(0, STAT_OPTIONS)


# ---------- Reroll ----------
func reroll_price() -> int:
	return REROLL_BASE_PRICE + REROLL_STEP * rerolls_this_wave


func can_reroll() -> bool:
	return gold >= reroll_price()


func buy_reroll() -> bool:
	if not can_reroll():
		return false
	gold -= reroll_price()
	rerolls_this_wave += 1
	gold_changed.emit()
	return true


# ---------- Waffen ----------
func weapon_level_of(weapon: WeaponType) -> int:
	return weapon_levels[weapon]


func is_unlocked(weapon: WeaponType) -> bool:
	return weapon_level_of(weapon) > 0


func weapon_price(weapon: WeaponType) -> int:
	return int(WEAPON_BASE_PRICE[weapon] * (1.0 + 0.75 * weapon_level_of(weapon)))


func can_buy(weapon: WeaponType) -> bool:
	return weapon_level_of(weapon) < MAX_WEAPON_LEVEL and gold >= weapon_price(weapon)


func buy_weapon(weapon: WeaponType) -> bool:
	if not can_buy(weapon):
		return false
	gold -= weapon_price(weapon)
	weapon_levels[weapon] += 1
	if weapon_levels[weapon] == 1:
		weapon_unlocked.emit(weapon)
	gold_changed.emit()
	return true


func compute_damage(base_damage: float, scaling_factor: float = 1.0) -> float:
	return (base_damage + ranged_damage * scaling_factor) * damage_multiplier


func weapon_cooldown_factor(weapon: WeaponType) -> float:
	return pow(COOLDOWN_LEVEL_FACTOR, weapon_level_of(weapon) - 1)
