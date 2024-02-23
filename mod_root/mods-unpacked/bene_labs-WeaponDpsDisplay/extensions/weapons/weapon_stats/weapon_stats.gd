extends "res://weapons/weapon_stats/weapon_stats.gd"

# Relevant efects
var pierces_on_crit = 0
var bounces_on_crit = 0
var projectiles_on_impact_stats = null
var atk_speed_override = null

# Vars needed to init new stats
var weapon_id : String
var sets : Array
var effects : Array
var is_structure : bool

func set_creation_data(weapon_id:String = "", sets:Array = [], effects:Array = [], is_structure:bool = false):
	self.weapon_id = weapon_id
	self.sets = sets
	self.effects = effects
	self.is_structure = is_structure

func set_effects(effects : Array):
	for effect in effects:
		match effect.key.to_lower():
			"effect_pierce_on_crit":
				pierces_on_crit = effect.value
			"effect_bounce_on_crit":
				bounces_on_crit = effect.value
			"effect_projectiles_on_hit", "effect_slow_projectiles_on_hit", "effect_lightning_on_hit":
				projectiles_on_impact_stats = effect.weapon_stats
				projectiles_on_impact_stats.nb_projectiles = effect.value


func get_text(base_stats: Resource) -> String:
	var text = .get_text(base_stats)
	var base_dps = get_base_dps(base_stats)

	text += "\n" + Text.text("STAT_FORMATTED", [get_col_a() + tr("WEAPON_DPS") + col_b, \
			get_dps_text(base_dps)])
	
	var stand_still_dps = try_get_stand_still_dps(base_stats)
	if stand_still_dps:
		text += "\n" + Text.text("STAT_FORMATTED", [get_col_a() + tr("STAND_STILL_DPS") + col_b, \
				get_signed_col_a(stand_still_dps, get_dps()) + str(stand_still_dps) + col_b])
	
	var burn_dps_per_stack = get_burning_dps_pet_stack(self)
	var max_burn_dps = get_max_burning_dps(self)
	if burn_dps_per_stack > 0:
		text += "\n" + Text.text("STAT_FORMATTED", [get_col_a() + tr("BURN_STACK_DPS") + col_b, \
				get_signed_col_a(1, 0) + str(burn_dps_per_stack) + col_b])
		text += "\n" + Text.text("STAT_FORMATTED", [get_col_a() + tr("BURN_MAX_DPS") + col_b, \
				get_signed_col_a(1, 0) + str(max_burn_dps) + col_b])
	return text


func get_base_dps_text(base_stats: Resource) -> String:
	var a = get_signed_col_a(0, 0)
	var text = a + str(get_base_dps(base_stats))
	return text


func get_dps_text(base_dps : float) -> String:
	var dps = get_dps() if RunData.effects["can_attack_while_moving"] or \
			 (is_instance_valid(TempStats.player) and TempStats.player.not_moving_bonuses_applied) else 0.0
	var a = get_signed_col_a(dps, base_dps)
	var difference_str = ("+" if dps > base_dps else "") + \
			str(stepify((dps - base_dps) / base_dps * 100, 0.01))
	var text = a + str(dps) + col_b
	if dps != base_dps:
		text += get_init_a() + str(base_dps) + col_b
		text += " (" + a + difference_str + "%" + col_b + ")"  
	return text


func try_get_stand_still_dps(base_stats):
	if RunData.effects["temp_stats_while_not_moving"].size() == 0:
		return false
	if is_instance_valid(TempStats.player) and TempStats.player.not_moving_bonuses_applied:
		return get_dps()
	
	for temp_stat_while_not_moving in RunData.effects["temp_stats_while_not_moving"]:
		if temp_stat_while_not_moving[0] in RunData.effects:
			RunData.effects[temp_stat_while_not_moving[0]] += temp_stat_while_not_moving[1]
		else:
			RunData.effects[temp_stat_while_not_moving[0]] = temp_stat_while_not_moving[1]

	var stand_still_dps = \
			(WeaponService.init_ranged_stats(base_stats, weapon_id, sets, effects, is_structure) \
			if base_stats is RangedWeaponStats else \
			WeaponService.init_melee_stats(base_stats, weapon_id, sets, effects, is_structure) \
			).get_dps()
	
	for temp_stat_while_not_moving in RunData.effects["temp_stats_while_not_moving"]:
		RunData.effects[temp_stat_while_not_moving[0]] -= temp_stat_while_not_moving[1]
	
	return stand_still_dps if stand_still_dps != get_dps() else false


