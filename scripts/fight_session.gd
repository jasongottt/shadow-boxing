class_name FightSession
extends Node

## What carries from one fight to the next: who is playing, how many walls each
## player has put down, and who throws the first punch next time.
##
## A rematch keeps all of it. Picking a mode from the main menu starts over.

const PLAYER_ONE := 1
const PLAYER_TWO := 2

var versus_cpu := false
var wins := {PLAYER_ONE: 0, PLAYER_TWO: 0}

## Whoever attacks first has the easier fight, so the loser of each fight gets
## to open the next one rather than player one swinging first forever.
var opening_player := PLAYER_ONE


func start(new_versus_cpu: bool) -> void:
	versus_cpu = new_versus_cpu
	wins = {PLAYER_ONE: 0, PLAYER_TWO: 0}
	opening_player = PLAYER_ONE


func record_win(winner: int) -> void:
	wins[winner] = get_wins(winner) + 1
	opening_player = PLAYER_TWO if winner == PLAYER_ONE else PLAYER_ONE


func get_wins(player: int) -> int:
	return wins.get(player, 0)
