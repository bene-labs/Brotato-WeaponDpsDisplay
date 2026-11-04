extends "res://ui/menus/shop/shop_item.gd"

var col_a = "[color=#eae2b0]"
var col_b = "[/color]"

func set_shop_item(p_item_data: ItemParentData, p_wave_value: int = RunData.current_wave) -> void:
	.set_shop_item(p_item_data, p_wave_value)
	
	if RunData.is_coop_run:
		return
	
	
	var impact_text = get_dps_impact_text(p_item_data)
	if impact_text == "":
		return
	
	var _effect = _item_description.get_effects()
	var line: EffectLine = _item_description.effect_line.instance()
	_effect.add_child(line)
	line._display_special_text(impact_text, null)
	

func get_dps_impact_text(p_item_data: ItemParentData) -> String:
	var prev_dps := 0.0
	var new_dps := 0.0
	
	for weapon in RunData.get_player_weapons(0):
		var stats = weapon.stats
		if weapon.stats is RangedWeaponStats:
			stats = WeaponService.init_ranged_stats(stats, player_index, false, weapon._init_stats_args_data)
		else:
			stats = WeaponService.init_melee_stats(stats, player_index, weapon._init_stats_args_data)
		prev_dps += stats.get_dps()
	
	if p_item_data.get_category() == Category.ITEM:
		RunData.add_item(p_item_data, 0)
	elif p_item_data.get_category() == Category.WEAPON:
		RunData.add_weapon(p_item_data, 0)
	
	for weapon in RunData.get_player_weapons(0):
		var stats = weapon.stats
		if weapon.stats is RangedWeaponStats:
			stats = WeaponService.init_ranged_stats(stats, player_index, false, weapon._init_stats_args_data)
		else:
			stats = WeaponService.init_melee_stats(stats, player_index, weapon._init_stats_args_data)
		
		new_dps += stats.get_dps()
	
	if p_item_data.get_category() == Category.ITEM:
		RunData.remove_item(p_item_data, 0)
	elif p_item_data.get_category() == Category.WEAPON:
		RunData.remove_weapon(p_item_data, 0)
	
	RunData._emit_stats_updated()
	
	if new_dps == prev_dps:
		return ""
	
	var signed_col_a = get_signed_col_a(new_dps, prev_dps)
	var difference_str = ("+" if new_dps > prev_dps else "") + \
			str(stepify((new_dps - prev_dps) / prev_dps * 100, 0.01))
	print(prev_dps, " => ", new_dps)
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
