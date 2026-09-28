@tool
class_name InkStyleBox
extends StyleBox

## A button face drawn the way the rest of the game is drawn: a flat fill inside
## a wobbly marker outline, sitting on a flat drop shadow like the labels have,
## instead of a clean vector rounded rectangle.
##
## Wobble is seeded from the canvas item being drawn, so every button gets its
## own slightly different outline, and a button keeps the same one however
## often it redraws (hover and focus redraw constantly).

@export var fill_color := Color.WHITE
@export var ink_color := Color.BLACK
@export var ink_width := 4.0
@export var wobble := 1.8
## Corners are clipped this far so the outline reads as drawn freehand rather
## than ruled.
@export var corner_cut := 6.0
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.0)
@export var shadow_offset := Vector2(4.0, 5.0)

const SEGMENT_LENGTH := 18.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var seed_value := int(to_canvas_item.get_id() % 100000)

	if shadow_color.a > 0.0:
		var shadow := get_face(Rect2(rect.position + shadow_offset, rect.size), seed_value)
		RenderingServer.canvas_item_add_polygon(
			to_canvas_item, shadow, PackedColorArray([shadow_color])
		)

	var face := get_face(rect, seed_value)
	RenderingServer.canvas_item_add_polygon(
		to_canvas_item, face, PackedColorArray([fill_color])
	)
	RenderingServer.canvas_item_add_polyline(
		to_canvas_item,
		HandDrawn.to_outline(face),
		PackedColorArray([ink_color]),
		ink_width,
		true,
	)


func get_face(rect: Rect2, seed_value: int) -> PackedVector2Array:
	# Inset by half the ink so the stroke stays inside the control's rect.
	var inner := rect.grow(-ink_width * 0.5)
	var cut := minf(corner_cut, minf(inner.size.x, inner.size.y) * 0.25)
	var left := inner.position.x
	var top := inner.position.y
	var right := inner.end.x
	var bottom := inner.end.y

	return HandDrawn.rough_loop(
		PackedVector2Array([
			Vector2(left + cut, top),
			Vector2(right - cut, top),
			Vector2(right, top + cut),
			Vector2(right, bottom - cut),
			Vector2(right - cut, bottom),
			Vector2(left + cut, bottom),
			Vector2(left, bottom - cut),
			Vector2(left, top + cut),
		]),
		wobble,
		seed_value,
		SEGMENT_LENGTH,
	)
