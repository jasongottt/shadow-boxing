class_name FighterPresentation
extends Node

const SHADOW_FLASH_SHADER := preload("res://shaders/shadow_outline.gdshader")
const SHADOW_RIM_SHADER := preload("res://shaders/shadow_rim.gdshader")

const IDLE_ANIMATION := &"default"
const CONTACT_FRAME := 2

const PUNCHER_FRAME_SIZE := Vector2(500.0, 500.0)
const PUNCHER_ANCHOR := Vector2(311.0, 470.0)
const PUNCHER_PIXEL_SCALE := 1.5
const PUNCHER_GROUND := Vector2(750.0, 665.0)
const PUNCHER_SCALE := Vector2(PUNCHER_PIXEL_SCALE, PUNCHER_PIXEL_SCALE)
const PUNCHER_POSITION := (
	PUNCHER_GROUND - (PUNCHER_ANCHOR - PUNCHER_FRAME_SIZE / 2.0) * PUNCHER_PIXEL_SCALE
)

const SHADOW_FRAME_SIZE := Vector2(800.0, 500.0)
const SHADOW_ANCHOR := Vector2(240.0, 500.0)
const SHADOW_PIXEL_SCALE := 1.5
const SHADOW_GROUND := Vector2(430.0, 675.0)
const SHADOW_SCALE := Vector2(SHADOW_PIXEL_SCALE, SHADOW_PIXEL_SCALE)
const SHADOW_POSITION := (
	SHADOW_GROUND - (SHADOW_ANCHOR - SHADOW_FRAME_SIZE / 2.0) * SHADOW_PIXEL_SCALE
)

const SHADOW_OUTLINE_WIDTH := 4.0
const SHADOW_RIM_OFFSETS: Array[Vector2] = [
	Vector2(-SHADOW_OUTLINE_WIDTH, 0.0),
	Vector2(SHADOW_OUTLINE_WIDTH, 0.0),
	Vector2(0.0, -SHADOW_OUTLINE_WIDTH),
	Vector2(0.0, SHADOW_OUTLINE_WIDTH),
	Vector2(-SHADOW_OUTLINE_WIDTH, -SHADOW_OUTLINE_WIDTH),
	Vector2(SHADOW_OUTLINE_WIDTH, -SHADOW_OUTLINE_WIDTH),
	Vector2(-SHADOW_OUTLINE_WIDTH, SHADOW_OUTLINE_WIDTH),
	Vector2(SHADOW_OUTLINE_WIDTH, SHADOW_OUTLINE_WIDTH),
]

var puncher: AnimatedSprite2D
var shadow: AnimatedSprite2D
var shadow_material: ShaderMaterial
var shadow_rim_material: ShaderMaterial
var shadow_rims: Array[AnimatedSprite2D] = []
var shadow_flash_tween: Tween


func setup(puncher_node: AnimatedSprite2D, shadow_node: AnimatedSprite2D) -> void:
	puncher = puncher_node
	shadow = shadow_node
	build_shadow_materials()
	build_shadow_rims()
	reset()


func build_shadow_materials() -> void:
	shadow_material = ShaderMaterial.new()
	shadow_material.shader = SHADOW_FLASH_SHADER
	shadow_material.set_shader_parameter(&"outline_width", 0.0)
	shadow.material = shadow_material

	shadow_rim_material = ShaderMaterial.new()
	shadow_rim_material.shader = SHADOW_RIM_SHADER


func build_shadow_rims() -> void:
	var visual_parent: Node = shadow.get_parent()
	for rim_offset: Vector2 in SHADOW_RIM_OFFSETS:
		var rim: AnimatedSprite2D = AnimatedSprite2D.new()
		rim.name = &"shadowrim"
		rim.sprite_frames = shadow.sprite_frames
		rim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rim.material = shadow_rim_material
		rim.set_meta(&"rim_offset", rim_offset)
		visual_parent.add_child(rim)
		visual_parent.move_child(rim, shadow.get_index())
		shadow_rims.append(rim)


func _process(_delta: float) -> void:
	if not is_instance_valid(shadow):
		return

	for rim: AnimatedSprite2D in shadow_rims:
		var rim_offset: Vector2 = rim.get_meta(&"rim_offset", Vector2.ZERO)
		rim.position = shadow.position + rim_offset
		rim.scale = shadow.scale
		rim.animation = shadow.animation
		rim.frame = shadow.frame
		rim.frame_progress = shadow.frame_progress
		rim.modulate.a = shadow.modulate.a
		rim.visible = shadow.visible


