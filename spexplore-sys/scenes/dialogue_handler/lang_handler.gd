@tool
class_name LangHandler extends Control
var dialog_handler: DialogueHandler

@export_group("Dialogue")
@export var id: String

var autoadvance: bool = false #Uses delay at end of line. Otherwise, does not continue line by line
var default_speed: float = 20 #Chars per second
var timed: bool = false #Uses time and scroll ratio instead of speed
var default_delay: float = 1 #Delay in S on end of line
var textbox: bool #Displays text box

var default_time: float #Time taken to show full line
var scroll_ratio: float = 1.3 #Multiplier for scroll speed, line finishes X times faster, and holds on full line for remaining duration

var sprite: bool = true
var persist: bool #Persist portrait when dialogue is ended
var idle_mood: String

#Constant references to objects
@onready var title_box: RichTextLabel = $TitleBox
@onready var talk_sprite: AnimatedSprite2D = $TalkSprite
@onready var dialogue_box: RichTextLabel = $TextContainer/TextMargin/DialogueBox
@onready var dialogue_box_mask: NinePatchRect = $TextContainer/DialogueBoxMask
@onready var dialogue_box_texture: NinePatchRect = $TextContainer/DialogueBoxTexture
@onready var delay_timer: Timer = $DelayTimer
@onready var stopwatch: Node = $Stopwatch

#Parsed values for when the dialog is initialized
#var dialog_id: String
var format: String
var title: String
var title_format: String
var text_array: Array
var speaker: String
var default_mood: String = "default"

#Values for dialogue handling
var current_dialog
var text_index: int
var typing: bool
var line_params
var max_chars: int = 0
var current_speed: float = default_speed
var current_delay: float = default_delay
var current_time: float = default_time
#Talk Sprite params
var default_speaker: SpriteFrames

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent: Node = get_parent()
	if(dialog_handler == null && parent is DialogueHandler):
		dialog_handler = parent
		pass
	
	if(!textbox): 
		$TextContainer/DialogueBoxTexture.hide()
		$TextContainer/DialogueBoxMask.hide()
		$TextContainer/TextMargin.add_theme_constant_override("margin_top", 0)
		$TextContainer/TextMargin.add_theme_constant_override("margin_bottom", 0)
		$TextContainer/TextMargin.add_theme_constant_override("margin_left", 0)
		$TextContainer/TextMargin.add_theme_constant_override("margin_right", 0)
	
	# TalkSprite Code
	if(!talk_sprite.sprite_frames): 
		set_speaker("default")
	pass

func _process(_delta: float) -> void:
	if(typing):
		if(current_time == 0): 
			dialogue_box.visible_characters = int($Stopwatch._get_time() * current_speed)
			pass
		else:
			dialogue_box.visible_ratio = $Stopwatch._get_time() / (current_time) * scroll_ratio
			pass
		if($DelayTimer.is_stopped() && 
		(dialogue_box.visible_characters >= max_chars || (current_time > 0 && $Stopwatch._get_time() >= current_time))):
			if(autoadvance):
				delay_timer.start()
			typing = false
			set_sprite_idle()
			pass
		pass
	pass

func _dialog(dialog: Dictionary):
	#clear_dialog()
	current_dialog = dialog
	text_index = 0
	parse_dialog(dialog)
	advance_line()
	pass

func parse_dialog(dialog: Dictionary):
	#dialog_id = dialog.get("id","")
	format = dialog.get("format", "")
	update_format(format)
	
	var titleDict = dialog.get("title")
	if(titleDict):
		title = titleDict.get("value", "")
		title_format = titleDict.get("format", "")
		title_box.text = title
		update_title_format(title_format)
	
	var spriteDict = dialog.get("sprite")
	if(spriteDict):
		default_mood = spriteDict.get("mood", default_mood)
		set_speaker(spriteDict.get("speaker", ""))
		if(speaker): update_format(speaker)
	
	text_array = dialog.get("text", [])
	pass

func clear_dialog():
	current_dialog = null
	text_index = 0
	format = ""
	title = ""
	title_format = ""
	text_array = []
	default_mood = "default"
	
	dialogue_box.text = ""
	dialogue_box.visible_characters = 0
	dialogue_box.visible_ratio = 0
	typing = false
	max_chars = 0
	
	title_box.text = ""
	set_sprite_idle()
	hide_dialog()
	pass

func hide_dialog():
	if(!persist):
		talk_sprite.hide()
	$TextContainer/DialogueBoxTexture.hide()
	$TextContainer/DialogueBoxMask.hide()

func end_dialog():
	dialog_handler._advance()
	clear_dialog()
	pass

func advance_line():
	if(text_index == text_array.size()):
		end_dialog()
		return
	parse_line()
	if(line_params == null): return
	show_line()
	if(sprite): show_sprite_line()
	if(textbox): 
		$TextContainer/DialogueBoxTexture.show()
		$TextContainer/DialogueBoxMask.show()
	text_index += 1
	pass

func skip():
	if(typing):
		if(current_time != 0): 
			dialogue_box.visible_ratio = 1
		else: dialogue_box.visible_characters = max_chars
		set_sprite_idle()
		typing = false
	elif(current_dialog):
		advance_line()

