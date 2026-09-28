class_name MainMenu
extends Control

const GAME_SCENE_PATH := "res://scenes/game.tscn"

## The previews breathe through the same four idle frames, at the same rate, as
## the fighter does in the ring. Player two runs half a cycle behind so the
## pair don't bob in lockstep.
const PREVIEW_FRAME_ORIGINS: Array[Vector2] = [
	Vector2(216, 244),
	Vector2(716, 244),
	Vector2(216, 744),
	Vector2(716, 744),
]
const PREVIEW_FPS := 5.0
const PREVIEW_TWO_FRAME_OFFSET := 2

## Room left for the title bar and taskbar when the window has to shrink.
const WINDOW_SCREEN_MARGIN := 96

@onready var main_options: VBoxContainer = $Center/Menu
@onready var start_button: Button = $Center/Menu/StartButton
@onready var cpu_button: Button = $Center/Menu/CpuButton
@onready var customize_button: Button = $Center/Menu/CustomizeButton
@onready var quit_button: Button = $Center/Menu/QuitButton
@onready var customize_panel: VBoxContainer = $Center/Customize
@onready var player_one_picker: ColorPickerButton = $Center/Customize/Players/PlayerOne/ColorPicker
@onready var player_two_picker: ColorPickerButton = $Center/Customize/Players/PlayerTwo/ColorPicker
@onready var player_one_preview: TextureRect = $Center/Customize/Players/PlayerOne/Preview
@onready var player_two_preview: TextureRect = $Center/Customize/Players/PlayerTwo/Preview
var transition_in_progress: bool = false
var preview_time: float = 0.0
var focus_sounds_muted: bool = false

static var window_fitted: bool = false


func _ready() -> void:
	fit_window_to_screen()
	sync_color_controls()

	if OS.has_feature("web"):
		# A browser tab can't be closed from inside the page.
		quit_button.hide()
		start_button.focus_neighbor_top = start_button.get_path_to(customize_button)
		customize_button.focus_neighbor_bottom = customize_button.get_path_to(start_button)

	start_button.grab_focus()
	hook_up_button_sounds()


func _process(delta: float) -> void:
	if not customize_panel.visible:
		return

	preview_time += delta
	var frame := int(preview_time * PREVIEW_FPS)
	set_preview_frame(player_one_preview, frame)
	set_preview_frame(player_two_preview, frame + PREVIEW_TWO_FRAME_OFFSET)


func _unhandled_input(event: InputEvent) -> void:
	if customize_panel.visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Sounds.play(&"ui_press", -4.0, 0.8)
		_on_back_button_pressed()


func sync_color_controls() -> void:
	player_one_picker.color = PlayerSettings.player_one_color
	player_two_picker.color = PlayerSettings.player_two_color
	player_one_preview.self_modulate = PlayerSettings.player_one_color
	player_two_preview.self_modulate = PlayerSettings.player_two_color


func set_preview_frame(preview: TextureRect, frame: int) -> void:
	var atlas := preview.texture as AtlasTexture
	atlas.region.position = PREVIEW_FRAME_ORIGINS[frame % PREVIEW_FRAME_ORIGINS.size()]


## Every button ticks as focus lands on it and pops when pressed. Moving the
## mouse over a button moves focus to it as well, so the mouse and the keyboard
## can never leave two different buttons highlighted. It has to be an actual
## move: a cursor merely resting where QUIT appears must not steal focus from
## START and turn the next Enter into a quit.
func hook_up_button_sounds() -> void:
	for button: BaseButton in find_children("*", "BaseButton", true, false):
		button.focus_entered.connect(_on_button_focus_entered)
		button.gui_input.connect(_on_button_gui_input.bind(button))
		button.pressed.connect(_on_button_pressed)


func _on_button_gui_input(event: InputEvent, button: BaseButton) -> void:
	if event is InputEventMouseMotion and not button.has_focus():
		button.grab_focus()


## Focus moved by the menu itself (after a press) shouldn't tick on top of the
## press it follows.
func focus_quietly(control: Control) -> void:
	focus_sounds_muted = true
	control.grab_focus()
	focus_sounds_muted = false


func _on_button_focus_entered() -> void:
	if not focus_sounds_muted:
		Sounds.play(&"ui_move", -12.0, 1.0, 0.04)


func _on_button_pressed() -> void:
	Sounds.play(&"ui_press", -4.0, 1.0, 0.04)


## The window is 1152 square, taller than a 1080p screen once the title bar and
## taskbar are counted, so on smaller screens it hung off the bottom edge.
## Viewport stretching keeps the picture whole at any size. Only done once per
## launch, so coming back to the menu never undoes a size the player chose.
func fit_window_to_screen() -> void:
	if window_fitted:
		return
	window_fitted = true

	var window := get_window()
	if window.mode != Window.MODE_WINDOWED:
		return

	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var side := mini(usable.size.x, usable.size.y) - WINDOW_SCREEN_MARGIN
	if side <= 0 or side >= window.size.y:
		return

	window.size = Vector2i(side, side)
	window.move_to_center()


func _on_customize_button_pressed() -> void:
	main_options.hide()
	customize_panel.show()
	focus_quietly(player_one_picker)


func _on_back_button_pressed() -> void:
	PlayerSettings.save_colors()
	customize_panel.hide()
	main_options.show()
	focus_quietly(customize_button)


func _on_player_one_color_changed(color: Color) -> void:
	PlayerSettings.set_player_one_color(color)
	player_one_preview.self_modulate = PlayerSettings.player_one_color


func _on_player_two_color_changed(color: Color) -> void:
	PlayerSettings.set_player_two_color(color)
	player_two_preview.self_modulate = PlayerSettings.player_two_color


func _on_reset_colors_pressed() -> void:
	PlayerSettings.reset_defaults()
	sync_color_controls()


func _on_start_button_pressed() -> void:
	start_fight(false)


func _on_cpu_button_pressed() -> void:
	start_fight(true)


func _on_quit_button_pressed() -> void:
	Sounds.quit_quietly()


func start_fight(versus_cpu: bool) -> void:
	if transition_in_progress:
		return

	transition_in_progress = true
	start_button.disabled = true
	cpu_button.disabled = true
	Session.start(versus_cpu)

	var error: Error = Curtain.change_scene(GAME_SCENE_PATH)
	if error == OK:
		return

	push_error("MainMenu could not open %s (error %d)" % [GAME_SCENE_PATH, error])
	transition_in_progress = false
	start_button.disabled = false
	cpu_button.disabled = false
