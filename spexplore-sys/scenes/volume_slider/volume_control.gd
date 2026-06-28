extends Node

var volume_db = -80
@export var BGMusic: AudioStream

@export var fade_in = false
@export var fade_in_rate:float = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BGMusic.stream = BGMusic
	$BGMusic.play()
	pass 

func _process(delta: float) -> void:
	proc_fade_in(delta)
	pass

#VOLUME CODE
# INFO: Possibly can cause lag, if it does move the first 2 lines to slider.drag_started()
func _on_volume_slider_value_changed(_value: float) -> void:
	volume_db = -80
	$MuteButton.button_pressed = false
	set_volume()
	pass 

func _on_mute_button_toggled(_toggled_on: bool) -> void:
	var swap = linear_to_db($VolumeSlider.value)
	$VolumeSlider.set_value_no_signal(db_to_linear(volume_db))
	volume_db = swap
	set_volume()
	pass 

func set_volume():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db($VolumeSlider.value))
	pass

#VISIBILITY CODE
func proc_fade_in(delta: float):
	if(fade_in):
		self.modulate.a += delta * fade_in_rate
		if(self.modulate.a >= 1): 
			self.modulate.a = 1
			fade_in = false
	pass
