class_name PauseMenu
extends CanvasLayer

## Esc mid-fight. Every beat of the fight waits on pausable tweens, so the whole
## thing (replays and hit-stops included) stops exactly where it was and picks
## up again from there.

signal restart_requested
signal menu_requested

var stashed_time_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func open() -> void:
	if visible:
		return

	# A hit-stop parks Engine.time_scale near zero; hold it here so the fight
	# resumes mid-freeze rather than skipping it.
	stashed_time_scale = Engine.time_scale
	Engine.time_scale = 1.0
	get_tree().paused = true
	show()
	Sounds.play(&"ui_press", -8.0)


func close() -> void:
	if not visible:
		return

	hide()
	Engine.time_scale = stashed_time_scale
	get_tree().paused = false
	Sounds.play(&"ui_press", -8.0, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif is_key_press(event, KEY_R):
		leave_with(restart_requested)
	elif is_key_press(event, KEY_M):
		leave_with(menu_requested)


## Whoever answers the signal replaces the scene, which unpauses the tree.
func leave_with(request: Signal) -> void:
	get_viewport().set_input_as_handled()
	hide()
	Sounds.play(&"ui_press", -8.0)
	request.emit()


func is_key_press(event: InputEvent, keycode: Key) -> bool:
	var key_event := event as InputEventKey
	return (
		key_event != null
		and key_event.pressed
		and not key_event.echo
		and key_event.keycode == keycode
	)
