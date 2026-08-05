class_name Game
extends Node2D

enum Direction {
	NONE = -1,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

enum State {
	INTRO,
	INPUT,
	REPLAY,
	SWITCHING,
	WALL_BREAK,
}

const PLAYER_ONE := 1
const PLAYER_TWO := 2
const MAX_HITS := 3
const ALL_DIRECTIONS: Array[int] = [
	Direction.UP,
	Direction.DOWN,
	Direction.LEFT,
	Direction.RIGHT,
]

const PUNCHER_IDLE_ANIMATION := &"default"

const PUNCHER_FRAME_SIZE := 500.0

const PUNCHER_ANCHOR := Vector2(211.5, 366.0)

const PUNCHER_BODY_TEXELS := 208.0
const PUNCHER_BODY_PIXELS := 273.0
const PUNCHER_SCALE := 1.5

## The point in the world the fighter's feet plant on.
const PUNCHER_GROUND := Vector2(568.594, 585.0)

## A node's position is the centre of its frame, so the anchor above has to be
## converted into that centre before it can be assigned.
const PUNCHER_POSITION := Vector2(
	PUNCHER_GROUND.x - (PUNCHER_ANCHOR.x - PUNCHER_FRAME_SIZE / 2.0) * PUNCHER_SCALE,
	PUNCHER_GROUND.y - (PUNCHER_ANCHOR.y - PUNCHER_FRAME_SIZE / 2.0) * PUNCHER_SCALE
)
const PUNCHER_NODE_SCALE := Vector2(PUNCHER_SCALE, PUNCHER_SCALE)

const SHADOW_IDLE_ANIMATION := &"default"

## The shadow sheets (shadidle.png, shadup.png) are 128x128 pixel-art frames.
## Every frame is bottom-anchored -- the silhouette's feet sit on the frame's
## bottom edge -- and centred 2 texels left of the frame centre, so all poses
## share one anchor and swapping animations never shifts the figure.
const SHADOW_FRAME_SIZE := 128.0
const SHADOW_SILHOUETTE_CENTER_X := 62.0

## The idle silhouette is 78 texels tall, the up-dodge leap 105. The playfield is
## letterboxed to roughly y 33..615 by the black bars, so the scale is driven by
## the tallest pose: 105 texels must fit in those ~582px. Scale 5 keeps the whole
## leap on screen (peaking at y 92, right where the up-punch crack lands) and is
## an integer, so pixels stay square under nearest-neighbour filtering exactly
## like the puncher's PIXEL_SCALE.
const SHADOW_PIXEL_SCALE := 5.0

## Poses are authored as the point the silhouette's feet stand on; this offset
## converts that into the node position, which is the centre of the frame.
const SHADOW_ANCHOR_OFFSET := Vector2(
	(SHADOW_FRAME_SIZE / 2.0 - SHADOW_SILHOUETTE_CENTER_X) * SHADOW_PIXEL_SCALE,
	-(SHADOW_FRAME_SIZE / 2.0) * SHADOW_PIXEL_SCALE
)
const SHADOW_DEFAULT_FEET := Vector2(540, 617)
const SHADOW_DEFAULT_POSITION := SHADOW_DEFAULT_FEET + SHADOW_ANCHOR_OFFSET
const SHADOW_DEFAULT_SCALE := Vector2(SHADOW_PIXEL_SCALE, SHADOW_PIXEL_SCALE)

## Everything that differs between the four punch directions, in one table.
const DIRECTION_DATA := {
	Direction.UP: {
		"animation": &"up",
		"particle_position": Vector2(613, 133),
		# The up sheet animates the leap itself, so the pose stays put.
		"shadow_feet": SHADOW_DEFAULT_FEET,
		"shadow_animation": &"up",
		"crack_position": Vector2(576, 105),
	},
	Direction.DOWN: {
		"animation": &"down",
		"particle_position": Vector2(610, 350),
		"shadow_feet": Vector2(582, 737),
		"shadow_animation": SHADOW_IDLE_ANIMATION,
		"crack_position": Vector2(582, 299),
	},
	Direction.LEFT: {
		"animation": &"left",
		"particle_position": Vector2(322, 265),
		"shadow_feet": Vector2(331, 617),
		"shadow_animation": SHADOW_IDLE_ANIMATION,
		"crack_position": Vector2(331, 250),
	},
	Direction.RIGHT: {
		"animation": &"right",
		"particle_position": Vector2(811, 269),
		"shadow_feet": Vector2(796, 617),
		"shadow_animation": SHADOW_IDLE_ANIMATION,
		"crack_position": Vector2(796, 250),
	},
}

const ARROW_ACTIONS := {
	&"up": Direction.UP,
	&"down": Direction.DOWN,
	&"left": Direction.LEFT,
	&"right": Direction.RIGHT,
}
const WASD_ACTIONS := {
	&"w": Direction.UP,
	&"s": Direction.DOWN,
	&"a": Direction.LEFT,
	&"d": Direction.RIGHT,
}

const TURN_TIME := 3.0
const TIMEOUT_PAUSE := 0.5

## Every fighter sheet is authored to the same five-beat shape: frame 0 neutral,
## 1 wind-up, 2 full extension, 3 extension held, 4 recovery. Frame 2 is the one
## that touches the wall (and the top of the shadow's leap), so the replay is
## timed against it -- the crack, the particles and the shake all land on the
## frame that actually connects instead of on a wind-up.
const CONTACT_FRAME := 2

const SEQUENCE_START_DELAY := 0.3

## Seconds from the start of a punch to its contact frame. The sheets' authored
## fps is scaled to fit these windows, so a ghost replays as a fast-forward of
## the same swing rather than being cut off before the arm ever extends.
const REPLAY_GHOST_CONTACT_TIME := 0.13
const REPLAY_GHOST_HOLD := 0.05
const REPLAY_GHOST_GAP := 0.05
const REPLAY_GHOST_ALPHA := 0.4
const REPLAY_LIVE_CONTACT_TIME := 0.26
## Long enough to outlast HIT_STOP_DURATION, so the freeze-frame ends while the
## fist is still planted in the wall.
const REPLAY_LIVE_HOLD := 0.19
const REPLAY_LIVE_GAP := 0.2

const CRACK_POP_SCALE := 1.45
const CRACK_POP_DURATION := 0.16

## The environment leans toward the attacking player's colour so whose turn it
## is readable from the whole frame, not just the two fighters.
const WALL_BASE_COLOR := Color(0.776, 0.607, 0.678, 1.0)
const WALL_GRADE_STRENGTH := 0.3
const GRADE_TWEEN_DURATION := 0.5

const IDLE_BOB_SPEED := 4.0
const IDLE_BOB_AMOUNT := 4.0
const IDLE_SHADOW_BOB_RATIO := -0.6

const INPUT_FLASH_DURATION := 0.05
const HIT_STOP_DURATION := 0.09
const HIT_STOP_TIME_SCALE := 0.05
const HIT_SHAKE_STRENGTH := 30.0
const MISS_SHAKE_STRENGTH := 7.0
const FLASH_ALPHA := 0.5
const FLASH_FADE_DURATION := 0.22

const WALL_BREAK_DELAY := 1.0
const SWITCH_FLASH_COUNT := 6
const BAR_SLIDE_DURATION := 1.0
const BAR_SLIDE_STAGGER := 0.12
const INTRO_ZOOM := 2.2
const TOP_BAR_TARGET_POSITION := Vector2(593, -143)
const BOTTOM_BAR_TARGET_POSITION := Vector2(591, 791)

const INDICATORS_POSITION := Vector2(576, 664)
const TIMER_BAR_POSITION := Vector2(576, 728)
const DIRECTION_INDICATORS_SCRIPT := preload("res://scripts/direction_indicators.gd")
const TURN_TIMER_BAR_SCRIPT := preload("res://scripts/turn_timer_bar.gd")

@export var player_one_color := Color(0.825, 0.332, 0.387, 1.0)
@export var player_two_color := Color(0.319, 0.533, 0.769, 1.0)
@export var max_shake_strength: float = 30.0
@export var shake_decay_rate: float = 5.0

@onready var camera: Camera2D = $camera
@onready var wall_sprite: AnimatedSprite2D = $Wall
@onready var crack_sprites: Array[Sprite2D] = [
	$cracks/Crack1,
	$cracks/Crack2,
	$cracks/Crack3,
]
@onready var puncher: AnimatedSprite2D = $puncher
@onready var shadow: AnimatedSprite2D = $shadow
@onready var switch_sprite: AnimatedSprite2D = $switch
@onready var wall_particles: CPUParticles2D = $wallpart
@onready var top_bar: Sprite2D = $blackbar2
@onready var bottom_bar: Sprite2D = $blackbar1
var indicators: DirectionIndicators
var timer_bar: TurnTimerBar
var flash_rect: ColorRect

var state := State.INTRO
## The attacker (current_player) drives the puncher, the other player the shadow.
var current_player := PLAYER_ONE
var punch_direction := Direction.NONE
var dodge_direction := Direction.NONE
var hits := 0
var available_directions: Array[int] = []
var punch_history: Array[Dictionary] = []
var switch_after_sequence := false
var turn_time_left := TURN_TIME
var idle_time := 0.0
var crack_base_scales: Array[Vector2] = []
var shake_strength := 0.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	build_hud()

