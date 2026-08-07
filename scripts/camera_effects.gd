class_name CameraEffects
extends Node

const PUSH_DECAY := 8.0
const SHAKE_FREQUENCY := 52.0

var camera: Camera2D
var max_shake_strength: float = 30.0
var shake_decay_rate: float = 5.0
var shake_strength: float = 0.0
var shake_axis: Vector2 = Vector2.RIGHT
var shake_time: float = 0.0
var push_offset: Vector2 = Vector2.ZERO
var random: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(
	camera_node: Camera2D, maximum_strength: float, decay_rate: float
) -> void:
	camera = camera_node
	max_shake_strength = maximum_strength
	shake_decay_rate = decay_rate
	random.randomize()


func shake(strength: float, direction: Vector2 = Vector2.ZERO) -> void:
	shake_strength = max_shake_strength if strength < 0.0 else strength
	shake_time = 0.0
	shake_axis = (
		Vector2.RIGHT.rotated(random.randf_range(0.0, TAU))
		if direction == Vector2.ZERO
		else direction.normalized()
	)


func push(direction: Vector2, strength: float) -> void:
	push_offset = direction.normalized() * strength


func clear() -> void:
	shake_strength = 0.0
	push_offset = Vector2.ZERO
	if is_instance_valid(camera):
		camera.offset = Vector2.ZERO


func _process(delta: float) -> void:
	if not is_instance_valid(camera):
		return

	var shake_weight: float = minf(shake_decay_rate * delta, 1.0)
	var push_weight: float = minf(PUSH_DECAY * delta, 1.0)
	shake_strength = lerpf(shake_strength, 0.0, shake_weight)
	push_offset = push_offset.lerp(Vector2.ZERO, push_weight)
	shake_time += delta * SHAKE_FREQUENCY

	var perpendicular: Vector2 = Vector2(-shake_axis.y, shake_axis.x)
	var primary: Vector2 = shake_axis * sin(shake_time) * shake_strength
	var secondary: Vector2 = (
		perpendicular * cos(shake_time * 1.67) * shake_strength * 0.24
	)
	camera.offset = push_offset + primary + secondary
