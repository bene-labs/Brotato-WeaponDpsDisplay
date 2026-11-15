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
		var text = col_a + tr("DPS") + ": " + col_b + a + str(dps) + col_b
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
	if p_item_data.my_id == "item_axolotl":
		return ""
	
	
	var prev_dps := _calc_total_weapons_dps()
	
	if prev_dps == 0:
		# doesn't make sense to compare by zero
		return ""
	
	var new_dps := 0.0
	var is_weapon := p_item_data.get_category() == Category.WEAPON
	var weapons_ref = RunData.get_player_weapons_ref(PLAYER_IDX)
	
	ChallengeService.checks_paused = true
	
	RunData.apply_item_effects(p_item_data, PLAYER_IDX)
	RunData.add_item_to_item_count(p_item_data)
	
	if is_weapon:
		weapons_ref.append(p_item_data)
		RunData.update_additional_weapon_bonuses(PLAYER_IDX)
	
	RunData.update_item_related_effects(PLAYER_IDX)
	
	new_dps = _calc_total_weapons_dps()
	
	#if is_weapon:
	#	new_dps += _calc_single_weapon_dps(p_item_data, PLAYER_IDX)
	
	if is_weapon:
		if len(weapons_ref) > 0 and weapons_ref[-1] == p_item_data:
			weapons_ref.pop_back()
		RunData.update_additional_weapon_bonuses(PLAYER_IDX)
	
	_decrement_item_count(p_item_data.my_id)
	RunData.unapply_item_effects(p_item_data, PLAYER_IDX)
	RunData.update_item_related_effects(PLAYER_IDX)
	
	ChallengeService.checks_paused = false
	
	if new_dps == prev_dps:
		return ""
	
	var signed_col_a = get_signed_col_a(new_dps, prev_dps)
	var difference_str = ("+" if new_dps > prev_dps else "") + \
			str(stepify((new_dps - prev_dps) / prev_dps * 100, 0.01))
	var text = col_a + tr("DPS_IMPACT") + ": " + col_b
	text += signed_col_a + difference_str + "%" + col_b
	return text


func _decrement_item_count(item_id: String) -> void:
	if not ProgressData.items_bought.has(item_id):
		return
	if ProgressData.items_bought[item_id] > 1:
		ProgressData.items_bought[item_id] -= 1
	else:
		ProgressData.items_bought.erase(item_id)


func _calc_total_weapons_dps(player_idx: int = PLAYER_IDX) -> float:
	var total := 0.0
	for weapon in RunData.get_player_weapons(player_idx):
		total += _calc_single_weapon_dps(weapon, player_idx)
	return total


func _calc_single_weapon_dps(weapon_data: WeaponData, player_idx: int = PLAYER_IDX) -> float:
	var stats = weapon_data.stats
	if weapon_data.stats is RangedWeaponStats:
		stats = WeaponService.init_ranged_stats(stats, player_idx, false, weapon_data._init_stats_args_data)
	else:
		stats = WeaponService.init_melee_stats(stats, player_idx, weapon_data._init_stats_args_data)
	return stats.get_dps()


func get_signed_col_a(value: float, base_value: float) -> String:
	var col_pos_a = "[color=#"+ ProgressData.settings.color_positive +"]"
	var col_neutral_a = "[color=white]"
	var col_neg_a = "[color=#"+ ProgressData.settings.color_negative +"]"
	if value > base_value: return col_pos_a
	elif value == base_value: return col_neutral_a
	else: return col_neg_a


func get_init_a() -> String:

	return " [color=#555555]| "
