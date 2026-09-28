class_name PlayerColorSettings
extends Node

const DEFAULT_PLAYER_ONE_COLOR := Color(0.825, 0.332, 0.387, 1.0)
const DEFAULT_PLAYER_TWO_COLOR := Color(0.319, 0.533, 0.769, 1.0)
const SETTINGS_PATH := "user://settings.cfg"
const COLOR_SECTION := "colors"

## Just under the defaults' OK lightness (0.553), so they pass through as they
## are and only a genuinely dark pick gets lifted.
const MIN_LIGHTNESS_ON_BLACK := 0.55

var player_one_color: Color = DEFAULT_PLAYER_ONE_COLOR
var player_two_color: Color = DEFAULT_PLAYER_TWO_COLOR


func _ready() -> void:
	load_colors()


func set_player_one_color(color: Color) -> void:
	player_one_color = with_full_alpha(color)


func set_player_two_color(color: Color) -> void:
	player_two_color = with_full_alpha(color)


func reset_defaults() -> void:
	player_one_color = DEFAULT_PLAYER_ONE_COLOR
	player_two_color = DEFAULT_PLAYER_TWO_COLOR


## The picker allows any colour, including ones as dark as the letterbox bars.
## Anything drawn in a player's colour on black (the HUD, "You Win" in the
## hole) goes through here, which keeps the hue but lifts it until it reads. A
## near-black pick used to leave that player's arrows, timer and tally
## invisible.
static func readable_on_black(color: Color) -> Color:
	if color.ok_hsl_l >= MIN_LIGHTNESS_ON_BLACK:
		return color

	return Color.from_ok_hsl(
		color.ok_hsl_h, color.ok_hsl_s, MIN_LIGHTNESS_ON_BLACK, color.a
	)


func with_full_alpha(color: Color) -> Color:
	var opaque_color: Color = color
	opaque_color.a = 1.0
	return opaque_color


## Saving is explicit rather than part of every set, so dragging through the
## picker doesn't hit the disk each frame, and a throwaway instance (the tests
## make one) can't overwrite the colours a player actually chose.
func save_colors() -> void:
	var config := ConfigFile.new()
	# Loaded first so anything else in the file survives the rewrite.
	config.load(SETTINGS_PATH)
	config.set_value(COLOR_SECTION, "player_one", player_one_color)
	config.set_value(COLOR_SECTION, "player_two", player_two_color)

	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save colours to %s (error %d)" % [SETTINGS_PATH, error])


func load_colors() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	var saved_one: Variant = config.get_value(
		COLOR_SECTION, "player_one", DEFAULT_PLAYER_ONE_COLOR
	)
	var saved_two: Variant = config.get_value(
		COLOR_SECTION, "player_two", DEFAULT_PLAYER_TWO_COLOR
	)
	if saved_one is Color:
		set_player_one_color(saved_one)
	if saved_two is Color:
		set_player_two_color(saved_two)
