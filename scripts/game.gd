extends Node2D

const DIR_NONE := -1
const DIR_UP := 1
const DIR_DOWN := 2
const DIR_LEFT := 3
const DIR_RIGHT := 4

var arrowNumb := DIR_NONE
var wasdNumb := DIR_NONE

var hits := 0
var tries := 3

var wall_breaking := false
var lose_started := false

@export var RANDOM_SHAKE_STRENGTH: float = 30.0
@export var SHAKE_DECAY_RATE: float = 5.0

@onready var camera = $camera
@onready var rand := RandomNumberGenerator.new()

var shake_strength: float = 0.0


func _ready() -> void:
	rand.randomize()


func _process(delta: float) -> void:
	update_camera_shake(delta)
	update_lives(delta)

	if tries <= 0 and hits < 3:
		play_lose_animation(delta)
		return

	if hits == 3 and !wall_breaking:
		breakwall()
		return

	if $waiter.is_stopped():
		handle_player_inputs()

		if arrowNumb == DIR_NONE and hits < 3:
			reset_puncher()

		if wasdNumb == DIR_NONE and hits < 3:
			reset_shadow()

		if arrowNumb != DIR_NONE and wasdNumb != DIR_NONE:
			start_attack()
	else:
		update_attack_visuals(delta)


func handle_player_inputs() -> void:
	if arrowNumb == DIR_NONE:
		if Input.is_action_just_pressed("up"):
			set_arrow_input(DIR_UP)
		elif Input.is_action_just_pressed("down"):
			set_arrow_input(DIR_DOWN)
		elif Input.is_action_just_pressed("left"):
			set_arrow_input(DIR_LEFT)
		elif Input.is_action_just_pressed("right"):
			set_arrow_input(DIR_RIGHT)

	if wasdNumb == DIR_NONE:
		if Input.is_action_just_pressed("w"):
			set_wasd_input(DIR_UP)
		elif Input.is_action_just_pressed("s"):
			set_wasd_input(DIR_DOWN)
		elif Input.is_action_just_pressed("a"):
			set_wasd_input(DIR_LEFT)
		elif Input.is_action_just_pressed("d"):
			set_wasd_input(DIR_RIGHT)


func set_arrow_input(direction: int) -> void:
	arrowNumb = direction
	flash_puncher()


func set_wasd_input(direction: int) -> void:
	wasdNumb = direction
	flash_shadow()


func flash_puncher() -> void:
	$puncher.set_modulate(Color(0.84, 0.31, 0.21, 1))
	await get_tree().create_timer(0.05).timeout
	$puncher.set_modulate(Color(1, 1, 1, 1))


func flash_shadow() -> void:
	$shadow.set_modulate(Color(1, 1, 1, 0.5))
	await get_tree().create_timer(0.05).timeout
	$shadow.set_modulate(Color(1, 1, 1, 1))


func start_attack() -> void:
	$waiter.start()
	$wallpart.restart()


func update_attack_visuals(delta: float) -> void:
	update_puncher_visuals(delta)
	update_shadow_visuals(delta)


func update_puncher_visuals(delta: float) -> void:
	match arrowNumb:
		DIR_UP:
			$wallpart.set_position(Vector2(613, 133))
			$puncher.set_region_rect(Rect2(1682, 28, 317, 900))
			$arrow.set_rotation_degrees(270)
			$arrow.set_position(lerp($arrow.get_position(), Vector2(600, 230), delta * 8))

		DIR_DOWN:
			$wallpart.set_position(Vector2(610, 350))
			$puncher.set_region_rect(Rect2(2166, 210, 250, 455))
			$arrow.set_rotation_degrees(90)
			$arrow.set_position(lerp($arrow.get_position(), Vector2(560, 760), delta * 8))

		DIR_LEFT:
			$wallpart.set_position(Vector2(322, 265))
			$puncher.set_position(Vector2(468.594, 509.715))
			$puncher.set_region_rect(Rect2(1051, 135, 566, 578))
			$arrow.set_rotation_degrees(180)
			$arrow.set_position(lerp($arrow.get_position(), Vector2(220, 560), delta * 8))

		DIR_RIGHT:
			$wallpart.set_position(Vector2(811, 269))
			$puncher.set_position(Vector2(668.594, 509.715))
			$puncher.set_region_rect(Rect2(436, 52, 566, 578))
			$arrow.set_rotation_degrees(0)
			$arrow.set_position(lerp($arrow.get_position(), Vector2(940, 560), delta * 8))


