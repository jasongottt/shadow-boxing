class_name SoundBoard
extends Node

## Every one-shot in the game plays through here rather than from a player node
## in its own scene, so a sound fired just before a scene change (the start
## click, the last bell of a fight) gets to ring out instead of dying with the
## scene that played it.
##
## The sounds are synthesized by tools/make_sounds.py: dry, rough, and a little
## cartoonish, to sit under the ink rather than on top of it.

const SOUNDS := {
	&"whoosh": preload("res://sounds/whoosh.wav"),
	&"hit": preload("res://sounds/hit.wav"),
	&"crack": preload("res://sounds/crack.wav"),
	&"miss": preload("res://sounds/miss.wav"),
	&"lock": preload("res://sounds/lock.wav"),
	&"tick": preload("res://sounds/tick.wav"),
	&"buzzer": preload("res://sounds/buzzer.wav"),
	&"bell": preload("res://sounds/bell.wav"),
	&"rumble": preload("res://sounds/rumble.wav"),
	&"crash": preload("res://sounds/crash.wav"),
	&"ui_move": preload("res://sounds/ui_move.wav"),
	&"ui_press": preload("res://sounds/ui_press.wav"),
}

## Enough that a full replay (a whoosh, a hit and a crack per punch, plus a
## ringing bell) never has to cut off a sound that is still audible.
const VOICE_COUNT := 16

var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	# The pause menu still clicks, and a bell rung as the tree pauses finishes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	get_tree().set_auto_accept_quit(false)

	for index in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.name = "voice%d" % index
		add_child(voice)
		voices.append(voice)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_quietly()


## Freeing a player mid-sound strands its playback in the AudioServer, and the
## bulb hum is *always* mid-sound, so a plain quit reported leaked instances on
## every exit. Stopping everything first and leaving one frame for the server
## to let go keeps the exit clean.
##
## The first frame's wait matters too: the Quit button's own click is started
## by a handler that runs *after* the one asking to quit, and it has to be
## playing before it can be stopped.
func quit_quietly() -> void:
	await get_tree().process_frame

	for player: Node in get_tree().root.find_children("*", "AudioStreamPlayer", true, false):
		(player as AudioStreamPlayer).stop()
	for player: Node in get_tree().root.find_children("*", "AudioStreamPlayer2D", true, false):
		(player as AudioStreamPlayer2D).stop()

	await get_tree().process_frame
	get_tree().quit()


## Jitter nudges the pitch either way by up to that fraction, so a sound heard
## over and over (every punch in a replay) doesn't turn into a machine gun.
func play(
	sound: StringName,
	volume_db: float = 0.0,
	pitch: float = 1.0,
	pitch_jitter: float = 0.0,
) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null:
		push_warning("SoundBoard has no sound called %s" % sound)
		return

	var voice := claim_voice()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch * random.randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	voice.play()


## The same sound several times in a row, the way a ring bell is struck.
## Unscaled so a hit-stop landing mid-sequence doesn't smear the rhythm.
func play_repeated(
	sound: StringName, count: int, interval: float, volume_db: float = 0.0
) -> void:
	for index in count:
		if index > 0:
			await get_tree().create_timer(interval, true, false, true).timeout
		play(sound, volume_db)


## A free voice if there is one, otherwise whichever started longest ago.
func claim_voice() -> AudioStreamPlayer:
	for offset in voices.size():
		var index := (next_voice + offset) % voices.size()
		if not voices[index].playing:
			next_voice = (index + 1) % voices.size()
			return voices[index]

	var oldest: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	return oldest
