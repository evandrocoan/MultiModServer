/*================================================================================
	
	----------------------------
	-*- [ZP] Zombie Features -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

new const bleeding_decals[] = { 99 , 107 , 108 , 184 , 185 , 186 , 187 , 188 , 189 }

new Array:g_bleeding_decals

#define TASK_BLOOD 100
#define ID_BLOOD (taskid - TASK_BLOOD)

#define CS_DEFAULT_FOV 90

new g_IsModCZ
new g_MsgSetFOV

new cvar_zombie_fov, cvar_zombie_silent, cvar_zombie_bleeding

public plugin_init()
{
	register_plugin("[ZP] Zombie Features", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgSetFOV = get_user_msgid("SetFOV")
	register_message(g_MsgSetFOV, "message_setfov")
	
	cvar_zombie_fov = register_cvar("zp_zombie_fov", "110")
	cvar_zombie_silent = register_cvar("zp_zombie_silent", "1")
	cvar_zombie_bleeding = register_cvar("zp_zombie_bleeding", "1")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	// Check if it's a CZ server
	new mymod[6]
	get_modname(mymod, charsmax(mymod))
	if (equal(mymod, "czero")) g_IsModCZ = 1
}

public plugin_precache()
{
	// Initialize arrays
	g_bleeding_decals = ArrayCreate(1, 1)
	
	// Load from external file
	amx_load_setting_int_arr(ZP_SETTINGS_FILE, "Zombie Decals", "DECALS", g_bleeding_decals)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_bleeding_decals) == 0)
	{
		for (index = 0; index < sizeof bleeding_decals; index++)
			ArrayPushCell(g_bleeding_decals, bleeding_decals[index])
		
		// Save to external file
		amx_save_setting_int_arr(ZP_SETTINGS_FILE, "Zombie Decals", "DECALS", g_bleeding_decals)
	}
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

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Remove bleeding task
	remove_task(victim+TASK_BLOOD)
}

public client_disconnect(id)
{
	// Remove bleeding task
	remove_task(id+TASK_BLOOD)
}

public message_setfov(msg_id, msg_dest, msg_entity)
{
	if (!is_user_alive(msg_entity) || !zp_core_is_zombie(msg_entity) || get_msg_arg_int(1) != CS_DEFAULT_FOV)
		return;
	
	set_msg_arg_int(1, get_msg_argtype(1), get_pcvar_num(cvar_zombie_fov))
}

public zp_fw_core_infect_post(id, attacker)
{
	// Set custom FOV?
	if (get_pcvar_num(cvar_zombie_fov) != CS_DEFAULT_FOV && get_pcvar_num(cvar_zombie_fov) != 0)
	{
		message_begin(MSG_ONE, g_MsgSetFOV, _, id)
		write_byte(get_pcvar_num(cvar_zombie_fov)) // angle
		message_end()
	}
	
	// Remove previous tasks
	remove_task(id+TASK_BLOOD)
	
	// Nemesis Class loaded?
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(id))
	{
		// Set silent footsteps?
		if (get_pcvar_num(cvar_zombie_silent))
			set_user_footsteps(id, 1)
		
		// Zombie bleeding?
		if (get_pcvar_num(cvar_zombie_bleeding))
			set_task(0.7, "zombie_bleeding", id+TASK_BLOOD, _, _, "b")
	}
	else
	{
		// Restore normal footsteps?
		if (get_pcvar_num(cvar_zombie_silent))
			set_user_footsteps(id, 0)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Restore FOV?
	if (get_pcvar_num(cvar_zombie_fov) != CS_DEFAULT_FOV && get_pcvar_num(cvar_zombie_fov) != 0)
	{
		message_begin(MSG_ONE, g_MsgSetFOV, _, id)
		write_byte(CS_DEFAULT_FOV) // angle
		message_end()
	}
	
	// Restore normal footsteps?
	if (get_pcvar_num(cvar_zombie_silent))
		set_user_footsteps(id, 0)
	
	// Remove bleeding task
	remove_task(id+TASK_BLOOD)
}

// Make zombies leave footsteps and bloodstains on the floor
public zombie_bleeding(taskid)
{
	// Only bleed when moving on ground
	if (!(pev(ID_BLOOD, pev_flags) & FL_ONGROUND) || fm_get_speed(ID_BLOOD) < 80)
		return;
	
	// Get user origin
	static Float:originF[3]
	pev(ID_BLOOD, pev_origin, originF)
	
	// If ducking set a little lower
	if (pev(ID_BLOOD, pev_bInDuck))
		originF[2] -= 18.0
	else
		originF[2] -= 36.0
	
	// Send the decal message
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(ArrayGetCell(g_bleeding_decals, random_num(0, ArraySize(g_bleeding_decals) - 1)) + (g_IsModCZ * 12)) // decal number (offsets +12 for CZ)
	message_end()
}

// Get entity's speed (from fakemeta_util)
stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}
