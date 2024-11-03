extends "res://singletons/weapon_service.gd"

func init_melee_stats(from_stats: MeleeWeaponStats, player_index: int, args: = WeaponServiceInitStatsArgs.new())->MeleeWeaponStats:
	var new_stats = .init_melee_stats(from_stats, player_index, args)
	new_stats.set_effects(args.effects)
	new_stats.set_creation_data(args.weapon_id, args.sets, args.effects, false)
	return new_stats

func init_ranged_stats(from_stats: RangedWeaponStats, player_index: int, is_special_spawn: = false, args: = WeaponServiceInitStatsArgs.new())->RangedWeaponStats:
	var new_stats = .init_ranged_stats(from_stats, player_index, is_special_spawn, args)
	new_stats.set_effects(args.effects)
	new_stats.set_creation_data(args.weapon_id, args.sets, args.effects, is_special_spawn)
	return new_stats
