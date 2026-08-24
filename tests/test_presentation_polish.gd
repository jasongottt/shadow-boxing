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
		"HUD/hittally": "res://scripts/hit_tally.gd",
	}
	for node_path: String in expected_scripts:
		var node: Node = game.get_node(node_path)
		var script: Script = node.get_script()
		assert(script.resource_path == expected_scripts[node_path])
	assert(game.has_node("HUD/flash/rect"))
	assert(game.has_node("HUD/rematch"))
	game.free()


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
