class_name ScoreTally
extends Node2D

## The running score across rematches, kept the way you'd keep it on a wall:
## tally marks in bundles of five, each player's in their own colour.
##
## Only shown once a fight is over, in the lower letterbox bar where the arrows
## and the timer were. Names sit either side of the centre and each player's
## marks grow outward from there, so a long session widens rather than
## crowding the middle.

const NAME_OFFSET := 44.0
const NAME_WIDTH := 120.0
const MARKS_START := 130.0
const MARK_SPACING := 16.0
const BUNDLE_GAP := 28.0
const MARK_HEIGHT := 46.0
const MARK_HALF_WIDTH := 4.0
const MARK_WOBBLE := 1.4
const MARK_SEGMENT := 8.0

## A short inked dash between the two names, so they read as one versus the
## other rather than as two unrelated labels.
const DASH_HALF_LENGTH := 14.0
const DASH_HALF_WIDTH := 3.0
const DASH_COLOR := Color(0.72, 0.68, 0.68, 0.6)
const DASH_SEED := 5

## Past this many marks a side switches to a numeral, so a marathon session
## can't run its tallies off the edge of the screen.
const MAX_MARKS := 20
const FONT_SIZE := 34

const BONE_COLOR := Color(0.92, 0.88, 0.86)
const NAME_BONE_MIX := 0.3
const MARK_BONE_MIX := 0.1

const LEFT_SEED := 67
const RIGHT_SEED := 131

var left_name := "P1"
var right_name := "P2"
var left_count := 0
var right_count := 0
var left_color := BONE_COLOR
var right_color := BONE_COLOR


func set_state(
	new_left_name: String,
	new_left_count: int,
	new_left_color: Color,
	new_right_name: String,
	new_right_count: int,
	new_right_color: Color,
) -> void:
	left_name = new_left_name
	left_count = new_left_count
	left_color = PlayerColorSettings.readable_on_black(new_left_color)
	right_name = new_right_name
	right_count = new_right_count
	right_color = PlayerColorSettings.readable_on_black(new_right_color)
	queue_redraw()


func _draw() -> void:
	var dash := HandDrawn.rough_loop(
		get_stroke_outline(
			Vector2(-DASH_HALF_LENGTH, 0.0), Vector2(DASH_HALF_LENGTH, 0.0), DASH_HALF_WIDTH
		),
		MARK_WOBBLE,
		DASH_SEED,
		MARK_SEGMENT,
	)
	draw_colored_polygon(dash, DASH_COLOR)

	draw_side(-1.0, left_name, left_count, left_color, LEFT_SEED)
	draw_side(1.0, right_name, right_count, right_color, RIGHT_SEED)


func draw_side(
	side: float, player_name: String, count: int, color: Color, seed_value: int
) -> void:
	var font := ThemeDB.fallback_font
	var name_x := -NAME_OFFSET - NAME_WIDTH if side < 0.0 else NAME_OFFSET
	var alignment := (
		HORIZONTAL_ALIGNMENT_RIGHT if side < 0.0 else HORIZONTAL_ALIGNMENT_LEFT
	)
	draw_string(
		font,
		Vector2(name_x, FONT_SIZE * 0.36),
		player_name,
		alignment,
		NAME_WIDTH,
		FONT_SIZE,
		color.lerp(BONE_COLOR, NAME_BONE_MIX),
	)

	var mark_color := color.lerp(BONE_COLOR, MARK_BONE_MIX)

	if count > MAX_MARKS:
		var numeral_x := MARKS_START if side > 0.0 else -MARKS_START - NAME_WIDTH
		draw_string(
			font,
			Vector2(numeral_x, FONT_SIZE * 0.36),
			str(count),
			alignment,
			NAME_WIDTH,
			FONT_SIZE,
			mark_color,
		)
		return

	for index in count:
		var stroke := get_mark_stroke(index)
		var points := HandDrawn.rough_loop(
			get_stroke_outline(
				stroke[0] * Vector2(side, 1.0), stroke[1] * Vector2(side, 1.0), MARK_HALF_WIDTH
			),
			MARK_WOBBLE,
			seed_value + index,
			MARK_SEGMENT,
		)
		draw_colored_polygon(points, mark_color)


## Where one mark runs, on the right-hand side (the left mirrors it). Four
## uprights per bundle, and every fifth mark strikes back across them.
func get_mark_stroke(index: int) -> Array[Vector2]:
	var bundle := floori(index / 5.0)
	var place := index % 5
	var bundle_start := MARKS_START + bundle * (MARK_SPACING * 3.0 + BUNDLE_GAP)
	var half_height := MARK_HEIGHT * 0.5

	if place < 4:
		var x := bundle_start + MARK_SPACING * place
		return [Vector2(x, -half_height), Vector2(x, half_height)]

	var reach := MARK_SPACING * 0.6
	return [
		Vector2(bundle_start - reach, half_height * 0.55),
		Vector2(bundle_start + MARK_SPACING * 3.0 + reach, -half_height * 0.55),
	]


## A stroke as a thin filled quad, so it can be roughened like everything else.
func get_stroke_outline(
	from: Vector2, to: Vector2, half_width: float
) -> PackedVector2Array:
	var across := (to - from).normalized().orthogonal() * half_width
	return PackedVector2Array([from + across, to + across, to - across, from - across])
