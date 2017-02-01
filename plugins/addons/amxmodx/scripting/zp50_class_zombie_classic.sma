/*================================================================================
	
	-----------------------------------
	-*- [ZP] Class: Zombie: Classic -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Classic Zombie Attributes
new const zombieclass1_name[] = "Classic Zombie"
new const zombieclass1_info[] = "=Balanced="
new const zombieclass1_models[][] = { "zombie_source" }
new const zombieclass1_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass1_health = 1800
const Float:zombieclass1_speed = 0.75
const Float:zombieclass1_gravity = 1.0
const Float:zombieclass1_knockback = 1.0

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Classic", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass1_name, zombieclass1_info, zombieclass1_health, zombieclass1_speed, zombieclass1_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass1_knockback)
	for (index = 0; index < sizeof zombieclass1_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass1_models[index])
	for (index = 0; index < sizeof zombieclass1_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass1_clawmodels[index])
}