func set_colors(attacker_color: Color, defender_color: Color, alpha: float = 1.0) -> void:
	var puncher_color: Color = attacker_color
	var shadow_color: Color = defender_color
	puncher_color.a = alpha
	shadow_color.a = alpha
	puncher.modulate = puncher_color
	shadow.modulate = shadow_color
	shadow_material.set_shader_parameter(&"outline_color", defender_color)

	var rim_color: Color = defender_color
	rim_color.a = 0.72
	shadow_rim_material.set_shader_parameter(&"rim_color", rim_color)


func apply_idle_bob(idle_time: float, speed: float, amount: float, shadow_ratio: float) -> void:
	var bob: float = sin(idle_time * speed) * amount
	puncher.position = PUNCHER_POSITION + Vector2(0.0, bob)
	shadow.position = SHADOW_POSITION + Vector2(0.0, bob * shadow_ratio)


func play_punch(animation: StringName, contact_time: float) -> void:
	puncher.scale = PUNCHER_SCALE
	puncher.position = PUNCHER_POSITION
	start_animation(puncher, animation, contact_time)


func play_shadow(animation: StringName, contact_time: float) -> void:
	shadow.scale = SHADOW_SCALE
	shadow.position = SHADOW_POSITION
	start_animation(shadow, animation, contact_time)


func hold_contact() -> void:
	freeze_on_contact(puncher)
	freeze_on_contact(shadow)


func freeze_on_contact(sprite: AnimatedSprite2D) -> void:
	if sprite.animation == IDLE_ANIMATION:
		return

	sprite.set_frame_and_progress(CONTACT_FRAME, 0.0)
	sprite.pause()


func play_recovery(duration: float) -> void:
	play_sprite_recovery(puncher, duration)
	play_sprite_recovery(shadow, duration)


func play_sprite_recovery(sprite: AnimatedSprite2D, duration: float) -> void:
	if sprite.animation == IDLE_ANIMATION or duration <= 0.0:
		return

	var frame_count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	var recovery_frame: int = mini(CONTACT_FRAME + 1, frame_count - 1)
	var remaining_frames: int = frame_count - recovery_frame
	var fps: float = sprite.sprite_frames.get_animation_speed(sprite.animation)
	if fps <= 0.0 or remaining_frames <= 0:
		return

	sprite.speed_scale = (remaining_frames / fps) / duration
	sprite.play(sprite.animation)
	sprite.set_frame_and_progress(recovery_frame, 0.0)


func start_animation(
	sprite: AnimatedSprite2D, animation: StringName, contact_time: float
) -> void:
	var must_rewind: bool = contact_time > 0.0 or sprite.animation != animation
	sprite.speed_scale = get_contact_speed_scale(sprite, animation, contact_time)
	sprite.play(animation)
	if must_rewind:
		sprite.set_frame_and_progress(0, 0.0)


func get_contact_speed_scale(
	sprite: AnimatedSprite2D, animation: StringName, contact_time: float
) -> float:
	if contact_time <= 0.0:
		return 1.0

	var fps: float = sprite.sprite_frames.get_animation_speed(animation)
	if fps <= 0.0:
		return 1.0
	return (CONTACT_FRAME / fps) / contact_time


func reset() -> void:
	reset_puncher()
	reset_shadow()


func reset_puncher() -> void:
	play_punch(IDLE_ANIMATION, 0.0)


func reset_shadow() -> void:
	play_shadow(IDLE_ANIMATION, 0.0)


func flash_puncher(color: Color) -> void:
	puncher.modulate = color


func flash_shadow(amount: float, duration: float) -> void:
	if shadow_flash_tween != null and shadow_flash_tween.is_valid():
		shadow_flash_tween.kill()

	set_shadow_flash(amount)
	shadow_flash_tween = create_tween()
	shadow_flash_tween.set_ignore_time_scale(true)
	shadow_flash_tween.tween_method(set_shadow_flash, amount, 0.0, duration).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)


func set_shadow_flash(amount: float) -> void:
	shadow_material.set_shader_parameter(&"flash_amount", amount)


func hide_shadow() -> void:
	shadow.hide()
	for rim: AnimatedSprite2D in shadow_rims:
		rim.hide()
