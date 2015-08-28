/*================================================================================
	
	---------------------------
	-*- [ZP] Rewards: Money -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

#define MAXPLAYERS 32
#define CS_MONEY_LIMIT 16000
#define NO_DATA -1

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSMONEY = 115

new g_MaxPlayers
new g_GameRestarting
new g_MsgMoney, g_MsgMoneyBlockStatus

new g_MoneyAtRoundStart[MAXPLAYERS+1] = { NO_DATA , ...}
new g_MoneyRewarded[MAXPLAYERS+1] = { NO_DATA , ...}
new g_MoneyBeforeKill[MAXPLAYERS+1]

new Float:g_DamageDealtToZombies[MAXPLAYERS+1]
new Float:g_DamageDealtToHumans[MAXPLAYERS+1]

new cvar_money_winner, cvar_money_loser
new cvar_money_damage, cvar_money_zombie_damaged_hp, cvar_money_human_damaged_hp
new cvar_money_zombie_killed, cvar_money_human_killed
new cvar_money_human_infected
new cvar_money_nemesis_ignore, cvar_money_survivor_ignore

public plugin_init()
{
	register_plugin("[ZP] Rewards: Money", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_will_restart_in")
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_Commencing")
	
	cvar_money_winner = register_cvar("zp_money_winner", "1000")
	cvar_money_loser = register_cvar("zp_money_loser", "500")
	
	cvar_money_damage = register_cvar("zp_money_damage", "100")
	cvar_money_zombie_damaged_hp = register_cvar("zp_money_zombie_damaged_hp", "500")
	cvar_money_human_damaged_hp = register_cvar("zp_money_human_damaged_hp", "250")
	cvar_money_zombie_killed = register_cvar("zp_money_zombie_killed", "200")
	cvar_money_human_killed = register_cvar("zp_money_human_killed", "200")
	cvar_money_human_infected = register_cvar("zp_money_human_infected", "200")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_money_nemesis_ignore = register_cvar("zp_money_nemesis_ignore", "0")
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_money_survivor_ignore = register_cvar("zp_money_survivor_ignore", "0")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	g_MsgMoney = get_user_msgid("Money")
	register_message(g_MsgMoney, "message_money")
	
	g_MaxPlayers = get_maxplayers()
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

public zp_fw_core_infect_post(id, attacker)
{
	// Reward money to zombies infecting humans?
	if (is_user_connected(attacker) && attacker != id && get_pcvar_num(cvar_money_human_infected) > 0)
		cs_set_user_money(attacker, min(cs_get_user_money(attacker) + get_pcvar_num(cvar_money_human_infected), CS_MONEY_LIMIT))
}

// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	// Ignore money rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_money_nemesis_ignore))
		return;
	
	// Ignore money rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_money_survivor_ignore))
		return;
	
	// Zombie attacking human...
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Reward money to zombies for damaging humans?
		if (get_pcvar_num(cvar_money_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToHumans[attacker] += damage
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToHumans[attacker] / get_pcvar_float(cvar_money_human_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				cs_set_user_money(attacker, min(cs_get_user_money(attacker) + (get_pcvar_num(cvar_money_damage) * how_many_rewards), CS_MONEY_LIMIT))
				g_DamageDealtToHumans[attacker] -= get_pcvar_float(cvar_money_human_damaged_hp) * how_many_rewards
			}
		}
	}
	// Human attacking zombie...
	else if (!zp_core_is_zombie(attacker) && zp_core_is_zombie(victim))
	{
		// Reward money to humans for damaging zombies?
		if (get_pcvar_num(cvar_money_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToZombies[attacker] += damage
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToZombies[attacker] / get_pcvar_float(cvar_money_zombie_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				cs_set_user_money(attacker, min(cs_get_user_money(attacker) + (get_pcvar_num(cvar_money_damage) * how_many_rewards), CS_MONEY_LIMIT))
				g_DamageDealtToZombies[attacker] -= get_pcvar_float(cvar_money_zombie_damaged_hp) * how_many_rewards
			}
		}
	}
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Non-player kill or self kill
	if (victim == attacker || !is_user_connected(attacker))
		return;
	
	// Block CS money message before the kill
	g_MsgMoneyBlockStatus = get_msg_block(g_MsgMoney)
	set_msg_block(g_MsgMoney, BLOCK_SET)
	
	// Save attacker's money before the kill
	g_MoneyBeforeKill[attacker] = cs_get_user_money(attacker)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Non-player kill or self kill
	if (victim == attacker || !is_user_connected(attacker))
		return;
		
	// Restore CS money message block status
	set_msg_block(g_MsgMoney, g_MsgMoneyBlockStatus)
	
	// Ignore money rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_money_nemesis_ignore))
	{
		cs_set_user_money(attacker, g_MoneyBeforeKill[attacker])
		return;
	}
	
	// Ignore money rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_money_survivor_ignore))
	{
		cs_set_user_money(attacker, g_MoneyBeforeKill[attacker])
		return;
	}
	
	// Reward money to attacker for the kill
	if (zp_core_is_zombie(victim))
		cs_set_user_money(attacker, min(g_MoneyBeforeKill[attacker] + get_pcvar_num(cvar_money_zombie_killed), CS_MONEY_LIMIT))
	else
		cs_set_user_money(attacker, min(g_MoneyBeforeKill[attacker] + get_pcvar_num(cvar_money_human_killed), CS_MONEY_LIMIT))
}

public event_round_start()
{
	// Don't reward money after game restart event
	if (g_GameRestarting)
	{
		g_GameRestarting = false
		return;
	}
	
	// Save player's money at round start, plus our custom money rewards
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id) || g_MoneyRewarded[id] == NO_DATA)
			continue;
		
		g_MoneyAtRoundStart[id] = min(cs_get_user_money(id) + g_MoneyRewarded[id], CS_MONEY_LIMIT)
		g_MoneyRewarded[id] = NO_DATA
	}
}

public zp_fw_gamemodes_end()
{
	// Determine round winner and money rewards
	if (!zp_core_get_zombie_count())
	{
		// Human team wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			if (zp_core_is_zombie(id))
				g_MoneyRewarded[id] = get_pcvar_num(cvar_money_loser)
			else
				g_MoneyRewarded[id] = get_pcvar_num(cvar_money_winner)
		}
	}
	else if (!zp_core_get_human_count())
	{
		// Zombie team wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			if (zp_core_is_zombie(id))
				g_MoneyRewarded[id] = get_pcvar_num(cvar_money_winner)
			else
				g_MoneyRewarded[id] = get_pcvar_num(cvar_money_loser)
		}
	}
	else
	{
		// No one wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			g_MoneyRewarded[id] = get_pcvar_num(cvar_money_loser)
		}
	}
}

public message_money(msg_id, msg_dest, msg_entity)
{
	if (!is_user_connected(msg_entity))
		return;
	
	// If arg 2 = 0, this is CS giving round win money or start money
	if (get_msg_arg_int(2) == 0 && g_MoneyAtRoundStart[msg_entity] != NO_DATA)
	{
		fm_cs_set_user_money(msg_entity, g_MoneyAtRoundStart[msg_entity])
		set_msg_arg_int(1, get_msg_argtype(1), g_MoneyAtRoundStart[msg_entity])
		g_MoneyAtRoundStart[msg_entity] = NO_DATA
	}
}

public event_game_restart()
{
	g_GameRestarting = true
}

public client_disconnect(id)
{
	// Clear saved money after disconnecting
	g_MoneyAtRoundStart[id] = NO_DATA
	g_MoneyRewarded[id] = NO_DATA
	
	// Clear damage after disconnecting
	g_DamageDealtToZombies[id] = 0.0
	g_DamageDealtToHumans[id] = 0.0
}

// Set User Money
stock fm_cs_set_user_money(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSMONEY, value)
}