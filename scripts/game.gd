extends Node2D
var arrowNumb = -1
var wasdNumb = -1
var hits = 0
var tries = 3
@export var RANDOM_SHAKE_STRENGTH: float = 30.0
@export var SHAKE_DECAY_RATE: float = 5.0
@onready var camera = $camera
@onready var rand = RandomNumberGenerator.new()
var shake_strength: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rand.randomize()

func apply_shake() -> void:
	shake_strength = RANDOM_SHAKE_STRENGTH

func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength), 
		rand.randf_range(-shake_strength, shake_strength),
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	camera.offset = get_random_offset()
	if ($waiter.is_stopped()):
		if (arrowNumb == -1):
			if Input.is_action_just_pressed("up"):
				$puncher.set_modulate(Color(.84, .31, .21, 1))
				await get_tree().create_timer(0.05).timeout
				$puncher.set_modulate(Color(1, 1, 1, 1))
				arrowNumb = 1
			if Input.is_action_just_pressed("down"):
				$puncher.set_modulate(Color(.84, .31, .21, 1))
				await get_tree().create_timer(0.05).timeout
				$puncher.set_modulate(Color(1, 1, 1, 1))
				arrowNumb = 2
			if Input.is_action_just_pressed("left"):
				$puncher.set_modulate(Color(.84, .31, .21, 1))
				await get_tree().create_timer(0.05).timeout
				$puncher.set_modulate(Color(1, 1, 1, 1))
				arrowNumb = 3
			if Input.is_action_just_pressed("right"):
				$puncher.set_modulate(Color(.84, .31, .21, 1))
				await get_tree().create_timer(0.05).timeout
				$puncher.set_modulate(Color(1, 1, 1, 1))
				arrowNumb = 4
			
	if ($waiter.is_stopped()):
		if (wasdNumb == -1):
			if Input.is_action_just_pressed("w"):
				$shadow.set_modulate(Color(1, 1, 1, .5))
				await get_tree().create_timer(0.05).timeout
				$shadow.set_modulate(Color(1, 1, 1, 1))
				wasdNumb = 1
			if Input.is_action_just_pressed("s"):
				$shadow.set_modulate(Color(1, 1, 1, .5))
				await get_tree().create_timer(0.05).timeout
				$shadow.set_modulate(Color(1, 1, 1, 1))
				wasdNumb = 2
			if Input.is_action_just_pressed("a"):
				$shadow.set_modulate(Color(1, 1, 1, .5))
				await get_tree().create_timer(0.05).timeout
				$shadow.set_modulate(Color(1, 1, 1, 1))
				wasdNumb = 3
			if Input.is_action_just_pressed("d"):
				$shadow.set_modulate(Color(1, 1, 1, .5))
				await get_tree().create_timer(0.05).timeout
				$shadow.set_modulate(Color(1, 1, 1, 1))
				wasdNumb = 4
	
	if (arrowNumb == -1 && $waiter.is_stopped() && ( hits < 3 || tries == 0)):
		$puncher.set_region_rect(Rect2(57, 305, 331, 388))
		$puncher.set_position(Vector2(568.594, 509.715))
		$arrow.set_position(Vector2(560, 560))
	if (wasdNumb == -1 && $waiter.is_stopped() && ( hits < 3 || tries == 0)):
		$shadow.set_region_rect(Rect2(100, 122, 372, 1061))
		$shadow.set_position(Vector2(540, 344))
		$shadow.set_scale(Vector2(0.534, 0.534))
		$shadarrow.set_position(Vector2(560, 200))
	
	if (arrowNumb != -1 && wasdNumb != -1 && $waiter.is_stopped()):
		$waiter.start()
		$wallpart.restart()
	
	if (!$waiter.is_stopped()):
		if (arrowNumb == 1):
			$wallpart.set_position(Vector2(613, 133))
			$puncher.set_region_rect(Rect2(1682, 28, 317, 900))
			$arrow.set_rotation_degrees(270)
			$arrow.set_position((lerp($arrow.get_position(), Vector2(600, 230), delta * 8)))	
		if (arrowNumb == 2):
			$wallpart.set_position(Vector2(610, 350))
			$puncher.set_region_rect(Rect2(2166, 210, 250, 455))
		if (arrowNumb == 3):
			$wallpart.set_position(Vector2(322, 265))
			$puncher.set_position(Vector2(468.594, 509.715))
			$puncher.set_region_rect(Rect2(1051, 135, 566, 578))
			$arrow.set_rotation_degrees(180)
			$arrow.set_position((lerp($arrow.get_position(), Vector2(220, 560), delta * 8)))	
		if (arrowNumb == 4):
			$wallpart.set_position(Vector2(811, 269))
			$puncher.set_position(Vector2(668.594, 509.715))
			$puncher.set_region_rect(Rect2(436, 52, 566, 578))
			$arrow.set_rotation_degrees(0)
			$arrow.set_position((lerp($arrow.get_position(), Vector2(940, 560), delta * 8)))	
			
		if (wasdNumb == 1):
			$shadow.set_position(Vector2(576, 335))
			$shadow.set_scale(Vector2(0.492, 0.492))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1326))
			$shadarrow.set_rotation_degrees(270)
			$shadarrow.set_position((lerp($shadarrow.get_position(), Vector2(560, 0), delta * 8)))	
		if (wasdNumb == 2):
			$shadow.set_scale(Vector2(0.488, 0.488))
			$shadow.set_position(Vector2(582, 499))
			$shadow.set_region_rect(Rect2(2281, 127, 777, 1126))
			$shadarrow.set_rotation_degrees(90)
			$shadarrow.set_position((lerp($shadarrow.get_position(), Vector2(560, 300), delta * 8)))	
		if (wasdNumb == 3):
			$shadow.set_position(Vector2(331, 370))
			$shadow.set_region_rect(Rect2(588, 140, 690, 1121))
			$shadarrow.set_rotation_degrees(180)
			$shadarrow.set_position((lerp($shadarrow.get_position(), Vector2(460, 200), delta * 8)))	
		if (wasdNumb == 4):
			$shadow.set_position(Vector2(796, 360))
			$shadow.set_region_rect(Rect2(1427, 149, 690, 1121))
			$shadarrow.set_rotation_degrees(0)
			$shadarrow.set_position((lerp($shadarrow.get_position(), Vector2(660, 200), delta * 8)))	
	
	if (tries < 3):
		get_node("lives/life" + str(tries)).scale = lerp(get_node("lives/life" + str(tries)).scale, Vector2(0, 0), delta * 10)
	
	if (hits == 4):
		$waiter.start()
		
	if (hits == 3):
		breakwall()
	if (tries == 0 && hits < 3):
		$shadow.scale = lerp($shadow.scale, Vector2(5, 5), delta * 2)
		$Youlose.set_modulate((lerp($Youlose.get_modulate(), Color(1.0,1.0,1.0,1.0), delta * 3)))	
		$waiter.start()
		
