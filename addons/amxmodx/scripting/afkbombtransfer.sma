/* AMX Mod X
*   AFK Bomb Transfer
*
* (c) Copyright 2006 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION
*       Plugin allow transfer bomb from AFK terrorist to closest non-AFK teammate.
*       Plugin will have no effect:
*         - at the freezetime
*         - if bomb is planting
*         - on non-bomb maps (comment #define BOMB_MAP_CHECK to suppress)
*
*     MODULES
*       fakemeta
*
*     CVARS
*       afk_bombtransfer_spawn (N: seconds, default: 7) - max. allowed bomb carrier AFK time
*         affects on spawned AFK bomb carrier which never moved after spawn
*
*       afk_bombtransfer_time (N: seconds, default: 15) - max. allowed bomb carrier AFK time
*         affects on any AFK bomb carrier except one which obey previous CVAR
*
*     HUD MESSAGES
*       Terrorist team (green color)
*         Bomb transferred to "NEW_CARRIER_NAME"
*         since "AFK_CARRIER_NAME" is AFK
*
*       New bomb carrier (yellow color)
*         You got the bomb!
*
*       Note: by defult message display time is 7 seconds (define MSG_TIME)
*
*     VERSIONS
*       0.4   backpack transfer method greatly improved
*             added pcvar natives support (backward compatibility saved)
*             few code optimization
*       0.3   now fakemeta instead of engine required (efficiency++ if engine is disabled)
*             "non-bomb map" check can be disabled (//#define BOMB_MAP_CHECK)
*             backpack finding method improved
*             few code optimization
*             added comments to the plugin source code
*       0.2   fixed format issue
*             code optimized
*             description improved
*
*       0.1   first release
*/

/* *************************************************** Init **************************************************** */

#include <amxmodx>
#include <fakemeta>

// plugin's main information
#define PLUGIN_NAME "AFK Bomb Transfer"
#define PLUGIN_VERSION "0.4"
#define PLUGIN_AUTHOR "VEN"

// comment to avoid autodisabling the plugin on maps which not contain bomb targets
#define BOMB_MAP_CHECK

// float value, hud messages display time (in seconds)
#define MSG_TIME 7.0

// CVAR name, affects on spawned AFK bomb carrier which never moved after spawn
new CVAR_SPAWN[] = "afk_bombtransfer_spawn"

// CVAR value, max. allowed bomb carrier AFK time (in seconds)
new DEFAULT_SPAWN[] = "7"

// CVAR name, affects on any AFK bomb carrier except one which obey previous CVAR
new CVAR_TIME[] = "afk_bombtransfer_time"

// CVAR value, max. allowed bomb carrier AFK time (in seconds)
new DEFAULT_TIME[] = "15"

// do not set this value less than "maxplayers"
#define MAX_PLAYERS 32

// initial AMXX version number supported CVAR pointers in get/set_pcvar_* natives
#define CVAR_POINTERS_AMXX_INIT_VER_NUM 170

// determine if get/set_pcvar_* natives can be used
#if defined AMXX_VERSION_NUM && AMXX_VERSION_NUM >= CVAR_POINTERS_AMXX_INIT_VER_NUM
	#define CVAR_POINTERS
	new g_pcvar_spawn
	new g_pcvar_time
#endif

new TEAM[] = "TERRORIST"
new WEAPON[] = "weapon_c4"

#define	FL_ONGROUND (1<<9)

new bool:g_freezetime = true
new bool:g_spawn
new bool:g_planting

new g_carrier

new g_pos[MAX_PLAYERS + 1][3]
new g_time[MAX_PLAYERS + 1]

new g_maxplayers

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

#if defined CVAR_POINTERS
	g_pcvar_spawn = register_cvar(CVAR_SPAWN, DEFAULT_SPAWN)
	g_pcvar_time = register_cvar(CVAR_TIME, DEFAULT_TIME)
#else
	register_cvar(CVAR_SPAWN, DEFAULT_SPAWN)
	register_cvar(CVAR_TIME, DEFAULT_TIME)
#endif

#if defined BOMB_MAP_CHECK
	// is current map not contain bomb targets?
	if (!engfunc(EngFunc_FindEntityByString, -1, "classname", "func_bomb_target"))
		return
