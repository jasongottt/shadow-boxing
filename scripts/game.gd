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
## Against the computer the human has the keyboard to themselves.
const ALL_ACTIONS := {
	&"up": Direction.UP,
	&"down": Direction.DOWN,
	&"left": Direction.LEFT,
	&"right": Direction.RIGHT,
	&"w": Direction.UP,
	&"s": Direction.DOWN,
	&"a": Direction.LEFT,
	&"d": Direction.RIGHT,
}

const TURN_TIME := 3.0
const TIMEOUT_PAUSE := 0.5

## The clock ticks through the same last second in which the timer bar reddens
## (TurnTimerBar.DANGER_THRESHOLD of TURN_TIME), a little higher each tick.
const COUNTDOWN_TIME := 1.0
const COUNTDOWN_TICK_INTERVAL := 0.25
const COUNTDOWN_PITCH_STEP := 0.08

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
const REMATCH_BREATHE_LOW := 0.55
const REMATCH_BREATHE_TIME := 0.9
const SWITCH_FLASH_COUNT := 6
## The stamp is switch_hd.png, the 172 px original re-inked at four times the
## size (tools/upscale_line_art.py) so it stays smooth at full swell. These are
## the original 0.1 and 5.674 divided by that factor.
const SWITCH_START_SCALE := 0.025
const SWITCH_PEAK_SCALE := 1.4185
const INTRO_ZOOM_DURATION := 1.12
const INTRO_ZOOM := 2.2

## "You Win" is painted white; pulled most of the way to the winner's colour it
## still reads against the bare backdrop the broken wall leaves behind.
const RESULT_WHITE_MIX := 0.3
const BANNER_BONE_MIX := 0.15
const BANNER_POP_DURATION := 0.35
const LOSE_CARD_FADE_DURATION := 0.6

## Whoever breaks the wall is the one punching, so the winner is always the
## boxer in the foreground: the shmile becomes their face. The offset is the
## head's centre in the idle frame, in frame pixels from the sprite's centre,
## so it follows the boxer if FighterPresentation ever moves or rescales them.
const SHMILE_HEAD_OFFSET := Vector2(86.0, 63.0)
const SHMILE_SCALE := 0.24
const SHMILE_POP_DELAY := 0.2
const SHMILE_POP_DURATION := 0.35

## "FIGHT!" is stamped over the wall with the opening bell, tilted like the
## hand-lettered hit words, then swells and fades. Short enough that it's gone
## before anyone has had time to want to look at the fighters under it.
const CALLOUT_TILT := -6.0
const CALLOUT_POP_DURATION := 0.18
const CALLOUT_SETTLE_DURATION := 0.1
const CALLOUT_HOLD := 0.55
const CALLOUT_EXIT_DURATION := 0.25
const CALLOUT_EXIT_SCALE := 1.25
const CALLOUT_SUB_BONE_MIX := 0.2
const BONE_COLOR := Color(0.92, 0.88, 0.86)

## Mix levels, in dB. The live swing is the loudest thing in a replay and every
## ghost of an earlier hit sits well underneath it, the same way they're drawn.
const WHOOSH_VOLUME_DB := -6.0
const GHOST_WHOOSH_VOLUME_DB := -14.0
const GHOST_WHOOSH_PITCH := 1.15
const HIT_VOLUME_DB := 0.0
const GHOST_HIT_VOLUME_DB := -10.0
const GHOST_HIT_PITCH := 1.1
const CRACK_VOLUME_DB := -3.0
const GHOST_CRACK_VOLUME_DB := -16.0
## Each crack in the same streak lands a little lower, so the third sounds like
## the one that will bring the wall down.
const HIT_PITCH_DROP := 0.06
const MISS_VOLUME_DB := -4.0
const LOCK_VOLUME_DB := -9.0
const ATTACKER_LOCK_PITCH := 1.2
const DEFENDER_LOCK_PITCH := 0.85
const TICK_VOLUME_DB := -10.0
const BUZZER_VOLUME_DB := -12.0
## The bell only opens and closes a fight. It used to ring on every switch too,
## and switches come often enough that it wore thin fast.
const BELL_VOLUME_DB := -8.0
const FINAL_BELL_COUNT := 3
const FINAL_BELL_INTERVAL := 0.18
const RUMBLE_VOLUME_DB := -2.0
const CRASH_VOLUME_DB := 0.0


@export var player_one_color := Color(0.825, 0.332, 0.387, 1.0)
@export var player_two_color := Color(0.319, 0.533, 0.769, 1.0)
@export var max_shake_strength: float = 30.0
@export var shake_decay_rate: float = 5.0

