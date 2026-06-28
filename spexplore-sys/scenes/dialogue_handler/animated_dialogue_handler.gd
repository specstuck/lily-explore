class_name AnimatedDialogueHandler extends DialogueHandler

func _play_anim(animation_name: String, id: String = ""):
	for lang_handler in self.get_children():
		if(lang_handler is AnimatedLangHandler && (id == "" || lang_handler.id == id)):
			lang_handler._play_anim(animation_name)
			pass 
	pass
