/*================================================================================
	
	-----------------------
	-*- [ZP] Deathmatch -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>

#define TASK_RESPAWN 100
#define ID_RESPAWN (taskid - TASK_RESPAWN)

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_RESPAWN_PRE = 0
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_GameModeStarted

new cvar_deathmatch, cvar_respawn_delay
new cvar_respawn_zombies, cvar_respawn_humans
new cvar_respawn_on_suicide

public plugin_init()
{
	register_plugin("[ZP] Deathmatch", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	cvar_deathmatch = register_cvar("zp_deathmatch", "0")
	cvar_respawn_delay = register_cvar("zp_respawn_delay", "5")
	cvar_respawn_zombies = register_cvar("zp_respawn_zombies", "1")
	cvar_respawn_humans = register_cvar("zp_respawn_humans", "1")
	cvar_respawn_on_suicide = register_cvar("zp_respawn_on_suicide", "0")
	
	g_MaxPlayers = get_maxplayers()
	
	g_Forwards[FW_USER_RESPAWN_PRE] = CreateMultiForward("zp_fw_deathmatch_respawn_pre", ET_CONTINUE, FP_CELL)
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove respawn task
	remove_task(id+TASK_RESPAWN)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Respawn if deathmatch is enabled
	if (get_pcvar_num(cvar_deathmatch))
	{
		// Respawn on suicide?
		if (!get_pcvar_num(cvar_respawn_on_suicide) && (victim == attacker || !is_user_connected(attacker)))
			return;
		
		// Respawn if human/zombie?
		if ((zp_core_is_zombie(victim) && !get_pcvar_num(cvar_respawn_zombies)) || (!zp_core_is_zombie(victim) && !get_pcvar_num(cvar_respawn_humans)))
			return;
		
		// Set the respawn task
		set_task(get_pcvar_float(cvar_respawn_delay), "respawn_player_task", victim+TASK_RESPAWN)
	}
}

// Respawn Player Task (deathmatch)
public respawn_player_task(taskid)
{
	// Already alive or round ended
	if (is_user_alive(ID_RESPAWN) || zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
		return;
	
	// Get player's team
	new CsTeams:team = cs_get_user_team(ID_RESPAWN)
	
	// Player moved to spectators
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return;
	
	// Allow other plugins to decide whether player can respawn or not
	ExecuteForward(g_Forwards[FW_USER_RESPAWN_PRE], g_ForwardResult, ID_RESPAWN)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	// Respawn as zombie?
	if (get_pcvar_num(cvar_deathmatch) == 2 || (get_pcvar_num(cvar_deathmatch) == 3 && random_num(0, 1)) || (get_pcvar_num(cvar_deathmatch) == 4 && zp_core_get_zombie_count() < GetAliveCount()/2))
	{
		// Only allow respawning as zombie after a game mode started
		if (g_GameModeStarted) zp_core_respawn_as_zombie(ID_RESPAWN, true)
	}
	
	respawn_player_manually(ID_RESPAWN)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public client_disconnect(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_RESPAWN)
}

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
	
	// Stop respawning after game mode ends
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_RESPAWN)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}
