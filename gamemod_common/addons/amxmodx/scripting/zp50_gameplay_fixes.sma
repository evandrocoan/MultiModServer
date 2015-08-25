/*================================================================================
	
	---------------------------
	-*- [ZP] Gameplay Fixes -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_colorchat>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

new const gameplay_ents[][] = { "func_vehicle", "item_longjump" }

#define CLASSNAME_MAX_LENGTH 32

new Array:g_gameplay_ents

const STATIONARY_USING = 2

#define TASK_RESPAWN 100
#define ID_RESPAWN (taskid - TASK_RESPAWN)

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

#define MENUCODE_TEAMSELECT 1

new g_MaxPlayers
new g_fwSpawn
new g_GameModeStarted
new g_RoundEnded

new cvar_remove_doors
new cvar_block_pushables
new cvar_block_suicide
new cvar_worldspawn_kill_respawn
new cvar_disable_minmodels
new cvar_keep_hp_on_disconnect

public plugin_init()
{
	register_plugin("[ZP] Gameplay Fixes", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_remove_doors = register_cvar("zp_remove_doors", "0")
	cvar_block_pushables = register_cvar("zp_block_pushables", "1")
	cvar_block_suicide = register_cvar("zp_block_suicide", "1")
	cvar_worldspawn_kill_respawn = register_cvar("zp_worldspawn_kill_respawn", "1")
	cvar_disable_minmodels = register_cvar("zp_disable_minmodels", "1")
	cvar_keep_hp_on_disconnect = register_cvar("zp_keep_hp_on_disconnect", "1")
	
	register_clcmd("chooseteam", "clcmd_changeteam")
	register_clcmd("jointeam", "clcmd_changeteam")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_pushable", "fw_UsePushable")
	register_forward(FM_ClientKill, "fw_ClientKill")
	unregister_forward(FM_Spawn, g_fwSpawn)
	
	register_message(get_user_msgid("Health"), "message_health")
	
	g_MaxPlayers = get_maxplayers()
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

public plugin_precache()
{
	// Initialize arrays
	g_gameplay_ents = ArrayCreate(CLASSNAME_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Objective Entities", "GAMEPLAY", g_gameplay_ents)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_gameplay_ents) == 0)
	{
		for (index = 0; index < sizeof gameplay_ents; index++)
			ArrayPushString(g_gameplay_ents, gameplay_ents[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Objective Entities", "GAMEPLAY", g_gameplay_ents)
	}
	
	// Prevent gameplay entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
}

public plugin_cfg()
{
	event_round_start()
}

public client_putinserver(id)
{
	// Disable minmodels for clients to see zombies properly?
	if (get_pcvar_num(cvar_disable_minmodels))
		set_task(0.1, "disable_minmodels_task", id)
}

public disable_minmodels_task(id)
{
	if (is_user_connected(id))
		client_cmd(id, "cl_minmodels 0")
}

// Team Change Commands
public clcmd_changeteam(id)
{
	// Block suicides by choosing a different team
	if (get_pcvar_num(cvar_block_suicide) && g_GameModeStarted && is_user_alive(id))
	{
		zp_colored_print(id, "%L", id, "CANT_CHANGE_TEAM")
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

// Event Round Start
public event_round_start()
{
	g_RoundEnded = false
	
	// Remove doors?
	if (get_pcvar_num(cvar_remove_doors) > 0)
		set_task(0.1, "remove_doors")
}

// Remove Doors Task
public remove_doors()
{
	new ent
	
	// Remove rotating doors
	ent = -1;
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door_rotating")) != 0)
		engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	
	// Remove all doors?
	if (get_pcvar_num(cvar_remove_doors) > 1)
	{
		ent = -1;
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_door")) != 0)
			engfunc(EngFunc_SetOrigin, ent, Float:{8192.0 ,8192.0 ,8192.0})
	}
}

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32], objective[32], size = ArraySize(g_gameplay_ents)
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	new index
	for (index = 0; index < size; index++)
	{
		ArrayGetString(g_gameplay_ents, index, objective, charsmax(objective))
		
		if (equal(classname, objective))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove respawn task
	remove_task(id+TASK_RESPAWN)
	
	// Respawn player if he dies because of a worldspawn kill?
	if (get_pcvar_num(cvar_worldspawn_kill_respawn))
		set_task(1.0, "respawn_player_check_task", id+TASK_RESPAWN)
}

// Respawn Player Check Task (if killed by worldspawn)
public respawn_player_check_task(taskid)
{
	// Successfully spawned or round ended
	if (is_user_alive(ID_RESPAWN) || g_RoundEnded)
		return;
	
	// Get player's team
	new CsTeams:team = cs_get_user_team(ID_RESPAWN)
	
	// Player moved to spectators
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return;
	
	// If player was being spawned as a zombie, set the flag again
	if (zp_core_is_zombie(ID_RESPAWN))
		zp_core_respawn_as_zombie(ID_RESPAWN, true)
	
	respawn_player_manually(ID_RESPAWN)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

// Client Disconnecting (prevent Game Commencing bug after last player on a team leaves)
public client_disconnect(leaving_player)
{
	// Remove respawn task on disconnect
	remove_task(leaving_player+TASK_RESPAWN)
	
	// Player was not alive
	if (!is_user_alive(leaving_player))
		return;
	
	// Last player, dont bother
	if (GetAliveCount() == 1)
		return;
	
	new id
	
	// Prevent empty teams when no game mode is in progress
	if (!g_GameModeStarted)
	{
		// Last Terrorist
		if ((cs_get_user_team(leaving_player) == CS_TEAM_T) && (GetAliveTCount() == 1))
		{
			// Find replacement and move him to T team
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			cs_set_player_team(id, CS_TEAM_T)
		}
		// Last CT
		else if ((cs_get_user_team(leaving_player) == CS_TEAM_CT) && (GetAliveCTCount() == 1))
		{
			// Find replacement and move him to CT team
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			cs_set_player_team(id, CS_TEAM_CT)
		}
	}
	// Prevent no zombies/humans after game mode started
	else
	{
		// Last Zombie
		if (zp_core_is_zombie(leaving_player) && zp_core_get_zombie_count() == 1)
		{
			// Only one CT left, don't leave an empty CT team
			if (zp_core_get_human_count() == 1 && GetCTCount() == 1)
				return;
			
			// Find replacement
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			
			new name[32]
			get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "%L", LANG_PLAYER, "LAST_ZOMBIE_LEFT", name)
			
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(leaving_player))
			{
				zp_class_nemesis_set(id)
				
				if (get_pcvar_num(cvar_keep_hp_on_disconnect))
					set_user_health(id, get_user_health(leaving_player))
			}
			else
				zp_core_infect(id, id)
		}
		// Last Human
		else if (!zp_core_is_zombie(leaving_player) && zp_core_get_human_count() == 1)
		{
			// Only one T left, don't leave an empty T team
			if (zp_core_get_zombie_count() == 1 && GetTCount() == 1)
				return;
			
			// Find replacement
			while ((id = GetRandomAlive(random_num(1, GetAliveCount()))) == leaving_player ) { /* keep looping */ }
			
			new name[32]
			get_user_name(id, name, charsmax(name))
			zp_colored_print(0, "%L", LANG_PLAYER, "LAST_HUMAN_LEFT", name)
			
			if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(leaving_player))
			{
				zp_class_survivor_set(id)
				
				if (get_pcvar_num(cvar_keep_hp_on_disconnect))
					set_user_health(id, get_user_health(leaving_player))
			}
			else
				zp_core_cure(id, id)
		}
	}
}

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
	
	// Block suicides by choosing a different team
	if (get_pcvar_num(cvar_block_suicide))
	{
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_alive(id))
				continue;
			
			// Disable any opened team change menus (bugfix)
			if (get_pdata_int(id, OFFSET_CSMENUCODE) == MENUCODE_TEAMSELECT)
				set_pdata_int(id, OFFSET_CSMENUCODE, 0)
		}
	}
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
	g_RoundEnded = true
	
	// Stop respawning after game mode ends
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_RESPAWN)
}