	for crack in crack_sprites:
		crack_base_scales.append(crack.scale)

	reset_round_state()
	reset_puncher()
	reset_shadow()
	set_player_color()
	refresh_indicators()
	apply_environment_grade()
	timer_bar.set_state(1.0, get_attacker_color(), false)
	animate_bars_in()


func _process(delta: float) -> void:
	update_camera_shake(delta)

	if state == State.INPUT:
		process_input_phase(delta)


## The HUD is built in code so the scene file stays free of UI plumbing.
func build_hud() -> void:
	indicators = DIRECTION_INDICATORS_SCRIPT.new()
	indicators.name = &"indicators"
	indicators.position = INDICATORS_POSITION
	add_child(indicators)

	timer_bar = TURN_TIMER_BAR_SCRIPT.new()
	timer_bar.name = &"timerbar"
	timer_bar.position = TIMER_BAR_POSITION
	add_child(timer_bar)

	var flash_layer := CanvasLayer.new()
	flash_layer.name = &"flash"
	add_child(flash_layer)

	flash_rect = ColorRect.new()
	flash_rect.name = &"rect"
	flash_rect.color = Color.WHITE
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash_rect)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.modulate.a = 0.0


#region Turn flow
func begin_input_phase() -> void:
	clear_directions()
	turn_time_left = TURN_TIME
	idle_time = 0.0
	refresh_indicators()
	refresh_lock_indicators()
	state = State.INPUT