func parse_line():
	line_params = text_array.get(text_index)
	var line_format = line_params.get("format", "")
	if(line_format):
		update_format(line_format)
		pass
	pass
	
	var new_speed = line_params.get("speed", "")
	if(new_speed):
		current_speed = float(new_speed)
		pass
	else: 
		current_speed = default_speed
		pass
	
	var new_delay = line_params.get("delay", "")
	if(new_delay):
		current_delay = float(new_delay)
		pass
	else: 
		current_delay = default_delay
		pass
	delay_timer.wait_time = current_delay
	
	var new_time = line_params.get("time", "")
	if(new_time):
		current_time = float(new_time)
		pass
	else: 
		current_time = default_time
		pass

func show_line():
	var line: String = line_params.get("value")
	print(line)
	dialogue_box.text = line
	dialogue_box.visible_ratio = 0
	dialogue_box.visible_characters = 0
	typing = true
	max_chars = line.length()
	
	stopwatch._reset()
	delay_timer.stop()
	pass

func show_sprite_line():
	line_params = text_array.get(text_index)
	var new_speaker = line_params.get("speaker", "")
	if(new_speaker):
		set_speaker(new_speaker)
		pass
	
	var new_mood = line_params.get("mood")
	if(is_valid_mood(new_mood)):
		talk_sprite.animation = new_mood
		pass
	else:
		talk_sprite.animation = default_mood
		pass
	
	talk_sprite.show()
	talk_sprite.play()
	pass

#Talk Sprite Code
func set_speaker(speaker_id: String):
	if(speaker_id): talk_sprite.sprite_frames = DialogueHelper.speakers.get(speaker_id, DialogueHelper.speakers.get("default")) 
	pass

func is_valid_mood(mood) -> bool:
	return talk_sprite.sprite_frames && mood && talk_sprite.sprite_frames.get_animation_names().find(mood) > -1

func set_sprite_idle() -> void:
	if(idle_mood):
		talk_sprite.animation = idle_mood
	else:
		talk_sprite.frame = talk_sprite.sprite_frames.get_frame_count(talk_sprite.animation) - 1
		talk_sprite.pause()
	pass

func update_format(format_name: String):
	var dialog_format = DialogueHelper.get_format(format_name)
	title_box.theme = dialog_format.get("title")
	dialogue_box.theme = dialog_format.get("text")
	talk_sprite.sprite_frames = dialog_format.get("speaker")
	dialogue_box_mask.modulate = dialog_format.get("color")
	
	title_box.text = dialog_format.get("title-text")
	pass

func _on_delay_timer_timeout() -> void:
	advance_line()
	pass

##Title Box Code
func update_title_format(format_name: String):
	var title_theme = DialogueHelper.text_formats.get(format_name)
	if(title_theme):
		title_box.theme = title_theme
		pass
	pass

##Properties Code
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	properties.append({
		"name" = "Text",
		"type" = TYPE_NIL,
		"usage" = PROPERTY_USAGE_SUBGROUP
	})
	properties.append({
		"name": "Textbox",
		"type": TYPE_BOOL
	})
	properties.append({
		"name": "Autoadvance",
		"type": TYPE_BOOL
	})
	if(!autoadvance):
		properties.append({
			"name": "Default Speed",
			"type": TYPE_FLOAT
		})
	else:
		properties.append({
			"name": "Timed",
			"type": TYPE_BOOL
		})
		if(timed):
			properties.append({
				"name": "Scroll Ratio",
				"type": TYPE_FLOAT
			})
			properties.append({
				"name": "Default Time",
				"type": TYPE_FLOAT
			})
			properties.append({
				"name": "Default Delay",
				"type": TYPE_FLOAT
			})
		else: 
			properties.append({
				"name": "Default Speed",
				"type": TYPE_FLOAT
			})
			properties.append({
				"name": "Default Delay",
				"type": TYPE_FLOAT
			})
			pass
	properties.append({
		"name" = "Sprite",
		"type" = TYPE_NIL,
		"usage" = PROPERTY_USAGE_SUBGROUP
	})
	properties.append({
		"name": "Sprite",
		"type": TYPE_BOOL
	})
	if(sprite):
		properties.append({
			"name": "Persist",
			"type": TYPE_BOOL
		})
		properties.append({
			"name": "Idle Mood",
			"type": TYPE_STRING
		})
		pass
	return properties

func _set(prop_name: StringName, val) -> bool:
	var retval: bool = true
	match prop_name: 
		"Textbox": 
			textbox = val
		"Autoadvance":
			autoadvance = val
			notify_property_list_changed()
		"Default Delay": 
			default_delay = val
		"Timed":
			timed = val
			notify_property_list_changed()
		"Default Time": 
			default_time = val
		"Scroll Ratio": 
			scroll_ratio = val
		"Default Speed": 
			default_speed = val
		"Sprite": 
			sprite = val
			notify_property_list_changed()
		"Persist": 
			persist = val
		"Idle Mood": 
			idle_mood = val
		_:
			retval = false
	return retval

func _get(prop_name: StringName):
	match prop_name:
		"Textbox":
			return textbox
		"Autoadvance":
			return autoadvance
		"Default Delay":
			return default_delay
		"Timed":
			return timed
		"Default Time":
			return default_time
		"Scroll Ratio":
			return scroll_ratio
		"Default Speed":
			return default_speed
		"Sprite":
			return sprite
		"Persist":
			return persist
		"Idle Mood":
			return idle_mood
	return null
