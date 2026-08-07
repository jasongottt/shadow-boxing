class_name ImpactBurst
extends Node2D

const BURST_DURATION := 0.18
const RAY_ANGLES: Array[float] = [-0.95, -0.58, -0.25, 0.0, 0.25, 0.58, 0.95]

var progress: float = 1.0:
	set(value):
		progress = value
		queue_redraw()
var burst_color: Color = Color.WHITE
var active_tween: Tween


func _ready() -> void:
	z_index = 20
	hide()


func play_burst(
	world_position: Vector2, direction: Vector2, color: Color, intensity: float = 1.0
) -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	position = world_position
	rotation = direction.angle()
	burst_color = color
	progress = 0.0
	scale = Vector2.ONE * intensity
	show()

	active_tween = create_tween()
	active_tween.set_ignore_time_scale(true)
	active_tween.tween_property(self, ^"progress", 1.0, BURST_DURATION).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	active_tween.tween_callback(hide)


func _draw() -> void:
	if progress >= 1.0:
		return

	var fade: float = pow(1.0 - progress, 2.0)
	var core_color := Color(1.0, 0.95, 0.72, fade)
	var accent_color := burst_color
	accent_color.a = fade
	var ring_radius: float = lerpf(8.0, 38.0, progress)
	var ray_start: float = lerpf(7.0, 16.0, progress)
	var ray_end: float = lerpf(30.0, 65.0, progress)

	draw_circle(Vector2.ZERO, lerpf(9.0, 2.0, progress), core_color)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 28, accent_color, 3.0, true)

	for index: int in range(RAY_ANGLES.size()):
		var angle: float = RAY_ANGLES[index]
		var ray_direction := Vector2.RIGHT.rotated(angle)
		var length_scale: float = 1.0 if index % 2 == 0 else 0.76
		draw_line(
			ray_direction * ray_start,
			ray_direction * ray_end * length_scale,
			accent_color,
			4.0,
			true,
		)
