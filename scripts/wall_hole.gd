class_name WallHole
extends Node2D

## The third straight hit goes through the wall. Rather than the whole wall
## vanishing (which left nothing behind it but the engine's flat grey), a
## jagged hole is punched out of it, inked the same way as everything else:
##
## - an ink rim, with the wall's cut thickness showing along the top where the
##   camera (sitting below the hole) can see into it;
## - a dark void behind, which is where "You Win" is painted;
## - cracks running out from the rim across what's left of the wall;
## - chunks of plaster that tumble out of the bottom lip and bounce to a stop
##   on the floor.
##
## Every shape is rolled once when the hole opens and then only moved, so
## nothing re-scribbles itself between frames.

## Sized and placed to frame the "You Win" lettering, stop short of the bulb on
## the right, and stay above the shmile and the boxer's head.
const CENTRE := Vector2(560.0, 180.0)
const RADII := Vector2(372.0, 190.0)
const RIM_POINTS := 34
const RIM_JITTER := 0.07
const SPIKE_EVERY := 5
const SPIKE_REACH := 0.13
## The bulb hangs just right of the hole; nothing may reach under its socket.
const RIGHT_LIMIT := 910.0

## The void sits a little lower than the rim it was cut from, so the band of
## cut plaster shows thickest across the top.
const VOID_SCALE := 0.94
const VOID_DROP := 10.0

const CRACK_COUNT := 11
const CRACK_SEGMENTS := 4
const CRACK_STEP_MIN := 18.0
const CRACK_STEP_MAX := 42.0
const CRACK_TURN := 0.55
const CRACK_WIDTH := 3.5

const CHUNK_COUNT := 7
## Where along the bottom lip chunks fall from, as a fraction of the hole's
## half-width. Weighted left: the boxer stands over the floor to the right and
## would hide anything that landed there.
const CHUNK_LIP_FROM := -0.8
const CHUNK_LIP_TO := 0.3
const CHUNK_RADIUS_MIN := 11.0
const CHUNK_RADIUS_MAX := 22.0
## Floor band of the wall art, where the chunks come to rest.
const FLOOR_Y_MIN := 612.0
const FLOOR_Y_MAX := 640.0
const CHUNK_FALL_TIME := 0.75
const CHUNK_STAGGER := 0.35
const CHUNK_SPIN := 3.0

const OPEN_DURATION := 0.28
const OPEN_FROM := 0.25

const PLASTER_COLOR := Color(0.97, 0.91, 0.88)
const PLASTER_SHADE := Color(0.78, 0.66, 0.58)
const VOID_COLOR := Color(0.13, 0.11, 0.12)
const INK_COLOR := Color(0.0, 0.0, 0.0)
const RIM_INK_WIDTH := 6.0
const VOID_INK_WIDTH := 3.0
const CHUNK_INK_WIDTH := 3.0
const INK_WOBBLE := 2.2

var rim := PackedVector2Array()
var void_shape := PackedVector2Array()
var cracks: Array[PackedVector2Array] = []
var chunks: Array[Dictionary] = []
var tint := Color.WHITE
var opened := 0.0:
	set(value):
		opened = value
		queue_redraw()
var elapsed := 0.0


func _ready() -> void:
	hide()
	set_process(false)


## `wall_tint` is the wall's current colour grade, so the plaster edges and
## rubble match the wall they came out of.
func open(wall_tint: Color) -> void:
	tint = wall_tint
	build_shapes()
	elapsed = 0.0
	opened = OPEN_FROM
	show()
	set_process(true)

	var open_tween := create_tween()
	open_tween.set_ignore_time_scale(true)
	open_tween.tween_property(self, ^"opened", 1.0, OPEN_DURATION).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed > CHUNK_FALL_TIME + CHUNK_STAGGER * 2.0:
		set_process(false)


