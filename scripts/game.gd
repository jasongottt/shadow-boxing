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

## Everything that differs between the four punch directions, in one table.
## Both sheets name their poses identically, so one animation name drives the
## punch and the dodge.
##
## Cracks are laid out as a compass around the silhouette rather than on top of
## it: the shadow is solid black, so anything drawn behind it (or on it) simply
## disappears, and the damage has to stay readable for the rest of the round.
## Each one sits in the free wall on the side its direction points to, clear of
## both the silhouette's idle outline and the boxer in the right foreground.
const DIRECTION_DATA := {
	Direction.UP: {
		"animation": &"up",
		"contact_position": Vector2(573, 70),
		"crack_position": Vector2(520, 155),
	},
	Direction.DOWN: {
		"animation": &"down",
		"contact_position": Vector2(575, 569),
		"crack_position": Vector2(190, 555),
	},
	Direction.LEFT: {
		"animation": &"left",
		"contact_position": Vector2(414, 356),
		"crack_position": Vector2(165, 375),
	},
	Direction.RIGHT: {
		"animation": &"right",
		"contact_position": Vector2(651, 361),
		"crack_position": Vector2(770, 220),
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

## FighterPresentation owns the shared five-frame animation shape and contact
## frame; this controller only decides how long each replay phase should take.
const SEQUENCE_START_DELAY := 0.3

## Ghosts are still shorter than the newest live swing, but each repeat gets a
## readable wind-up, contact beat, and recovery instead of flashing by as a blur.
const REPLAY_GHOST_CONTACT_TIME := 0.24
const REPLAY_GHOST_HOLD := 0.075
const REPLAY_GHOST_RECOVERY := 0.14
const REPLAY_GHOST_GAP := 0.08
const REPLAY_GHOST_ALPHA := 0.5
const REPLAY_GHOST_SHAKE_STRENGTH := 12.0
const REPLAY_GHOST_CAMERA_PUSH := 6.0
const REPLAY_GHOST_BURST_INTENSITY := 0.78

## The live swing gets a readable anticipation, a sharp contact hold, then plays
## the authored recovery frames instead of snapping straight back to idle.
const REPLAY_LIVE_CONTACT_TIME := 0.30
const REPLAY_LIVE_HOLD := 0.10
const REPLAY_LIVE_RECOVERY := 0.16
const REPLAY_LIVE_GAP := 0.12

const SHADOW_HIT_FLASH_DURATION := 0.16
const CAMERA_PUSH_STRENGTH := 14.0

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

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const WALL_BREAK_DELAY := 1.0

## Long enough after the wall goes that the prompt reads as an offer rather than
## as an interruption of the win beat.
const REMATCH_PROMPT_DELAY := 1.2
const REMATCH_FADE_DURATION := 0.4
const SWITCH_FLASH_COUNT := 6
const INTRO_ZOOM_DURATION := 1.12
const INTRO_ZOOM := 2.2


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
# Variant avoids a resource cycle while game.tscn is loading the scripts that
# provide these typed controller nodes. Their scene paths are validated in tests.
@onready var indicators: Variant = $HUD/indicators
@onready var timer_bar: Variant = $HUD/timerbar
@onready var hit_tally: Variant = $HUD/hittally
@onready var rematch_prompt: Label = $HUD/rematch
@onready var flash_rect: ColorRect = $HUD/flash/rect
@onready var fighters: Variant = $Presentation/Fighters
@onready var impacts: Variant = $Presentation/Impacts
@onready var camera_effects: Variant = $Presentation/CameraEffects

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
var awaiting_rematch := false


func _ready() -> void:
	player_one_color = PlayerSettings.player_one_color
	player_two_color = PlayerSettings.player_two_color
	setup_presentation_effects()

	reset_round_state()
	fighters.reset()
	set_player_color()
	refresh_indicators()
	apply_environment_grade()
	timer_bar.set_state(1.0, get_attacker_color(), false)
	animate_bars_in()


func _process(delta: float) -> void:
	if state == State.INPUT:
		process_input_phase(delta)


## Persistent controller and HUD nodes live in game.tscn; Game only connects
## them to the concrete scene nodes they operate on.
func setup_presentation_effects() -> void:
	fighters.setup(puncher, shadow)
	impacts.setup(wall_particles, crack_sprites)
	camera_effects.setup(camera, max_shake_strength, shake_decay_rate)


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
	fighters.apply_idle_bob(
		idle_time, IDLE_BOB_SPEED, IDLE_BOB_AMOUNT, IDLE_SHADOW_BOB_RATIO
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
			apply_shake(MISS_SHAKE_STRENGTH, punch["punch"])

		# Unscaled so the freeze-frame doesn't stretch with Engine.time_scale.
		await get_tree().create_timer(
			REPLAY_LIVE_HOLD if is_newest else REPLAY_GHOST_HOLD, true, false, true
		).timeout

		var recovery_time: float = (
			REPLAY_LIVE_RECOVERY if is_newest else REPLAY_GHOST_RECOVERY
		)
		fighters.play_recovery(recovery_time)
		await get_tree().create_timer(recovery_time).timeout

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


func hold_contact_frame() -> void:
	fighters.hold_contact()


func play_hit_feedback(punch: Dictionary, crack_index: int, is_newest: bool) -> void:
	var direction: Direction = punch["punch"]
	var direction_vector: Vector2 = get_direction_vector(direction)
	var contact_position: Vector2 = get_contact_position(direction)
	var crack_position: Vector2 = get_direction_value(
		direction, "crack_position", Vector2.ZERO
	)
	impacts.show_crack(crack_index, crack_position, is_newest)

	if not is_newest:
		impacts.play_hit_word(
			int(direction), contact_position, direction_vector, get_attacker_color(), 0.72
		)
		impacts.play_burst(
			contact_position,
			direction_vector,
			get_attacker_color().lerp(Color.WHITE, 0.35),
			REPLAY_GHOST_BURST_INTENSITY,
		)
		fighters.flash_shadow(0.48, 0.12)
		apply_shake(REPLAY_GHOST_SHAKE_STRENGTH, direction)
		apply_camera_push(direction, REPLAY_GHOST_CAMERA_PUSH)
		return

	# The newest strike gets debris, full-screen flash, hit-stop, and the largest
	# comic-book word in addition to the local feedback shared with its ghosts.
	impacts.play_hit_word(
		int(direction), contact_position, direction_vector, get_attacker_color(), 1.0
	)
	impacts.play_directional_debris(contact_position, direction_vector)
	impacts.play_burst(
		contact_position,
		direction_vector,
		get_attacker_color().lerp(Color.WHITE, 0.5),
		1.2,
	)
	fighters.flash_shadow(0.95, SHADOW_HIT_FLASH_DURATION)
	refresh_indicators()
	apply_shake(HIT_SHAKE_STRENGTH, direction)
	apply_camera_push(direction)
	play_flash()
	play_hit_stop()


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
	fighters.play_punch(get_direction_animation(direction), contact_time)


func update_shadow_visuals(direction: Direction, contact_time: float = 0.0) -> void:
	fighters.play_shadow(get_direction_animation(direction), contact_time)


func get_direction_animation(direction: Direction) -> StringName:
	return get_direction_value(direction, "animation", &"default")


func get_direction_value(direction: Direction, key: String, fallback: Variant) -> Variant:
	if not DIRECTION_DATA.has(direction):
		return fallback

	return DIRECTION_DATA[direction][key]


func get_contact_position(direction: Direction) -> Vector2:
	return get_direction_value(direction, "contact_position", Vector2.ZERO)


func get_direction_vector(direction: Direction) -> Vector2:
	match direction:
		Direction.UP:
			return Vector2.UP
		Direction.DOWN:
			return Vector2.DOWN
		Direction.LEFT:
			return Vector2.LEFT
		Direction.RIGHT:
			return Vector2.RIGHT
		_:
			return Vector2.ZERO


func refresh_indicators() -> void:
	var spent: Array[int] = []

	for direction in ALL_DIRECTIONS:
		if not available_directions.has(direction):
			spent.append(direction)

	indicators.set_state(spent, get_attacker_color())
	# Both readouts describe the same round, and every moment that changes one
	# changes the other, so they refresh together.
	hit_tally.set_state(hits, MAX_HITS, get_attacker_color())


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
	fighters.flash_puncher(Color(0.84, 0.31, 0.21, 1.0))
	await get_tree().create_timer(INPUT_FLASH_DURATION).timeout
	if state == State.INPUT:
		set_player_color()


func flash_shadow() -> void:
	fighters.flash_shadow(0.42, INPUT_FLASH_DURATION * 2.0)


func get_attacker_color() -> Color:
	return player_one_color if current_player == PLAYER_ONE else player_two_color


func get_defender_color() -> Color:
	return player_two_color if current_player == PLAYER_ONE else player_one_color


func set_player_color(alpha: float = 1.0) -> void:
	fighters.set_colors(get_attacker_color(), get_defender_color(), alpha)


func reset_puncher() -> void:
	fighters.reset_puncher()


func reset_shadow() -> void:
	fighters.reset_shadow()


func reset_cracks() -> void:
	impacts.reset_cracks()
#endregion


#region Camera
func apply_shake(strength: float = -1.0, direction: Direction = Direction.NONE) -> void:
	camera_effects.shake(strength, get_direction_vector(direction))


func apply_camera_push(
	direction: Direction, strength: float = CAMERA_PUSH_STRENGTH
) -> void:
	camera_effects.push(get_direction_vector(direction), strength)
#endregion


#region Intro / outro
func animate_bars_in() -> void:
	camera.zoom = Vector2(INTRO_ZOOM, INTRO_ZOOM)

	var zoom_tween := create_tween()
	zoom_tween.tween_property(
		camera,
		^"zoom",
		Vector2.ONE,
		INTRO_ZOOM_DURATION,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await zoom_tween.finished
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

	impacts.play_wall_break_debris(Vector2(613, 233))
	$Crack4.modulate = Color(1, 1, 1, 0.6)
	apply_shake(HIT_SHAKE_STRENGTH)

	await get_tree().create_timer(WALL_BREAK_DELAY).timeout

	apply_shake(HIT_SHAKE_STRENGTH)
	play_flash()
	$Wall.hide()
	reset_puncher()
	reset_cracks()
	$Crack4.hide()
	fighters.hide_shadow()
	$Shmile.show()

	await get_tree().create_timer(REMATCH_PROMPT_DELAY).timeout

	offer_rematch()


## Until now the wall breaking was the last thing that ever happened: the fight
## simply stopped, with no way back to a new one short of relaunching.
func offer_rematch() -> void:
	rematch_prompt.modulate.a = 0.0
	rematch_prompt.show()
	awaiting_rematch = true

	var prompt_tween := create_tween()
	prompt_tween.tween_property(
		rematch_prompt, ^"modulate:a", 1.0, REMATCH_FADE_DURATION
	)


func _unhandled_input(event: InputEvent) -> void:
	if not awaiting_rematch:
		return

	if event.is_action_pressed(&"ui_cancel"):
		leave_to_menu()
	elif event.is_action_pressed(&"ui_accept"):
		restart_fight()


func restart_fight() -> void:
	end_fight()
	get_tree().reload_current_scene()


func leave_to_menu() -> void:
	end_fight()

	var error: Error = get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("Game could not open %s (error %d)" % [MAIN_MENU_SCENE_PATH, error])


## The hit-stop parks Engine.time_scale globally, so a fight that ended while one
## was still unwinding would hand the next scene a world running at 5% speed.
func end_fight() -> void:
	awaiting_rematch = false
	Engine.time_scale = 1.0
#endregion