func get_average_atk_speed(stats: Resource):
	var atk_speed = stats.atk_speed_override if stats.atk_speed_override else stats.get_cooldown_value(stats)
	if stats.additional_cooldown_every_x_shots > 0:
		var additional_cooldown_stats = stats.duplicate()
		additional_cooldown_stats.cooldown *= stats.additional_cooldown_multiplier
		var additional_atk_speed = additional_cooldown_stats.get_cooldown_value(additional_cooldown_stats)
		atk_speed = (atk_speed * (stats.additional_cooldown_every_x_shots - 1.0) + \
				additional_atk_speed) / stats.additional_cooldown_every_x_shots
	return atk_speed


func get_dps(extra_damage : int = 0) -> float:
	var atk_speed = get_average_atk_speed(self)
	damage += extra_damage
	var dps = stepify(get_average_damage(self) / atk_speed, 0.01)
	
	if projectiles_on_impact_stats != null:
		var scale_damage = WeaponService.get_scaling_stats_value(projectiles_on_impact_stats.scaling_stats)
		projectiles_on_impact_stats.atk_speed_override = get_cooldown_value(self)
		dps += projectiles_on_impact_stats.get_dps(scale_damage)
	damage -= extra_damage
	return dps


func get_base_dps(base_stats: Resource) -> float:
	var atk_speed = get_average_atk_speed(base_stats)
	var base_dps = stepify(get_average_damage(base_stats) / atk_speed, 0.01)

	if projectiles_on_impact_stats != null:
		projectiles_on_impact_stats.atk_speed_override = get_cooldown_value(base_stats)
		base_dps += projectiles_on_impact_stats.get_dps()
	return base_dps


func get_average_damage(stats: Resource) -> float:
	var dmg = stats.damage
	
	if min(1.0, stats.crit_chance) > 0:
		dmg = dmg * (1.0 - min(1.0, stats.crit_chance)) + round(dmg * stats.crit_damage) * min(1.0, stats.crit_chance)
	if stats is RangedWeaponStats:
		var bounce_damage : float = stats.damage
		for i in range(stats.bounce):
			bounce_damage = int(bounce_damage - bounce_damage * stats.bounce_dmg_reduction)
			dmg += max(1, bounce_damage * (1.0 - min(1.0, stats.crit_chance)) + \
					round(bounce_damage * stats.crit_damage) * min(1.0, stats.crit_chance))
		if bounces_on_crit > 0:
			var on_crit_bounce_damage = bounce_damage
			for i in range(bounces_on_crit):
				on_crit_bounce_damage = int(on_crit_bounce_damage - on_crit_bounce_damage * \
						stats.bounce_dmg_reduction)
				dmg += max(1, round(on_crit_bounce_damage * stats.crit_damage) * min(1.0, stats.crit_chance))
			bounce_damage = bounce_damage - bounce_damage * (stats.bounce_dmg_reduction * min(1.0, stats.crit_chance))
		
		var pierce_damage : float = bounce_damage
		for i in range(stats.piercing):
			pierce_damage = int(pierce_damage - pierce_damage * stats.piercing_dmg_reduction)
			dmg += max(1, pierce_damage * (1.0 - min(1.0, stats.crit_chance)) + \
					round(pierce_damage * stats.crit_damage) * min(1.0, stats.crit_chance))
		var on_crit_pierce_damage = pierce_damage
		for i in range(pierces_on_crit):
			on_crit_pierce_damage = int(on_crit_pierce_damage - on_crit_pierce_damage * \
					stats.piercing_dmg_reduction)
			dmg += max(1, round(on_crit_pierce_damage * stats.crit_damage) * min(1.0, stats.crit_chance))
		
		dmg *= stats.nb_projectiles
	return dmg


func get_burning_dps_pet_stack(stats: Resource) -> float:
	var burning = stats.burning_data
	var burn_speed = 1.0 - (RunData.effects["burning_cooldown_reduction"] / 100.0)
	var atk_speed = get_average_atk_speed(stats)
	var burn_damage_per_second = burning.damage / burn_speed if burning.chance > 0.0 else 0.0
	
	return stepify(burn_damage_per_second, 0.01)


# The result from this is crazy high, but this is due to it being extremly unlike to actually get close to the max burn dps
# I might still change this later, not sure how helpful it really is...
func get_max_burning_dps(stats: Resource) -> float:
	var burning = stats.burning_data
	var burn_speed = 1.0 - (RunData.effects["burning_cooldown_reduction"] / 100.0)
	var atk_speed = get_average_atk_speed(stats)
	var new_burn_damage_per_second = min(1.0, burning.chance) * burning.damage / atk_speed / burn_speed
	new_burn_damage_per_second *= 1 + burning.spread
	if stats is RangedWeaponStats:
		new_burn_damage_per_second *= 1 + stats.bounce
		new_burn_damage_per_second *= 1 + stats.piercing
		new_burn_damage_per_second *= stats.nb_projectiles
	# Burn duration is accounted for as it might cause multiple stacks of burn damage to go off in the same second
	return stepify(new_burn_damage_per_second + (burning.duration - atk_speed) * new_burn_damage_per_second, 0.01)
