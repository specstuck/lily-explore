extends Node
var default_frames: SpriteFrames = preload("res://assets/texture/animations/default.tres")
var mike_frames: SpriteFrames = preload("res://assets/texture/animations/mike.tres")
var lily_frames: SpriteFrames = preload("res://assets/texture/animations/lily.tres")
var eden_frames: SpriteFrames = preload("res://assets/texture/animations/eden.tres")
var john_frames: SpriteFrames = preload("res://assets/texture/animations/john.tres")
var dave_frames: SpriteFrames = preload("res://assets/texture/animations/dave.tres")
var mikeTrickster_frames : SpriteFrames = preload("res://assets/texture/animations/mike_trickster.tres")

var default: Theme = preload("res://assets/lang/theme/default.tres")
var lily_title: Theme = preload("res://assets/lang/theme/lily_title.theme")
var lily_dialogue: Theme = preload("res://assets/lang/theme/lily_dialogue.tres")
var mike_title: Theme = preload("res://assets/lang/theme/mike_title.theme")
var mike_dialogue: Theme = preload("res://assets/lang/theme/mike_dialogue.tres")
var eden_title: Theme = preload("res://assets/lang/theme/eden_title.theme")
var eden_dialogue: Theme = preload("res://assets/lang/theme/eden_dialogue.tres")
var john_title: Theme = preload("res://assets/lang/theme/john_title.theme")
var john_dialogue: Theme = preload("res://assets/lang/theme/john_dialogue.tres")
var dave_title: Theme = preload("res://assets/lang/theme/dave_title.theme")
var dave_dialogue: Theme = preload("res://assets/lang/theme/dave_dialogue.tres")
var mgs_dialogue: Theme = preload("res://assets/lang/theme/mgs_dialogue.tres")
var narrator: Theme = preload("res://assets/lang/theme/narrator.theme")

var defaultColor: Color = Color.BLACK
var mikeColor: Color = Color("a78e00")
var lilyColor: Color = Color("5d19b3")
var edenColor: Color = Color("c00015")
var johnColor: Color = Color("0715cd")
var daveColor: Color = Color("e00707")

var text_formats: Dictionary[String, Theme] = {
	"default": default,
	"mike-title": mike_title,
	"mike-dialogue": mike_dialogue,
	"lily-title": lily_title,
	"lily-dialogue": lily_dialogue,
	"eden-title": eden_title,
	"eden-dialogue": eden_dialogue,
	"narrator-title": narrator,
	"narrator-dialogue": narrator,
}

var speakers: Dictionary[String, SpriteFrames] = {
	"default": default_frames,
	"mike": mike_frames,
	"lily": lily_frames,
	"eden": mikeTrickster_frames,
	"mike-trickster": mikeTrickster_frames
}

var colors: Dictionary[String, Color] = {
	"mike": mikeColor,
	"lily": lilyColor,
	"eden": edenColor,
	"john": johnColor,
	"dave": daveColor,
	"narrator": defaultColor
}

var titles: Dictionary[String, String] = {
	"mike": "MIKE",
	"lily": "LILY",
	"eden": "EDEN",
	"john": "JOHN",
	"dave": "DAVE",
}

func get_format(format_name: String) -> Dictionary:
	var format = formats.get(format_name, {})
	if(format != {}):
		return format
	format.set("title", text_formats.get(format_name + "-title", default))
	format.set("text", text_formats.get(format_name + "-dialogue", default))
	format.set("speaker", speakers.get(format_name, default_frames))
	format.set("color", colors.get(format_name, defaultColor))
	
	format.set("title-text", titles.get(format_name, ""))
	return format

var formats: Dictionary = {
}
