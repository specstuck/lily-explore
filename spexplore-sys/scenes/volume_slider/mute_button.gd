extends TextureButton
@onready var volume_tex = load("res://assets/texture/volume.png")
@onready var volume_mute_tex = load("res://assets/texture/volumemute.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#volume_tex 
	#volume_mute_tex 
	pass # Replace with function body.

func _on_mouse_entered() -> void:
	self.modulate.a = .6
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	self.modulate.a = .4
	pass # Replace with function body.

func _on_toggled(_toggled_on: bool) -> void:
	print("pressed")
	if(button_pressed):
		self.texture_normal = volume_mute_tex
	else:
		self.texture_normal = volume_tex
	pass
