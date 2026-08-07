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
