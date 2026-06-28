class_name Stopwatch extends Node

var time: float = 0
var stopped: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!stopped):
		time += delta
	pass

func _get_time() -> float:
	return time

func _reset():
	time = 0
	pass

func _start():
	stopped = false


func _stop():
	stopped = true
