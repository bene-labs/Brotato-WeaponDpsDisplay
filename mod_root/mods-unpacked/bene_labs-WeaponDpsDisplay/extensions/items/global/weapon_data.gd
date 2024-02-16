extends "res://singletons/weapon_service.gd"

func init_melee_stats(from_stats:MeleeWeaponStats = MeleeWeaponStats.new(), weapon_id:String = "", sets:Array = [], effects:Array = [], is_structure:bool = false)->MeleeWeaponStats:
	var new_stats = .init_melee_stats(from_stats, weapon_id, sets, effects, is_structure)
	new_stats.set_effects(effects)
	return new_stats

func init_ranged_stats(from_stats:RangedWeaponStats = RangedWeaponStats.new(), weapon_id:String = "", sets:Array = [], effects:Array = [], is_structure:bool = false)->RangedWeaponStats:
	var new_stats = .init_ranged_stats(from_stats, weapon_id, sets, effects, is_structure)
	new_stats.set_effects(effects)
	return new_stats
