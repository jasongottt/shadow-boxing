class_name TurnTimerBar
extends Node2D

## Horizontal bar that drains from both ends toward the centre while the
## players are choosing a direction. Turns red as the turn runs out.

const BAR_SIZE := Vector2(300.0, 9.0)
const BACKGROUND_COLOR := Color(0.1, 0.08, 0.09, 0.45)
const DANGER_COLOR := Color(0.9, 0.2, 0.2, 1.0)
const DANGER_THRESHOLD := 0.33

var progress := 1.0
var bar_color := Color(0.92, 0.88, 0.86, 0.95)
var is_active := false


func set_state(new_progress: float, new_bar_color: Color, new_is_active: bool) -> void:
	progress = clampf(new_progress, 0.0, 1.0)
	bar_color = new_bar_color
	is_active = new_is_active
	queue_redraw()


func _draw() -> void:
	var background := Rect2(-BAR_SIZE * 0.5, BAR_SIZE)
	draw_rect(background, BACKGROUND_COLOR)

	if not is_active or progress <= 0.0:
		return

	var fill_width := BAR_SIZE.x * progress
	var fill := Rect2(
		Vector2(-fill_width * 0.5, -BAR_SIZE.y * 0.5),
		Vector2(fill_width, BAR_SIZE.y),
	)

	draw_rect(fill, get_fill_color())


func get_fill_color() -> Color:
	if progress > DANGER_THRESHOLD:
		return bar_color

	var danger_weight := 1.0 - (progress / DANGER_THRESHOLD)

	return bar_color.lerp(DANGER_COLOR, danger_weight)