// Ham Use Stationary Gun Forward
public fw_UseStationary(entity, caller, activator, use_type)
{
	// Prevent zombies from using stationary guns
	if (use_type == STATIONARY_USING && is_user_alive(caller) && zp_core_is_zombie(caller))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Use Pushable Forward
public fw_UsePushable()
{
	// Prevent speed bug with pushables?
	if (get_pcvar_num(cvar_block_pushables))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Client Kill Forward
public fw_ClientKill()
{
	// Prevent players from killing themselves?
	if (get_pcvar_num(cvar_block_suicide) && g_GameModeStarted)
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

// Fix for the HL engine bug when HP is multiples of 256
public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	new health = get_msg_arg_int(1)
	
	// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		set_user_health(msg_entity, get_user_health(msg_entity) + 1)
	
	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

// Get Alive CTs -returns number of CTs alive-
GetAliveCTCount()
{
	new iCTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
			iCTs++
	}
	
	return iCTs;
}

// Get Alive Ts -returns number of Ts alive-
GetAliveTCount()
{
	new iTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
			iTs++
	}
	
	return iTs;
}

// Get CTs -returns number of CTs connected-
GetCTCount()
{
	new iCTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_CT)
			iCTs++
	}
	
	return iCTs;
}

// Get Ts -returns number of Ts connected-
GetTCount()
{
	new iTs, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_connected(id) && cs_get_user_team(id) == CS_TEAM_T)
			iTs++
	}
	
	return iTs;
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

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}