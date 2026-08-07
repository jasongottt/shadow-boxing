class_name MainMenuTests
extends Node

const MAIN_MENU_SCENE := preload("res://scenes/main_menu.tscn")


func test_main_menu_has_functional_start_button() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var start_button: Button = menu.get_node("Center/Menu/StartButton")
	assert(start_button.text == "START GAME")
	assert(not start_button.disabled)
	assert(start_button.pressed.is_connected(menu._on_start_button_pressed))
	assert(ResourceLoader.exists(MainMenu.GAME_SCENE_PATH))
	menu.free()


func test_customize_panel_and_color_settings_are_available() -> void:
	var menu: Control = MAIN_MENU_SCENE.instantiate()
	var customize_panel: VBoxContainer = menu.get_node("Center/Customize")
	var customize_button: Button = menu.get_node("Center/Menu/CustomizeButton")
	var player_one_picker: ColorPickerButton = menu.get_node(
		"Center/Customize/Players/PlayerOne/ColorPicker"
	)
	var player_two_picker: ColorPickerButton = menu.get_node(
		"Center/Customize/Players/PlayerTwo/ColorPicker"
	)
	assert(customize_button.pressed.is_connected(menu._on_customize_button_pressed))
	assert(player_one_picker.color_changed.is_connected(menu._on_player_one_color_changed))
	assert(player_two_picker.color_changed.is_connected(menu._on_player_two_color_changed))
	assert(not customize_panel.visible)

	var custom_one: Color = Color(0.95, 0.72, 0.18, 1.0)
	var custom_two: Color = Color(0.26, 0.84, 0.58, 1.0)
	var settings: PlayerColorSettings = PlayerColorSettings.new()
	settings.set_player_one_color(custom_one)
	settings.set_player_two_color(custom_two)
	assert(settings.player_one_color == custom_one)
	assert(settings.player_two_color == custom_two)
	assert(ProjectSettings.has_setting("autoload/PlayerSettings"))

	settings.free()
	menu.free()
