class_name DialogueHandler
extends Node2D

@export var dialogue_path: String = "res://lang/dialogue.json"

signal dialogue_ended

var _db: Dictionary = {}
#NOTE: Dialogue index can be an integer, or a prefixed integer: example/1
var dialog_index: String = "1"
var dialog: Dictionary
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_db()
	#_start_dialogue()
	pass

func _load_db() -> void:
	var f = FileAccess.open(dialogue_path, FileAccess.READ)
	if f == null:
		push_error("Missing dialogue: %s" % dialogue_path)
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		push_error("Bad JSON: %s" % json.get_error_message())
		return
	_db = json.data if json.data is Dictionary else {}
	return

func _start_dialogue(index: String = dialog_index):
	dialog_index = index
	dialog = _db.get(dialog_index)
	if(dialog == null):
		push_warning("Missing dialogue index: %s" % dialog_index)
		emit_signal("dialogue_ended")
		return
	for lang_handler in self.get_children():
		if(lang_handler is LangHandler && lang_handler.id == dialog.get("id", "")):
			print("Starting " + dialog_index + " at " + lang_handler.id)
			lang_handler._dialog(dialog)
			pass 
	return

func _advance(new_index: String = ""):
	if(new_index == ""):
		var split_index = dialog_index.split("/")
		var index_incremented = String.num(split_index.get(split_index.size() - 1).to_int() + 1, 0)
		dialog_index = index_incremented if split_index.size() == 1 else split_index.get(0) + "/" + index_incremented
		pass
	else:
		dialog_index = new_index
		pass
	_start_dialogue()
	pass

func _skip():
		for lang_handler in self.get_children():
			if(lang_handler is LangHandler):
				if(lang_handler.id == dialog.get("id", "")):
					print("Advancing " + dialog_index + " at " + lang_handler.id)
					lang_handler.skip()
					return

func _on_skip_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if($SkipBox/SkipTimer.is_stopped() && event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed):
		_skip()
		$SkipBox/SkipTimer.start()
	pass
