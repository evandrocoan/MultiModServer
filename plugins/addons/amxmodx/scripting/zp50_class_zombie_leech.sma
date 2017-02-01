/*================================================================================
	
	---------------------------------
	-*- [ZP] Class: Zombie: Leech -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Zombie Classes file
new const ZP_ZOMBIECLASSES_FILE[] = "zp_zombieclasses.ini"

// Leech Zombie Attributes
new const zombieclass5_name[] = "Leech Zombie"
new const zombieclass5_info[] = "HP- Knockback+ Leech++"
new const zombieclass5_models[][] = { "zombie_source" }
new const zombieclass5_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass5_health = 1300
const Float:zombieclass5_speed = 0.75
const Float:zombieclass5_gravity = 1.0
const Float:zombieclass5_knockback = 1.25
new zombieclass5_hp_reward = 200 // extra hp for infections/kills

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Leech", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass5_name, zombieclass5_info, zombieclass5_health, zombieclass5_speed, zombieclass5_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass5_knockback)
	for (index = 0; index < sizeof zombieclass5_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass5_models[index])
	for (index = 0; index < sizeof zombieclass5_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass5_clawmodels[index])
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	// HP rewarded for infection/kills
	if (!amx_load_setting_int(ZP_ZOMBIECLASSES_FILE, zombieclass5_name, "HP REWARD", zombieclass5_hp_reward))
		amx_save_setting_int(ZP_ZOMBIECLASSES_FILE, zombieclass5_name, "HP REWARD", zombieclass5_hp_reward)
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Infected by a valid attacker?
	if (is_user_alive(attacker) && attacker != id && zp_core_is_zombie(attacker))
	{
		// Leech Zombie infection hp bonus
		if (zp_class_zombie_get_current(attacker) == g_ZombieClassID)
			set_user_health(attacker, get_user_health(attacker) + zombieclass5_hp_reward)
	}
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Killed by a non-player entity or self killed
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	// Leech Zombie kill hp bonus
	if (zp_core_is_zombie(attacker) && zp_class_zombie_get_current(attacker) == g_ZombieClassID)
	{
		// Unless nemesis
		if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(attacker))
			set_user_health(attacker, get_user_health(attacker) + zombieclass5_hp_reward)
	}
}