func breakwall():
	hits = 4
	await get_tree().create_timer(1.0).timeout
	$wallpart.set_position(Vector2(613, 233))
	$wallpart.restart()
	$Crack4.set_modulate(Color(255, 255, 255, 0.6))
	apply_shake()
	await get_tree().create_timer(1.0).timeout
	apply_shake()
	$Wall.hide()
	$darkline.hide()
	$puncher.set_region_rect(Rect2(57, 305, 331, 388))
	$puncher.set_position(Vector2(568.594, 509.715))
	$cracks/Crack1.hide()
	$cracks/Crack2.hide()
	$cracks/Crack3.hide()
	$Crack4.hide()
	$shadow.hide()
	$Shmile.show()

func _on_waiter_timeout():
	if (wasdNumb == arrowNumb):
		hits += 1
		apply_shake()
		if (wasdNumb == 1):
			get_node("cracks/Crack" + str(hits)).set_position(Vector2(576, 105))
		if (wasdNumb == 2):
			get_node("cracks/Crack" + str(hits)).set_position(Vector2(582, 299))
		if (wasdNumb == 3):
			get_node("cracks/Crack" + str(hits)).set_position(Vector2(331, 250))
		if (wasdNumb == 4):
			get_node("cracks/Crack" + str(hits)).set_position(Vector2(796, 250))
		get_node("cracks/Crack" + str(hits)).show()	
	tries -= 1
	arrowNumb = -1
	wasdNumb = -1
