/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Modes Manager -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
	-TODO: cvar prevent consecutive modes (should work for all except default)
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_gamemodes_const>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

#define TASK_GAMEMODE 100

// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.12

// Some constants
const DMG_HEGRENADE = (1<<24)

enum _:TOTAL_FORWARDS
{
	FW_GAME_MODE_CHOOSE_PRE = 0,
	FW_GAME_MODE_CHOOSE_POST,
	FW_GAME_MODE_START,
	FW_GAME_MODE_END,
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_HudSync

new cvar_gamemode_delay, cvar_round_start_show_hud, cvar_prevent_consecutive

// Game Modes data
new Array:g_GameModeName
new Array:g_GameModeFileName
new g_GameModeCount
new g_DefaultGameMode = 0 // first game mode is used as default if none specified
new g_ChosenGameMode = ZP_NO_GAME_MODE
new g_CurrentGameMode = ZP_NO_GAME_MODE
new g_LastGameMode = ZP_NO_GAME_MODE
new g_AllowInfection

public plugin_init()
{
	register_plugin("[ZP] Game Modes Manager", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_will_restart_in")
	
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	
	cvar_gamemode_delay = register_cvar("zp_gamemode_delay", "10")
	cvar_round_start_show_hud = register_cvar("zp_round_start_show_hud", "1")
	cvar_prevent_consecutive = register_cvar("zp_prevent_consecutive_modes", "1")
	
	g_Forwards[FW_GAME_MODE_CHOOSE_PRE] = CreateMultiForward("zp_fw_gamemodes_choose_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_CHOOSE_POST] = CreateMultiForward("zp_fw_gamemodes_choose_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_START] = CreateMultiForward("zp_fw_gamemodes_start", ET_IGNORE, FP_CELL)
	g_Forwards[FW_GAME_MODE_END] = CreateMultiForward("zp_fw_gamemodes_end", ET_IGNORE, FP_CELL)
	
	g_MaxPlayers = get_maxplayers()
	g_HudSync = CreateHudSyncObj()
}

public plugin_natives()
{
	register_library("zp50_gamemodes")
	register_native("zp_gamemodes_register", "native_gamemodes_register")
	register_native("zp_gamemodes_set_default", "native_gamemodes_set_default")
	register_native("zp_gamemodes_get_default", "native_gamemodes_get_default")
	register_native("zp_gamemodes_get_chosen", "native_gamemodes_get_chosen")
	register_native("zp_gamemodes_get_current", "native_gamemodes_get_current")
	register_native("zp_gamemodes_get_id", "native_gamemodes_get_id")
	register_native("zp_gamemodes_get_name", "native_gamemodes_get_name")
	register_native("zp_gamemodes_start", "native_gamemodes_start")
	register_native("zp_gamemodes_get_count", "native_gamemodes_get_count")
	register_native("zp_gamemodes_set_allow_infect", "_gamemodes_set_allow_infect")
	register_native("zp_gamemodes_get_allow_infect", "_gamemodes_get_allow_infect")
	
	// Initialize dynamic arrays
	g_GameModeName = ArrayCreate(32, 1)
	g_GameModeFileName = ArrayCreate(64, 1)
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_gamemodes_register(plugin_id, num_params)
{
	new name[32], filename[64]
	get_string(1, name, charsmax(name))
	get_plugin(plugin_id, filename, charsmax(filename))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register game mode with an empty name")
		return ZP_INVALID_GAME_MODE;
	}
	
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Game mode already registered (%s)", name)
			return ZP_INVALID_GAME_MODE;
		}
	}
	
	ArrayPushString(g_GameModeName, name)
	ArrayPushString(g_GameModeFileName, filename)
	
	// Pause Game Mode plugin after registering
	pause("ac", filename)
	
	g_GameModeCount++
	return g_GameModeCount - 1;
}

public native_gamemodes_set_default(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	g_DefaultGameMode = game_mode_id
	return true;
}

public native_gamemodes_get_default(plugin_id, num_params)
{
	return g_DefaultGameMode;
}

public native_gamemodes_get_chosen(plugin_id, num_params)
{
	return g_ChosenGameMode;
}

