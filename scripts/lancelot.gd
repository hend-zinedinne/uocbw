extends RigidBody2D

@onready var lute: Area2D = $lute
@onready var health_label: Label = $health
@onready var bounce: AudioStreamPlayer2D = manager.bounce
@onready var hurt_timer: Timer = $hurt_timer
@onready var lancelot_sprites: AnimatedSprite2D = $lancelot_sprites
@onready var arena: Node2D = $"../arena"
@onready var ability_timer: Timer = $ability_timer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wind_timer: Timer = $wind_timer
@onready var heal: AudioStreamPlayer2D = $spell_sfx/heal_spell
@onready var wind: AudioStreamPlayer2D = $spell_sfx/wind_spell
@onready var barrier: AudioStreamPlayer2D = $spell_sfx/barrier_spell
@onready var sleep: AudioStreamPlayer2D = $spell_sfx/sleep_spell
@onready var chords: AudioStreamPlayer2D = $spell_sfx/chords_spell
@onready var sleep_area: Area2D = $sleep_area

signal weapon_hit
signal meter_full

var spells : Array = [
	"heal",
	"sleep",
	"chords",
	"wind",
	"barrier"
]

var chord = load("res://scenes/chord.tscn")
var status = null
var mood = manager.moods.CAUTIOUS
var casting : bool = false
var winded : bool = false
var current_spell : String
var meter_max := 7.5
var meter := 0.0
var default_melee_speed := 5.0
var melee_rotation_speed := default_melee_speed
var melee_rotation_direction := 1
var melee_damage := 2
var max_speed := 500.0
var default_speed := 300.0
var speed := default_speed
var health := 100.0
var previous_valid_velocity : Vector2
@export var direction: Vector2 = Vector2(randi_range(-10, 10), randi_range(-10, 10))

func _ready():
	$sleep_area/Sprite2D.modulate.a = 0
	lancelot_sprites.play("default")
	linear_velocity = direction.normalized() * speed
	sleep_area.monitoring = false

func _physics_process(delta):
	if !linear_velocity.is_finite():
		previous_valid_velocity = linear_velocity
	else:
		linear_velocity = previous_valid_velocity
	speed = lerp(speed, default_speed, 0.1)
	melee_rotation_speed = lerp(melee_rotation_speed, default_melee_speed * melee_rotation_direction, 0.1)
	lute.rotation += melee_rotation_speed * delta
	linear_velocity = linear_velocity.normalized() * speed
	health_label.text = str(int(health))
	rotation = 0
	meter += delta
	if meter >= meter_max:
		current_spell = spells.pick_random()
		ability_timer.start()
		casting = true
	if winded:
		default_speed = 600.0
		default_melee_speed = 10.0
	elif casting:
		default_speed = 0
		default_melee_speed = 0
		meter = 0.0
	else:
		default_speed = 300.0
		default_melee_speed = 5.0


func _integrate_forces(state):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

func _on_lancelot_body_entered(body: Node) -> void:
	if body.is_in_group("wall"):
		manager.bounce.play()
		melee_rotation_speed += 15 * melee_rotation_direction
	elif body.is_in_group("ball"):
		manager.hit.play()
		take_damage(melee_damage)
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)

func take_damage(damage):
	health -= damage
	lancelot_sprites.play("hurt")
	hurt_timer.start()
	manager.hitstop_signal.emit()
	arena.add_trauma(0.1)
	speed += 100
	if casting:
		ability_timer.stop()
		casting = false
		take_damage(5)
		manager.hurt.play()

func _on_hurt_timer_timeout() -> void:
	lancelot_sprites.play("default")

func _on_lute_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		weapon_hit.emit()
		body.take_damage(melee_damage)
		manager.hit.play()
		manager.hitstop_signal.emit()
		linear_velocity *= -1
		melee_rotation_direction *= -1
		melee_rotation_speed += 10 * melee_rotation_direction

func _on_spell_timer_timeout() -> void:
	meter_full.emit()
	cast_spell(current_spell)

func cast_spell(spell):
	casting = false
	print(spell)
	if spell == "wind":
		winded = true
		wind.play()
		wind_timer.start()
	if spell == "heal":
		health += 10
		heal.play()
	if spell == "sleep":
		sleep.play()
		sleep_area.monitoring = true
		animation_player.play("sleep_aura")
	if spell == "chords":
		chords.play()
		for i in range(0,3):
			var chord_rotation = 360 / 3 * i
			var chord_direction = Vector2.from_angle(chord_rotation)
			var offset = chord_direction * 50
			var chord_instance = chord.instantiate()
			get_parent().add_child(chord_instance)
			chord_instance.global_position = global_position + offset
	if spell == "barrier":
		barrier.play()

func _on_weapon_hit() -> void:
	animation_player.play("flip_weapon")

func _on_wind_timer_timeout() -> void:
	winded = false

func _on_sleep_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.status = manager.statuses.SLEEP
	sleep_area.monitoring = false
