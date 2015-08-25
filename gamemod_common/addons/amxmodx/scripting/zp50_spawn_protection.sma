/*================================================================================
	
	-----------------------------
	-*- [ZP] Spawn Protection -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>

#define TASK_SPAWNPROTECT 100
#define ID_SPAWNPROTECT (taskid - TASK_SPAWNPROTECT)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_SpawnProtectBlockDamage

new cvar_spawn_protection_time, cvar_spawn_protection_humans, cvar_spawn_protection_zombies

public plugin_init()
{
	register_plugin("[ZP] Spawn Protection", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	cvar_spawn_protection_time = register_cvar("zp_spawn_protection_time", "3")
	cvar_spawn_protection_humans = register_cvar("zp_spawn_protection_humans", "1")
	cvar_spawn_protection_zombies = register_cvar("zp_spawn_protection_zombies", "1")
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove spawn protection from a previous round
	remove_task(id+TASK_SPAWNPROTECT)
	flag_unset(g_SpawnProtectBlockDamage, id)
	
	// Enable spawn protection?
	if (get_pcvar_float(cvar_spawn_protection_time) > 0.0)
	{
		if (zp_core_is_zombie(id))
		{
			// Spawn protection disabled for zombies?
			if (!get_pcvar_num(cvar_spawn_protection_zombies))
				return;
		}
		else
		{
			// Spawn protection disabled for humans?
			if (!get_pcvar_num(cvar_spawn_protection_humans))
				return;
		}
		
		// Do not take damage
		flag_set(g_SpawnProtectBlockDamage, id)
		
		// Set task to remove it
		set_task(get_pcvar_float(cvar_spawn_protection_time), "remove_spawn_protection", id+TASK_SPAWNPROTECT)
	}
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has spawn protection
	if (flag_get(g_SpawnProtectBlockDamage, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when victim has spawn protection
	if (flag_get(g_SpawnProtectBlockDamage, victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Remove spawn protection task
	remove_task(victim+TASK_SPAWNPROTECT)
	flag_unset(g_SpawnProtectBlockDamage, victim)
}

// Remove Spawn Protection Task
public remove_spawn_protection(taskid)
{
	// Remove spawn protection
	flag_unset(g_SpawnProtectBlockDamage, ID_SPAWNPROTECT)
}

public client_disconnect(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_SPAWNPROTECT)
	flag_unset(g_SpawnProtectBlockDamage, id)
}