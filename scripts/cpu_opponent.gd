class_name CpuOpponent
extends RefCounted

## Plays player two when the fight is against the computer.
##
## It has no read on the human at all: it waits a human-looking beat and then
## commits to any direction still on the table. Against a uniform guess no
## pattern helps or hurts you, so it is exactly as hard to out-think as a
## stranger, which is what a shadow ought to be.

## Always well inside Game.TURN_TIME, so the computer never forfeits by
## hesitating and never locks in so fast it feels like it's reading your keys.
const COMMIT_DELAY_MIN := 0.45
const COMMIT_DELAY_MAX := 1.7

var random := RandomNumberGenerator.new()
var commit_at := 0.0


func _init() -> void:
	random.randomize()


func begin_turn() -> void:
	commit_at = random.randf_range(COMMIT_DELAY_MIN, COMMIT_DELAY_MAX)


## -1 (Game.Direction.NONE) while still "thinking", then one available direction.
func choose(elapsed: float, available: Array[int]) -> int:
	if elapsed < commit_at or available.is_empty():
		return -1

	return available[random.randi_range(0, available.size() - 1)]
