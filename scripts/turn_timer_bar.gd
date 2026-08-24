class_name TurnTimerBar
extends Node2D

## Marker stroke that drains from both ends toward the centre while the players
## are choosing a direction. Reddens as the turn runs out.
##
## The roughness is baked once into a table of edge offsets sampled across the
## full width, and the fill reads out of that table rather than generating its
## own wobble. Otherwise the ink would re-scribble itself on every frame the
## progress changes, which is every frame of the input phase.

const BAR_SIZE := Vector2(340.0, 26.0)
const EDGE_SAMPLES := 30
const EDGE_WOBBLE := 2.4
const EDGE_SEED := 90210

## The stroke thins toward whichever ends are currently draining, so it reads as
## ink lifting off the page instead of a rectangle losing width.
const TAPER_LENGTH := 18.0
const TAPER_MIN := 0.34

## Faint bone outline showing the full turn; the old dark background was
## invisible now the bar sits on the letterbox.
const TRACK_COLOR := Color(0.75, 0.71, 0.7, 0.32)
const TRACK_WIDTH := 4.0
const DANGER_COLOR := Color(0.9, 0.2, 0.2, 1.0)
const DANGER_THRESHOLD := 0.33

var progress := 1.0
var bar_color := Color(0.92, 0.88, 0.86, 0.95)
var is_active := false

var top_offsets := PackedFloat32Array()
var bottom_offsets := PackedFloat32Array()


func _ready() -> void:
	bake_edge_offsets()


func set_state(new_progress: float, new_bar_color: Color, new_is_active: bool) -> void:
	progress = clampf(new_progress, 0.0, 1.0)
	bar_color = new_bar_color
	is_active = new_is_active
	queue_redraw()


func bake_edge_offsets() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = EDGE_SEED

	top_offsets.resize(EDGE_SAMPLES + 1)
	bottom_offsets.resize(EDGE_SAMPLES + 1)

	for index in EDGE_SAMPLES + 1:
		top_offsets[index] = rng.randf_range(-EDGE_WOBBLE, EDGE_WOBBLE)
		bottom_offsets[index] = rng.randf_range(-EDGE_WOBBLE, EDGE_WOBBLE)


func _draw() -> void:
	var half_width := BAR_SIZE.x * 0.5

	draw_polyline(
		HandDrawn.to_outline(build_stroke(-half_width, half_width)),
		TRACK_COLOR,
		TRACK_WIDTH,
		true,
	)

	if not is_active or progress <= 0.0:
		return

	var fill_half := half_width * progress
	draw_colored_polygon(build_stroke(-fill_half, fill_half), get_fill_color())


## Walks the baked top edge left to right, then the bottom edge back again,
## clipped to the span the stroke currently covers.
func build_stroke(from_x: float, to_x: float) -> PackedVector2Array:
	var positions := collect_sample_positions(from_x, to_x)
	var stroke := PackedVector2Array()

	for x: float in positions:
		stroke.append(Vector2(x, edge_y(x, from_x, to_x, top_offsets, -1.0)))

	for index in range(positions.size() - 1, -1, -1):
		var x: float = positions[index]
		stroke.append(Vector2(x, edge_y(x, from_x, to_x, bottom_offsets, 1.0)))

	return stroke


## Both ends of the span, plus every baked sample that falls strictly inside it.
func collect_sample_positions(from_x: float, to_x: float) -> PackedFloat32Array:
	var positions := PackedFloat32Array([from_x])

	for index in EDGE_SAMPLES + 1:
		var x := sample_x(index)

		if x > from_x and x < to_x:
			positions.append(x)

	positions.append(to_x)

	return positions


func sample_x(index: int) -> float:
	return lerpf(
		-BAR_SIZE.x * 0.5, BAR_SIZE.x * 0.5, float(index) / float(EDGE_SAMPLES)
	)


## Baked wobble interpolated at an arbitrary x, plus the draining-end taper.
func edge_y(
	x: float,
	from_x: float,
	to_x: float,
	offsets: PackedFloat32Array,
	side: float,
) -> float:
	var sample := (x + BAR_SIZE.x * 0.5) / BAR_SIZE.x * float(EDGE_SAMPLES)
	var index := clampi(int(sample), 0, EDGE_SAMPLES - 1)
	var wobble := lerpf(offsets[index], offsets[index + 1], sample - float(index))

	return side * BAR_SIZE.y * 0.5 * get_taper(x, from_x, to_x) + wobble


func get_taper(x: float, from_x: float, to_x: float) -> float:
	var edge_distance := minf(x - from_x, to_x - x)

	return clampf(edge_distance / TAPER_LENGTH, TAPER_MIN, 1.0)


func get_fill_color() -> Color:
	if progress > DANGER_THRESHOLD:
		return bar_color

	var danger_weight := 1.0 - (progress / DANGER_THRESHOLD)

	return bar_color.lerp(DANGER_COLOR, danger_weight)