@onready var camera: Camera2D = $camera
@onready var wall_sprite: AnimatedSprite2D = $Wall
@onready var wall_hole: Variant = $hole
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
@onready var rematch_prompt: Label = $HUD/rematch
@onready var winner_banner: Label = $HUD/winner
@onready var callout: Control = $HUD/callout
@onready var callout_sub: Label = $HUD/callout/sub
@onready var score_tally: Variant = $HUD/score
@onready var pause_menu: Variant = $HUD/pause
@onready var flash_rect: ColorRect = $HUD/flash/rect
@onready var fighters: Variant = $Presentation/Fighters
@onready var impacts: Variant = $Presentation/Impacts
@onready var camera_effects: Variant = $Presentation/CameraEffects
@onready var you_win: Sprite2D = $Youwin
@onready var you_win_shadow: Sprite2D = $Youwinshadow
@onready var you_lose: Sprite2D = $Youlose
@onready var shmile: Sprite2D = $Shmile

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
var last_countdown_tick := -1
var awaiting_rematch := false
var leaving := false
## Only set when the fight is against the computer, which always plays P2.
var cpu: CpuOpponent


func _ready() -> void:
	player_one_color = PlayerSettings.player_one_color
	player_two_color = PlayerSettings.player_two_color
	current_player = Session.opening_player
	if Session.versus_cpu:
		cpu = CpuOpponent.new()
	setup_presentation_effects()
	pause_menu.restart_requested.connect(restart_fight)
	pause_menu.menu_requested.connect(leave_to_menu)

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
## Every beat of the fight waits on this rather than on a bare tree timer.
## Those run straight through a paused tree, so a replay would carry on playing
## out under the pause menu; and they outlive the scene, so restarting from the
## pause menu would wake this coroutine up on a freed Game. A tween bound to
## this node pauses with it and dies with it.
func wait(seconds: float, ignore_time_scale: bool = false) -> Signal:
	var timer := create_tween()
	timer.set_ignore_time_scale(ignore_time_scale)
	timer.tween_interval(seconds)
	return timer.finished


func begin_input_phase() -> void:
	clear_directions()
	turn_time_left = TURN_TIME
	idle_time = 0.0
	last_countdown_tick = -1
	if cpu != null:
		cpu.begin_turn()
	refresh_indicators()
	state = State.INPUT


func process_input_phase(delta: float) -> void:
	turn_time_left -= delta
	idle_time += delta
	timer_bar.set_state(turn_time_left / TURN_TIME, get_attacker_color(), true)
	apply_idle_bob()

	if turn_time_left <= 0.0:
		handle_turn_timeout()
		return

	play_countdown_tick()
	handle_player_inputs()

	if punch_direction != Direction.NONE and dodge_direction != Direction.NONE:
		resolve_exchange()


func play_countdown_tick() -> void:
	if turn_time_left > COUNTDOWN_TIME:
		return

	var tick := ceili(turn_time_left / COUNTDOWN_TICK_INTERVAL)
	if tick == last_countdown_tick:
		return

	last_countdown_tick = tick
	var ticks_in := ceili(COUNTDOWN_TIME / COUNTDOWN_TICK_INTERVAL) - tick
	Sounds.play(&"tick", TICK_VOLUME_DB, 1.0 + COUNTDOWN_PITCH_STEP * ticks_in)


## Keeps the fighters breathing while the turn timer drains.
func apply_idle_bob() -> void:
	fighters.apply_idle_bob(
		idle_time, IDLE_BOB_SPEED, IDLE_BOB_AMOUNT, IDLE_SHADOW_BOB_RATIO
	)


func handle_turn_timeout() -> void:
	timer_bar.set_state(0.0, get_attacker_color(), true)
	Sounds.play(&"buzzer", BUZZER_VOLUME_DB)

	# A shadow that never moves takes the punch where it stands. Before this, a
	# defender could simply never press anything, run out every clock, and
	# never be beaten.
	if punch_direction != Direction.NONE:
		resolve_exchange()
		return

	# The attacker hesitating costs the turn outright.
	state = State.SWITCHING
	apply_shake(MISS_SHAKE_STRENGTH)
	clear_directions()

	await wait(TIMEOUT_PAUSE)

	switch_player()


## Matching directions land. So does any punch at a shadow that never moved.
static func lands_hit(punch: Direction, dodge: Direction) -> bool:
	return punch != Direction.NONE and (dodge == punch or dodge == Direction.NONE)


