extends Node2D

## DIALOG SYSTEM NOTES:
#Index and ID are mandatory
#Format establishes a base font for the whole Dialog
## Sprite
#Mood establishes a base mood for the whole Dialog
#Speaker establishes an initial speaker for the Dialog, can be overridden by Text Speaker
## Text
#Line Value represents the text for this line of dialog
#Line Speaker changes the speaker for the rest of the Dialog
#Line Mood overrides the mood for this line of dialog
#Line Format overrides the format for the rest of the Dialog
## Title
#Title represents the text for the title
#Title Format overrides the format for the title

@export var export_path: String = "res://dialogue_export.json"
var _db: Dictionary = {}

var current_dialog = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_db()
	pass # Replace with function body.

func _load_db() -> void:
	var f = FileAccess.open(export_path, FileAccess.READ)
	if f == null:
		push_error("Missing dialogue: %s" % export_path)
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("Bad JSON: %s" % json.get_error_message())
		return
	_db = json.data if json.data is Dictionary else {}
	$FullPreview.text = JSON.stringify(_db, "\t")
	return

func _on_update_dialog() -> void:
	if(!is_dialog_valid()): return
	
	current_dialog.set("id", $ID.text)
	
	if($Format.text): current_dialog.set("format", $Format.text)
	
	if($Title.text):
		var title: Dictionary
		title.set("value", $Title.text)
		if($TitleFormat.text): title.set("format", $TitleFormat.text)
		current_dialog.set("title", title)
		
	current_dialog.get_or_add("text", [])
	
	var sprite: Dictionary
	if($Mood.text || $Speaker.text):
		if($Mood.text): sprite.set("mood", $Mood.text)
		if($Speaker.text): sprite.set("speaker", $Speaker.text)
		current_dialog.set("sprite", sprite)
	update_preview()
	pass 

func _on_submit_dialog_pressed() -> void:
	if($Index.text == ""):
		push_error("No Index")
		return
	if(!is_dialog_valid()): return
	_on_update_dialog()
	var index = $Index.text if !$Prefix.text else ($Prefix.text + "/" + $Index.text)
	_db.set(index, current_dialog.duplicate_deep())
	$FullPreview.text = JSON.stringify(_db, "\t")
	
	(current_dialog.get("text") as Array).clear()
	var index_num = int($Index.text)
	if(index_num > 0):
		$Index.text = String.num_int64(index_num + 1)
	dialog_clear()
	pass

func is_dialog_valid() -> bool:
	if($ID.text == ""):
		push_error("Empty ID")
		return false
	#if($Mood.text == ""):
		#push_error("Empty Mood")
		#return false
	return true

func dialog_clear():
	$ID.clear()
	$Format.clear()
	$Title.clear()
	$TitleFormat.clear()
	$Speaker.clear()
	$Mood.clear()
	
	$Preview.text = ""
	pass

func _on_submit_text_pressed() -> void:
	_on_update_dialog()
	
	if(current_dialog.get("text") == null):
		push_error("No associated dialog")
		return
	
	if($TextValue.text == ""):
		push_error("No text value")
		return
	
	var line: Dictionary = {}
	
	line.set("value", $TextValue.text)
	if($TextFormat.text): line.set("format", $TextFormat.text)
	if($TextSpeaker.text): line.set("speaker", $TextSpeaker.text)
	if($TextMood.text): line.set("mood", $TextMood.text)
	if($TextSpeed.value > 0): line.set("speed", $TextSpeed.value)
	if($TextDelay.value > -1): line.set("delay", $TextDelay.value)
	
	current_dialog.get("text").push_back(line)
	update_preview()
	text_clear()
	pass

func text_clear():
	$TextValue.clear()
	$TextFormat.clear()
	$TextMood.clear()
	$TextSpeaker.clear()
	$TextSpeed.value = -1
	$TextDelay.value = -1
	pass

func _on_undo_text_pressed() -> void:
	var lines:Array = current_dialog.get("text")
	lines.pop_back()
	update_preview()
	pass

func update_preview():
	$Preview.text = JSON.stringify(current_dialog, "\t")
	#print($Preview.text)
	pass

func _on_export_pressed() -> void:
	_on_submit_dialog_pressed()
	
	var db_string:String = JSON.stringify(_db, "\t")
	var file = FileAccess.open(export_path, FileAccess.WRITE)
	file.store_string(db_string)
	file.close()
	pass

func _on_save_preview_pressed() -> void:
	var file = FileAccess.open(export_path, FileAccess.WRITE)
	file.store_string($FullPreview.text)
	file.close()
	pass # Replace with function body.
