extends Node

## EventHandler - Global event coordinator.

## This autoload singleton provides a central hub for passing events between buttons,
## UI elements, and the dialogue system. It supports direct method calls (e.g., from buttons)
## and emits signals for loosely‑coupled components.

## Typical usage:
##   - Call EventHandler.dialogue_start("greeting") to trigger a dialogue event.
##   - Call EventHandler.on_button_pressed("inventory") from any button's pressed signal.
##   - The dialogue system should register itself via register_dialogue_system().

## Ko if you have questions please ask. This is really Godot-y
## Everyone else you're fine glhf.

# ------------------------------------------------------------------------------
# Signals: Allow any node to listen without knowing the sender.
# ------------------------------------------------------------------------------

## Emitted when a dialogue event is requested, before any direct call.
## Listeners can handle the event even if no dialogue system is registered.
signal dialogue_requested(event_name: String)

## Emitted when a dialogue choice is made. The optional event_name helps context.
signal choice_made(choice_id: String, event_name: String)

## Emitted when any button (identified by a unique string) is pressed.
signal button_event(button_id: String)

## Emitted when an unknown or erroneous event occurs.
signal error_occurred(error_message: String)

# ------------------------------------------------------------------------------
# Member Variables
# ------------------------------------------------------------------------------

## Reference to the active dialogue system node (must have `start_dialogue(event_name)`).
## Use `register_dialogue_system()` to set this. Keeping a weak reference prevents
## memory leaks if the dialogue system is freed.
var _dialogue_system: WeakRef = null

# ------------------------------------------------------------------------------
# Public API - Registration
# ------------------------------------------------------------------------------

## Registers the dialogue system node so that dialogue_start() can call it directly.
## The node must have a method `start_dialogue(event_name: String) -> void`.

## Example:
##   EventHandler.register_dialogue_system($DialogueManager)
func register_dialogue_system(system: Node) -> void:
	if not system.has_method("start_dialogue"):
		push_error("EventHandler: Registered node does not have a 'start_dialogue' method.")
		emit_signal("error_occurred", "Dialogue system missing start_dialogue method")
		return
	_dialogue_system = weakref(system)
	print("[EventHandler] Dialogue system registered: ", system.name)

## Unregisters the current dialogue system.
func unregister_dialogue_system() -> void:
	_dialogue_system = null
	print("[EventHandler] Dialogue system unregistered.")

# ------------------------------------------------------------------------------
# Public API - Dialogue Control
# ------------------------------------------------------------------------------

## Starts a dialogue event by name (as defined in JSON event file).
## Emits the `dialogue_requested` signal and, if a dialogue system is registered,
## calls its `start_dialogue` method directly.

## Example:
##   EventHandler.dialogue_start("lily_intro")
func dialogue_start(event_name: String) -> void:
	if event_name.is_empty():
		var err_msg = "dialogue_start called with empty event name"
		push_warning(err_msg)
		emit_signal("error_occurred", err_msg)
		return

	# Notify any listeners (e.g., alternative dialogue displays)
	emit_signal("dialogue_requested", event_name)

	# Direct call to registered dialogue system
	var system = _get_dialogue_system()
	if system:
		system.start_dialogue(event_name)
	else:
		push_warning("EventHandler: No dialogue system registered. Event '%s' was only emitted as signal." % event_name)

## Informs the EventHandler that a dialogue choice was made.
## Emits the `choice_made` signal and, if the dialogue system supports it,
## calls its `on_choice_selected` method.

## Parameters:
##   choice_id:   Unique identifier of the choice (e.g., "drink_cocktail").
##   event_name:  (Optional) The dialogue event that this choice belongs to.
func make_choice(choice_id: String, event_name: String = "") -> void:
	emit_signal("choice_made", choice_id, event_name)

	var system = _get_dialogue_system()
	if system and system.has_method("on_choice_selected"):
		system.on_choice_selected(choice_id, event_name)
	elif system:
		push_warning("EventHandler: Dialogue system lacks 'on_choice_selected' method. Choice '%s' not handled directly." % choice_id)

# ------------------------------------------------------------------------------
# Public API - Button & UI Events
# ------------------------------------------------------------------------------

## Called when any button (or other UI element) is pressed.
## Use a descriptive button_id (e.g., "main_menu_start", "inventory_open").
## Emits the `button_event` signal for other systems to react.

## Example (in a Button node):
##   pressed.connect(EventHandler.on_button_pressed.bind("start_game"))
func on_button_pressed(button_id: String) -> void:
	if button_id.is_empty():
		push_warning("EventHandler: on_button_pressed called with empty button_id")
		return
	emit_signal("button_event", button_id)

	# Add custom routing logic here if needed (e.g., open quest log, toggle pause).
	# This keeps the method extendable without touching other team members' code.
	_route_button_event(button_id)

## Internal routing for button events. Override or extend this in a subclass
## or by modifying the script but keep it simple PLEASE : ) . For complex logic,
## prefer connecting to the `button_event` signal in other scripts.
func _route_button_event(button_id: String) -> void:
	match button_id:
		"debug_toggle":
			print("[EventHandler] Debug button pressed - toggling debug overlay")
			# Example: get_tree().call_group("debug_panel", "toggle_visibility")
		_:
			# Do nothing by default and let signal listeners handle it.
			pass

# ------------------------------------------------------------------------------
# Helper Methods
# ------------------------------------------------------------------------------

## Returns the registered dialogue system node or null if it is no longer valid.
func _get_dialogue_system() -> Node:
	if not _dialogue_system:
		return null
	var system: Node = _dialogue_system.get_ref()
	if not is_instance_valid(system):
		_dialogue_system = null
		return null
	return system

# ------------------------------------------------------------------------------
# Editor warning slop
# ------------------------------------------------------------------------------

## Shows a warning in the Godot editor if no dialogue system is ever registered.
## This only appears when the EventHandler node is selected in the editor.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	# This check only works if the EventHandler is placed in a scene (not autoload).
	# For autoloads, consider adding a separate debug script.
	if not _dialogue_system and not Engine.is_editor_hint():
		# In a running game, we might still not have a dialogue system.
		# This warning is more useful during development.
		pass
	return warnings

# ------------------------------------------------------------------------------
# CQ Sound System (check MusicCue.gd and MusicManager.tscn for info)
# ------------------------------------------------------------------------------

## Play a sound via the global music manager.
## very simplified version of the potential sound system, i'll publish an indepth guide doc soon
func play_track(sound_name: MusicCue) -> void:
	if sound_name.is_empty():
		return
	MusicManager.play_cue(sound_name)
	print("[EventHandler] Playing sound: ", sound_name)

# ------------------------------------------------------------------------------
# flag bearers
# ------------------------------------------------------------------------------

## Set or update a game progress flag.
## Flags to be stored in a save system (as yet unimplemented)
func set_flag(flag_name: String, value) -> void:
	if not has_meta("game_flags"):
		set_meta("game_flags", {})
	var flags = get_meta("game_flags")
	flags[flag_name] = value
	print("[EventHandler] Flag set: ", flag_name, " = ", value)

## Retrieve a flag value. Returns null if flag does not exist.
func get_flag(flag_name: String):
	if not has_meta("game_flags"):
		return null
	var flags = get_meta("game_flags")
	return flags.get(flag_name)
