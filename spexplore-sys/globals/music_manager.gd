extends Node

@export var bus_name := "Music"
@export var default_fade := 0.8

@onready var main_a: AudioStreamPlayer = $MainA
@onready var main_b: AudioStreamPlayer = $MainB

# -------------------------
# Pause snapshot state
# -------------------------
var _paused := false
var _saved_cue: MusicCue = null
var _saved_mode := ""              # "single" or "stems"
var _saved_pos := 0.0              # seconds into current playback

# Single-mode resume
var _saved_single_stream: AudioStream = null   # intro or loop
var _saved_single_intro_playing := false

# Stem-mode resume
var _stem_weights: Dictionary[String, float] = {}    
var _saved_stem_weights: Dictionary[String, float] = {}  # snapshot


var _active_main: AudioStreamPlayer
var _inactive_main: AudioStreamPlayer

# Active cue + mode
var _cue: MusicCue = null
var _mode := "" # "single" or "stems"

# Single-track intro/loop state
var _single_intro_playing := false
var _single_loop_stream: AudioStream = null

# Stem players
var _stem_players: Dictionary[String, AudioStreamPlayer] = {}
var _stem_target_db := 0.0

# Tween management
var _fade_tween: Dictionary[Object, Tween] = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for p in [main_a, main_b]:
		p.bus = bus_name
		p.volume_db = -80.0
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.finished.connect(_on_main_finished)

	_active_main = main_a
	_inactive_main = main_b

# -------------------------
# Public API
# -------------------------

func play_cue(cue: MusicCue, fade := -1.0) -> void:
	if cue.stems.size() > 0:
		_mode = "stems"
		_start_stems(cue, fade)
	else:
	
		if cue == null:
			push_warning("MusicManager: play_cue called with null cue")
			return
		if fade < 0.0:
			fade = default_fade
	
		# If same cue already active, ignore
		if _cue == cue:
			return
	
		# Stop whatever is currently active
		_stop_current(fade)
	
		_cue = cue
	
		# Decide mode == stems if stems dict has content, otherwise single intro/loop
		if cue.stems.size() > 0:
			_mode = "stems"
			_start_stems(cue, fade)
		else:
			_mode = "single"
			_start_single_intro_loop(cue, fade)
			
func set_stem(name: String, weight: float, fade := 0.35, align_to_bar := false) -> void:
	if _mode != "stems":
		return
	if align_to_bar:
		var wait := _time_until_next_bar()
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout
	_set_stem_weight(name, weight, fade)

func set_stem_mix(mix: Dictionary[String, float], fade := 0.35, align_to_bar := false) -> void:
	if _mode != "stems":
		return
	if align_to_bar:
		var wait := _time_until_next_bar()
		if wait > 0.0:
			await get_tree().create_timer(wait).timeout

	for name in _stem_players.keys():
		var w := 0.0
		if mix.has(name):
			w = float(mix[name])
		_set_stem_weight(name, w, fade)

func pause_to_menu(pause_cue: MusicCue, fade := 0.35) -> void:
	if _paused:
		return
	if pause_cue == null:
		push_warning("MusicManager: pause_to_menu called with null cue")
		return

	# Snapshot current state
	_saved_cue = _cue
	_saved_mode = _mode
	_saved_pos = _get_music_time_sec()

	if _mode == "single":
		_saved_single_intro_playing = _single_intro_playing
		_saved_single_stream = _active_main.stream
	elif _mode == "stems":
		_saved_stem_weights = _stem_weights.duplicate()

	_paused = true

	# Fade out whatever is currently playing and stop it
	_stop_current(fade)

	# Switch to pause cue
	play_cue(pause_cue, fade)

func resume_from_menu(fade := 0.35) -> void:
	if not _paused:
		return

	# Fade out pause cue
	_stop_current(fade)

	# Restore saved cue at saved time
	var cue := _saved_cue
	if cue == null:
		_paused = false
		return

	_cue = cue

	if _saved_mode == "stems" and cue.stems.size() > 0:
		_mode = "stems"
		_start_stems(cue, fade, _saved_pos, _saved_stem_weights)
	else:
		_mode = "single"
		_restore_single(cue, fade, _saved_pos)

	_paused = false

func _restore_single(cue: MusicCue, fade: float, pos: float) -> void:
	# If we were in the intro, try resuming intro. If no intro stream, fall back to loop.
	var stream_to_play: AudioStream = _saved_single_stream
	var was_intro := _saved_single_intro_playing

	_single_loop_stream = cue.loop

	if was_intro and cue.intro != null and stream_to_play == cue.intro:
		_single_intro_playing = true
		_play_on_main(cue.intro, fade, pos, cue.target_db)
		return

	# Otherwise resume loop
	if cue.loop != null:
		_single_intro_playing = false
		_play_on_main(cue.loop, fade, pos, cue.target_db)
	else:
		# If no loop exists, just play whatever we had
		_single_intro_playing = false
		if stream_to_play != null:
			_play_on_main(stream_to_play, fade, pos, cue.target_db)


# -------------------------
# Single-track intro -> loop
# -------------------------

