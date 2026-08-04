class_name DirectionIndicators
extends Node2D

## Draws the four punch directions as arrows around a centre point.
## Directions that have already landed a hit are "spent" and drawn hollow,
## so both players can see which options are still on the table.

## Keys match Game.Direction (UP = 0, DOWN = 1, LEFT = 2, RIGHT = 3).
const ARROW_VECTORS := {
	0: Vector2(0, -1),
	1: Vector2(0, 1),
	2: Vector2(-1, 0),
	3: Vector2(1, 0),
}

const ARROW_OFFSET := 30.0
const ARROW_LENGTH := 14.0
const ARROW_WIDTH := 11.0
const SPENT_COLOR := Color(0.16, 0.13, 0.14, 0.55)
const OUTLINE_WIDTH := 2.0

## Lock-in dots sit either side of the arrow cluster: attacker left, defender right.
const LOCK_DOT_OFFSET := 74.0
const LOCK_DOT_RADIUS := 7.0
const LOCK_DOT_UNLIT_ALPHA := 0.3

var spent_directions: Array[int] = []
var active_color := Color(0.92, 0.88, 0.86, 0.95)
var attacker_color := Color(0.92, 0.88, 0.86, 0.95)
var defender_color := Color(0.92, 0.88, 0.86, 0.95)
var attacker_locked := false
var defender_locked := false


func set_state(new_spent_directions: Array[int], new_active_color: Color) -> void:
	spent_directions = new_spent_directions.duplicate()
	active_color = new_active_color
	queue_redraw()


## Shows *that* a player has committed, never *which* direction they picked.
func set_lock_state(
	new_attacker_locked: bool,
	new_defender_locked: bool,
	new_attacker_color: Color,
	new_defender_color: Color,
) -> void:
	attacker_locked = new_attacker_locked
	defender_locked = new_defender_locked
	attacker_color = new_attacker_color
	defender_color = new_defender_color
	queue_redraw()


func _draw() -> void:
	for direction: int in ARROW_VECTORS.keys():
		var points := get_arrow_points(direction)

		if spent_directions.has(direction):
			var outline := points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, SPENT_COLOR, OUTLINE_WIDTH, true)
		else:
			draw_colored_polygon(points, active_color)

	draw_lock_dot(Vector2(-LOCK_DOT_OFFSET, 0.0), attacker_color, attacker_locked)
	draw_lock_dot(Vector2(LOCK_DOT_OFFSET, 0.0), defender_color, defender_locked)


func draw_lock_dot(centre: Vector2, color: Color, is_locked: bool) -> void:
	if is_locked:
		draw_circle(centre, LOCK_DOT_RADIUS, color)
		return

	var unlit := color
	unlit.a = LOCK_DOT_UNLIT_ALPHA
	draw_arc(centre, LOCK_DOT_RADIUS, 0.0, TAU, 24, unlit, OUTLINE_WIDTH, true)


func get_arrow_points(direction: int) -> PackedVector2Array:
	var facing: Vector2 = ARROW_VECTORS[direction]
	var side := Vector2(-facing.y, facing.x)
	var centre := facing * ARROW_OFFSET

	return PackedVector2Array([
		centre + facing * ARROW_LENGTH,
		centre - facing * ARROW_LENGTH * 0.6 + side * ARROW_WIDTH,
		centre - facing * ARROW_LENGTH * 0.6 - side * ARROW_WIDTH,
	])
