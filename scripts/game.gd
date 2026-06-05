extends Node2D

const DIR_NONE := -1
const DIR_UP := 1
const DIR_DOWN := 2
const DIR_LEFT := 3
const DIR_RIGHT := 4

@export var p1_color = Color(0.825, 0.332, 0.387, 1.0)
@export var p2_color = Color(0.319, 0.533, 0.769, 1.0)

var current_player := 1

var arrowNumb := DIR_NONE
var wasdNumb := DIR_NONE
var hitlist = []
var hits := 0
var tries := 3

var wall_breaking := false

@export var RANDOM_SHAKE_STRENGTH: float = 30.0
@export var SHAKE_DECAY_RATE: float = 5.0

@onready var camera = $camera
@onready var rand := RandomNumberGenerator.new()

var shake_strength: float = 0.0


func _ready() -> void:
	rand.randomize()
	set_player_color()


func _process(delta: float) -> void:
	update_camera_shake(delta)
	update_lives(delta)

	if tries <= 0 and hits < 3:
		switch_player()
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
	set_player_color()


func flash_shadow() -> void:
	$shadow.set_modulate(Color(1, 1, 1, 0.5))
	await get_tree().create_timer(0.05).timeout
	set_player_color()


func set_player_color() -> void:
	var color = p1_color

	if current_player == 2:
		color = p2_color

	$puncher.set_modulate(color)
	$shadow.set_modulate(color)

func switch_animation():
	var switch_sprite = $switch
	switch_sprite.show()
	switch_sprite.scale = Vector2(0.1, 0.1)
	switch_sprite.modulate = p1_color
	var scale_tween = create_tween()
	var flash_tween = create_tween()
	scale_tween.tween_property(
		switch_sprite,
		"scale",
		Vector2(0.674, 0.674),
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in range(6):
		flash_tween.tween_property(switch_sprite, "modulate", p1_color, 0.18)
		flash_tween.tween_property(switch_sprite, "modulate", p2_color, 0.18)
	scale_tween.tween_property(
		switch_sprite,
		"scale",
		Vector2.ZERO,
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await scale_tween.finished
	switch_sprite.hide()

func switch_player() -> void:
	if current_player == 1:
		current_player = 2
	else:
		current_player = 1

	tries = 3
	hits = 0;
	arrowNumb = DIR_NONE
	wasdNumb = DIR_NONE

	await switch_animation()
	reset_puncher()
	reset_shadow()
	set_player_color()
	reset_lives()


func reset_lives() -> void:
	for i in range(3):
		get_node("lives/life" + str(i)).scale = Vector2(0.119, 0.119)


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
			$puncher.play("up")

		DIR_DOWN:
			$wallpart.set_position(Vector2(610, 350))
			$puncher.play("down")

		DIR_LEFT:
			$wallpart.set_position(Vector2(322, 265))
			$puncher.set_position(Vector2(468.594, 509.715))
			$puncher.play("left")

		DIR_RIGHT:
			$wallpart.set_position(Vector2(811, 269))
			$puncher.set_position(Vector2(668.594, 509.715))
			$puncher.play("right")

func update_shadow_visuals(delta: float) -> void:
	match wasdNumb:
		DIR_UP:
			$shadow.set_position(Vector2(576, 335))
			$shadow.set_scale(Vector2(0.492, 0.492))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1326))

		DIR_DOWN:
			$shadow.set_scale(Vector2(0.488, 0.488))
			$shadow.set_position(Vector2(582, 499))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1126))

		DIR_LEFT:
			$shadow.set_position(Vector2(331, 370))
			$shadow.set_region_rect(Rect2(588, 140, 690, 1121))

		DIR_RIGHT:
			$shadow.set_position(Vector2(796, 360))
			$shadow.set_region_rect(Rect2(1427, 149, 690, 1121))

func reset_puncher() -> void:
	$puncher.play("default")
	$puncher.set_position(Vector2(568.594, 479.715))

func reset_shadow() -> void:
	$shadow.set_region_rect(Rect2(100, 122, 372, 1061))
	$shadow.set_position(Vector2(540, 344))
	$shadow.set_scale(Vector2(0.534, 0.534))


func update_lives(delta: float) -> void:
	var lost_lives := 3 - tries

	for i in range(lost_lives):
		var life = get_node("lives/life" + str(i))
		life.scale = lerp(life.scale, Vector2.ZERO, delta * 10)


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
	if wall_breaking:
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
