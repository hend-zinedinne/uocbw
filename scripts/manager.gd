extends Node2D

enum moods {
	CAUTIOUS,
	AGGRESSIVE,
	CENTERED,
	SILLY,
	SNEAKY,
	THINKER,
	NONE
}

enum statuses {
	SLEEP,
	FIRE,
	FREEZE,
	SPOOKED,
	SHOCK,
	COMBO,
	TOXIC,
	HEALING,
	NONE
}

@onready var defeat: AudioStreamPlayer2D = $defeat
@onready var hit: AudioStreamPlayer2D = $hit
@onready var bounce: AudioStreamPlayer2D = $bounce
@onready var hurt: AudioStreamPlayer2D = $hurt
@onready var deflect: AudioStreamPlayer2D = $deflect
@onready var hitstop: Timer = $hitstop

signal hitstop_signal

func _on_hitstop_timeout() -> void:
	Engine.time_scale = 1.0

func _on_hitstop_signal() -> void:
	hitstop.start()
	Engine.time_scale = 0.000001
