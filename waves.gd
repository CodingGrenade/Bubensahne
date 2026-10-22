class_name Waves

enum EnemyKind { SCOUT, TANK, SHOOTER, BOSS, CHARGER, SWARM_BAT,}

const ENDLESS := -1

const WAVES: Array = [
	{ # Welle 1
		"length": 20,
		"spawn_interval" : 0.5,
		"enemies": [
			{"kind": EnemyKind.SCOUT, "weight": 1.0, "health": 10, "speed": 250, "xp_amount" : 1},
		],
	},
	{ # Welle 2
		"length": 30,
		"spawn_interval": 0.6,
		"enemies": [
			{"kind": EnemyKind.TANK, "weight": 0.5, "health": 50, "speed": 200, "xp_amount" : 1},
			{"kind": EnemyKind.SCOUT, "weight": 0.5, "health": 10, "speed": 250, "xp_amount" : 1},
		],
	},
	{ # Welle 3
		"length": 40,
		"spawn_interval": 0.6,
		"enemies": [
			{"kind": EnemyKind.SCOUT, "weight": 0.4, "health": 80, "speed": 280, "xp_amount" : 1},
			{"kind": EnemyKind.SHOOTER, "weight": 0.6, "health": 50, "speed": 150, "xp_amount" : 1.5},
		],
	},
	{ # Welle 4
		"length": 50,
		"spawn_interval": 0.7,
		"enemies": [
			{"kind": EnemyKind.SCOUT, "weight": 0.55, "health": 80, "speed": 350, "xp_amount" : 1.5},
			{"kind": EnemyKind.SHOOTER, "weight": 0.4, "health": 50, "speed": 150, "xp_amount" : 2},
			{"kind": EnemyKind.BOSS, "weight": 0.05, "health": 500, "speed": 50, "scale": 1.5,"xp_amount" : 5},
		],
	},
	{ # Welle 5
		"length": 60,
		"spawn_interval": 0.6,
		"enemies": [
			{"kind": EnemyKind.SHOOTER, "weight": 0.3, "health": 50, "speed": 150, "xp_amount" : 2},
			{"kind": EnemyKind.CHARGER, "weight": 0.7, "health": 180, "speed": 180, "xp_amount": 2}
		],
	},
	{ # Welle 6
		"length": 70,
		"spawn_interval": 0.2,
		"enemies": [
			{"kind": EnemyKind.SWARM_BAT, "weight": 0.95, "health": 50, "speed": 300, "xp_amount": 1, "scale": 0.8},
			{"kind": EnemyKind.TANK, "weight": 0.05, "health": 300, "speed": 100, "xp_amount": 2}
		],
	},
	{
		"length": ENDLESS,
		"spawn_interval": 0.2,
		"enemies": [
			{"kind": EnemyKind.SCOUT, "weight": 0.4, "health": 140, "speed": 380, "xp_amount" : 1},
			{"kind": EnemyKind.SHOOTER, "weight": 0.4, "health": 100, "speed": 150, "xp_amount" : 1.5},
			{"kind": EnemyKind.CHARGER, "weight": 0.2, "health": 1000, "speed": 70, "scale": 1.3, "xp_amount" : 3},
		],
	},
]


static func length_of(wave: int) -> int:
	return _wave_data(wave)["length"]

static func spawn_interval_of(wave :int) -> float:
	return _wave_data(wave)["spawn_interval"]

static func pick_enemy(wave: int) -> Dictionary:
	var entries: Array = _wave_data(wave)["enemies"]
	var total_weight := 0.0
	for entry in entries:
		total_weight += entry["weight"]

	var roll := randf() * total_weight
	for entry in entries:
		roll -= entry["weight"]
		if roll <= 0.0:
			return entry
	return entries.back()


# Wellen hinter der Tabelle benutzen die letzte Welle weiter.
static func _wave_data(wave: int) -> Dictionary:
	return WAVES[clampi(wave - 1, 0, WAVES.size() - 1)]
