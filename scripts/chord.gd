extends RigidBody2D

@onready var sprite: AnimatedSprite2D = $sprite

var status = null
var meter_max := 25.0
var meter := 0.0
var health := 100
var mood = manager.moods.CENTERED
var melee_damage := 3
var max_speed := 500.0
var default_speed := 300.0
var speed := default_speed

@export var direction: Vector2 = Vector2(randi_range(-10, 10), randi_range(-10, 10))

func _ready():
	sprite.play(str(randi_range(1,3)))
	gravity_scale = 0
	linear_velocity = direction.normalized() * speed

func _physics_process(delta):
	# Keep constant speed (important for stable movement)
	linear_velocity = linear_velocity.normalized() * speed
	rotation = 0
	meter += delta

func _integrate_forces(_state):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		manager.bounce.play()
	elif body.is_in_group("ball") and !body.is_in_group("lancelot"):
		manager.hurt.play()
		queue_free()
		health -= body.melee_damage
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)
		else:
			manager.deflect.play()
			queue_free()