func update_shadow_visuals(delta: float) -> void:
	match wasdNumb:
		DIR_UP:
			$shadow.set_position(Vector2(576, 335))
			$shadow.set_scale(Vector2(0.492, 0.492))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1326))
			$shadarrow.set_rotation_degrees(270)
			$shadarrow.set_position(lerp($shadarrow.get_position(), Vector2(560, 0), delta * 8))

		DIR_DOWN:
			$shadow.set_scale(Vector2(0.488, 0.488))
			$shadow.set_position(Vector2(582, 499))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1126))
			$shadarrow.set_rotation_degrees(90)
			$shadarrow.set_position(lerp($shadarrow.get_position(), Vector2(560, 300), delta * 8))

		DIR_LEFT:
			$shadow.set_position(Vector2(331, 370))
			$shadow.set_region_rect(Rect2(588, 140, 690, 1121))
			$shadarrow.set_rotation_degrees(180)
			$shadarrow.set_position(lerp($shadarrow.get_position(), Vector2(460, 200), delta * 8))

		DIR_RIGHT:
			$shadow.set_position(Vector2(796, 360))
			$shadow.set_region_rect(Rect2(1427, 149, 690, 1121))
			$shadarrow.set_rotation_degrees(0)
			$shadarrow.set_position(lerp($shadarrow.get_position(), Vector2(660, 200), delta * 8))


func reset_puncher() -> void:
	$puncher.set_region_rect(Rect2(57, 305, 331, 388))
	$puncher.set_position(Vector2(568.594, 509.715))
	$arrow.set_position(Vector2(560, 560))


func reset_shadow() -> void:
	$shadow.set_region_rect(Rect2(100, 122, 372, 1061))
	$shadow.set_position(Vector2(540, 344))
	$shadow.set_scale(Vector2(0.534, 0.534))
	$shadarrow.set_position(Vector2(560, 200))


func update_lives(delta: float) -> void:
	if tries < 3 and tries >= 0:
		var life = get_node("lives/life" + str(tries))
		life.scale = lerp(life.scale, Vector2.ZERO, delta * 10)


func play_lose_animation(delta: float) -> void:
	lose_started = true
	$shadow.scale = lerp($shadow.scale, Vector2(5, 5), delta * 2)
	$Youlose.set_modulate(lerp($Youlose.get_modulate(), Color(1, 1, 1, 1), delta * 3))

	if $waiter.is_stopped():
		$waiter.start()


func apply_shake() -> void:
	shake_strength = RANDOM_SHAKE_STRENGTH


func update_camera_shake(delta: float) -> void:
	shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	camera.offset = get_random_offset()


func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength),
		rand.randf_range(-shake_strength, shake_strength)
	)


func _on_waiter_timeout() -> void:
	if wall_breaking or lose_started:
		return

	if wasdNumb == arrowNumb:
		register_hit()
	else:
		tries -= 1

	arrowNumb = DIR_NONE
	wasdNumb = DIR_NONE


func register_hit() -> void:
	hits += 1
	apply_shake()

	var crack = get_node("cracks/Crack" + str(hits))

	match wasdNumb:
		DIR_UP:
			crack.set_position(Vector2(576, 105))
		DIR_DOWN:
			crack.set_position(Vector2(582, 299))
		DIR_LEFT:
			crack.set_position(Vector2(331, 250))
		DIR_RIGHT:
			crack.set_position(Vector2(796, 250))

	crack.show()


func breakwall() -> void:
	wall_breaking = true
	hits = 4

	await get_tree().create_timer(1.0).timeout

	$wallpart.set_position(Vector2(613, 233))
	$wallpart.restart()
	$Crack4.set_modulate(Color(1, 1, 1, 0.6))
	apply_shake()

	await get_tree().create_timer(1.0).timeout

	apply_shake()

	$Wall.hide()
	$darkline.hide()

	reset_puncher()

	$cracks/Crack1.hide()
	$cracks/Crack2.hide()
	$cracks/Crack3.hide()
	$Crack4.hide()
	$shadow.hide()
	$Shmile.show()
