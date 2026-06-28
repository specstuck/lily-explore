extends Node3D

func _ready() -> void:
	$AnimationPlayer.queue("RESET")
	$AnimationPlayer.queue("center")
	$AnimationPlayer.queue("left")
