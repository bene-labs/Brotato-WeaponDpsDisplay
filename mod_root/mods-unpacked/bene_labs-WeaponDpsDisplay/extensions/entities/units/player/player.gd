extends "res://entities/units/player/player.gd"

func check_not_moving_stats(movement: Vector2)->void :
	.check_not_moving_stats(movement)
	TempStats.set_player_not_moving_bonuses_applied(player_index, not_moving_bonuses_applied)
