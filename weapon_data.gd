class_name WeaponData
extends Resource

@export var weapon_type: GameState.WeaponType
@export var projectile_scene: PackedScene
@export var damage: float = 40.0
@export var cooldown: float = 0.5
@export var impulse: float = 1000.0
@export var color: Color = Color.RED
@export var projectile_scale: float = 1.0
@export var range_factor: float = 1.0
@export var price: float = 0
@export_range(0.0, 2.0, 0.05) var scaling_factor: float = 1.0   # Anteil des Fernschadens, der bei dieser Waffe zählt

@export_group("Streuung")
@export var pellets: int = 1                 # Projektile pro Schuss
@export var spread_degrees: float = 0.0      # Fächerbreite in Grad
@export var lifetime: float = 0.0            # 0 = Standard des Projektils
