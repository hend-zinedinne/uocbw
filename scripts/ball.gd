extends RigidBody2D
@onready var health_label: Label = $health
@onready var bounce: AudioStreamPlayer2D = manager.bounce
@onready var sprites: AnimatedSprite2D = $sprites
@onready var hurt_timer: Timer = $hurt_timer
@onready var arena: Node2D = $"../arena"
@onready var ability_timer: Timer = $ability_timer
@onready var sleep_timer: Timer = $sleep_timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var enemy_check: Area2D = $enemy_check

signal meter_full

var knockback_resist : float = 0.7
var damage_resist : float = 0.7
var resist_increase : float = 0.0

var enemy_direction : Vector2

var defeated : bool = false
var status = manager.statuses.NONE
var meter_max := 25.0
var meter := 0.0
var health := 100
var mood = manager.moods.CENTERED
var melee_damage := 0
var default_speed := 300.0
var speed := default_speed

@export var direction: Vector2 = Vector2(randi_range(-10, 10), randi_range(-10, 10))

func _ready():
	sprites.play("default")
	gravity_scale = 0
	linear_velocity = direction.normalized() * speed

func _physics_process(delta):
	health = clamp(health,0, 100)
	speed = lerp(speed, default_speed, 5 * delta)
	linear_velocity = linear_velocity.normalized() * speed
	health_label.text = str(health)
	meter += delta
	if status == manager.statuses.SLEEP:
		default_speed = 0.0
		sleep_timer.start()
	else:
		default_speed = 300.0 * knockback_resist
	if health <= 0:
		defeated = true
		animation_player.play("death")
	if meter >= meter_max:
		meter_full.emit()
	for i in enemy_check.get_overlapping_bodies():
		if i.is_in_group("ball") and i != self:
			enemy_direction = global_position.direction_to(i.global_position)

func _integrate_forces(_state):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed

func _on_ball_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		resist_increase = 0.09
		body.take_damage(melee_damage)
	elif body.is_in_group("weapon"):
		resist_increase = 0.03
		take_damage(body.melee_damage)
		launch_away(body.melee_damage)
	elif body.is_in_group("wall"):
		manager.bounce.play()
		speed += 100

func launch_away(enemy_damage):
	linear_velocity = (enemy_direction * clamp((enemy_damage / 10) + 1,1, INF) * -1)

func take_damage(damage):
	health -= damage * damage_resist
	damage_resist = clamp(damage_resist - resist_increase, 0.1, 0.7)
	knockback_resist = clamp(knockback_resist + resist_increase, 0.1, 0.7)
	sprites.play("hurt")
	hurt_timer.start()
	manager.hitstop_signal.emit()
	arena.add_trauma(0.1)
	speed += 100
	status = manager.statuses.NONE

func _on_hurt_timer_timeout() -> void:
	sprites.play("default")

func _on_sleep_timer_timeout() -> void:
	status = manager.statuses.NONE
