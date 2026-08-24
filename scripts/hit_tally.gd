class_name HitTally
extends Node2D

## Shows how many hits the attacker has landed toward breaking the wall, which
## the fight otherwise never states: until now you could not tell one hit from
## two, only that the wall had not gone yet.
##
## Lives in the upper letterbox bar, in the same inked idiom as the rest of the
## HUD. Deliberately diamonds rather than the rings used for lock-in, so the two
## readouts stay tellable apart at a glance.

const MARK_SPACING := 110.0
const MARK_HALF_SIZE := 26.0
const MARK_WOBBLE := 2.4
const MARK_SEGMENT := 12.0
const OUTLINE_WIDTH := 6.0

## Faint bone, matching the spent-arrow treatment: legible on black without
## competing with the marks that have actually been earned.
const PENDING_COLOR := Color(0.72, 0.68, 0.68, 0.38)

## Offset so each mark's wobble is its own, and stable between redraws.
const MARK_SEED := 41

var hits := 0
var max_hits := 3
var mark_color := Color(0.92, 0.88, 0.86, 0.95)


func set_state(new_hits: int, new_max_hits: int, new_mark_color: Color) -> void:
	hits = new_hits
	max_hits = maxi(new_max_hits, 1)
	mark_color = new_mark_color
	queue_redraw()


func _draw() -> void:
	var span := MARK_SPACING * float(max_hits - 1)

	for index in max_hits:
		var centre := Vector2(-span * 0.5 + MARK_SPACING * float(index), 0.0)
		var mark := HandDrawn.rough_loop(
			get_mark_points(centre), MARK_WOBBLE, index + MARK_SEED, MARK_SEGMENT
		)

		if index < hits:
			draw_colored_polygon(mark, mark_color)
		else:
			draw_polyline(HandDrawn.to_outline(mark), PENDING_COLOR, OUTLINE_WIDTH, true)


## A tilted square, so the marks read as struck chips rather than as UI boxes.
func get_mark_points(centre: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		centre + Vector2(0.0, -MARK_HALF_SIZE),
		centre + Vector2(MARK_HALF_SIZE, 0.0),
		centre + Vector2(0.0, MARK_HALF_SIZE),
		centre + Vector2(-MARK_HALF_SIZE, 0.0),
	])
