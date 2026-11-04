extends "res://ui/menus/shop/item_description.gd"

var col_a = "[color=#eae2b0]"
var col_b = "[/color]"

func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void :
	.set_item(item_data, player_index, item_count)
	
	if item_data is CharacterData:
		var dps = 0.0
		var base_dps = 0.0
		for weapon in RunData.get_player_weapons(player_index):
			var stats = weapon.stats
			if weapon.stats is RangedWeaponStats:
				stats = WeaponService.init_ranged_stats(stats, player_index, false, weapon._init_stats_args_data)
			else:
				stats = WeaponService.init_melee_stats(stats, player_index, weapon._init_stats_args_data)
			base_dps += weapon.stats.get_base_dps(weapon.stats)
			dps += stats.get_dps()
		
		var _effect = get_effects()
		var line: EffectLine = effect_line.instance()
		_effect.add_child(line)
		
		var a = get_signed_col_a(dps, base_dps)
		var difference_str = ("+" if dps > base_dps else "") + \
				str(stepify((dps - base_dps) / base_dps * 100, 0.01))
		var text = col_a + tr("TOTAL_DPS") + ": " + col_b + a + str(dps) + col_b
		if dps != base_dps:
			text += get_init_a() + str(base_dps) + col_b
			text += " (" + a + difference_str + "%" + col_b + ")"  
		
		line._display_special_text(text) 


func get_signed_col_a(value: float, base_value: float) -> String:
	var col_pos_a = "[color=#"+ ProgressData.settings.color_positive +"]"
	var col_neutral_a = "[color=white]"
	var col_neg_a = "[color=#"+ ProgressData.settings.color_negative +"]"
	if value > base_value: return col_pos_a
	elif value == base_value: return col_neutral_a
	else: return col_neg_a


func get_init_a() -> String:

	return " [color=#555555]| "
