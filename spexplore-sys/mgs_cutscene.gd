extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$MGS_UI/AnimationPlayer.play("Setup")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if(anim_name == 'Setup'):
		$DialogueHandler._start_dialogue()
		#$MGS_UI/AnimationPlayer.play("Loop")
	pass # Replace with function body.
