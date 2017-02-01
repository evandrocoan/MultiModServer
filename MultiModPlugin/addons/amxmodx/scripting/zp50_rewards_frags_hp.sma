/*================================================================================
	
	--------------------------------
	-*- [ZP] Rewards: Frags & HP -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSDEATHS = 444

new g_MsgScoreInfo
new g_LastHumanHealthRewarded
new g_GameModeStarted

new cvar_frags_zombie_killed
new cvar_frags_human_killed, cvar_frags_human_infected
new cvar_frags_nemesis_ignore, cvar_frags_survivor_ignore

new cvar_infection_health_bonus
new cvar_human_last_health_bonus

public plugin_init()
{
	register_plugin("[ZP] Rewards: Frags & HP", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	cvar_frags_zombie_killed = register_cvar("zp_frags_zombie_killed", "1")
	cvar_frags_human_killed = register_cvar("zp_frags_human_killed", "1")
	cvar_frags_human_infected = register_cvar("zp_frags_human_infected", "1")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_frags_nemesis_ignore = register_cvar("zp_frags_nemesis_ignore", "0")
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_frags_survivor_ignore = register_cvar("zp_frags_survivor_ignore", "0")
	
	cvar_infection_health_bonus = register_cvar("zp_infection_health_bonus", "100")
	cvar_human_last_health_bonus = register_cvar("zp_human_last_health_bonus", "50")
}

public plugin_natives()
{
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

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Killed by a non-player entity or self killed
	if (victim == attacker || !is_user_connected(attacker))
		return;
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_frags_nemesis_ignore))
	{
		// Ignore nemesis frags
		RemoveFrags(attacker, victim)
		return;
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_frags_survivor_ignore))
	{
		// Ignore survivor frags
		RemoveFrags(attacker, victim)
		return;
	}
	
	// Human killed zombie, add up the extra frags for kill
	if (!zp_core_is_zombie(attacker) && get_pcvar_num(cvar_frags_zombie_killed) > 1)
		UpdateFrags(attacker, victim, get_pcvar_num(cvar_frags_zombie_killed) - 1, 0, 0)
	
	// Zombie killed human, add up the extra frags for kill
	if (zp_core_is_zombie(attacker) && get_pcvar_num(cvar_frags_human_killed) > 1)
		UpdateFrags(attacker, victim, get_pcvar_num(cvar_frags_human_killed) - 1, 0, 0)
}

public zp_fw_core_infect_post(id, attacker)
{
	if (is_user_connected(attacker) && attacker != id)
	{
		// Reward frags, deaths
		UpdateFrags(attacker, id, get_pcvar_num(cvar_frags_human_infected), 1, 1)
		
		// Reward health
		if (is_user_alive(attacker))
			set_user_health(attacker, get_user_health(attacker) + get_pcvar_num(cvar_infection_health_bonus))
	}
}

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
	g_LastHumanHealthRewarded = false
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
}

public zp_fw_core_last_human(id)
{
	if (g_GameModeStarted && !g_LastHumanHealthRewarded)
	{
		set_user_health(id, get_user_health(id) + get_pcvar_num(cvar_human_last_health_bonus))
		g_LastHumanHealthRewarded = true
	}
}

// Update Player Frags and Deaths
UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	// Set attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	// Set victim deaths
	fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)
	
	// Update scoreboard with attacker and victim info
	if (scoreboard)
	{
		message_begin(MSG_BROADCAST, g_MsgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(cs_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(_:cs_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_MsgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(cs_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(_:cs_get_user_team(victim)) // team
		message_end()
	}
}

// Remove Player Frags (when Nemesis/Survivor ignore_frags cvar is enabled)
RemoveFrags(attacker, victim)
{
	// Remove attacker frags
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) - 1))
	
	// Remove victim deaths
	fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) - 1)
}

// Set User Deaths
stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSDEATHS, value)
}