func process_input_phase(delta: float) -> void:
	turn_time_left -= delta
	idle_time += delta
	timer_bar.set_state(turn_time_left / TURN_TIME, get_attacker_color(), true)
	apply_idle_bob()

	if turn_time_left <= 0.0:
		handle_turn_timeout()
		return

	handle_player_inputs()
	refresh_lock_indicators()

	if punch_direction != Direction.NONE and dodge_direction != Direction.NONE:
		resolve_exchange()


## Keeps the fighters breathing while the turn timer drains.
func apply_idle_bob() -> void:
	var bob := sin(idle_time * IDLE_BOB_SPEED) * IDLE_BOB_AMOUNT
	puncher.position = PUNCHER_POSITION + Vector2(0.0, bob)
	shadow.position = get_shadow_node_position(
		SHADOW_DEFAULT_FEET + Vector2(0.0, bob * IDLE_SHADOW_BOB_RATIO)
	)


func handle_turn_timeout() -> void:
	# Hesitating costs the turn outright.
	state = State.SWITCHING
	timer_bar.set_state(0.0, get_attacker_color(), true)
	apply_shake(MISS_SHAKE_STRENGTH)
	clear_directions()

	await get_tree().create_timer(TIMEOUT_PAUSE).timeout

	switch_player()


func resolve_exchange() -> void:
	var punch := {
		"punch": punch_direction,
		"dodge": dodge_direction,
		"hit": punch_direction == dodge_direction,
		"attacker": current_player,
	}
	punch_history.append(punch)

	if punch["hit"]:
		hits += 1
		available_directions.erase(int(punch["punch"]))
	else:
		# A miss ends this attacker's turn: the other player takes over.
		switch_after_sequence = true

	clear_directions()
	refresh_lock_indicators()
	play_punch_sequence()


