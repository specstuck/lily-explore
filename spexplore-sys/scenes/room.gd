extends Node2D
class_name Room

@export var room_number: int = 0
@export var background: CompressedTexture2D

func get_room_number() -> int:
	return room_number

func _ready() -> void:
	$TextureRect.texture = background
	# Start with only the first room visible
	visible = (room_number == 0)
