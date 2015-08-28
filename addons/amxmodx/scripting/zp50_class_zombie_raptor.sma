/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Zombie: Raptor -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Raptor Zombie Attributes
new const zombieclass2_name[] = "Raptor Zombie"
new const zombieclass2_info[] = "HP-- Speed++ Knockback++"
new const zombieclass2_models[][] = { "zombie_source" }
new const zombieclass2_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass2_health = 900
const Float:zombieclass2_speed = 0.90
const Float:zombieclass2_gravity = 1.0
const Float:zombieclass2_knockback = 1.5

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Raptor", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass2_name, zombieclass2_info, zombieclass2_health, zombieclass2_speed, zombieclass2_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass2_knockback)
	for (index = 0; index < sizeof zombieclass2_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass2_models[index])
	for (index = 0; index < sizeof zombieclass2_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass2_clawmodels[index])
}
