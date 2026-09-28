class_name SceneCurtain
extends CanvasLayer

## Every scene change drops a quick curtain of the same black as the letterbox
## bars and lifts it again on the far side, so going from the menu to the ring
## (or back, or into a rematch) reads as the lights going down rather than as a
## hard cut.

const FADE_OUT := 0.22
const FADE_IN := 0.32

var cover: ColorRect
var busy := false


func _ready() -> void:
	layer = 100
	# Fades run through a paused tree (quitting to the menu from pause) and
	# through a hit-stop's crawl alike.
	process_mode = Node.PROCESS_MODE_ALWAYS

	cover = ColorRect.new()
	cover.name = &"cover"
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.modulate.a = 0.0
	add_child(cover)


## Checked up front so the caller hears about a bad path immediately, instead
## of after a fade into black that never lifts.
func change_scene(path: String) -> Error:
	if busy:
		return ERR_BUSY
	if not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND

	run_change(func() -> Error: return get_tree().change_scene_to_file(path))
	return OK


func reload_scene() -> Error:
	if busy:
		return ERR_BUSY

	run_change(func() -> Error: return get_tree().reload_current_scene())
	return OK


func run_change(change: Callable) -> void:
	busy = true
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	await fade_to(1.0, FADE_OUT)

	var error: Error = change.call()
	if error != OK:
		push_error("SceneCurtain could not change scene (error %d)" % error)
	# Whatever was going on in the old scene, the new one starts running.
	get_tree().paused = false

	# The swap happens at the end of this frame; lift once the new scene is in.
	await get_tree().process_frame
	await fade_to(0.0, FADE_IN)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false


func fade_to(alpha: float, duration: float) -> void:
	var fade := create_tween()
	fade.set_ignore_time_scale(true)
	fade.tween_property(cover, ^"modulate:a", alpha, duration)
	await fade.finished
