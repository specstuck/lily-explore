extends Node

## Current active room node (must have an exported 'room_number' variable)
var current_room: Node = null
var back_rooms: Array[int] = [0]

## Changes to the room with number 'target_number'.
## All rooms should be children of a single parent (e.g., a 'Rooms' node).
func change_room(target_number: int) -> void:
	var rooms_parent = get_tree().get_first_node_in_group("rooms_parent")
	if not rooms_parent:
		push_error("RoomManager: No node with group 'rooms_parent' found.")
		return

	var target_room: Node = null
	for child in rooms_parent.get_children():
		if child.has_method("get_room_number") and child.get_room_number() == target_number:
			target_room = child
			break

	if not target_room:
		push_error("RoomManager: No room with number %d found." % target_number)
		return

	# Hide current room
	if current_room and is_instance_valid(current_room):
		current_room.visible = false
		back_rooms.push_back(current_room.get_room_number())

	# Show target room
	target_room.visible = true
	current_room = target_room

func back():
	if(!back_rooms.is_empty()):
		change_room(back_rooms.pop_back())
		back_rooms.pop_back()
	pass
