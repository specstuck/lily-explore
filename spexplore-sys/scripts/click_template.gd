extends Area2D
class_name ClickableItem

## The dialogue event name to pass to EventHandler.dialogue_start()
@export var dialogue_event: String = ""

## Optional sound to play when clicked (passed to UisfxSound.play)
@export var click_sound: String = ""

## Optional flag to set when clicked (passed to EventHandler.set_flag)
@export var flag_name: String = ""
@export var flag_value = true

@onready var hover_label: Label = $Label 

func _ready() -> void:
	if hover_label:
		hover_label.visible = false
	# Enable mouse detection
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

func _on_mouse_entered() -> void:
	if hover_label:
		hover_label.visible = true

func _on_mouse_exited() -> void:
	if hover_label:
		hover_label.visible = false

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		interact()

func interact() -> void:
	# 1. Start dialogue
	if not dialogue_event.is_empty():
		EventHandler.dialogue_start(dialogue_event)
	# 2. Play sound if provided
	if not click_sound.is_empty():
		UisfxSound.play(click_sound)
	else:
		UisfxSound.play("blip")
	# 3. Update progress flag if provided
	if not flag_name.is_empty():
		EventHandler.set_flag(flag_name, flag_value)
