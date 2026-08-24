class_name HandDrawn

## Drawing helpers that keep the HUD in the same register as the game's
## brush-inked artwork: every edge is resampled and nudged off true, so nothing
## reads as a clean vector primitive next to the wall and the fighters.
##
## Wobble comes from an explicit seed rather than a live RNG, so a shape that
## redraws every frame stays put instead of boiling.

## Roughly how far apart the resampled points sit. Edges shorter than this keep
## their corner and nothing more, which stops small notches from folding over
## themselves once the wobble is applied.
const SEGMENT_LENGTH := 14.0


## Resamples a closed polygon and nudges every sample off true, turning a clean
## outline into an inked one. The same seed always yields the same wobble.
static func rough_loop(
	points: PackedVector2Array,
	amount: float,
	seed_value: int,
	segment_length: float = SEGMENT_LENGTH,
) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var rough := PackedVector2Array()
	var count := points.size()

	for index in count:
		var from := points[index]
		var to := points[(index + 1) % count]
		var steps := maxi(1, int(from.distance_to(to) / segment_length))

		for step in steps:
			var along := from.lerp(to, float(step) / float(steps))
			rough.append(along + Vector2(
				rng.randf_range(-amount, amount),
				rng.randf_range(-amount, amount),
			))

	return rough


## A circle drawn the way a marker draws one: never quite round.
static func rough_circle(
	centre: Vector2,
	radius: float,
	amount: float,
	seed_value: int,
	segments: int = 20,
) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var points := PackedVector2Array()

	for index in segments:
		var angle := TAU * float(index) / float(segments)
		var wobble := radius + rng.randf_range(-amount, amount)
		points.append(centre + Vector2(cos(angle), sin(angle)) * wobble)

	return points


## Repeats the first point so a filled shape can be re-drawn as a closed stroke.
static func to_outline(points: PackedVector2Array) -> PackedVector2Array:
	var outline := points.duplicate()

	if not outline.is_empty():
		outline.append(outline[0])

	return outline
