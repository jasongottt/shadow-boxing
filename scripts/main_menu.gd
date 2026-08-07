class_name MainMenu
extends Control

const GAME_SCENE_PATH := "res://scenes/game.tscn"

@onready var main_options: VBoxContainer = $Center/Menu
@onready var start_button: Button = $Center/Menu/StartButton
@onready var customize_button: Button = $Center/Menu/CustomizeButton
@onready var customize_panel: VBoxContainer = $Center/Customize
@onready var player_one_picker: ColorPickerButton = $Center/Customize/Players/PlayerOne/ColorPicker
@onready var player_two_picker: ColorPickerButton = $Center/Customize/Players/PlayerTwo/ColorPicker
@onready var player_one_preview: ColorRect = $Center/Customize/Players/PlayerOne/Preview
@onready var player_two_preview: ColorRect = $Center/Customize/Players/PlayerTwo/Preview
@onready var back_button: Button = $Center/Customize/BackButton
var transition_in_progress: bool = false


func _ready() -> void:
	sync_color_controls()
	start_button.grab_focus()


func sync_color_controls() -> void:
	player_one_picker.color = PlayerSettings.player_one_color
	player_two_picker.color = PlayerSettings.player_two_color
	player_one_preview.color = PlayerSettings.player_one_color
	player_two_preview.color = PlayerSettings.player_two_color


func _on_customize_button_pressed() -> void:
	main_options.hide()
	customize_panel.show()
	player_one_picker.grab_focus()


func _on_back_button_pressed() -> void:
	customize_panel.hide()
	main_options.show()
	customize_button.grab_focus()


func _on_player_one_color_changed(color: Color) -> void:
	PlayerSettings.set_player_one_color(color)
	player_one_preview.color = PlayerSettings.player_one_color


func _on_player_two_color_changed(color: Color) -> void:
	PlayerSettings.set_player_two_color(color)
	player_two_preview.color = PlayerSettings.player_two_color


func _on_reset_colors_pressed() -> void:
	PlayerSettings.reset_defaults()
	sync_color_controls()


func _on_start_button_pressed() -> void:
	if transition_in_progress:
		return

	transition_in_progress = true
	start_button.disabled = true
	var error: Error = get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error == OK:
		return

	push_error("MainMenu could not open %s (error %d)" % [GAME_SCENE_PATH, error])
	transition_in_progress = false
	start_button.disabled = false
