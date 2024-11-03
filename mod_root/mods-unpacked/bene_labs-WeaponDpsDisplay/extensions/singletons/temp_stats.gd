extends "res://singletons/temp_stats.gd"

var player_not_moving_bonuses_applied_lookup = [false, false, false, false]


func set_player_not_moving_bonuses_applied(player_index: int, value: bool)->void:
	player_not_moving_bonuses_applied_lookup[player_index] = value


func get_player_not_moving_bonuses_applied(player_index)->bool:
	return player_not_moving_bonuses_applied_lookup[player_index]
