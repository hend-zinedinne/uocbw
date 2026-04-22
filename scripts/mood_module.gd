extends Node2D

@export var ball : RigidBody2D
@onready var think_timer: Timer = $think_timer
@onready var mood_trigger_timer: Timer = $mood_trigger_timer

signal mood_trigger

func _on_mood_trigger() -> void:
	mood_trigger_timer.start()

func _on_think_timer_timeout() -> void:
	ball.target_speed = ball.default_speed

func _on_mood_trigger_timer_timeout() -> void:
	ball.mood_bubble.play(ball.mood)
	ball.mood_trigger_anim.play("mood_trigger")
	
	if ball.mood == manager.moods.CAUTIOUS:
		ball.launch_away()
	if ball.mood == manager.moods.AGGRESSIVE:
		ball.linear_velocity = ball.enemy_position
	if ball.mood == manager.moods.SILLY:
		ball.linear_veloicty = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if ball.mood == manager.moods.THINKER:
		ball.default_speed = 0
		think_timer.start()
	if ball.mood == manager.moods.CENTERED:
		ball.linear_velocity = ball.global_position.direction_to(Vector2.ZERO)
	if ball.mood == manager.moods.SNEAKY:
		pass
