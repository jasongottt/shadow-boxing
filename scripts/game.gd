extends Node2D

enum Direction {
	NONE = -1,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

const PLAYER_ONE := 1
const PLAYER_TWO := 2
const MAX_HITS := 3
const MAX_TRIES := 3
const INPUT_FLASH_DURATION := 0.05
const WALL_BREAK_DELAY := 1.0
const SWITCH_FLASH_COUNT := 6

const PUNCHER_DEFAULT_POSITION := Vector2(568.594, 479.715)
const PUNCHER_LEFT_POSITION := Vector2(468.594, 509.715)
const PUNCHER_RIGHT_POSITION := Vector2(668.594, 509.715)
const SHADOW_DEFAULT_POSITION := Vector2(540, 344)
const SHADOW_DEFAULT_SCALE := Vector2(0.534, 0.534)
const SHADOW_DEFAULT_REGION := Rect2(100, 122, 372, 1061)
const LIFE_SCALE := Vector2(0.119, 0.119)
const BAR_SLIDE_DURATION := 1.0
const BAR_SLIDE_STAGGER := 0.12
const INTRO_ZOOM := 2.2

const TOP_BAR_TARGET_POSITION := Vector2(593, -143)
const BOTTOM_BAR_TARGET_POSITION := Vector2(591, 791)

@export var player_one_color := Color(0.825, 0.332, 0.387, 1.0)
@export var player_two_color := Color(0.319, 0.533, 0.769, 1.0)
@export var max_shake_strength: float = 30.0
@export var shake_decay_rate: float = 5.0

@onready var camera: Camera2D = $camera
@onready var crack_sprites: Array[Sprite2D] = [
	$cracks/Crack1,
	$cracks/Crack2,
	$cracks/Crack3,
]
@onready var life_sprites: Array[Sprite2D] = [
	$lives/life0,
	$lives/life1,
	$lives/life2,
]
@onready var puncher: AnimatedSprite2D = $puncher
@onready var shadow: Sprite2D = $shadow
@onready var switch_sprite: Sprite2D = $switch
@onready var waiter: Timer = $waiter
@onready var wall_particles: CPUParticles2D = $wallpart
@onready var top_bar: Sprite2D = $blackbar2
@onready var bottom_bar: Sprite2D = $blackbar1

var current_player := PLAYER_ONE
var arrow_direction := Direction.NONE
var wasd_direction := Direction.NONE
var hits := 0
var remaining_tries := MAX_TRIES
var is_switching_players := false
var is_wall_breaking := false
var is_intro_playing := true
var shake_strength := 0.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	reset_puncher()
	reset_shadow()
	set_player_color()
	animate_bars_in()


func _process(delta: float) -> void:
	update_camera_shake(delta)
	update_lives(delta)

	if is_intro_playing or is_switching_players or is_wall_breaking:
		return

	if remaining_tries <= 0:
		switch_player()
		return

	if hits >= MAX_HITS:
		break_wall()
		return

	if waiter.is_stopped():
		handle_player_inputs()

		if arrow_direction != Direction.NONE and wasd_direction != Direction.NONE:
			start_attack()


func animate_bars_in() -> void:
	var start_y_offset := 600.0
	var lives_original_position: Vector2 = $lives.position

	camera.zoom = Vector2(INTRO_ZOOM, INTRO_ZOOM)

	top_bar.position = TOP_BAR_TARGET_POSITION + Vector2(0, -start_y_offset)
	bottom_bar.position = BOTTOM_BAR_TARGET_POSITION + Vector2(0, start_y_offset)
	$lives.position = lives_original_position + Vector2(0, start_y_offset)

