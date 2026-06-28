extends Resource
class_name MusicCue

@export var cue_name := ""
@export var bpm := 120.0
@export var beats_per_bar := 4
@export var bar_offset_sec := 0.0

# Optional: single-track music with intro/loop (no stems)
@export var intro: AudioStream = null
@export var loop: AudioStream = null  # should be set to loop in Import settings

# Optional: stem-based music (base is required if you use stems)
# Example keys: "base", "cave", "combat", "danger", "indoors"
@export var stems: Dictionary[String, AudioStream] = {}

# Default mix when cue starts (0..1 per stem)
@export var default_mix: Dictionary[String, float] = {}

# Volume target for the whole cue
@export var target_db := 0.0