func _start_single_intro_loop(cue: MusicCue, fade: float) -> void:
	var intro := cue.intro
	var loop := cue.loop

	_single_intro_playing = false
	_single_loop_stream = loop

	# If there is an intro, play it first then swap to loop on finished
	if intro != null:
		_single_intro_playing = true
		_play_on_main(intro, fade, 0.0, cue.target_db)
	else:
		# No intro go straight to loop 
		if loop == null:
			push_warning("MusicManager: cue has no intro and no loop: %s" % cue.cue_name)
			return
		_play_on_main(loop, fade, 0.0, cue.target_db)

func _on_main_finished() -> void:
	# Only relevant for single-track cues where intro finished
	if _mode != "single":
		return
	if not _single_intro_playing:
		return

	_single_intro_playing = false

	if _single_loop_stream == null:
		return

	# Switch to loop without a big fade (intro already ended)
	# We just start loop at full target.
	var target_db := (_cue.target_db if _cue else 0.0)
	_play_on_main(_single_loop_stream, 0.05, 0.0, target_db)

# -------------------------
# Stem-based dynamic music
# -------------------------

func _start_stems(cue: MusicCue, fade: float, start_pos := 0.0, initial_mix: Dictionary[String, float] = {}) -> void:
	_clear_stems()
	_stem_target_db = cue.target_db

	for stem_name in cue.stems.keys():
		var stream: AudioStream = cue.stems[stem_name]
		if stream == null:
			continue

		var p := AudioStreamPlayer.new()
		p.name = "Stem_%s" % stem_name
		p.bus = bus_name
		p.volume_db = -80.0
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.stream = stream
		add_child(p)

		_stem_players[String(stem_name)] = p

	# Start all stems in sync at the saved time
	for p in _stem_players.values():
		p.play(start_pos)

	# Determine initial mix
	var mix := initial_mix.duplicate()
	if mix.is_empty():
		mix = cue.default_mix.duplicate()
		if mix.is_empty() and _stem_players.has("base"):
			mix["base"] = 1.0

	# Apply mix (no bar alignment during start)
	set_stem_mix(mix, fade, false)


func _set_stem_weight(name: String, weight: float, fade: float) -> void:
	weight = clampf(weight, 0.0, 1.0)
	if not _stem_players.has(name):
		push_warning("MusicManager: unknown stem '%s'" % name)
		return

	_stem_weights[name] = weight  

	var p := _stem_players[name]
	var target_db := lerpf(-80.0, _stem_target_db, weight)
	_fade_to(p, target_db, fade, false)


# -------------------------
# Core playback + fades
# -------------------------

func _play_on_main(stream: AudioStream, fade: float, start_pos: float, target_db: float) -> void:
	# Use inactive main player, fade it in, fade active out
	_inactive_main.stop()
	_inactive_main.stream = stream
	_inactive_main.volume_db = -80.0
	_inactive_main.play(start_pos)

	_crossfade(_active_main, _inactive_main, target_db, fade)

	# swap
	var old := _active_main
	_active_main = _inactive_main
	_inactive_main = old

func _stop_current(fade: float) -> void:
	# Stop main players
	_fade_to(_active_main, -80.0, fade, true)
	_fade_to(_inactive_main, -80.0, 0.05, true)

	# Stop stems if active
	if _mode == "stems":
		for p in _stem_players.values():
			_fade_to(p, -80.0, fade, true)

func _clear_stems() -> void:
	for p in _stem_players.values():
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
	_stem_players.clear()
	_stem_weights.clear()


func _crossfade(from_p: AudioStreamPlayer, to_p: AudioStreamPlayer, to_db: float, dur: float) -> void:
	_fade_to(to_p, to_db, dur, false)
	_fade_to(from_p, -80.0, dur, true)

func _fade_to(p: AudioStreamPlayer, target_db: float, dur: float, stop_when_done: bool) -> void:
	if p == null:
		return

	# Kill any existing tween for this player
	if _fade_tween.has(p) and is_instance_valid(_fade_tween[p]):
		_fade_tween[p].kill()

	var tw := create_tween()
	_fade_tween[p] = tw
	tw.tween_property(p, "volume_db", target_db, dur)
	if stop_when_done:
		tw.tween_callback(func():
			if is_instance_valid(p):
				p.stop()
		)

func _bar_length_sec() -> float:
	if _cue == null or _cue.bpm <= 0.0 or _cue.beats_per_bar <= 0:
		return 0.0
	return (60.0 / _cue.bpm) * float(_cue.beats_per_bar)

func _get_music_time_sec() -> float:
	# Use main player time for single mode, stem base if available for stems mode.
	if _mode == "stems" and _stem_players.has("base"):
		return _stem_players["base"].get_playback_position()
	return _active_main.get_playback_position()

func _time_until_next_bar() -> float:
	var bar_len := _bar_length_sec()
	if bar_len <= 0.0:
		return 0.0

	var t := _get_music_time_sec() - (_cue.bar_offset_sec if _cue else 0.0)
	# Ensure positive
	while t < 0.0:
		t += bar_len

	var into_bar := fmod(t, bar_len)
	var remain := bar_len - into_bar

	# If we're extremely close, hop to next bar
	if remain < 0.01:
		remain = bar_len
	return remain

func play_cue_aligned(cue: MusicCue, fade := -1.0) -> void:
	if cue == null:
		return
	if fade < 0.0:
		fade = default_fade

	# Wait to next bar of the CURRENT cue, then switch
	var wait := _time_until_next_bar()
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout

	play_cue(cue, fade)
