/*================================================================================
	
	------------------------------
	-*- [ZP] Objective Remover -*-
	------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_core_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

new const objective_ents[][] = { "func_bomb_target" , "info_bomb_target" , "info_vip_start" , "func_vip_safetyzone" , "func_escapezone" , "hostage_entity" , "monster_scientist" , "func_hostage_rescue" , "info_hostage_rescue" }

#define CLASSNAME_MAX_LENGTH 32

new Array:g_objective_ents

new g_fwSpawn
new g_fwPrecacheSound

public plugin_init()
{
	register_plugin("[ZP] Objective Remover", ZP_VERSION_STRING, "ZP Dev Team")
	unregister_forward(FM_Spawn, g_fwSpawn)
	unregister_forward(FM_PrecacheSound, g_fwPrecacheSound)
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_message(get_user_msgid("Scenario"), "message_scenario")
	register_message(get_user_msgid("HostagePos"), "message_hostagepos")
}

public plugin_precache()
{
	// Initialize arrays
	g_objective_ents = ArrayCreate(CLASSNAME_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Objective Entities", "OBJECTIVES", g_objective_ents)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_objective_ents) == 0)
	{
		for (index = 0; index < sizeof objective_ents; index++)
			ArrayPushString(g_objective_ents, objective_ents[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Objective Entities", "OBJECTIVES", g_objective_ents)
	}
	
	// Fake Hostage (to force round ending)
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	if (pev_valid(ent))
	{
		engfunc(EngFunc_SetOrigin, ent, Float:{8192.0,8192.0,8192.0})
		dllfunc(DLLFunc_Spawn, ent)
	}
	
	// Prevent objective entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
	// Prevent hostage sounds from being precached
	g_fwPrecacheSound = register_forward(FM_PrecacheSound, "fw_PrecacheSound")
}

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32], objective[32], size = ArraySize(g_objective_ents)
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	new index
	for (index = 0; index < size; index++)
	{
		ArrayGetString(g_objective_ents, index, objective, charsmax(objective))
		
		if (equal(classname, objective))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Sound Precache Forward
public fw_PrecacheSound(const sound[])
{
	// Block all those unneeeded hostage sounds
	if (equal(sound, "hostage", 7))
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Block all those unneeeded hostage sounds
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Block hostage HUD display
public message_scenario()
{
	if (get_msg_args() > 1)
	{
		new sprite[8]
		get_msg_arg_string(2, sprite, charsmax(sprite))
		
		if (equal(sprite, "hostage"))
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

// Block hostages from appearing on radar
public message_hostagepos()
{
	return PLUGIN_HANDLED;
}
