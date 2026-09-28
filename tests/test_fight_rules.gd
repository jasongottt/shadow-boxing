class_name FightRulesTests
extends Node

const HUD_SCENE := preload("res://scenes/game_hud.tscn")


func test_matching_directions_and_frozen_shadows_take_the_hit() -> void:
	assert(Game.lands_hit(Game.Direction.UP, Game.Direction.UP))
	assert(not Game.lands_hit(Game.Direction.UP, Game.Direction.LEFT))
	# A shadow that never committed stood still for the punch.
	assert(Game.lands_hit(Game.Direction.RIGHT, Game.Direction.NONE))
	# No punch thrown, nothing lands.
	assert(not Game.lands_hit(Game.Direction.NONE, Game.Direction.NONE))


func test_cpu_thinks_then_commits_to_an_available_direction() -> void:
	var cpu: CpuOpponent = CpuOpponent.new()
	cpu.begin_turn()
	var only_left: Array[int] = [Game.Direction.LEFT]
	var nothing_left: Array[int] = []

	assert(cpu.commit_at > 0.0)
	assert(cpu.commit_at < Game.TURN_TIME)
	assert(cpu.choose(0.0, only_left) == Game.Direction.NONE)
	assert(cpu.choose(Game.TURN_TIME, only_left) == Game.Direction.LEFT)
	assert(cpu.choose(Game.TURN_TIME, nothing_left) == Game.Direction.NONE)


func test_loser_opens_the_next_fight_and_menu_starts_over() -> void:
	var session: FightSession = FightSession.new()
	session.start(false)
	assert(session.opening_player == FightSession.PLAYER_ONE)

	session.record_win(FightSession.PLAYER_ONE)
	assert(session.opening_player == FightSession.PLAYER_TWO)
	assert(session.get_wins(FightSession.PLAYER_ONE) == 1)
	assert(session.get_wins(FightSession.PLAYER_TWO) == 0)

	session.record_win(FightSession.PLAYER_TWO)
	assert(session.opening_player == FightSession.PLAYER_ONE)
	assert(session.get_wins(FightSession.PLAYER_TWO) == 1)

	session.start(true)
	assert(session.versus_cpu)
	assert(session.get_wins(FightSession.PLAYER_ONE) == 0)
	assert(session.opening_player == FightSession.PLAYER_ONE)
	session.free()


func test_every_sound_loads_and_the_bulb_hum_loops() -> void:
	for sound: StringName in SoundBoard.SOUNDS:
		assert(SoundBoard.SOUNDS[sound] is AudioStreamWAV)

	var hum: AudioStreamWAV = load("res://sounds/hum.wav")
	assert(hum.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(ProjectSettings.has_setting("autoload/Sounds"))
	assert(ProjectSettings.has_setting("autoload/Session"))
	assert(ProjectSettings.has_setting("autoload/Curtain"))


func test_pause_menu_stops_the_tree_and_holds_the_hit_stop() -> void:
	var hud: Node = HUD_SCENE.instantiate()
	add_child(hud)
	var pause: PauseMenu = hud.get_node("pause")
	assert(not pause.visible)

	Engine.time_scale = 0.05
	pause.open()
	assert(get_tree().paused)
	assert(Engine.time_scale == 1.0)

	pause.close()
	assert(not get_tree().paused)
	assert(Engine.time_scale == 0.05)

	Engine.time_scale = 1.0
	hud.free()


func test_every_fifth_tally_mark_strikes_through_the_four_before_it() -> void:
	var tally: ScoreTally = ScoreTally.new()
	var first: Array[Vector2] = tally.get_mark_stroke(0)
	var fourth: Array[Vector2] = tally.get_mark_stroke(3)
	var strike: Array[Vector2] = tally.get_mark_stroke(4)
	var next_bundle: Array[Vector2] = tally.get_mark_stroke(5)

	assert(strike[0].x < first[0].x)
	assert(strike[1].x > fourth[0].x)
	assert(next_bundle[0].x > strike[1].x)
	tally.free()
