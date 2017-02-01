/*================================================================================
	
	----------------------------------------------
	-*- [ZP] Biohazard Subplugin Compatibility -*-
	----------------------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
	TODO:
	- Bio 2.00 zombie classes support
	- Preinfect natives support
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <zp50_class_zombie>

enum _:TOTAL_FORWARDS
{
	FW_EVENT_INFECT = 0,
	FW_EVENT_INFECT2,
	FW_EVENT_GAMESTART,
	FW_EVENT_TEAMWIN
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_GameStarted
new CsTeams:g_winningteam

public plugin_init()
{
	// Name should be "Biohazard" for subplugins that check if BIO is enabled
	register_plugin("Biohazard", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_message(get_user_msgid("TextMsg"), 	"msg_textmsg")
	
	g_MaxPlayers = get_maxplayers()
	
	// Forwards
	g_Forwards[FW_EVENT_INFECT] = CreateMultiForward("event_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_EVENT_INFECT2] = CreateMultiForward("event_infect2", ET_IGNORE, FP_CELL)
	g_Forwards[FW_EVENT_GAMESTART] = CreateMultiForward("event_gamestart", ET_IGNORE)
	g_Forwards[FW_EVENT_TEAMWIN] = CreateMultiForward("event_teamwin", ET_IGNORE, FP_CELL)
}

public plugin_precache()
{
	// For subplugins that check if BIO is enabled
	register_cvar("bh_enabled", "1", FCVAR_SERVER|FCVAR_SPONLY)
}

public event_round_start()
{
	g_GameStarted = false
}

public msg_textmsg(msgid, dest, id)
{
	if (get_msg_arg_int(1) != 4)
		return PLUGIN_CONTINUE
	
	static txtmsg[25]
	get_msg_arg_string(2, txtmsg, 24)

	if(equal(txtmsg[1], "Terrorists_Win"))
		g_winningteam = CS_TEAM_T
	else if(equal(txtmsg[1], "Target_Saved") || equal(txtmsg[1], "CTs_Win"))
		g_winningteam = CS_TEAM_CT
	
	return PLUGIN_CONTINUE
}

public logevent_round_end()
{
	g_GameStarted = false
	
	if(g_winningteam > CS_TEAM_UNASSIGNED)
	{
		ExecuteForward(g_Forwards[FW_EVENT_TEAMWIN], g_ForwardResult, g_winningteam)
		g_winningteam = CS_TEAM_UNASSIGNED
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	ExecuteForward(g_Forwards[FW_EVENT_INFECT], g_ForwardResult, id, attacker)
	ExecuteForward(g_Forwards[FW_EVENT_INFECT2], g_ForwardResult, id)
}

public zp_fw_gamemodes_start(game_mode_id)
{
	g_GameStarted = true
	ExecuteForward(g_Forwards[FW_EVENT_GAMESTART], g_ForwardResult)
}

public plugin_natives()
{
	register_library("biohazardf")
	
	// Natives
	register_native("game_started", "native_game_started")
	register_native("is_game_started", "native_game_started")
	register_native("infect_user", "native_infect_user")
	register_native("cure_user", "native_cure_user")
	register_native("preinfect_user", "native_preinfect_user")
	register_native("is_user_zombie", "native_is_user_zombie")
	register_native("is_user_infected", "native_is_user_infected")
	register_native("get_user_class", "native_get_user_class")
	register_native("register_class", "native_register_class")
	register_native("set_class_pmodel", "native_set_class_pmodel")
	register_native("set_class_wmodel", "native_set_class_wmodel")
	register_native("get_class_id", "native_get_class_id")
	register_native("get_class_data", "native_get_class_data")
	register_native("set_class_data", "native_set_class_data")
	register_native("is_user_firstzombie", "native_is_user_firstzombie")
	register_native("firstzombie", "native_firstzombie")
}

public native_game_started(plugin_id, num_params)
{
	return g_GameStarted;
}

public native_infect_user(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_alive(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	if (!g_GameStarted)
		return false;
	
	if (attacker)
		return zp_core_infect(id, attacker);
	return zp_core_infect(id, id);
}

public native_cure_user(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_cure(id, id);
}

public native_preinfect_user(plugin_id, num_params)
{
	// Not implemented in ZP yet...
	return false;
}

public native_is_user_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return zp_core_is_zombie(id);
}

public native_is_user_infected(plugin_id, num_params)
{
	// Not implemented in ZP yet...
	return false;
}

public native_get_user_class(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return zp_class_zombie_get_current(id);
}

public native_register_class(plugin_id, num_params)
{
	// todo...
	return -1;
}

public native_set_class_pmodel(plugin_id, num_params)
{
	// todo...
	return false;
}

public native_set_class_wmodel(plugin_id, num_params)
{
	// todo...
	return false;
}

public native_get_class_id(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	return zp_class_zombie_get_id(name);
}

public native_get_class_data(plugin_id, num_params)
{
	// todo...
	return -1;
}

public native_set_class_data(plugin_id, num_params)
{
	// todo...
	return false;
}

public native_is_user_firstzombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	// This should also be returning true for preinfected, which is not implemented in ZP yet...
	return zp_core_is_first_zombie(id);
}

public native_firstzombie(plugin_id, num_params)
{
	// This should also be returning index of preinfected, which is not implemented in ZP yet...
	if (!g_GameStarted)
		return -1;
	
	new player
	for (player = 1; player <= g_MaxPlayers; player++)
	{
		if (is_user_alive(player) && zp_core_is_first_zombie(player))
			return player;
	}
	return -1;
}