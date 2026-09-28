class_name PresentationPolishTests
extends Node

const GAME_SCENE := preload("res://scenes/game.tscn")
const DIRECTIONS: Array[StringName] = [&"up", &"down", &"left", &"right"]


func test_directional_animations_share_five_frame_contact_shape() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var puncher: AnimatedSprite2D = game.get_node("puncher")
	var shadow: AnimatedSprite2D = game.get_node("shadow")

	for animation: StringName in DIRECTIONS:
		assert(puncher.sprite_frames.get_frame_count(animation) == 5)
		assert(shadow.sprite_frames.get_frame_count(animation) == 5)
		assert(not puncher.sprite_frames.get_animation_loop(animation))
		assert(not shadow.sprite_frames.get_animation_loop(animation))

	game.free()


func test_persistent_controllers_are_attached_in_scene() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var expected_scripts: Dictionary = {
		"Presentation/Fighters": "res://scripts/fighter_presentation.gd",
		"Presentation/Impacts": "res://scripts/impact_presentation.gd",
		"Presentation/CameraEffects": "res://scripts/camera_effects.gd",
		"HUD/indicators": "res://scripts/direction_indicators.gd",
		"HUD/timerbar": "res://scripts/turn_timer_bar.gd",
		"HUD/score": "res://scripts/score_tally.gd",
		"HUD/pause": "res://scripts/pause_menu.gd",
	}
	for node_path: String in expected_scripts:
		var node: Node = game.get_node(node_path)
		var script: Script = node.get_script()
		assert(script.resource_path == expected_scripts[node_path])
	assert(game.has_node("HUD/flash/rect"))
	assert(game.has_node("HUD/rematch"))
	assert(game.has_node("HUD/winner"))
	assert(game.has_node("HUD/callout/sub"))
	assert(game.has_node("light/hum"))
	var hole_script: Script = game.get_node("hole").get_script()
	assert(hole_script.resource_path == "res://scripts/wall_hole.gd")
	game.free()


func test_you_win_waits_in_front_of_the_hole_until_the_wall_breaks() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var hole: Node = game.get_node("hole")
	var you_win: CanvasItem = game.get_node("Youwin")
	var wall: Node = game.get_node("Wall")

	assert(not you_win.visible)
	assert(hole.get_index() > wall.get_index())
	assert(you_win.get_index() > hole.get_index())
	game.free()


func test_wall_hole_stops_short_of_the_bulb_and_drops_rubble_on_the_floor() -> void:
	var hole: WallHole = WallHole.new()
	hole.build_shapes()

	for point: Vector2 in hole.rim:
		assert(point.x <= WallHole.RIGHT_LIMIT + WallHole.INK_WOBBLE)
	for chunk: Dictionary in hole.chunks:
		var landing: Vector2 = chunk["to"]
		assert(landing.y >= WallHole.FLOOR_Y_MIN and landing.y <= WallHole.FLOOR_Y_MAX)
	hole.free()


func test_switch_stamp_uses_the_reinked_texture() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var switch_sprite: AnimatedSprite2D = game.get_node("switch")
	var frame: AtlasTexture = switch_sprite.sprite_frames.get_frame_texture(&"default", 0)
	assert(frame.atlas.resource_path == "res://sprites/switch_hd.png")
	assert(frame.region.size == Vector2(688, 688))
	game.free()


func test_ink_button_face_stays_inside_its_rect() -> void:
	var style: InkStyleBox = InkStyleBox.new()
	var rect := Rect2(0.0, 0.0, 320.0, 66.0)
	var reach := rect.grow(style.wobble)
	for point: Vector2 in style.get_face(rect, 7):
		assert(reach.has_point(point))


func test_hit_words_are_available_to_impact_controller() -> void:
	assert(ImpactPresentation.HIT_WORD_TEXTURES.size() == 4)
	for texture: Texture2D in ImpactPresentation.HIT_WORD_TEXTURES:
		assert(texture != null)


func test_presentation_resources_exist() -> void:
	assert(ResourceLoader.exists("res://scripts/impact_burst.gd"))
	assert(ResourceLoader.exists("res://scripts/fighter_presentation.gd"))
	assert(ResourceLoader.exists("res://scripts/impact_presentation.gd"))
	assert(ResourceLoader.exists("res://scripts/camera_effects.gd"))
	assert(ResourceLoader.exists("res://shaders/shadow_outline.gdshader"))
	assert(ResourceLoader.exists("res://shaders/shadow_rim.gdshader"))


func test_fighter_controller_owns_shared_contact_frame() -> void:
	assert(FighterPresentation.CONTACT_FRAME == 2)
	assert(FighterPresentation.PUNCHER_POSITION == Vector2(658.5, 335.0))
	assert(FighterPresentation.SHADOW_POSITION == Vector2(670.0, 300.0))


func test_shadow_rims_change_pose_with_the_shadow() -> void:
	var game: Node = GAME_SCENE.instantiate()
	var fighters: FighterPresentation = game.get_node("Presentation/Fighters")
	fighters.setup(game.get_node("puncher"), game.get_node("shadow"))

	# No frame runs between these, as none does when a replay tween resets the
	# pose; the rims must not wait for _process to catch up.
	fighters.play_shadow(&"up", 0.3)
	for rim: AnimatedSprite2D in fighters.shadow_rims:
		assert(rim.animation == &"up")
	fighters.reset_shadow()
	for rim: AnimatedSprite2D in fighters.shadow_rims:
		assert(rim.animation == FighterPresentation.IDLE_ANIMATION)
	game.free()


func test_dark_player_colours_are_lifted_on_black() -> void:
	var near_black := Color(0.08, 0.11, 0.1)
	var lifted := PlayerColorSettings.readable_on_black(near_black)
	assert(lifted.ok_hsl_l >= PlayerColorSettings.MIN_LIGHTNESS_ON_BLACK - 0.01)
	assert(absf(lifted.ok_hsl_h - near_black.ok_hsl_h) < 0.01)

	var bar: TurnTimerBar = TurnTimerBar.new()
	bar.set_state(1.0, near_black, true)
	assert(bar.bar_color == lifted)
	bar.free()

	# The defaults already read, and pass through untouched.
	for color: Color in [
		PlayerColorSettings.DEFAULT_PLAYER_ONE_COLOR,
		PlayerColorSettings.DEFAULT_PLAYER_TWO_COLOR,
	]:
		assert(PlayerColorSettings.readable_on_black(color) == color)


func test_camera_controller_accepts_directional_impulses() -> void:
	var camera: Camera2D = Camera2D.new()
	var effects: CameraEffects = CameraEffects.new()
	effects.setup(camera, 30.0, 5.0)
	effects.shake(12.0, Vector2.LEFT)
	effects.push(Vector2.UP, 6.0)
	assert(effects.shake_axis == Vector2.LEFT)
	assert(effects.shake_strength == 12.0)
	assert(effects.push_offset == Vector2(0.0, -6.0))
	camera.free()
	effects.free()


func test_every_direction_has_contact_and_crack_positions() -> void:
	for direction: int in Game.ALL_DIRECTIONS:
		var data: Dictionary = Game.DIRECTION_DATA[direction]
		assert(data.has("contact_position"))
		assert(data["contact_position"] is Vector2)
		assert(data.has("crack_position"))
		assert(data["crack_position"] is Vector2)
