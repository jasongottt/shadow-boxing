class_name PlayerColorSettings
extends Node

const DEFAULT_PLAYER_ONE_COLOR := Color(0.825, 0.332, 0.387, 1.0)
const DEFAULT_PLAYER_TWO_COLOR := Color(0.319, 0.533, 0.769, 1.0)

var player_one_color: Color = DEFAULT_PLAYER_ONE_COLOR
var player_two_color: Color = DEFAULT_PLAYER_TWO_COLOR


func set_player_one_color(color: Color) -> void:
	player_one_color = with_full_alpha(color)


func set_player_two_color(color: Color) -> void:
	player_two_color = with_full_alpha(color)


func reset_defaults() -> void:
	player_one_color = DEFAULT_PLAYER_ONE_COLOR
	player_two_color = DEFAULT_PLAYER_TWO_COLOR


func with_full_alpha(color: Color) -> Color:
	var opaque_color: Color = color
	opaque_color.a = 1.0
	return opaque_color
