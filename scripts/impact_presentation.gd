class_name ImpactPresentation
extends Node

const IMPACT_BURST_SCRIPT := preload("res://scripts/impact_burst.gd")
const HIT_WORD_TEXTURES: Array[Texture2D] = [
	preload("res://sprites/wham.png"),
	preload("res://sprites/blam.png"),
	preload("res://sprites/pow.png"),
	preload("res://sprites/boom.png"),
]
const CRACK_POP_SCALE := 1.35
const CRACK_POP_DURATION := 0.14
const CRACK_OPACITY := 0.58
const DEBRIS_SPREAD := 42.0
const HIT_WORD_OFFSET := 105.0
const HIT_WORD_RISE := 24.0
const HIT_WORD_DURATION := 0.42

var particles: CPUParticles2D
var cracks: Array[Sprite2D] = []
var crack_base_scales: Array[Vector2] = []
var burst: ImpactBurst
var hit_word: Node2D
var hit_word_sprite: Sprite2D
var hit_word_shadow: Sprite2D
var hit_word_motion_tween: Tween
var hit_word_scale_tween: Tween


func setup(
	particle_node: CPUParticles2D, crack_nodes: Array[Sprite2D]
) -> void:
	particles = particle_node
	cracks = crack_nodes
	particles.spread = DEBRIS_SPREAD

	for crack: Sprite2D in cracks:
		crack.modulate.a = CRACK_OPACITY
		crack_base_scales.append(crack.scale)

	burst = IMPACT_BURST_SCRIPT.new() as ImpactBurst
	burst.name = &"impactburst"
	add_child(burst)
	build_hit_word()


func build_hit_word() -> void:
	hit_word = Node2D.new()
	hit_word.name = &"hitword"
	hit_word.z_index = 18
	add_child(hit_word)

	hit_word_shadow = Sprite2D.new()
	hit_word_shadow.name = &"shadow"
	hit_word_shadow.position = Vector2(6.0, 7.0)
	hit_word_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hit_word.add_child(hit_word_shadow)

	hit_word_sprite = Sprite2D.new()
	hit_word_sprite.name = &"word"
	hit_word_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hit_word.add_child(hit_word_sprite)
	hit_word.hide()


func play_hit_word(
	word_index: int,
	contact_position: Vector2,
	direction: Vector2,
	color: Color,
	intensity: float = 1.0,
) -> void:
	if hit_word_motion_tween != null and hit_word_motion_tween.is_valid():
		hit_word_motion_tween.kill()
	if hit_word_scale_tween != null and hit_word_scale_tween.is_valid():
		hit_word_scale_tween.kill()

	var texture_index: int = posmod(word_index, HIT_WORD_TEXTURES.size())
	var texture: Texture2D = HIT_WORD_TEXTURES[texture_index]
	var away_from_hit: Vector2 = -direction.normalized()
	var start_position: Vector2 = (
		contact_position + away_from_hit * HIT_WORD_OFFSET + Vector2(0.0, -20.0)
	)
	var start_scale: Vector2 = Vector2.ONE * 0.18 * intensity
	var settled_scale: Vector2 = Vector2.ONE * 0.9 * intensity
	var punch_color: Color = color
	punch_color.a = 1.0

	hit_word.position = start_position
	hit_word.rotation = deg_to_rad(-7.0 if word_index % 2 == 0 else 7.0)
	hit_word.scale = start_scale
	hit_word.modulate.a = 1.0
	hit_word_sprite.texture = texture
	hit_word_sprite.modulate = punch_color
	hit_word_shadow.texture = texture
	hit_word_shadow.modulate = Color(0.08, 0.035, 0.045, 0.68)
	hit_word.show()

	var duration: float = HIT_WORD_DURATION * (0.9 if intensity < 1.0 else 1.0)
	hit_word_motion_tween = create_tween()
	hit_word_motion_tween.set_ignore_time_scale(true)
	hit_word_motion_tween.set_parallel(true)
	hit_word_motion_tween.tween_property(
		hit_word, ^"position", start_position + Vector2(0.0, -HIT_WORD_RISE), duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hit_word_motion_tween.tween_property(
		hit_word, ^"modulate:a", 0.0, duration * 0.38
	).set_delay(duration * 0.62)
	hit_word_motion_tween.tween_callback(hit_word.hide).set_delay(duration)

	hit_word_scale_tween = create_tween()
	hit_word_scale_tween.set_ignore_time_scale(true)
	hit_word_scale_tween.tween_property(
		hit_word, ^"scale", Vector2.ONE * 1.14 * intensity, 0.09
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hit_word_scale_tween.tween_property(
		hit_word, ^"scale", settled_scale, 0.11
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func reset_cracks() -> void:
	for crack: Sprite2D in cracks:
		crack.hide()


func show_crack(
	crack_index: int, world_position: Vector2, emphasize: bool
) -> void:
	if crack_index < 0 or crack_index >= cracks.size():
		return

	var crack: Sprite2D = cracks[crack_index]
	var base_scale: Vector2 = crack_base_scales[crack_index]
	crack.position = world_position
	crack.scale = base_scale
	crack.show()

	if not emphasize:
		return

	crack.scale = base_scale * CRACK_POP_SCALE
	var pop_tween: Tween = create_tween()
	pop_tween.set_ignore_time_scale(true)
	pop_tween.tween_property(
		crack, ^"scale", base_scale, CRACK_POP_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_burst(
	world_position: Vector2,
	direction: Vector2,
	color: Color,
	intensity: float
) -> void:
	burst.play_burst(world_position, direction, color, intensity)


func play_directional_debris(
	world_position: Vector2, direction: Vector2
) -> void:
	particles.position = world_position
	particles.direction = direction
	particles.restart()


func play_wall_break_debris(world_position: Vector2) -> void:
	particles.position = world_position
	particles.restart()
