extends Node

var num_players = 30
var bus = "Master"

var available = []
var queue = []
var volume_db = 0
var recent = []

func _ready():
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = bus
		p.volume_db = volume_db

func _on_stream_finished(stream):
	stream.volume_db = volume_db
	available.append(stream)

func play(sound_path, pitch = 1.0, volume = 1.0):
	if sound_path and not recent.has(sound_path):
		recent_sound(sound_path)
		queue.append([sound_path, pitch, volume])
		return true
	return false

func recent_sound(sound_path):
	recent.append(sound_path)
	await get_tree().create_timer(0.02, true, false, true).timeout

	recent.erase(sound_path)

func _process(_delta):
	if not queue.is_empty() and not available.is_empty():
		var popped = queue.pop_front()
		var player:AudioStreamPlayer = available.pop_front()

		player.stream = load(popped[0])
		player.pitch_scale = popped[1]
		player.volume_db = volume_db + linear_to_db(popped[2])
		player.play()
