/*================================================================================
	
	------------------------
	-*- [ZP] Core/Engine -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core_const>

#define MAXPLAYERS 32

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_INFECT_PRE = 0,
	FW_USER_INFECT,
	FW_USER_INFECT_POST,
	FW_USER_CURE_PRE,
	FW_USER_CURE,
	FW_USER_CURE_POST,
	FW_USER_LAST_ZOMBIE,
	FW_USER_LAST_HUMAN,
	FW_USER_SPAWN_POST
}

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new g_IsZombie
new g_IsFirstZombie
new g_IsLastZombie
new g_LastZombieForwardCalled
new g_IsLastHuman
new g_LastHumanForwardCalled
new g_RespawnAsZombie
new g_ForwardResult
new g_Forwards[TOTAL_FORWARDS]

public plugin_init()
{
	register_plugin("[ZP] Core/Engine", ZP_VERSION_STRING, "ZP Dev Team")
	register_dictionary("zombie_plague.txt")
	register_dictionary("zombie_plague50.txt")
	
	g_Forwards[FW_USER_INFECT_PRE] = CreateMultiForward("zp_fw_core_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT] = CreateMultiForward("zp_fw_core_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT_POST] = CreateMultiForward("zp_fw_core_infect_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_Forwards[FW_USER_CURE_PRE] = CreateMultiForward("zp_fw_core_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE] = CreateMultiForward("zp_fw_core_cure", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE_POST] = CreateMultiForward("zp_fw_core_cure_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_Forwards[FW_USER_LAST_ZOMBIE] = CreateMultiForward("zp_fw_core_last_zombie", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_HUMAN] = CreateMultiForward("zp_fw_core_last_human", ET_IGNORE, FP_CELL)
	
	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("zp_fw_core_spawn_post", ET_IGNORE, FP_CELL)
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	
	// To help players find ZP servers
	register_cvar("zp_version", ZP_VERSION_STR_LONG, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_version", ZP_VERSION_STR_LONG)
}

public plugin_cfg()
{
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	// Execute config file (zombieplague.cfg)
	server_cmd("exec %s/zombieplague.cfg", cfgdir)
}

public plugin_natives()
{
	register_library("zp50_core")
	register_native("zp_core_is_zombie", "native_core_is_zombie")
	register_native("zp_core_is_first_zombie", "native_core_is_first_zombie")
	register_native("zp_core_is_last_zombie", "native_core_is_last_zombie")
	register_native("zp_core_is_last_human", "native_core_is_last_human")
	register_native("zp_core_get_zombie_count", "native_core_get_zombie_count")
	register_native("zp_core_get_human_count", "native_core_get_human_count")
	register_native("zp_core_infect", "native_core_infect")
	register_native("zp_core_cure", "native_core_cure")
	register_native("zp_core_force_infect", "native_core_force_infect")
	register_native("zp_core_force_cure", "native_core_force_cure")
	register_native("zp_core_respawn_as_zombie", "native_core_respawn_as_zombie")
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was zombie before disconnecting)
	flag_unset(g_IsZombie, id)
	flag_unset(g_RespawnAsZombie, id)
	
	// This should be called AFTER client disconnects (post forward)
	CheckLastZombieHuman()
}

public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// ZP Spawn Forward
	ExecuteForward(g_Forwards[FW_USER_SPAWN_POST], g_ForwardResult, id)
	
	// Set zombie/human attributes upon respawn
	if (flag_get(g_RespawnAsZombie, id))
		InfectPlayer(id, id)
	else
		CurePlayer(id)
	
	// Reset flag afterwards
	flag_unset(g_RespawnAsZombie, id)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post()
{
	CheckLastZombieHuman()
}

InfectPlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_INFECT_PRE], g_ForwardResult, id, attacker)
	
	// One or more plugins blocked infection
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	ExecuteForward(g_Forwards[FW_USER_INFECT], g_ForwardResult, id, attacker)
	
	flag_set(g_IsZombie, id)
	
	if (GetZombieCount() == 1)
		flag_set(g_IsFirstZombie, id)
	else
		flag_unset(g_IsFirstZombie, id)
	
	ExecuteForward(g_Forwards[FW_USER_INFECT_POST], g_ForwardResult, id, attacker)
	
	CheckLastZombieHuman()
}

CurePlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_CURE_PRE], g_ForwardResult, id, attacker)
	
	// One or more plugins blocked cure
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	ExecuteForward(g_Forwards[FW_USER_CURE], g_ForwardResult, id, attacker)
	
	flag_unset(g_IsZombie, id)
	
	ExecuteForward(g_Forwards[FW_USER_CURE_POST], g_ForwardResult, id, attacker)
	
	CheckLastZombieHuman()
}

// Last Zombie/Human Check
CheckLastZombieHuman()
{
	new id, last_zombie_id, last_human_id
	new zombie_count = GetZombieCount()
	new human_count = GetHumanCount()
	
	if (zombie_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last zombie
			if (is_user_alive(id) && flag_get(g_IsZombie, id))
			{
				flag_set(g_IsLastZombie, id)
				last_zombie_id = id
			}
			else
				flag_unset(g_IsLastZombie, id)
		}
	}
	else
	{
		g_LastZombieForwardCalled = false
		
		for (id = 1; id <= g_MaxPlayers; id++)
			flag_unset(g_IsLastZombie, id)
	}
	
	// Last zombie forward
	if (last_zombie_id > 0 && !g_LastZombieForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE], g_ForwardResult, last_zombie_id)
		g_LastZombieForwardCalled = true
	}
	
	if (human_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last human
			if (is_user_alive(id) && !flag_get(g_IsZombie, id))
			{
				flag_set(g_IsLastHuman, id)
				last_human_id = id
			}
			else
				flag_unset(g_IsLastHuman, id)
		}
	}
	else
	{
		g_LastHumanForwardCalled = false
		
		for (id = 1; id <= g_MaxPlayers; id++)
			flag_unset(g_IsLastHuman, id)
	}
	
	// Last human forward
	if (last_human_id > 0 && !g_LastHumanForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN], g_ForwardResult, last_human_id)
		g_LastHumanForwardCalled = true
	}
}

public native_core_is_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsZombie, id);
}

public native_core_is_first_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsFirstZombie, id);
}

public native_core_is_last_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsLastZombie, id);
}

public native_core_is_last_human(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsLastHuman, id);
}

public native_core_get_zombie_count(plugin_id, num_params)
{
	return GetZombieCount();
}

public native_core_get_human_count(plugin_id, num_params)
{
	return GetHumanCount();
}

public native_core_infect(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsZombie, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already infected (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_connected(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	InfectPlayer(id, attacker)
	return true;
}

public native_core_cure(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (!flag_get(g_IsZombie, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player not infected (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_connected(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	CurePlayer(id, attacker)
	return true;
}

public native_core_force_infect(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	InfectPlayer(id)
	return true;
}

public native_core_force_cure(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	CurePlayer(id)
	return true;
}

public native_core_respawn_as_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new respawn_as_zombie = get_param(2)
	
	if (respawn_as_zombie)
		flag_set(g_RespawnAsZombie, id)
	else
		flag_unset(g_RespawnAsZombie, id)
	
	return true;
}

// Get Zombie Count -returns alive zombies number-
GetZombieCount()
{
	new iZombies, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsZombie, id))
			iZombies++
	}
	
	return iZombies;
}

// Get Human Count -returns alive humans number-
GetHumanCount()
{
	new iHumans, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && !flag_get(g_IsZombie, id))
			iHumans++
	}
	
	return iHumans;
}
