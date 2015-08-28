/*================================================================================
	
	--------------------------------
	-*- [ZP] Rewards: Ammo Packs -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_ammopacks>

#define MAXPLAYERS 32

new g_MaxPlayers

new Float:g_DamageDealtToZombies[MAXPLAYERS+1]
new Float:g_DamageDealtToHumans[MAXPLAYERS+1]

new cvar_ammop_winner, cvar_ammop_loser
new cvar_ammop_damage, cvar_ammop_zombie_damaged_hp, cvar_ammop_human_damaged_hp
new cvar_ammop_zombie_killed, cvar_ammop_human_killed
new cvar_ammop_human_infected
new cvar_ammop_nemesis_ignore, cvar_ammop_survivor_ignore

public plugin_init()
{
	register_plugin("[ZP] Rewards: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_ammop_winner = register_cvar("zp_ammop_winner", "3")
	cvar_ammop_loser = register_cvar("zp_ammop_loser", "1")
	
	cvar_ammop_damage = register_cvar("zp_ammop_damage", "1")
	cvar_ammop_zombie_damaged_hp = register_cvar("zp_ammop_zombie_damaged_hp", "500")
	cvar_ammop_human_damaged_hp = register_cvar("zp_ammop_human_damaged_hp", "250")
	cvar_ammop_zombie_killed = register_cvar("zp_ammop_zombie_killed", "1")
	cvar_ammop_human_killed = register_cvar("zp_ammop_human_killed", "1")
	cvar_ammop_human_infected = register_cvar("zp_ammop_human_infected", "1")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_ammop_nemesis_ignore = register_cvar("zp_ammop_nemesis_ignore", "0")
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_ammop_survivor_ignore = register_cvar("zp_ammop_survivor_ignore", "0")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
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
	// Reward ammo packs to zombies infecting humans?
	if (is_user_connected(attacker) && attacker != id && get_pcvar_num(cvar_ammop_human_infected) > 0)
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + get_pcvar_num(cvar_ammop_human_infected))
}

// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	// Ignore ammo pack rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_ammop_nemesis_ignore))
		return;
	
	// Ignore ammo pack rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_ammop_survivor_ignore))
		return;
	
	// Zombie attacking human...
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Reward ammo packs to zombies for damaging humans?
		if (get_pcvar_num(cvar_ammop_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToHumans[attacker] += damage
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToHumans[attacker] / get_pcvar_float(cvar_ammop_human_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + (get_pcvar_num(cvar_ammop_damage) * how_many_rewards))
				g_DamageDealtToHumans[attacker] -= get_pcvar_float(cvar_ammop_human_damaged_hp) * how_many_rewards
			}
		}
	}
	// Human attacking zombie...
	else if (!zp_core_is_zombie(attacker) && zp_core_is_zombie(victim))
	{
		// Reward ammo packs to humans for damaging zombies?
		if (get_pcvar_num(cvar_ammop_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToZombies[attacker] += damage
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToZombies[attacker] / get_pcvar_float(cvar_ammop_zombie_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + (get_pcvar_num(cvar_ammop_damage) * how_many_rewards))
				g_DamageDealtToZombies[attacker] -= get_pcvar_float(cvar_ammop_zombie_damaged_hp) * how_many_rewards
			}
		}
	}
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Non-player kill or self kill
	if (victim == attacker || !is_user_connected(attacker))
		return;
	
	// Ignore ammo pack rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_ammop_nemesis_ignore))
		return;
	
	// Ignore ammo pack rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_ammop_survivor_ignore))
		return;
	
	// Reward ammo packs to attacker for the kill
	if (zp_core_is_zombie(victim))
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + get_pcvar_num(cvar_ammop_zombie_killed))
	else
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + get_pcvar_num(cvar_ammop_human_killed))
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
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
			else
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_winner))
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
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_winner))
			else
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
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
			
			zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
		}
	}
}

public client_disconnect(id)
{
	// Clear damage after disconnecting
	g_DamageDealtToZombies[id] = 0.0
	g_DamageDealtToHumans[id] = 0.0
}
