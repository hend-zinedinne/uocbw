extends Control

@onready var health_meter: TextureProgressBar = $health_meter
@onready var red_meter: TextureProgressBar = $red_meter
@onready var health_number: Label = $health_meter/health_number
@onready var ability_meter: TextureProgressBar = $ability_meter

@export var ball: RigidBody2D

func _ready() -> void:
	red_meter.value = health_meter.value
	ability_meter.max_value = ball.meter_max

func _process(delta: float) -> void:
	ability_meter.value = ball.meter
	health_number.text = str((int(health_meter.value)))
	health_meter.value = ball.health
	red_meter.value = lerp(red_meter.value, health_meter.value, 0.1)