#endif

	register_event("WeapPickup", "event_got_bomb", "be", "1=6")
	register_event("BarTime", "event_bar_time", "be")
	register_event("TextMsg", "event_bomb_drop", "bc", "2=#Game_bomb_drop")
	register_event("TextMsg", "event_bomb_drop", "a", "2=#Bomb_Planted")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")

	register_logevent("logevent_round_start", 2, "1=Round_Start")

	set_task(1.0, "task_afk_check", _, _, _, "b") // plugin's core loop

	g_maxplayers = get_maxplayers()
}

/* *************************************************** Base **************************************************** */

public event_new_round() {
	g_freezetime = true
	g_spawn = true
	g_planting = false
	g_carrier = 0
}

public event_got_bomb(id) {
	g_carrier = id
}

public event_bar_time(id) {
	if (id == g_carrier) {
		g_planting = bool:read_data(1)
		get_user_origin(id, g_pos[id])
		g_time[id] = 0
	}
}

public event_bomb_drop() {
	g_spawn = false
	g_planting = false
	g_carrier = 0
}

public logevent_round_start() {
	new id[32], num
	get_players(id, num, "ae", TEAM)

	if (!num) // is server empty?
		return

	g_freezetime = false

	// update afk timers and current positions
	new x
	for (new i = 0; i < num; ++i) {
		x = id[i]
		get_user_origin(x, g_pos[x])
		g_time[x] = 0
	}
}

public task_afk_check() {
	if (g_freezetime) // is freezetime right now?
		return

	// afk check
	new id[32], num, x, origin[3]
	get_players(id, num, "ae", TEAM)
	for (new i = 0; i < num; ++i) {
		x = id[i]
		get_user_origin(x, origin)
		if (origin[0] != g_pos[x][0] || origin[1] != g_pos[x][1] || (x == g_carrier && g_planting)) {
			g_time[x] = 0
			g_pos[x][0] = origin[0]
			g_pos[x][1] = origin[1]
			if (g_spawn && x == g_carrier)
				g_spawn = false
		}
		else
			g_time[x]++
	}

	// is bomb not currently carried or Ts number less than 2?
	if (!g_carrier || num < 2)
		return

#if defined CVAR_POINTERS
	new max_time = get_pcvar_num(g_spawn ? g_pcvar_spawn : g_pcvar_time)
#else
	new max_time = get_cvar_num(g_spawn ? CVAR_SPAWN : CVAR_TIME)
#endif

	// is plugin disabled (cvar <= 0) or carrier isn't afk?
	if (max_time <= 0 || g_time[g_carrier] < max_time)
		return

	// find who from non-afk Ts is the closest to the afk carrier
	get_user_origin(g_carrier, origin)
	new min_dist = 999999, dist, recipient, origin2[3]
	for (new i = 0; i < num; ++i) {
		x = id[i]
		if (g_time[x] < max_time) {
			get_user_origin(x, origin2)
			dist = get_distance(origin, origin2)
			if (dist < min_dist) {
				min_dist = dist
				recipient = x
			}
		}
	}

	if (!recipient) // is all Ts afk?
		return

	new carrier = g_carrier
	engclient_cmd(carrier, "drop", WEAPON) // drop the backpack
	new c4 = engfunc(EngFunc_FindEntityByString, -1, "classname", WEAPON) // find weapon_c4 entity
	if (!c4)
		return

	new backpack = pev(c4, pev_owner) // get backpack entity
	if (backpack <= g_maxplayers)
		return

	// my backpack transfer trick (improved)
	set_pev(backpack, pev_flags, pev(backpack, pev_flags) | FL_ONGROUND)
	dllfunc(DLLFunc_Touch, backpack, recipient)

	// hud messages stuff below
	set_hudmessage(0, 255, 0, 0.35, 0.8, _, _, MSG_TIME)
	new message[128], c_name[32], r_name[32]
	get_user_name(carrier, c_name, 31)
	get_user_name(recipient, r_name, 31)
	format(message, 127, "Bomb transferred to ^"%s^"^nsince ^"%s^" is AFK", r_name, c_name)
	for (new i = 0; i < num; ++i)
		show_hudmessage(id[i], "%s", message)

	set_hudmessage(255, 255, 0, 0.42, 0.3, _, _, MSG_TIME, _, _, 3)
	show_hudmessage(recipient, "You got the bomb!")
}

/* **************************************************** EOF **************************************************** */
