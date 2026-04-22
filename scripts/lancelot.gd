extends RigidBody2D

@onready var lute: Area2D = $lute
@onready var health_label: Label = $health
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
@onready var mood_bubble: AnimatedSprite2D = $mood_bubble
@onready var mood_module: Node2D = $mood_module
@onready var spell_barrier: Area2D = $spell_barrier
@onready var enemy_check: Area2D = $enemy_check

signal weapon_hit
signal meter_full
signal death
signal bounce

var spells : Array = [
	"heal",
	"sleep",
	"chords",
	"wind",
	"barrier"
]

enum states {
	DEFAULT,
	WINDED,
	DEFEATED,
	CASTING,
}

var barrier_health := 5.0
var enemy_direction : Vector2
var chord = load("res://scenes/chord.tscn")
var status = manager.statuses.NONE
var mood = manager.moods.CAUTIOUS
var state = states.DEFAULT
var current_spell : String
var meter_max := 7.5
var meter := 0.0
var default_melee_speed := 5.0
var melee_rotation_speed := default_melee_speed
var melee_rotation_direction := 1
var melee_damage := 2
var default_speed := 300.0
var speed := default_speed
var health := 100.0
var previous_valid_position : Vector2
@export var direction: Vector2 = Vector2(randi_range(-10, 10), randi_range(-10, 10))

func _ready():
	$sleep_area/Sprite2D.modulate.a = 0
	lancelot_sprites.play("default")
	linear_velocity = direction.normalized() * speed
	sleep_area.monitoring = false
	spell_barrier.monitoring = false
	spell_barrier.modulate.a = 0

func _physics_process(delta):
	mood_bubble.play(str(mood))
	health = clamp(health,0, 100)
	speed = lerp(speed, default_speed, 5 * delta)
	melee_rotation_speed = lerp(melee_rotation_speed, default_melee_speed * melee_rotation_direction, 0.1)
	lute.rotation += melee_rotation_speed * delta
	linear_velocity = linear_velocity.normalized() * speed
	health_label.text = str(int(health))
	meter += delta
	if meter >= meter_max:
		current_spell = spells.pick_random()
		ability_timer.start()
		state = states.CASTING
	if state == states.CASTING or state == states.DEFEATED:
		default_speed = 0
		default_melee_speed = 0
		meter = 0.0
		lute.monitoring = false
		lute.modulate = Color(0.5, 0.5, 0.5, 1)
	elif state == states.WINDED:
		default_speed = 600.0
		default_melee_speed = 10.0
		lute.monitoring = true
	else:
		default_speed = 300.0
		default_melee_speed = 5.0
		lute.monitoring = true
	for i in enemy_check.get_overlapping_bodies():
		if i.is_in_group("ball") and i != self:
			enemy_direction = global_position.direction_to(i.global_position)

func _integrate_forces(_state):
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * speed

func _on_lancelot_body_entered(body: Node) -> void:
	if randi_range(1,5) == 5:
		mood_module.mood_trigger.emit()
	if body.is_in_group("wall"):
		manager.bounce.play()
		melee_rotation_speed += 15 * melee_rotation_direction
	elif body.is_in_group("ball"):
		manager.hit.play()
		take_damage(body.melee_damage)
		if body.has_method("take_damage"):
			body.take_damage(melee_damage)

func launch_away(enemy_damage):
	linear_velocity = (enemy_direction * clamp((enemy_damage / 10) + 1,1, INF) * -1)

func take_damage(damage):
	health -= damage
	if damage != 0:
		lancelot_sprites.play("hurt")
		hurt_timer.start()
	manager.hitstop_signal.emit()
	arena.add_trauma(0.1)
	if state == states.CASTING:
		lute.modulate = Color(1, 1, 1, 1)
		ability_timer.stop()
		state = states.DEFAULT
		manager.defeat.play()
		manager.hurt.play()
	if health <= 0:
		death.emit()

func _on_hurt_timer_timeout() -> void:
	if state == states.DEFEATED:
		lancelot_sprites.play("default")

func _on_lute_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		weapon_hit.emit()
		body.take_damage(melee_damage)
		manager.hit.play()
		manager.hitstop_signal.emit()
		launch_away(body.melee_damage)
		melee_rotation_direction *= -1
		melee_rotation_speed += 10 * melee_rotation_direction
		body.launch_away(melee_damage)

func _on_spell_timer_timeout() -> void:
	meter_full.emit()
	cast_spell(current_spell)

func cast_spell(spell):
	state = states.DEFAULT
	lute.modulate = Color(1, 1, 1, 1)
	print(spell)
	if spell == "wind":
		state = states.WINDED
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
			var chord_rotation = 360.0 / 3 * i
			var chord_direction = Vector2.from_angle(chord_rotation)
			var offset = chord_direction * 50
			var chord_instance = chord.instantiate()
			get_parent().add_child(chord_instance)
			chord_instance.global_position = global_position + offset
	if spell == "barrier":
		barrier.play()
		barrier_health = 5.0
		animation_player.play("barrier")
		spell_barrier.get_child(2).text = barrier_health
		spell_barrier.get_child(2).visibility.visible = false

func _on_weapon_hit() -> void:
	animation_player.play("flip_weapon")

func _on_wind_timer_timeout() -> void:
	state = states.DEFAULT

func _on_sleep_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.status = manager.statuses.SLEEP

func _on_death() -> void:
	manager.defeat.play()
	state = states.DEFEATED
	animation_player.play("death")
	arena.death_camera.emit(self)

func _on_spell_barrier_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		barrier_health -= body.melee_damage
		if barrier_health <= 0:
			spell_barrier.get_child(2).visibility.visible = false
			animation_player.play_backwards("barrier")
