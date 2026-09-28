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

## Both player colours are dark enough to disappear against the bar, so the
## role caption is pulled toward bone until it reads.
const BONE_COLOR := Color(0.92, 0.88, 0.86)

## Either side of the cluster is captioned, attacker left and defender right:
## the role in that player's colour, and under it whose keys drive it. Roles
## swap on every miss, and without this the only way to find out you were now
## dodging was to punch and see nothing.
const CAPTION_GAP := 40.0
const CAPTION_WIDTH := 220.0
const ROLE_FONT_SIZE := 29
const KEYS_FONT_SIZE := 19
const ROLE_BASELINE := 1.0
const KEYS_BASELINE := 24.0
const CAPTION_BONE_MIX := 0.25
const CAPTION_KEYS_COLOR := Color(0.72, 0.68, 0.68, 0.8)

var spent_directions: Array[int] = []
var active_color := Color(0.92, 0.88, 0.86, 0.95)
var attacker_color := Color(0.92, 0.88, 0.86, 0.95)
var defender_color := Color(0.92, 0.88, 0.86, 0.95)
var attacker_caption := ""
var defender_caption := ""


func set_state(new_spent_directions: Array[int], new_active_color: Color) -> void:
	spent_directions = new_spent_directions.duplicate()
	active_color = PlayerColorSettings.readable_on_black(new_active_color)
	queue_redraw()


## Who is on each side, e.g. "P1 · ARROWS". Only changes when roles swap.
func set_captions(
	new_attacker_caption: String,
	new_defender_caption: String,
	new_attacker_color: Color,
	new_defender_color: Color,
) -> void:
	attacker_caption = new_attacker_caption
	defender_caption = new_defender_caption
	attacker_color = PlayerColorSettings.readable_on_black(new_attacker_color)
	defender_color = PlayerColorSettings.readable_on_black(new_defender_color)
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

	draw_caption(-1.0, "PUNCH", attacker_caption, attacker_color)
	draw_caption(1.0, "DODGE", defender_caption, defender_color)


func draw_caption(side: float, role: String, keys: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var inner_edge := ARROW_TIP + CAPTION_GAP
	var x := -inner_edge - CAPTION_WIDTH if side < 0.0 else inner_edge
	var alignment := (
		HORIZONTAL_ALIGNMENT_RIGHT if side < 0.0 else HORIZONTAL_ALIGNMENT_LEFT
	)

	draw_string(
		font,
		Vector2(x, ROLE_BASELINE),
		role,
		alignment,
		CAPTION_WIDTH,
		ROLE_FONT_SIZE,
		color.lerp(BONE_COLOR, CAPTION_BONE_MIX),
	)
	draw_string(
		font,
		Vector2(x, KEYS_BASELINE),
		keys,
		alignment,
		CAPTION_WIDTH,
		KEYS_FONT_SIZE,
		CAPTION_KEYS_COLOR,
	)


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
