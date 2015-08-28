/*================================================================================
	
	-----------------------------
	-*- [CS] MaxSpeed API 1.0 -*-
	-----------------------------
	
	- Allows easily setting a player's maxspeed in CS and CZ
	- Lets you use maxspeed multipliers instead of absolute values
	- Doesn't affect CS Freezetime
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <cs_maxspeed_api_const>

#define MAXPLAYERS 32

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

#define flag_get(%1,%2)		(%1 & (1 << (%2 & 31)))
#define flag_set(%1,%2)		%1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2)	%1 &= ~(1 << (%2 & 31))

new g_HasCustomMaxSpeed
new g_MaxSpeedIsMultiplier
new Float:g_CustomMaxSpeed[MAXPLAYERS+1]
new g_FreezeTime

public plugin_init()
{
	register_plugin("[CS] MaxSpeed API", "1.0", "WiLS")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_start",2, "1=Round_Start")
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_ResetMaxSpeed_Post", 1)
	RegisterHamBots(Ham_Player_ResetMaxSpeed, "fw_ResetMaxSpeed_Post", 1)
}

public plugin_cfg()
{
	// Prevents CS from limiting player maxspeeds at 320
	server_cmd("sv_maxspeed 9999")
}

public plugin_natives()
{
	register_library("cs_maxspeed_api")
	register_native("cs_set_player_maxspeed", "native_set_player_maxspeed")
	register_native("cs_reset_player_maxspeed", "native_reset_player_maxspeed")
}

public native_set_player_maxspeed(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new Float:maxspeed = get_param_f(2)
	
	if (maxspeed < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid maxspeed value %.2f", maxspeed)
		return false;
	}
	
	new multiplier = get_param(3)
	
	flag_set(g_HasCustomMaxSpeed, id)
	g_CustomMaxSpeed[id] = maxspeed
	
	if (multiplier)
		flag_set(g_MaxSpeedIsMultiplier, id)
	else
		flag_unset(g_MaxSpeedIsMultiplier, id)
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	return true;
}

public native_reset_player_maxspeed(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	// Player doesn't have custom maxspeed, no need to reset
	if (!flag_get(g_HasCustomMaxSpeed, id))
		return true;
	
	flag_unset(g_HasCustomMaxSpeed, id)
	
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	return true;
}

public client_disconnect(id)
{
	flag_unset(g_HasCustomMaxSpeed, id)
}

public event_round_start()
{
	g_FreezeTime = true
}

public logevent_round_start()
{
	g_FreezeTime = false
}

public fw_ResetMaxSpeed_Post(id)
{
	if (g_FreezeTime || !is_user_alive(id) || !flag_get(g_HasCustomMaxSpeed, id))
		return;
	
	if (flag_get(g_MaxSpeedIsMultiplier, id))
		set_user_maxspeed(id, get_user_maxspeed(id) * g_CustomMaxSpeed[id])
	else
		set_user_maxspeed(id, g_CustomMaxSpeed[id])
}