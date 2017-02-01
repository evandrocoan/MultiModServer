/*
 *
 *	Author:		Cheesy Peteza
 *	Date:		18-Mar-2004
 *
 *
 *	Description:	A generic AFK Kicker that should work with nearly all Half-Life mods.
 *			Tested with Natural-Selection v3.0 beta 3, Counter-Strike 1.6 and Day of Defeat.
 *
 *	Cvars:
 *			mp_afktime 90		Time a player is allowed to be AFK in seconds before they are kicked. (minimum 30 sec)
 *						They time is only accumulated while they are alive.
 *			mp_afkminplayers 8	Minimum number of players required to be on the server before the plugin starts kicking.
 *
 *
 *	Requirements:	AMXModX
 *
 *
 */

#include <amxmodx>

#define MIN_AFK_TIME 30		// I use this incase stupid admins accidentally set mp_afktime to something silly.
#define WARNING_TIME 15		// Start warning the user this many seconds before they are about to be kicked.
#define CHECK_FREQ 5		// This is also the warning message frequency.

new g_oldangles[33][3]
new g_afktime[33]
new bool:g_spawned[33] = {true, ...}

public plugin_init() {
	register_plugin("AFK Kicker","1.0b","Cheesy Peteza") 
	register_cvar("afk_version", "1.0b", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)

	register_cvar("mp_afktime", "90")	// Kick people AFK longer than this time
	register_cvar("mp_afkminplayers", "8")	// Only kick AFKs when there is atleast this many players on the server
	set_task(float(CHECK_FREQ),"checkPlayers",_,_,_,"b")
	register_event("ResetHUD", "playerSpawned", "be")
}

public checkPlayers() {
	for (new i = 1; i <= get_maxplayers(); i++) {
		if (is_user_alive(i) && is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i) && g_spawned[i]) {
			new newangle[3]
			get_user_origin(i, newangle)

			if ( newangle[0] == g_oldangles[i][0] && newangle[1] == g_oldangles[i][1] && newangle[2] == g_oldangles[i][2] ) {
				g_afktime[i] += CHECK_FREQ
				check_afktime(i)
			} else {
				g_oldangles[i][0] = newangle[0]
				g_oldangles[i][1] = newangle[1]
				g_oldangles[i][2] = newangle[2]
				g_afktime[i] = 0
			}
		}
	}
	return PLUGIN_HANDLED
}

check_afktime(id) {
	new numplayers = get_playersnum()
	new minplayers = get_cvar_num("mp_afkminplayers")
					
	if (numplayers >= minplayers) {
		new maxafktime = get_cvar_num("mp_afktime")
		if (maxafktime < MIN_AFK_TIME) {
			log_amx("cvar mp_afktime %i is too low. Minimum value is %i.", maxafktime, MIN_AFK_TIME)
			maxafktime = MIN_AFK_TIME
			set_cvar_num("mp_afktime", MIN_AFK_TIME)
		}

		if ( maxafktime-WARNING_TIME <= g_afktime[id] < maxafktime) {
			new timeleft = maxafktime - g_afktime[id]
			client_print(id, print_chat, "[AFK Kicker] You have %i seconds to move or you will be kicked for being AFK", timeleft)
		} else if (g_afktime[id] > maxafktime) {
			new name[32]
			get_user_name(id, name, 31)
			client_print(0, print_chat, "[AFK Kicker] %s was kicked for being AFK longer than %i seconds", name, maxafktime)
			log_amx("%s was kicked for being AFK longer than %i seconds", name, maxafktime)
			server_cmd("kick #%d ^"You were kicked for being AFK longer than %i seconds^"", get_user_userid(id), maxafktime)
		}
	}
}

public client_connect(id) {
	g_afktime[id] = 0
	return PLUGIN_HANDLED
}

public client_putinserver(id) {
	g_afktime[id] = 0
	return PLUGIN_HANDLED
}

public playerSpawned(id) {
	g_spawned[id] = false
	new sid[1]
	sid[0] = id
	set_task(0.75, "delayedSpawn",_, sid, 1)	// Give the player time to drop to the floor when spawning
	return PLUGIN_HANDLED
}

public delayedSpawn(sid[]) {
	get_user_origin(sid[0], g_oldangles[sid[0]])
	g_spawned[sid[0]] = true
	return PLUGIN_HANDLED
}