func play_punch_sequence() -> void:
	state = State.REPLAY
	timer_bar.set_state(0.0, get_attacker_color(), false)

	reset_cracks()
	reset_puncher()
	reset_shadow()

	await get_tree().create_timer(SEQUENCE_START_DELAY).timeout

	var shown_hits := 0
	var last_index := punch_history.size() - 1

	for index in range(punch_history.size()):
		var punch: Dictionary = punch_history[index]
		var is_newest := index == last_index
		var contact_time := (
			REPLAY_LIVE_CONTACT_TIME if is_newest else REPLAY_GHOST_CONTACT_TIME
		)

		show_punch(punch, is_newest, contact_time)

		# Let the swing run all the way to the wall before anything reacts to it.
		await get_tree().create_timer(contact_time).timeout

		hold_contact_frame()

		if punch["hit"]:
			play_hit_feedback(punch, shown_hits, is_newest)
			shown_hits += 1
		elif is_newest:
			apply_shake(MISS_SHAKE_STRENGTH)

		# Unscaled so the freeze-frame doesn't stretch with Engine.time_scale.
		await get_tree().create_timer(
			REPLAY_LIVE_HOLD if is_newest else REPLAY_GHOST_HOLD, true, false, true
		).timeout

		reset_puncher()
		reset_shadow()

		await get_tree().create_timer(
			REPLAY_LIVE_GAP if is_newest else REPLAY_GHOST_GAP
		).timeout

	clear_directions()
	set_player_color()

	if hits >= MAX_HITS:
		break_wall()
	elif switch_after_sequence:
		switch_after_sequence = false
		switch_player()
	else:
		begin_input_phase()


func switch_player() -> void:
	state = State.SWITCHING
	current_player = PLAYER_TWO if current_player == PLAYER_ONE else PLAYER_ONE
	hits = 0
	switch_after_sequence = false
	reset_round_state()
	timer_bar.set_state(1.0, get_attacker_color(), false)
	refresh_indicators()
	apply_environment_grade()

	await play_switch_animation()

	reset_puncher()
	reset_shadow()
	reset_cracks()
	set_player_color()
	begin_input_phase()


func reset_round_state() -> void:
	available_directions = ALL_DIRECTIONS.duplicate()
	punch_history.clear()
	clear_directions()


func clear_directions() -> void:
	punch_direction = Direction.NONE
	dodge_direction = Direction.NONE
#endregion


#region Input
func handle_player_inputs() -> void:
	if punch_direction == Direction.NONE:
		var direction := get_pressed_direction(get_attacker_actions())
		if direction != Direction.NONE:
			punch_direction = direction
			flash_puncher()

	if dodge_direction == Direction.NONE:
		var direction := get_pressed_direction(get_defender_actions())
		if direction != Direction.NONE:
			dodge_direction = direction
			flash_shadow()


## Player one attacks with the arrow keys, player two with WASD.
func get_attacker_actions() -> Dictionary:
	return ARROW_ACTIONS if current_player == PLAYER_ONE else WASD_ACTIONS