func resolve_exchange() -> void:
	var punch := {
		"punch": punch_direction,
		"dodge": dodge_direction,
		"hit": lands_hit(punch_direction, dodge_direction),
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
	play_punch_sequence()


func play_punch_sequence() -> void:
	state = State.REPLAY
	timer_bar.set_state(0.0, get_attacker_color(), false)

	reset_cracks()
	reset_puncher()
	reset_shadow()

	await wait(SEQUENCE_START_DELAY)

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
		await wait(contact_time)

		hold_contact_frame()

		if punch["hit"]:
			play_hit_feedback(punch, shown_hits, is_newest)
			shown_hits += 1
		elif is_newest:
			apply_shake(MISS_SHAKE_STRENGTH, punch["punch"])
			Sounds.play(&"miss", MISS_VOLUME_DB, 1.0, 0.05)

		# Unscaled so the freeze-frame doesn't stretch with Engine.time_scale.
		await wait(REPLAY_LIVE_HOLD if is_newest else REPLAY_GHOST_HOLD, true)

		var recovery_time: float = (
			REPLAY_LIVE_RECOVERY if is_newest else REPLAY_GHOST_RECOVERY
		)
		fighters.play_recovery(recovery_time)
		await wait(recovery_time)

		reset_puncher()
		reset_shadow()

		await wait(REPLAY_LIVE_GAP if is_newest else REPLAY_GHOST_GAP)

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
		var direction := read_direction(current_player)
		if direction != Direction.NONE:
			punch_direction = direction
			flash_puncher()
			Sounds.play(&"lock", LOCK_VOLUME_DB, ATTACKER_LOCK_PITCH)

	if dodge_direction == Direction.NONE:
		var direction := read_direction(get_defender())
		if direction != Direction.NONE:
			dodge_direction = direction
			flash_shadow()
			Sounds.play(&"lock", LOCK_VOLUME_DB, DEFENDER_LOCK_PITCH)


func read_direction(player: int) -> Direction:
	if is_cpu(player):
		return cpu.choose(idle_time, available_directions) as Direction

	return get_pressed_direction(get_player_actions(player))


## Player one plays on the arrow keys and player two on WASD, whichever of
## them is attacking.
func get_player_actions(player: int) -> Dictionary:
	if Session.versus_cpu:
		return ALL_ACTIONS

	return ARROW_ACTIONS if player == PLAYER_ONE else WASD_ACTIONS


func get_defender() -> int:
	return PLAYER_TWO if current_player == PLAYER_ONE else PLAYER_ONE


func is_cpu(player: int) -> bool:
	return cpu != null and player == PLAYER_TWO


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

	if is_newest:
		Sounds.play(&"whoosh", WHOOSH_VOLUME_DB, 1.0, 0.05)
	else:
		Sounds.play(&"whoosh", GHOST_WHOOSH_VOLUME_DB, GHOST_WHOOSH_PITCH, 0.05)


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
		Sounds.play(&"hit", GHOST_HIT_VOLUME_DB, GHOST_HIT_PITCH, 0.04)
		Sounds.play(&"crack", GHOST_CRACK_VOLUME_DB, 1.0, 0.1)
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
	Sounds.play(&"hit", HIT_VOLUME_DB, 1.0 - HIT_PITCH_DROP * crack_index, 0.03)
	Sounds.play(&"crack", CRACK_VOLUME_DB, 1.0, 0.1)
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
	await wait(HIT_STOP_DURATION, true)
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
	indicators.set_captions(
		get_player_caption(current_player),
		get_player_caption(get_defender()),
		get_attacker_color(),
		get_defender_color(),
	)


func get_wall_grade_color() -> Color:
	return WALL_BASE_COLOR.lerp(get_attacker_color(), WALL_GRADE_STRENGTH)


## The wall leans toward the attacker's colour, so whose turn it is stays
## readable from the whole frame and not just the two fighters.
func apply_environment_grade() -> void:
	var grade_tween := create_tween()
	grade_tween.tween_property(
		wall_sprite, ^"modulate", get_wall_grade_color(), GRADE_TWEEN_DURATION
	)


func flash_puncher() -> void:
	fighters.flash_puncher(Color(0.84, 0.31, 0.21, 1.0))
	await wait(INPUT_FLASH_DURATION)
	if state == State.INPUT:
		set_player_color()


func flash_shadow() -> void:
	fighters.flash_shadow(0.42, INPUT_FLASH_DURATION * 2.0)


func get_attacker_color() -> Color:
	return player_one_color if current_player == PLAYER_ONE else player_two_color


func get_defender_color() -> Color:
	return player_two_color if current_player == PLAYER_ONE else player_one_color


func get_player_color(player: int) -> Color:
	return player_one_color if player == PLAYER_ONE else player_two_color


func get_player_name(player: int) -> String:
	return "PLAYER ONE" if player == PLAYER_ONE else "PLAYER TWO"


func get_short_name(player: int) -> String:
	if Session.versus_cpu:
		return "YOU" if player == PLAYER_ONE else "CPU"

	return "P1" if player == PLAYER_ONE else "P2"


## Names the player and, in a two-player fight, the keys they're on.
func get_player_caption(player: int) -> String:
	if Session.versus_cpu:
		return get_short_name(player)

	var keys := "ARROWS" if player == PLAYER_ONE else "WASD"
	return "%s · %s" % [get_short_name(player), keys]


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
	await wait(0.3)

	Sounds.play(&"bell", BELL_VOLUME_DB)
	play_fight_callout()
	begin_input_phase()


## The opener changes from fight to fight (see FightSession), so the callout
## says who it is this time.
func play_fight_callout() -> void:
	var opener := get_short_name(current_player)
	var verb := "THROW" if opener == "YOU" else "THROWS"
	callout_sub.text = "%s %s FIRST" % [opener, verb]
	# Outlined in black, so it needs the same lift as the HUD.
	callout_sub.add_theme_color_override(
		&"font_color",
		PlayerColorSettings.readable_on_black(get_attacker_color()).lerp(
			BONE_COLOR, CALLOUT_SUB_BONE_MIX
		),
	)

	callout.scale = Vector2.ONE * 0.2
	callout.rotation = deg_to_rad(CALLOUT_TILT)
	callout.modulate.a = 1.0
	callout.show()

	var callout_tween := create_tween()
	callout_tween.tween_property(
		callout, ^"scale", Vector2.ONE * 1.12, CALLOUT_POP_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	callout_tween.tween_property(callout, ^"scale", Vector2.ONE, CALLOUT_SETTLE_DURATION)
	callout_tween.tween_interval(CALLOUT_HOLD)
	callout_tween.tween_property(
		callout, ^"scale", Vector2.ONE * CALLOUT_EXIT_SCALE, CALLOUT_EXIT_DURATION
	).set_ease(Tween.EASE_IN)
	callout_tween.parallel().tween_property(
		callout, ^"modulate:a", 0.0, CALLOUT_EXIT_DURATION
	)
	callout_tween.tween_callback(callout.hide)


func play_switch_animation() -> void:
	# current_player has already flipped, so the attacker colour is the incoming
	# one. The stamp's fill is all the colour it has; a near-black one turned
	# the word into a smudge.
	var incoming_color := PlayerColorSettings.readable_on_black(get_attacker_color())
	var outgoing_color := PlayerColorSettings.readable_on_black(get_defender_color())

	switch_sprite.show()
	switch_sprite.scale = Vector2.ONE * SWITCH_START_SCALE
	switch_sprite.modulate = outgoing_color

	var scale_tween := create_tween()
	scale_tween.tween_property(
		switch_sprite,
		^"scale",
		Vector2.ONE * SWITCH_PEAK_SCALE,
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
	var winner := current_player
	Session.record_win(winner)
	timer_bar.hide()
	indicators.hide()

	await wait(WALL_BREAK_DELAY)

	impacts.play_wall_break_debris(Vector2(613, 233))
	$Crack4.modulate = Color(1, 1, 1, 0.6)
	apply_shake(HIT_SHAKE_STRENGTH)
	Sounds.play(&"rumble", RUMBLE_VOLUME_DB)

	await wait(WALL_BREAK_DELAY)

	apply_shake(HIT_SHAKE_STRENGTH)
	play_flash()
	Sounds.play(&"crash", CRASH_VOLUME_DB)
	Sounds.play_repeated(&"bell", FINAL_BELL_COUNT, FINAL_BELL_INTERVAL, BELL_VOLUME_DB)
	wall_hole.open(wall_sprite.modulate)
	reset_puncher()
	reset_cracks()
	$Crack4.hide()
	fighters.hide_shadow()
	show_result(winner)

	await wait(REMATCH_PROMPT_DELAY)

	offer_rematch()


## Breaking through reveals "You Win" painted on the far side of the wall. In a
## hot-seat fight that "you" could be either player, so it takes the winner's
## colour and the top bar names them. Against the computer there is only one
## "you", and when the computer is the one who wins, the You Lose card covers
## the lot.
func show_result(winner: int) -> void:
	# Both are painted on black: the void behind the wall and the top bar.
	var winner_color := PlayerColorSettings.readable_on_black(get_player_color(winner))

	if is_cpu(winner):
		var card_tween := create_tween()
		card_tween.tween_property(you_lose, ^"modulate:a", 1.0, LOSE_CARD_FADE_DURATION)
	else:
		you_win.modulate = winner_color.lerp(Color.WHITE, RESULT_WHITE_MIX)
		you_win.show()
		you_win_shadow.show()
		put_shmile_on_winner()

	if Session.versus_cpu:
		return

	winner_banner.text = "%s WINS" % get_player_name(winner)
	winner_banner.add_theme_color_override(
		&"font_color", winner_color.lerp(BONE_COLOR, BANNER_BONE_MIX)
	)
	winner_banner.pivot_offset = winner_banner.size / 2.0
	winner_banner.scale = Vector2.ONE * 0.3
	winner_banner.show()

	var banner_tween := create_tween()
	banner_tween.tween_property(
		winner_banner, ^"scale", Vector2.ONE, BANNER_POP_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Lands just after the flash, so it reads as the winner grinning rather than as
## part of the explosion.
func put_shmile_on_winner() -> void:
	shmile.position = puncher.position + SHMILE_HEAD_OFFSET * puncher.scale
	shmile.scale = Vector2.ZERO
	shmile.show()

	var shmile_tween := create_tween()
	shmile_tween.tween_property(
		shmile, ^"scale", Vector2.ONE * SHMILE_SCALE, SHMILE_POP_DURATION
	).set_delay(SHMILE_POP_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Until now the wall breaking was the last thing that ever happened: the fight
## simply stopped, with no way back to a new one short of relaunching.
func offer_rematch() -> void:
	score_tally.set_state(
		get_short_name(PLAYER_ONE),
		Session.get_wins(PLAYER_ONE),
		player_one_color,
		get_short_name(PLAYER_TWO),
		Session.get_wins(PLAYER_TWO),
		player_two_color,
	)
	score_tally.modulate.a = 0.0
	score_tally.show()
	rematch_prompt.modulate.a = 0.0
	rematch_prompt.show()
	awaiting_rematch = true

	var prompt_tween := create_tween().set_parallel(true)
	prompt_tween.tween_property(
		score_tally, ^"modulate:a", 1.0, REMATCH_FADE_DURATION
	)
	prompt_tween.tween_property(
		rematch_prompt, ^"modulate:a", 1.0, REMATCH_FADE_DURATION
	)
	await prompt_tween.finished

	# Once it's up, the prompt breathes slowly: it's the one thing on screen
	# still waiting on the players.
	var breathe := create_tween().set_loops()
	breathe.tween_property(
		rematch_prompt, ^"modulate:a", REMATCH_BREATHE_LOW, REMATCH_BREATHE_TIME
	).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(
		rematch_prompt, ^"modulate:a", 1.0, REMATCH_BREATHE_TIME
	).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
	# The fight keeps drawing under the curtain as it falls, but it's over: an
	# Esc now would pause a tree the next scene then inherits.
	if leaving:
		return

	if awaiting_rematch:
		if event.is_action_pressed(&"ui_cancel"):
			leave_to_menu()
		elif event.is_action_pressed(&"ui_accept"):
			restart_fight()
		return

	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		# Paused in the opening second, "FIGHT!" froze right behind "PAUSED".
		# It's only a flourish; its tween runs out hidden after the resume.
		callout.hide()
		pause_menu.open()


## The loser of the last fight opens this one (see FightSession).
func restart_fight() -> void:
	end_fight()
	Sounds.play(&"ui_press")
	Curtain.reload_scene()


func leave_to_menu() -> void:
	end_fight()
	Sounds.play(&"ui_press", 0.0, 0.8)

	var error: Error = Curtain.change_scene(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("Game could not open %s (error %d)" % [MAIN_MENU_SCENE_PATH, error])


## The hit-stop parks Engine.time_scale globally, so a fight that ended while one
## was still unwinding would hand the next scene a world running at 5% speed.
## The pause menu can end a fight too, and the tree is still paused when it does.
func end_fight() -> void:
	leaving = true
	awaiting_rematch = false
	Engine.time_scale = 1.0
	get_tree().paused = false
#endregion
