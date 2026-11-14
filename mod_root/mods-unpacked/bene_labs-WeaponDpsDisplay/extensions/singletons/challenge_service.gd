extends "res://singletons/challenge_service.gd"

var checks_paused := false

func check_stat_challenges(player_index: int) -> void:
	if checks_paused:
		return
	.check_stat_challenges(player_index)
