extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	self.modulate.a = 1
	pass # Replace with function body.

func _on_mouse_exited() -> void:
	self.modulate.a = .6
	pass # Replace with function body.
