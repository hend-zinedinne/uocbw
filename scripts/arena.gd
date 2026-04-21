extends Node2D

@onready var bg_color: ColorRect = $bg_color
@export var decay = 0.95  # How quickly the shaking stops [0, 1].
@export var max_offset = Vector2(15, 10)  # Maximum hor/ver shake in pixels.
@export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
@onready var camera: Camera2D = $Camera2D
@onready var camera_zoom_timer: Timer = $Camera2D/camera_zoom_timer

signal death_camera(ball:RigidBody2D)

var camera_zooming : bool = false
var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func _ready():
	randomize()

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	if camera_zooming:
		camera.zoom = lerp(camera.zoom, Vector2(1.5, 1.5), 5 * delta)
	else:
		camera.zoom = lerp(camera.zoom, Vector2(1.0, 1.0), 5 * delta)

func shake():
	var amount = pow(trauma, trauma_power)
	camera.offset.x = max_offset.x * amount * randf_range(-1.0, 1.0)
	camera.offset.y = max_offset.y * amount * randf_range(-1.0, 1.0)

func _on_button_pressed() -> void:
	add_trauma(1)

func _on_death_camera(ball:RigidBody2D) -> void:
	
	camera.global_position = ball.global_position
	camera_zoom_timer.start()
	camera_zooming = true
	


func _on_camera_zoom_timer_timeout() -> void:
	camera_zooming = false
	camera.global_position = Vector2(360, 360)
