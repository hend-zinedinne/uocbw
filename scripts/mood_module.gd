extends Node2D

@onready var ball : RigidBody2D = get_parent()

signal mood_trigger

func _on_mood_trigger() -> void:
	ball.mood_bubble.play(ball.mood)
	ball.animation_player.play("mood_trigger")
	
	if ball.mood == manager.moods.CAUTIOUS:
		ball.launch_away(ball.enemy_direction, 1)
	
