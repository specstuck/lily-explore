@tool
class_name AnimatedPlogLangHandler extends AnimatedLangHandler

func _ready():
	super()
	stopwatch._stop()

func _process(_delta: float) -> void:
	if(typing):
		if(current_time == 0): 
			dialogue_box.visible_characters = int($Stopwatch._get_time() * current_speed)
			pass
		if($DelayTimer.is_stopped() &&  dialogue_box.visible_characters >= max_chars):
			if(autoadvance):
				delay_timer.start()
			stopwatch._stop()
			typing = false
			set_sprite_idle()
			pass
		pass
	pass

func update_format(format_name: String):
	var dialog_format = DialogueHelper.get_format(format_name)
	dialogue_box.theme = dialog_format.get("text")
	pass

func show_line():
	if(persist):
		queue_anim("talk_start")
	else:
		queue_anim("intro")
	queue_anim("talking")
	
	var line: String = line_params.get("value")
	print(line)
	dialogue_box.text = dialogue_box.text + line + "\n"
	max_chars = dialogue_box.text.length()
	typing = true
	
	stopwatch._start()
	delay_timer.stop()
	pass

func clear_dialog():
	super()
	stopwatch._stop()
	stopwatch._reset()
	pass

func skip():
	stopwatch.time = max_chars / current_speed
	super()
