extends RigidBody2D
@onready var health_label: Label = $health
@onready var bounce: AudioStreamPlayer2D = manager.bounce
@onready var sprites: AnimatedSprite2D = $sprites
@onready var hurt_timer: Timer = $hurt_timer
@onready var arena: Node2D = $"../arena"
@onready var ability_timer: Timer = $ability_timer
@onready var sleep_timer: Timer = $sleep_timer

signal meter_full

var status = null
var meter_max := 25.0
var meter := 0.0
var health := 100
var mood = manager.moods.CENTERED
var melee_damage := 0
var max_speed := 500.0
var default_speed := 300.0
var speed := default_speed

@export var direction: Vector2 = Vector2(randi_range(-10, 10), randi_range(-10, 10))

func _ready():
	sprites.play("default")
	gravity_scale = 0
	linear_velocity = direction.normalized() * speed

func _physics_process(delta):
	speed = lerp(speed, default_speed, 0.1)
	linear_velocity = linear_velocity.normalized() * speed
	health_label.text = str(health)
	rotation = 0
	meter += delta
	if status == manager.statuses.SLEEP:
		default_speed = 0.0
		sleep_timer.start()
	else:
		default_speed = 300.0

func _integrate_forces(state):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed

func _on_ball_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		bounce.play()
	elif body.is_in_group("ball"):
		manager.hit.play()
		health -= body.melee_damage
		if body.has_method("take_damage"):
			body.take_damage(2)

func take_damage(damage):
	health -= damage
	sprites.play("hurt")
	hurt_timer.start()
	manager.hitstop_signal.emit()
	linear_velocity *= -1
	arena.add_trauma(0.1)
	speed += 100
	status = null

func _on_hurt_timer_timeout() -> void:
	sprites.play("default")

func _on_sleep_timer_timeout() -> void:
	status = null
