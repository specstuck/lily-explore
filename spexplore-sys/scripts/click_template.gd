@tool
extends Area2D
class_name ClickableItem

## The dialogue event name to pass to EventHandler.dialogue_start()
@export var dialogue_event: String = ""

## Optional sound to play when clicked (passed to UisfxSound.play)
@export var click_sound: String = ""
@export var label_text = ""

## Optional flag to set when clicked (passed to EventHandler.set_flag)
@export var flag_name: String = ""
@export var flag_value = true

## Optional location for new scene on click
@export var scene_mover = false
@export var scene_location = 0

@export var click_image: CompressedTexture2D:
	set(value):
		click_image = value
		$Sprite2D.texture = value
		var collision_shape = $CollisionShape2D
		if collision_shape:
			var bounding_box = RectangleShape2D.new()
			bounding_box.size = click_image.get_size()
			$CollisionShape2D.shape = bounding_box
		#$CollisionShape2D.shape.size = value.get_size()

@onready var hover_label: Label = $Label 

func _ready() -> void:
	$Label.text = label_text
	if hover_label:
		hover_label.visible = false
	#$Sprite2D.texture = click_image
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
	#print($CollisionShape2D.shape.size)
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
	if scene_mover:
		if(scene_location == -1):
			RoomManager.back()
			return
		RoomManager.change_room(scene_location)