	var zoom_tween := create_tween()
	zoom_tween.tween_property(
		camera,
		^"zoom",
		Vector2.ONE,
		BAR_SLIDE_DURATION + BAR_SLIDE_STAGGER,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var top_tween := create_tween()
	top_tween.tween_property(
		top_bar,
		^"position",
		TOP_BAR_TARGET_POSITION,
		BAR_SLIDE_DURATION,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var bottom_tween := create_tween()
	bottom_tween.tween_interval(BAR_SLIDE_STAGGER)
	bottom_tween.tween_property(
		bottom_bar,
		^"position",
		BOTTOM_BAR_TARGET_POSITION,
		BAR_SLIDE_DURATION,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bottom_tween.tween_property(
		$lives,
		^"position",
		lives_original_position,
		BAR_SLIDE_DURATION,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await bottom_tween.finished
	await get_tree().create_timer(0.3).timeout
	is_intro_playing = false


func handle_player_inputs() -> void:
	if arrow_direction == Direction.NONE:
		var direction := get_arrow_direction()
		if direction != Direction.NONE:
			arrow_direction = direction
			flash_puncher()

	if wasd_direction == Direction.NONE:
		var direction := get_wasd_direction()
		if direction != Direction.NONE:
			wasd_direction = direction
			flash_shadow()


func get_arrow_direction() -> Direction:
	if Input.is_action_just_pressed(&"up"):
		return Direction.UP
	if Input.is_action_just_pressed(&"down"):
		return Direction.DOWN
	if Input.is_action_just_pressed(&"left"):
		return Direction.LEFT
	if Input.is_action_just_pressed(&"right"):
		return Direction.RIGHT

	return Direction.NONE


func get_wasd_direction() -> Direction:
	if Input.is_action_just_pressed(&"w"):
		return Direction.UP
	if Input.is_action_just_pressed(&"s"):
		return Direction.DOWN
	if Input.is_action_just_pressed(&"a"):
		return Direction.LEFT
	if Input.is_action_just_pressed(&"d"):
		return Direction.RIGHT

	return Direction.NONE


func flash_puncher() -> void:
	puncher.modulate = Color(0.84, 0.31, 0.21, 1.0)
	await get_tree().create_timer(INPUT_FLASH_DURATION).timeout
	set_player_color()


func flash_shadow() -> void:
	shadow.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(INPUT_FLASH_DURATION).timeout
	set_player_color()


func set_player_color() -> void:
	var color := player_one_color if current_player == PLAYER_ONE else player_two_color
	puncher.modulate = color
	shadow.modulate = color


func switch_player() -> void:
	is_switching_players = true
	current_player = PLAYER_TWO if current_player == PLAYER_ONE else PLAYER_ONE
	remaining_tries = MAX_TRIES
	hits = 0
	clear_directions()

	await play_switch_animation()

	reset_puncher()
	reset_shadow()
	reset_cracks()
	reset_lives()
	set_player_color()
	is_switching_players = false


func play_switch_animation() -> void:
	switch_sprite.show()
	switch_sprite.scale = Vector2(0.1, 0.1)
	switch_sprite.modulate = player_one_color

	var scale_tween := create_tween()
	scale_tween.tween_property(
		switch_sprite,
		^"scale",
		Vector2(0.674, 0.674),
		0.8,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(
		switch_sprite,
		^"scale",
		Vector2.ZERO,
		0.2,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	var flash_tween := create_tween()
	for _flash in range(SWITCH_FLASH_COUNT):
		flash_tween.tween_property(switch_sprite, ^"modulate", player_one_color, 0.18)
		flash_tween.tween_property(switch_sprite, ^"modulate", player_two_color, 0.18)

	await scale_tween.finished
	flash_tween.kill()
	switch_sprite.hide()


func start_attack() -> void:
	update_puncher_visuals()
	update_shadow_visuals()
	wall_particles.restart()
	waiter.start()


func update_puncher_visuals() -> void:
	puncher.position = PUNCHER_DEFAULT_POSITION

	match arrow_direction:
		Direction.UP:
			wall_particles.position = Vector2(613, 133)
			puncher.play(&"up")
		Direction.DOWN:
			wall_particles.position = Vector2(610, 350)
			puncher.play(&"down")
		Direction.LEFT:
			wall_particles.position = Vector2(322, 265)
			puncher.position = PUNCHER_LEFT_POSITION
			puncher.play(&"left")
		Direction.RIGHT:
			wall_particles.position = Vector2(811, 269)
			puncher.position = PUNCHER_RIGHT_POSITION
			puncher.play(&"right")


func update_shadow_visuals() -> void:
	shadow.scale = SHADOW_DEFAULT_SCALE

	match wasd_direction:
		Direction.UP:
			shadow.position = Vector2(576, 335)
			shadow.scale = Vector2(0.492, 0.492)
			shadow.region_rect = Rect2(2281, 127, 777, 1326)
		Direction.DOWN:
			shadow.position = Vector2(582, 499)
			shadow.scale = Vector2(0.488, 0.488)
			shadow.region_rect = Rect2(2281, 127, 777, 1126)
		Direction.LEFT:
			shadow.position = Vector2(331, 370)
			shadow.region_rect = Rect2(588, 140, 690, 1121)
		Direction.RIGHT:
			shadow.position = Vector2(796, 360)
			shadow.region_rect = Rect2(1427, 149, 690, 1121)


func reset_puncher() -> void:
	puncher.play(&"default")
	puncher.position = PUNCHER_DEFAULT_POSITION


func reset_shadow() -> void:
	shadow.region_rect = SHADOW_DEFAULT_REGION
	shadow.position = SHADOW_DEFAULT_POSITION
	shadow.scale = SHADOW_DEFAULT_SCALE


func reset_cracks() -> void:
	for crack in crack_sprites:
		crack.hide()


func reset_lives() -> void:
	for life in life_sprites:
		life.scale = LIFE_SCALE


func update_lives(delta: float) -> void:
	var lost_lives := clampi(MAX_TRIES - remaining_tries, 0, life_sprites.size())
	var interpolation_weight := minf(delta * 10.0, 1.0)

	for index in range(lost_lives):
		var life := life_sprites[index]
		life.scale = life.scale.lerp(Vector2.ZERO, interpolation_weight)


func apply_shake() -> void:
	shake_strength = max_shake_strength


func update_camera_shake(delta: float) -> void:
	var interpolation_weight := minf(shake_decay_rate * delta, 1.0)
	shake_strength = lerpf(shake_strength, 0.0, interpolation_weight)
	camera.offset = get_random_camera_offset()


func get_random_camera_offset() -> Vector2:
	return Vector2(
		random.randf_range(-shake_strength, shake_strength),
		random.randf_range(-shake_strength, shake_strength),
	)


func _on_waiter_timeout() -> void:
	if is_wall_breaking:
		return

	if wasd_direction == arrow_direction:
		register_hit()
	else:
		remaining_tries -= 1

	clear_directions()

	if hits < MAX_HITS:
		reset_puncher()
		reset_shadow()


func clear_directions() -> void:
	arrow_direction = Direction.NONE
	wasd_direction = Direction.NONE


func register_hit() -> void:
	hits += 1
	apply_shake()

	var crack := crack_sprites[hits - 1]
	crack.position = get_crack_position(wasd_direction)
	crack.show()


func get_crack_position(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2(576, 105)
		Direction.DOWN:
			return Vector2(582, 299)
		Direction.LEFT:
			return Vector2(331, 250)
		Direction.RIGHT:
			return Vector2(796, 250)

	return Vector2.ZERO


func break_wall() -> void:
	is_wall_breaking = true

	await get_tree().create_timer(WALL_BREAK_DELAY).timeout

	wall_particles.position = Vector2(613, 233)
	wall_particles.restart()
	$Crack4.modulate = Color(1, 1, 1, 0.6)
	apply_shake()

	await get_tree().create_timer(WALL_BREAK_DELAY).timeout

	apply_shake()
	$Wall.hide()
	$darkline.hide()
	reset_puncher()
	reset_cracks()
	$Crack4.hide()
	shadow.hide()
	$Shmile.show()
