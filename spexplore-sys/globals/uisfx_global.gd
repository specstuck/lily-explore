extends Node

@export var bus_name := "SFX"

@onready var _players: Dictionary[String, AudioStreamPlayer] = {}

func _ready() -> void:
	_cache_players()
	_apply_bus()

func _cache_players() -> void:
	_players.clear()
	for child in get_children():
		if child is AudioStreamPlayer:
			_players[child.name.to_lower()] = child
	print(_players)

func _apply_bus() -> void:
	for p in _players.values():
		p.bus = bus_name

func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	var key := name.to_lower()
	if not _players.has(key):
		push_warning("UISFX: Unknown sound '%s'" % name)
		push_warning(_players)
		return

	var p := _players[key]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func stop(name: String) -> void:
	var key := name.to_lower()
	if _players.has(key):
		_players[key].stop()

func stop_all() -> void:
	for p in _players.values():
		p.stop()
