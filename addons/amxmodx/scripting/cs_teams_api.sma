/*================================================================================
	
	--------------------------
	-*- [CS] Teams API 1.2 -*-
	--------------------------
	
	- Allows easily setting a player's team in CS and CZ
	- Lets you decide whether to send the TeamInfo message to update scoreboard
	- Prevents server crashes when changing all teams at once
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#define TEAMCHANGE_DELAY 0.1

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new Float:g_TeamMsgTargetTime
new g_MsgTeamInfo, g_MsgScoreInfo
new g_MaxPlayers

public plugin_init()
{
	register_plugin("[CS] Teams API", "1.2", "WiLS")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	g_MaxPlayers = get_maxplayers()
}

public plugin_natives()
{
	register_library("cs_teams_api")
	register_native("cs_set_player_team", "native_set_player_team")
}

public native_set_player_team(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", id)
		return false;
	}
	
	new CsTeams:team = CsTeams:get_param(2)
	
	if (team < CS_TEAM_UNASSIGNED || team > CS_TEAM_SPECTATOR)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid team %d", _:team)
		return false;
	}
	
	new update = get_param(3)
	
	fm_cs_set_user_team(id, team, update)
	return true;
}

// Event Round Start
public event_round_start()
{
	// CS automatically sends TeamInfo messages
	// at roundstart for all players
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_TEAMMSG)
}

public client_disconnect(id)
{
	remove_task(id+TASK_TEAMMSG)
}

// Set a Player's Team
stock fm_cs_set_user_team(id, CsTeams:team, send_message)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	// Already belongs to the team
	if (cs_get_user_team(id) == team)
		return;
	
	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Set team offset
	set_pdata_int(id, OFFSET_CSTEAMS, _:team)
	
	// Send message to update team?
	if (send_message) fm_user_team_update(id)
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_MsgTeamInfo)
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[_:cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()
	
	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, g_MsgScoreInfo)
	ewrite_byte(ID_TEAMMSG) // id
	ewrite_short(pev(ID_TEAMMSG, pev_frags)) // frags
	ewrite_short(cs_get_user_deaths(ID_TEAMMSG)) // deaths
	ewrite_short(0) // class?
	ewrite_short(_:cs_get_user_team(ID_TEAMMSG)) // team
	emessage_end()
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id)
{	
	new Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_TeamMsgTargetTime >= TEAMCHANGE_DELAY)
	{
		set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = current_time + TEAMCHANGE_DELAY
	}
	else
	{
		set_task((g_TeamMsgTargetTime + TEAMCHANGE_DELAY) - current_time, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = g_TeamMsgTargetTime + TEAMCHANGE_DELAY
	}
}
