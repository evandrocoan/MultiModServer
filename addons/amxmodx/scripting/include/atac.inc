/* ATAC Functions
*
* Copyright © 2006-2008, ATAC Team
*
* This file is provided as is (no warranties).
*
*/

#if defined _atac_included
	#endinput
#endif
#define _atac_included

#pragma reqlib atac

// The following two define how many plugins can hook into ATAC.
// remember: atac.sma will need to be recompiled if you change these values!
#define MAX_PUNISHMENTS 32
#define MAX_ADDONS 8

#define ATAC_HOOK_CONTINUE 0
#define ATAC_HOOK_SPAWNED 1
#define ATAC_HOOK_RESET 2

// Register a punishment returns -1 on failure. Allows hooking any forward from [Punishments]
native atac_register_punishment();

// Called when ATAC builds it's Team Kill Menu. You must return with EngFunc_AllocString! [Punishments]
forward atac_punishment_name(victim);

// Called when a punishment is chosen. [Punishments]
forward atac_player_punish(killer, victim);

// Called when a player dies and just before a player respawns. [Punishments]
forward atac_player_reset(killer, victim);

// Called when a player (re)spawns. [Punishments]
forward atac_player_spawn(killer, victim);


// Register a addon returns -1 on failure. Allows hooking any forward from [Addons]
native atac_register_addon();

// Called when a team attack occurs. [Addons]
forward atac_team_attack(attacker, victim, damage);

// Called when a team kill occurs. [Addons]
forward atac_team_kill(killer, victim);

// Called when a team kill increment occurs. This forward can supercede ATAC's banning system by: return PLUGIN_HANDLED [Addons]
forward atac_punished(killer, const name[], const authid[], bantype);

// Called when a punishment activates. [Addons]
forward atac_punishment_activated(punishment_id, killer, victim);


// Returns -1 on failure or plugin index if punishment is valid.
native is_punishment_valid(index);

// Returns maximum amount of punishments registered.
native get_maxpunishments();

// Gets the amount of Team Attacks done by a player.
native get_atac_attacks(id);

// Sets the amount of Team Attacks done by a player. If attacker & victim teams match, Team Attack is simulated.
native set_atac_attacks(attacker, victim, amount=-1);

// Gets the amount of Team Kills done by a player.
native get_atac_kills(id);

// Sets the amount of Team Kills done by a player.
/* special:
	-1	- No action
	0	- Simulate a real team kill longs the killer & victim teams match!
	1	- Fun Menu
	2+	- Activate a specific punishment
*/
native set_atac_kills(killer, victim, amount=-1, special=-1);
