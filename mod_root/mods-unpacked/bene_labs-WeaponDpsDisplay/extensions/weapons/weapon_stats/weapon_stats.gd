extends "res://weapons/weapon_stats/weapon_stats.gd"


var pierces_on_crit = 0
var bounces_on_crit = 0
var projectiles_on_impact_stats = null
var atk_speed_override = null


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
	
	var burn_dps = get_burning_dps(self)
	if burn_dps > 0:
		text += "\n" + Text.text("STAT_FORMATTED", [get_col_a() + tr("WEAPON_BURN_DPS") + col_b, \
				get_signed_col_a(1, 0) + str(burn_dps) + col_b])
	return text


func get_base_dps_text(base_stats: Resource) -> String:
	var a = get_signed_col_a(0, 0)
	var text = a + str(get_base_dps(base_stats))
	return text


func get_dps_text(base_dps : float) -> String:
	var dps = get_dps()
	var a = get_signed_col_a(dps, base_dps)
	var difference_str = ""
	if dps >= base_dps:
		difference_str = "+" + str(stepify((dps - base_dps) / base_dps * 100, 0.01))
	else:
		difference_str = "-" + str(stepify((base_dps - dps) / dps * 100, 0.01))
		difference_str = "-" + str(stepify((base_dps - dps) / dps * 100, 0.01))
	var text = a + str(dps) + col_b
	if (dps != base_dps):
		text += get_init_a() + str(base_dps) + col_b
	text += " (" + a + difference_str + "%" + col_b + ")"  

	return text


func get_dps(extra_damage : int = 0) -> float:
	var atk_speed = atk_speed_override if atk_speed_override else get_cooldown_value(self)
	damage += extra_damage
	
	if additional_cooldown_every_x_shots > 0:
		var additional_cooldown_stats = self.duplicate()
		additional_cooldown_stats.cooldown *= additional_cooldown_multiplier
		var additional_atk_speed = additional_cooldown_stats.get_cooldown_value(additional_cooldown_stats)
		atk_speed = (atk_speed * (additional_cooldown_every_x_shots - 1.0) + additional_atk_speed) \
				/ additional_cooldown_every_x_shots
	var dps = stepify(get_average_damage(self) / atk_speed, 0.01)
	if projectiles_on_impact_stats != null:
		var scale_damage = WeaponService.get_scaling_stats_value(projectiles_on_impact_stats.scaling_stats)
		projectiles_on_impact_stats.atk_speed_override = get_cooldown_value(self)
		dps += projectiles_on_impact_stats.get_dps(scale_damage)
	damage -= extra_damage
	return dps


func get_base_dps(base_stats: Resource) -> float:
	var atk_speed =  get_base_cooldown_value(base_stats)
	if base_stats.additional_cooldown_every_x_shots > 0:
		var additional_cooldown_stats = base_stats.duplicate()
		additional_cooldown_stats.cooldown *= additional_cooldown_multiplier
		var additional_atk_speed = additional_cooldown_stats.get_cooldown_value(additional_cooldown_stats)
		atk_speed = (atk_speed * (base_stats.additional_cooldown_every_x_shots - 1.0) + additional_atk_speed) \
				/ base_stats.additional_cooldown_every_x_shots
	
	var base_dps = stepify(get_average_damage(base_stats) / atk_speed, 0.01)
	if projectiles_on_impact_stats != null:
		projectiles_on_impact_stats.atk_speed_override = get_cooldown_value(base_stats)
		base_dps += projectiles_on_impact_stats.get_dps()
	return base_dps


func get_average_damage(stats: Resource) -> float:
	var dmg = stats.damage
	
	if stats is RangedWeaponStats:
		var bounce_damage = dmg
		for i in range(stats.bounce):
			bounce_damage -= bounce_damage * stats.bounce_dmg_reduction
			dmg += max(1, bounce_damage)
		var on_crit_bounce_damage = bounce_damage
		if bounces_on_crit > 0:
			for i in range(bounces_on_crit):
				on_crit_bounce_damage -= on_crit_bounce_damage * stats.bounce_dmg_reduction
				dmg += max(1, on_crit_bounce_damage)
			bounce_damage = bounce_damage - bounce_damage * (stats.piercing_dmg_reduction * stats.crit_chance)
		var pierce_damage = bounce_damage - bounce_damage * stats.piercing_dmg_reduction
		for i in range(stats.piercing):
			dmg += max(1, pierce_damage)
			pierce_damage -= pierce_damage * stats.piercing_dmg_reduction
		for i in range(pierces_on_crit):
			dmg += max(1, pierce_damage)
			pierce_damage -= pierce_damage * stats.piercing_dmg_reduction
		dmg *= stats.nb_projectiles
	if stats.crit_chance > 0:
		dmg = dmg * (1 - stats.crit_chance) + round(dmg * stats.crit_damage) * stats.crit_chance
	return dmg


func get_burning_dps(stats: Resource) -> float:
	var burning = stats.burning_data
	var cooldown = get_cooldown_value(stats)
	var new_burn_damage_per_second = burning.chance * burning.damage / cooldown
	
	if stats is RangedWeaponStats:
		new_burn_damage_per_second *= stats.nb_projectiles
	# Burn duration is accounted for as it might cause multiple stacks of burn damage to go off in the same second
	return stepify(new_burn_damage_per_second + (burning.duration - cooldown) * new_burn_damage_per_second, 0.01)
