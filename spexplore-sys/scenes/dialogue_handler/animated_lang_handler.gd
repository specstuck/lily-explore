@tool
class_name AnimatedLangHandler extends LangHandler
@export_group("Animations")
@export var animation: String
@export_subgroup("Overrides")
@export var intro_anim: String = "" #Plays when starting a dialogue 
@export var outro_anim: String = ""#Plays when ending a dialogue
@export var talk_anim: String = "" #Plays during a line
@export var talk_start_anim: String = "" #Plays during a line
@export var talk_stop_anim: String = "" #Plays during a line


@onready var animations: Dictionary = {
	"intro": intro_anim,
	"outro": outro_anim,
	"talking": talk_anim,
	"talk_start": talk_start_anim,
	"talk_stop": talk_stop_anim
}

# On dialogue start, play start intro if necessary
# On dialogue start also queue talk
# init can be any point prior 

# On end of dialogue play end anim
# Clear text box
# Advance

# Called when the node enters the scene tree for the first time.

func queue_anim(animation_type: String):
	var animation_name = animations.get(animation_type)
	if(animation_name):
		print("playing " + animation_name + " on " + name)
		$AnimationPlayer.queue(animation_name)
	else:
		print("playing " + animation + "/" + animation_type + " on " + name)
		$AnimationPlayer.queue(animation + "/" + animation_type)
	pass

func _dialog(dialog: Dictionary):
	#_queue_anim(start_anim)
	super(dialog)
	pass

func _on_speaker_updated() -> void:
	#_queue_anim(end_anim)
	print("changing speaker to " + talk_sprite.sprite_frames.resource_name if talk_sprite else "")
	if(persist):
		queue_anim("outro")
		queue_anim("intro")
	pass # Replace with function body.

func show_line():
	super()
	if(persist):
		queue_anim("talk_start")
	else:
		queue_anim("intro")
	queue_anim("talking")
	pass 

func hide_dialog():
	if(persist):
		queue_anim("talk_stop")
	else:
		queue_anim("outro")
	$TextContainer/DialogueBoxTexture.hide()
	$TextContainer/DialogueBoxMask.hide()
	pass
	
func is_playing() -> bool:
	return $AnimationPlayer.is_playing()