public native_gamemodes_get_current(plugin_id, num_params)
{
	return g_CurrentGameMode;
}

public native_gamemodes_get_id(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	// Loop through every game mode
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
			return index;
	}
	
	return ZP_INVALID_GAME_MODE;
}

public native_gamemodes_get_name(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_GameModeName, game_mode_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public native_gamemodes_start(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new target_player = get_param(2)
	
	if (target_player != RANDOM_TARGET_PLAYER && !is_user_alive(target_player))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid player (%d)", target_player)
		return false;
	}
	
	// Game modes can only be started at roundstart
	if (!task_exists(TASK_GAMEMODE))
		return false;
	
	new previous_mode, filename_previous[64]
	
	// Game mode already chosen?
	if (g_ChosenGameMode != ZP_NO_GAME_MODE)
	{
		// Pause previous game mode before picking a new one
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename_previous, charsmax(filename_previous))
		pause("ac", filename_previous)
		previous_mode = true
	}
	
	// Set chosen game mode id
	g_ChosenGameMode = game_mode_id
	
	// Unpause game mode once it's chosen
	new filename[64]
	ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
	unpause("ac", filename)
	
	// Execute game mode choose attempt forward (skip checks = true)
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
	
	// Game mode can't be started
	if (g_ForwardResult >= PLUGIN_HANDLED)
	{
		// Pause the game mode we were trying to start
		pause("ac", filename)
		
		// Unpause previously chosen game mode
		if (previous_mode) unpause("ac", filename_previous)
		
		return false;
	}
	
	// Execute game mode chosen forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, target_player)
	
	// Override task and start game mode manually
	remove_task(TASK_GAMEMODE)
	start_game_mode_task()
	return true;
}

public native_gamemodes_get_count(plugin_id, num_params)
{
	return g_GameModeCount;
}

public _gamemodes_set_allow_infect(plugin_id, num_params)
{
	g_AllowInfection = get_param(1)
}

public _gamemodes_get_allow_infect(plugin_id, num_params)
{
	return g_AllowInfection;
}

public event_game_restart()
{
	logevent_round_end()
}

public logevent_round_end()
{
	ExecuteForward(g_Forwards[FW_GAME_MODE_END], g_ForwardResult, g_CurrentGameMode)
	
	if (g_ChosenGameMode != ZP_NO_GAME_MODE)
	{
		// pause game mode after its round ends
		new filename[64]
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		pause("ac", filename)
	}
	
	g_CurrentGameMode = ZP_NO_GAME_MODE
	g_ChosenGameMode = ZP_NO_GAME_MODE
	g_AllowInfection = false
	
	// Stop game mode task
	remove_task(TASK_GAMEMODE)
	
	// Balance the teams
	balance_teams()
}

public event_round_start()
{
	// Players respawn as humans when a new round begins
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		zp_core_respawn_as_zombie(id, false)
	}
	
	// No game modes registered?
	if (g_GameModeCount < 1)
	{
		set_fail_state("[ZP] No game modes registered!")
		return;
	}
	
	// Remove previous tasks
	remove_task(TASK_GAMEMODE)
	
	// Pick game mode for the current round (delay needed because not all players are alive at this point)
	set_task(0.1, "choose_game_mode", TASK_GAMEMODE)
	
	// Start game mode task (delay should be greater than choose_game_mode task)
	set_task(0.2 + get_pcvar_float(cvar_gamemode_delay), "start_game_mode_task", TASK_GAMEMODE)
	
	if (get_pcvar_num(cvar_round_start_show_hud))
	{
		// Show T-virus HUD notice
		set_hudmessage(0, 125, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_VIRUS_FREE")
	}
}

