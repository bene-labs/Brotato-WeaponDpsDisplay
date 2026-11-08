extends "res://ui/menus/shop/item_description.gd"

var col_a = "[color=#eae2b0]"
var col_b = "[/color]"

# only support single player for now - check only for player 1 and abort if playing coop
var PLAYER_IDX = 0

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
	elif item_data is WeaponData or \
	(item_data is ItemData and item_data.get_category() != Category.CHARACTER and \
	item_data.get_category() != Category.CHALLENGE):
		if RunData.is_coop_run:
			return
	
		var impact_text = get_dps_impact_text(item_data)
		if impact_text == "":
			return
		
		var _effect = get_effects()
		var line: EffectLine = effect_line.instance()
		_effect.add_child(line)
		line._display_special_text(impact_text, null)
	

func get_dps_impact_text(p_item_data: ItemParentData) -> String:
	var prev_dps := 0.0
	var new_dps := 0.0
	
	for weapon in RunData.get_player_weapons(0):
		var stats = weapon.stats
		if weapon.stats is RangedWeaponStats:
			stats = WeaponService.init_ranged_stats(stats, PLAYER_IDX, false, weapon._init_stats_args_data)
		else:
			stats = WeaponService.init_melee_stats(stats, PLAYER_IDX, weapon._init_stats_args_data)
		prev_dps += stats.get_dps()
		
	if prev_dps == 0:
		# doesn't make sense to compare by zero
		return ""
	
	if p_item_data.get_category() == Category.ITEM:
		RunData.add_item(p_item_data, PLAYER_IDX)
	elif p_item_data.get_category() == Category.WEAPON:
		RunData.add_weapon(p_item_data, PLAYER_IDX)
	
	for weapon in RunData.get_player_weapons(0):
		var stats = weapon.stats
		if weapon.stats is RangedWeaponStats:
			stats = WeaponService.init_ranged_stats(stats, PLAYER_IDX, false, weapon._init_stats_args_data)
		else:
			stats = WeaponService.init_melee_stats(stats, PLAYER_IDX, weapon._init_stats_args_data)
		
		new_dps += stats.get_dps()
	
	if p_item_data.get_category() == Category.ITEM:
		RunData.remove_item(p_item_data, PLAYER_IDX, true, false)
	elif p_item_data.get_category() == Category.WEAPON:
		var idx = RunData.get_player_weapons_ref(0).size() - 1
		RunData.remove_weapon_by_index(idx, PLAYER_IDX)
	
	RunData._emit_stats_updated()
	
	if new_dps == prev_dps:
		return ""
	
	var signed_col_a = get_signed_col_a(new_dps, prev_dps)
	var difference_str = ("+" if new_dps > prev_dps else "") + \
			str(stepify((new_dps - prev_dps) / prev_dps * 100, 0.01))
	var text = col_a + tr("DPS_IMPACT") + ": " + col_b
	text += signed_col_a + difference_str + "%" + col_b
	return text
	
func get_signed_col_a(value: float, base_value: float) -> String:
	var col_pos_a = "[color=#"+ ProgressData.settings.color_positive +"]"
	var col_neutral_a = "[color=white]"
	var col_neg_a = "[color=#"+ ProgressData.settings.color_negative +"]"
	if value > base_value: return col_pos_a
	elif value == base_value: return col_neutral_a
	else: return col_neg_a


func get_init_a() -> String:

	return " [color=#555555]| "