func get_defender_actions() -> Dictionary:
	return WASD_ACTIONS if current_player == PLAYER_ONE else ARROW_ACTIONS


func get_pressed_direction(actions: Dictionary) -> Direction:
	for action: StringName in actions.keys():
		if not Input.is_action_just_pressed(action):
			continue

		var direction: Direction = actions[action]

		# Directions that already landed a hit are spent and cannot be reused.
		if available_directions.has(int(direction)):
			return direction

	return Direction.NONE
#endregion


#region Presentation
func show_punch(punch: Dictionary, is_newest: bool, contact_time: float) -> void:
	var alpha := 1.0 if is_newest else REPLAY_GHOST_ALPHA
	set_player_color(alpha)
	update_puncher_visuals(punch["punch"], contact_time)
	update_shadow_visuals(punch["dodge"], contact_time)


## Freezes both fighters on the frame that connects. Without this the sheets --
## which loop -- would keep running through their recovery frames and back to
## neutral underneath the crack, the hit-stop and the shake.
func hold_contact_frame() -> void:
	freeze_on_contact(puncher, PUNCHER_IDLE_ANIMATION)
	freeze_on_contact(shadow, SHADOW_IDLE_ANIMATION)


func freeze_on_contact(sprite: AnimatedSprite2D, idle_animation: StringName) -> void:
	# Dodges that reuse the idle sheet have no strike to freeze; they just stand
	# somewhere else, and should keep breathing.
	if sprite.animation == idle_animation:
		return

	sprite.set_frame_and_progress(CONTACT_FRAME, 0.0)
	sprite.pause()


func play_hit_feedback(punch: Dictionary, crack_index: int, is_newest: bool) -> void:
	if crack_index < crack_sprites.size():
		show_crack(crack_index, punch["dodge"], is_newest)

	if not is_newest:
		apply_shake(MISS_SHAKE_STRENGTH)
		return

	# Only a landed punch chips the wall, and only as it happens live.
	wall_particles.restart()
	refresh_indicators()
	apply_shake(HIT_SHAKE_STRENGTH)
	play_flash()
	play_hit_stop()