public choose_game_mode()
{
	// No players joined yet
	if (GetAliveCount() <= 0)
		return;
	
	new index, filename[64]
	
	// Try choosing a game mode
	for (index = g_DefaultGameMode + 1; /*no condition*/; index++)
	{
		// Start over when we reach the end
		if (index >= g_GameModeCount)
			index = 0
		
		// Game mode already chosen?
		if (g_ChosenGameMode != ZP_NO_GAME_MODE)
		{
			// Pause previous game mode before picking a new one
			ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
			pause("ac", filename)
		}
		
		// Set chosen game mode index
		g_ChosenGameMode = index
		
		// Unpause game mode once it's chosen
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		unpause("ac", filename)
		
		// Starting non-default game mode?
		if (index != g_DefaultGameMode)
		{
			// Execute game mode choose attempt forward (skip checks = false)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, false)
			
			// Custom game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED && (!get_pcvar_num(cvar_prevent_consecutive) || g_LastGameMode != index))
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				g_LastGameMode = g_ChosenGameMode
				break;
			}
		}
		else
		{
			// Execute game mode choose attempt forward (skip checks = true)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
			
			// Default game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				g_LastGameMode = g_ChosenGameMode
				break;
			}
			else
			{
				remove_task(TASK_GAMEMODE)
				abort(AMX_ERR_GENERAL, "[ZP] Default game mode can't be started. Check server settings.")
				break;
			}
		}
	}
}

public start_game_mode_task()
{
	// No game mode was chosen (not enough players)
	if (g_ChosenGameMode == ZP_NO_GAME_MODE)
		return;
	
	// Set current game mode
	g_CurrentGameMode = g_ChosenGameMode
	
	// Execute game mode started forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_START], g_ForwardResult, g_CurrentGameMode)
}

// Client Disconnected Post Forward
public fw_ClientDisconnect_Post(id)
{
	// Are there any other players? (if not, round end is automatically triggered after last player leaves)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Are there any other players? (if not, round end is automatically triggered after last player dies)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ZP_NO_GAME_MODE)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (zp_core_is_zombie(attacker) == zp_core_is_zombie(victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ZP_NO_GAME_MODE)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (zp_core_is_zombie(attacker) == zp_core_is_zombie(victim))
		return HAM_SUPERCEDE;
	
	// Mode allows infection and zombie attacking human...
	if (g_AllowInfection && zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Nemesis shouldn't be infecting
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker))
			return HAM_IGNORED;
		
		// Survivor shouldn't be infected
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(victim))
			return HAM_IGNORED;
		
		// Prevent infection/damage by HE grenade (bugfix)
		if (damage_type & DMG_HEGRENADE)
			return HAM_SUPERCEDE;
		
		// Last human is killed to trigger round end
		if (zp_core_get_human_count() == 1)
			return HAM_IGNORED;
		
		// Infect only if damage is done to victim
		if (damage > 0.0 && GetHamReturnStatus() != HAM_SUPERCEDE)
		{
			// Infect victim!
			zp_core_infect(victim, attacker)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public zp_fw_core_infect_post(id, attacker)
{
	if (g_CurrentGameMode != ZP_NO_GAME_MODE)
	{
		// Zombies are switched to Terrorist team
		cs_set_player_team(id, CS_TEAM_T)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	if (g_CurrentGameMode != ZP_NO_GAME_MODE)
	{
		// Humans are switched to CT team
		cs_set_player_team(id, CS_TEAM_CT)
	}
}

// Balance Teams
balance_teams()
{
	// Get amount of users playing
	new players_count = GetPlayingCount()
	
	// No players, don't bother
	if (players_count < 1) return;
	
	// Split players evenly
	new iTerrors
	new iMaxTerrors = players_count / 2
	new id, CsTeams:team
	
	// First, set everyone to CT
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing
		if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		// Set team
		cs_set_player_team(id, CS_TEAM_CT, 0)
	}
	
	// Then randomly move half of the players to Terrorists
	while (iTerrors < iMaxTerrors)
	{
		// Keep looping through all players
		if (++id > g_MaxPlayers) id = 1
		
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing or already a Terrorist
		if (team != CS_TEAM_CT)
			continue;
		
		// Random chance
		if (random_num(0, 1))
		{
			cs_set_player_team(id, CS_TEAM_T, 0)
			iTerrors++
		}
	}
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

// Get Playing Count -returns number of users playing-
GetPlayingCount()
{
	new iPlaying, id, CsTeams:team
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		if (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
			iPlaying++
	}
	
	return iPlaying;
}