func build_shapes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var outline := PackedVector2Array()
	for index in RIM_POINTS:
		var angle := TAU * float(index) / float(RIM_POINTS)
		var reach := 1.0 + rng.randf_range(-RIM_JITTER, RIM_JITTER * 0.6)
		if index % SPIKE_EVERY == 0:
			reach += SPIKE_REACH * rng.randf_range(0.6, 1.0)
		var point := CENTRE + Vector2(cos(angle), sin(angle)) * RADII * reach
		point.x = minf(point.x, RIGHT_LIMIT)
		outline.append(point)
	rim = HandDrawn.rough_loop(outline, INK_WOBBLE, rng.randi())

	void_shape = PackedVector2Array()
	for point in rim:
		void_shape.append(CENTRE + (point - CENTRE) * VOID_SCALE + Vector2(0.0, VOID_DROP))

	cracks.clear()
	for index in CRACK_COUNT:
		var start: Vector2 = outline[rng.randi_range(0, outline.size() - 1)]
		var heading := (start - CENTRE).normalized()
		var crack := PackedVector2Array([start])
		for step in CRACK_SEGMENTS:
			heading = heading.rotated(rng.randf_range(-CRACK_TURN, CRACK_TURN))
			var tip := crack[crack.size() - 1]
			crack.append(tip + heading * rng.randf_range(CRACK_STEP_MIN, CRACK_STEP_MAX))
		cracks.append(crack)

	chunks.clear()
	for index in CHUNK_COUNT:
		# Out of the lower lip of the hole, onto the floor below it.
		var along := rng.randf_range(CHUNK_LIP_FROM, CHUNK_LIP_TO)
		var lip := CENTRE + Vector2(along * RADII.x, RADII.y * sqrt(1.0 - along * along) * 0.9)
		var radius := rng.randf_range(CHUNK_RADIUS_MIN, CHUNK_RADIUS_MAX)
		chunks.append({
			"from": lip,
			"to": Vector2(
				lip.x + rng.randf_range(-60.0, 40.0), rng.randf_range(FLOOR_Y_MIN, FLOOR_Y_MAX)
			),
			"delay": rng.randf_range(0.0, CHUNK_STAGGER),
			"spin": rng.randf_range(-CHUNK_SPIN, CHUNK_SPIN),
			"shape": HandDrawn.rough_circle(Vector2.ZERO, radius, radius * 0.3, rng.randi(), 7),
			"shaded": rng.randf() < 0.4,
		})


func _draw() -> void:
	if rim.is_empty():
		return

	for crack: PackedVector2Array in cracks:
		draw_polyline(scaled(crack), INK_COLOR, CRACK_WIDTH, true)

	var scaled_rim := scaled(rim)
	draw_colored_polygon(scaled_rim, PLASTER_COLOR * tint)
	var scaled_void := scaled(void_shape)
	draw_colored_polygon(scaled_void, VOID_COLOR)
	draw_polyline(HandDrawn.to_outline(scaled_void), INK_COLOR, VOID_INK_WIDTH, true)
	draw_polyline(HandDrawn.to_outline(scaled_rim), INK_COLOR, RIM_INK_WIDTH, true)

	for chunk: Dictionary in chunks:
		draw_chunk(chunk)


func draw_chunk(chunk: Dictionary) -> void:
	var time := clampf((elapsed - float(chunk["delay"])) / CHUNK_FALL_TIME, 0.0, 1.0)
	if time <= 0.0:
		return

	var from: Vector2 = chunk["from"]
	var to: Vector2 = chunk["to"]
	var x := lerpf(from.x, to.x, time)
	var y: float = Tween.interpolate_value(
		from.y, to.y - from.y, time, 1.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT
	)
	var spin: float = chunk["spin"] * time
	var shape := Transform2D(spin, Vector2(x, y)) * (chunk["shape"] as PackedVector2Array)
	var fill := (PLASTER_SHADE if chunk["shaded"] else PLASTER_COLOR) * tint

	draw_colored_polygon(shape, fill)
	draw_polyline(HandDrawn.to_outline(shape), INK_COLOR, CHUNK_INK_WIDTH, true)


## The hole bursts open from its centre, so the rim and cracks are drawn
## scaled toward CENTRE by however far open it is.
func scaled(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(CENTRE + (point - CENTRE) * opened)
	return out