func show_crack(crack_index: int, direction: Direction, is_newest: bool) -> void:
	var crack: Sprite2D = crack_sprites[crack_index]
	var base_scale: Vector2 = crack_base_scales[crack_index]
	crack.position = get_direction_value(direction, "crack_position", Vector2.ZERO)
	crack.scale = base_scale
	crack.show()

	if not is_newest:
		return

	crack.scale = base_scale * CRACK_POP_SCALE

	var pop_tween := create_tween()
	# Ignore time scale so the pop plays through the hit-stop instead of crawling.
	pop_tween.set_ignore_time_scale(true)
	pop_tween.tween_property(
		crack,
		^"scale",
		base_scale,
		CRACK_POP_DURATION,
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_hit_stop() -> void:
	Engine.time_scale = HIT_STOP_TIME_SCALE
	# Ignore time scale so the freeze lasts a fixed amount of real time.
	await get_tree().create_timer(HIT_STOP_DURATION, true, false, true).timeout
	Engine.time_scale = 1.0


func play_flash() -> void:
	flash_rect.modulate.a = FLASH_ALPHA

	var flash_tween := create_tween()
	flash_tween.tween_property(flash_rect, ^"modulate:a", 0.0, FLASH_FADE_DURATION)


func update_puncher_visuals(direction: Direction, contact_time: float = 0.0) -> void:
	var animation: StringName = get_direction_value(
		direction, "animation", PUNCHER_IDLE_ANIMATION
	)
	apply_puncher_pose(animation, contact_time)
	wall_particles.position = get_direction_value(
		direction, "particle_position", wall_particles.position
	)


func update_shadow_visuals(direction: Direction, contact_time: float = 0.0) -> void:
	var animation: StringName = get_direction_value(
		direction, "shadow_animation", SHADOW_IDLE_ANIMATION
	)

	# Side and low dodges reuse the idle sheet and only change where the
	# silhouette stands, so there is no leap to time against the punch.
	var dodge_contact_time := 0.0 if animation == SHADOW_IDLE_ANIMATION else contact_time

	apply_shadow_pose(
		get_direction_value(direction, "shadow_feet", SHADOW_DEFAULT_FEET),
		animation,
		dodge_contact_time,
	)


func get_direction_value(direction: Direction, key: String, fallback: Variant) -> Variant:
	if not DIRECTION_DATA.has(direction):
		return fallback

	return DIRECTION_DATA[direction][key]


func refresh_indicators() -> void:
	var spent: Array[int] = []

	for direction in ALL_DIRECTIONS:
		if not available_directions.has(direction):
			spent.append(direction)

	indicators.set_state(spent, get_attacker_color())


func get_wall_grade_color() -> Color:
	return WALL_BASE_COLOR.lerp(get_attacker_color(), WALL_GRADE_STRENGTH)


## The wall leans toward the attacker's colour, so whose turn it is stays
## readable from the whole frame and not just the two fighters.
func apply_environment_grade() -> void:
	var grade_tween := create_tween()
	grade_tween.tween_property(
		wall_sprite, ^"modulate", get_wall_grade_color(), GRADE_TWEEN_DURATION
	)


func refresh_lock_indicators() -> void:
	indicators.set_lock_state(
		punch_direction != Direction.NONE,
		dodge_direction != Direction.NONE,
		get_attacker_color(),
		get_defender_color(),
	)


func flash_puncher() -> void:
	puncher.modulate = Color(0.84, 0.31, 0.21, 1.0)
	await get_tree().create_timer(INPUT_FLASH_DURATION).timeout
	if state == State.INPUT:
		set_player_color()


func flash_shadow() -> void:
	shadow.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(INPUT_FLASH_DURATION).timeout
	if state == State.INPUT:
		set_player_color()


func get_attacker_color() -> Color:
	return player_one_color if current_player == PLAYER_ONE else player_two_color


func get_defender_color() -> Color:
	return player_two_color if current_player == PLAYER_ONE else player_one_color


func set_player_color(alpha: float = 1.0) -> void:
	var attacker_color := get_attacker_color()
	var defender_color := get_defender_color()
	attacker_color.a = alpha
	defender_color.a = alpha
	puncher.modulate = attacker_color
	shadow.modulate = defender_color


## Every puncher animation shares one scale and one anchor, so playing a pose is
## just a matter of (re)asserting them and starting the sheet.
func apply_puncher_pose(animation: StringName, contact_time: float = 0.0) -> void:
	puncher.scale = PUNCHER_NODE_SCALE
	puncher.position = PUNCHER_POSITION
	start_animation(puncher, animation, contact_time)


## Starts an animation, optionally stretching or compressing it so CONTACT_FRAME
## arrives exactly `contact_time` seconds from now. Passing 0.0 plays the sheet
## at its authored speed.
func start_animation(
	sprite: AnimatedSprite2D, animation: StringName, contact_time: float
) -> void:
	# play() only rewinds when the animation name changes, and pause() leaves the
	# playhead wherever the last freeze put it, so a direction thrown twice in a
	# row would otherwise resume mid-swing instead of winding up again.
	var must_rewind := contact_time > 0.0 or sprite.animation != animation

	sprite.speed_scale = get_contact_speed_scale(sprite, animation, contact_time)
	sprite.play(animation)

	if must_rewind:
		sprite.set_frame_and_progress(0, 0.0)


## How much to scale an animation's authored fps so its contact frame lands
## `contact_time` seconds after it starts.
func get_contact_speed_scale(
	sprite: AnimatedSprite2D, animation: StringName, contact_time: float
) -> float:
	if contact_time <= 0.0:
		return 1.0

	var fps: float = sprite.sprite_frames.get_animation_speed(animation)
	if fps <= 0.0:
		return 1.0

	return (CONTACT_FRAME / fps) / contact_time


func reset_puncher() -> void:
	apply_puncher_pose(PUNCHER_IDLE_ANIMATION)


## Converts the point the silhouette's feet stand on into the AnimatedSprite2D's
## node position, which is the centre of the (mostly empty) 128x128 frame.
func get_shadow_node_position(feet_position: Vector2) -> Vector2:
	return feet_position + SHADOW_ANCHOR_OFFSET


## Scale is constant across poses, and every sheet is anchored the same way, so
## the shadow never jumps or resizes when the animation changes.
func apply_shadow_pose(
	feet_position: Vector2, animation: StringName, contact_time: float = 0.0
) -> void:
	shadow.scale = SHADOW_DEFAULT_SCALE
	shadow.position = get_shadow_node_position(feet_position)
	start_animation(shadow, animation, contact_time)


func reset_shadow() -> void:
	apply_shadow_pose(SHADOW_DEFAULT_FEET, SHADOW_IDLE_ANIMATION)


func reset_cracks() -> void:
	for crack in crack_sprites:
		crack.hide()
#endregion


#region Camera
func apply_shake(strength: float = -1.0) -> void:
	shake_strength = max_shake_strength if strength < 0.0 else strength


func update_camera_shake(delta: float) -> void:
	var interpolation_weight := minf(shake_decay_rate * delta, 1.0)
	shake_strength = lerpf(shake_strength, 0.0, interpolation_weight)
	camera.offset = get_random_camera_offset()


func get_random_camera_offset() -> Vector2:
	return Vector2(
		random.randf_range(-shake_strength, shake_strength),
		random.randf_range(-shake_strength, shake_strength),
	)
#endregion


#region Intro / outro
func animate_bars_in() -> void:
	var start_y_offset := 600.0

	camera.zoom = Vector2(INTRO_ZOOM, INTRO_ZOOM)

	top_bar.position = TOP_BAR_TARGET_POSITION + Vector2(0, -start_y_offset)
	bottom_bar.position = BOTTOM_BAR_TARGET_POSITION + Vector2(0, start_y_offset)

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

	await bottom_tween.finished
	await get_tree().create_timer(0.3).timeout

	begin_input_phase()


func play_switch_animation() -> void:
	# current_player has already flipped, so the attacker colour is the incoming one.
	var incoming_color := get_attacker_color()
	var outgoing_color := get_defender_color()

	switch_sprite.show()
	switch_sprite.scale = Vector2(0.1, 0.1)
	switch_sprite.modulate = outgoing_color

	var scale_tween := create_tween()
	scale_tween.tween_property(
		switch_sprite,
		^"scale",
		Vector2(5.674, 5.674),
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
		flash_tween.tween_property(switch_sprite, ^"modulate", outgoing_color, 0.18)
		flash_tween.tween_property(switch_sprite, ^"modulate", incoming_color, 0.18)

	await scale_tween.finished
	flash_tween.kill()
	switch_sprite.modulate = incoming_color
	switch_sprite.hide()


func break_wall() -> void:
	state = State.WALL_BREAK
	timer_bar.hide()
	indicators.hide()

	await get_tree().create_timer(WALL_BREAK_DELAY).timeout

	wall_particles.position = Vector2(613, 233)
	wall_particles.restart()
	$Crack4.modulate = Color(1, 1, 1, 0.6)
	apply_shake(HIT_SHAKE_STRENGTH)

	await get_tree().create_timer(WALL_BREAK_DELAY).timeout

	apply_shake(HIT_SHAKE_STRENGTH)
	play_flash()
	$Wall.hide()
	$darkline.hide()
	reset_puncher()
	reset_cracks()
	$Crack4.hide()
	shadow.hide()
	$Shmile.show()
#endregion
