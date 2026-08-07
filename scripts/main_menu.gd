class_name MainMenu
extends Control

const GAME_SCENE_PATH := "res://scenes/game.tscn"

@onready var start_button: Button = $Center/Menu/StartButton
var transition_in_progress: bool = false


func _ready() -> void:
	start_button.grab_focus()


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
