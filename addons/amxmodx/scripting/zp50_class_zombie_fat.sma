/*================================================================================
	
	-------------------------------
	-*- [ZP] Class: Zombie: Fat -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Big Zombie Attributes
new const zombieclass4_name[] = "Fat Zombie"
new const zombieclass4_info[] = "HP++ Speed- Knockback--"
new const zombieclass4_models[][] = { "zombie_source" }
new const zombieclass4_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass4_health = 2700
const Float:zombieclass4_speed = 0.65
const Float:zombieclass4_gravity = 1.0
const Float:zombieclass4_knockback = 0.5

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Fat", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass4_name, zombieclass4_info, zombieclass4_health, zombieclass4_speed, zombieclass4_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass4_knockback)
	for (index = 0; index < sizeof zombieclass4_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass4_models[index])
	for (index = 0; index < sizeof zombieclass4_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass4_clawmodels[index])
}
