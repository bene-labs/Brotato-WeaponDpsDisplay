extends Node

const MOD_DIR = "bene_labs-WeaponDpsDisplay/"
const MENUSTRING_LOG = "bene_labs-WeaponDpsDisplay"

func _init(modLoader = ModLoader):
	ModLoaderUtils.log_info("Init", MENUSTRING_LOG)

	modLoader.install_script_extension(\
		"res://mods-unpacked/bene_labs-WeaponDpsDisplay/extensions/weapons/weapon_stats/weapon_stats.gd")

	var dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR
	ModLoaderMod.add_translation(dir + "translation/weapon_dps_display_text.de.translation")
	ModLoaderMod.add_translation(dir + "translation/weapon_dps_display_text.en.translation")


func _ready():
	ModLoaderUtils.log_info("Ready", MENUSTRING_LOG)
