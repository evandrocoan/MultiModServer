/*================================================================================
	
	--------------------------------
	-*- [ZP] Class: Zombie: Rage -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Rage Zombie Attributes
new const zombieclass6_name[] = "Rage Zombie"
new const zombieclass6_info[] = "HP+ Speed+ Radioactivity++"
new const zombieclass6_models[][] = { "zombie_source" }
new const zombieclass6_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass6_health = 2250
const Float:zombieclass6_speed = 0.80
const Float:zombieclass6_gravity = 1.0
const Float:zombieclass6_knockback = 1.0

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Rage", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass6_name, zombieclass6_info, zombieclass6_health, zombieclass6_speed, zombieclass6_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass6_knockback)
	for (index = 0; index < sizeof zombieclass6_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass6_models[index])
	for (index = 0; index < sizeof zombieclass6_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass6_clawmodels[index])
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
	// Rage Zombie glow
	if (zp_class_zombie_get_current(id) == g_ZombieClassID)
	{
		// Apply custom glow, unless nemesis
		if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(id))
			set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 15)
	}
}

public zp_fw_core_infect(id, attacker)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zp_class_zombie_get_current(id) == g_ZombieClassID)
		set_user_rendering(id)
}

public zp_fw_core_cure(id, attacker)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zp_class_zombie_get_current(id) == g_ZombieClassID)
		set_user_rendering(id)
}

public client_disconnect(id)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zp_class_zombie_get_current(id) == g_ZombieClassID)
		set_user_rendering(id)
}