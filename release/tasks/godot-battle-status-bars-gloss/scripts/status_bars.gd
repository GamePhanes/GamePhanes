extends Control
class_name StatusBars

@onready var hp_fill: ColorRect = $HpBar/HpFill
@onready var mp_fill: ColorRect = $MpBar/MpFill

var hp := 100.0
var hp_max := 100.0
var mp := 100.0
var mp_max := 100.0


func _ready() -> void:
    set_status(hp, hp_max, mp, mp_max)


func set_status(next_hp: float, next_hp_max: float, next_mp: float, next_mp_max: float) -> void:
    hp_max = maxf(1.0, next_hp_max)
    mp_max = maxf(1.0, next_mp_max)
    hp = clampf(next_hp, 0.0, hp_max)
    mp = clampf(next_mp, 0.0, mp_max)
    hp_fill.anchor_right = hp / hp_max
    hp_fill.offset_right = 0.0
    mp_fill.anchor_right = mp / mp_max
    mp_fill.offset_right = 0.0


func snapshot() -> Dictionary:
    return {
        "hp": hp,
        "hp_max": hp_max,
        "mp": mp,
        "mp_max": mp_max,
        "hp_ratio": hp_fill.anchor_right,
        "mp_ratio": mp_fill.anchor_right,
    }
