class_name DirectionIndicators
extends Node2D

## Draws the four punch directions as inked arrows around a centre point.
## Directions that have already landed a hit are "spent" and drawn hollow,
## so both players can see which options are still on the table.
##
## This cluster lives inside the lower letterbox bar, so the ink runs the other
## way round from the rest of the game: bone and player colour on black, rather
## than the black brushwork the wall gets.

## Keys match Game.Direction (UP = 0, DOWN = 1, LEFT = 2, RIGHT = 3).
const ARROW_VECTORS := {
	0: Vector2(0, -1),
	1: Vector2(0, 1),
	2: Vector2(-1, 0),
	3: Vector2(1, 0),
}

## Arrow geometry, measured along the direction it points, out from the centre.
## Sized so the whole cluster clears the bar's edges even at full camera shake.
const ARROW_TAIL := 16.0
const ARROW_HEAD_BASE := 40.0
const ARROW_TIP := 68.0
const SHAFT_HALF_WIDTH := 12.0
const HEAD_HALF_WIDTH := 27.0

## Ash rather than the near-black previously used over the wall, which would be
## invisible now the cluster sits on the letterbox bar.
const SPENT_COLOR := Color(0.72, 0.68, 0.68, 0.4)
const OUTLINE_WIDTH := 5.0
const INK_WOBBLE := 2.2

## Lock-in marks sit either side of the arrow cluster: attacker left, defender
## right, far enough out to stay clear of the horizontal arrows.
const LOCK_MARK_OFFSET := 150.0
const LOCK_MARK_RADIUS := 24.0
const LOCK_MARK_UNLIT_ALPHA := 0.6
const LOCK_WOBBLE := 1.9

## Both player colours are dark enough to disappear against the bar, so an
## unlit ring is pulled toward bone until it reads — far enough to stay legible,
## not so far that you lose whose ring it is.
const BONE_COLOR := Color(0.92, 0.88, 0.86)
const UNLIT_BONE_MIX := 0.45

## Fixed per-shape seeds keep each arrow wonky in its own particular way while
## still redrawing identically every frame.
const ATTACKER_SEED := 11
const DEFENDER_SEED := 23

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
		var points := HandDrawn.rough_loop(
			get_arrow_points(direction), INK_WOBBLE, direction + 1
		)

		if spent_directions.has(direction):
			draw_polyline(HandDrawn.to_outline(points), SPENT_COLOR, OUTLINE_WIDTH, true)
		else:
			draw_colored_polygon(points, active_color)

	draw_lock_mark(
		Vector2(-LOCK_MARK_OFFSET, 0.0), attacker_color, attacker_locked, ATTACKER_SEED
	)
	draw_lock_mark(
		Vector2(LOCK_MARK_OFFSET, 0.0), defender_color, defender_locked, DEFENDER_SEED
	)


func draw_lock_mark(
	centre: Vector2, color: Color, is_locked: bool, seed_value: int
) -> void:
	var ring := HandDrawn.rough_circle(centre, LOCK_MARK_RADIUS, LOCK_WOBBLE, seed_value)

	if is_locked:
		draw_colored_polygon(ring, color)
		return

	var unlit := color.lerp(BONE_COLOR, UNLIT_BONE_MIX)
	unlit.a = LOCK_MARK_UNLIT_ALPHA
	draw_polyline(HandDrawn.to_outline(ring), unlit, OUTLINE_WIDTH, true)


## A shafted arrow rather than a bare triangle: the notch where the head meets
## the shaft is what makes it read as drawn rather than as a UI glyph.
func get_arrow_points(direction: int) -> PackedVector2Array:
	var facing: Vector2 = ARROW_VECTORS[direction]
	var side := Vector2(-facing.y, facing.x)

	return PackedVector2Array([
		facing * ARROW_TIP,
		facing * ARROW_HEAD_BASE + side * HEAD_HALF_WIDTH,
		facing * ARROW_HEAD_BASE + side * SHAFT_HALF_WIDTH,
		facing * ARROW_TAIL + side * SHAFT_HALF_WIDTH,
		facing * ARROW_TAIL - side * SHAFT_HALF_WIDTH,
		facing * ARROW_HEAD_BASE - side * SHAFT_HALF_WIDTH,
		facing * ARROW_HEAD_BASE - side * HEAD_HALF_WIDTH,
	])
