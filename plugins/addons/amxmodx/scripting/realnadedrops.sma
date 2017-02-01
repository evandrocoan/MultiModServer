/* AMX Mod X
*   Real Nade Drops
*
* (c) Copyright 2005-2006 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION
*       Plugin allow to players drop grenades while alive and leave grenades on death.
*
*     FEATURES
*       Plugin obey all weapon drop/leave/collect/remove CS standards.
*       - "drop [weapon_name]" command support
*       - CS standard-like weapon switching after drop
*       - death players leave nades on any death type
*       - cleanup of dropped nades on every new round
*       - unique throw-on-death fix
*       - server crash protection
*       - buy/drop flood protection
*
*     MODULES
*       fakemeta 1.71+
*
*     COMMANDS
*       rnd_alive [0|1] (default: 1) - disallows/allows to alive players drop nades
*       rnd_death [0|1] (default: 1) - disables/enables drop player nades on death
*       rnd_buy [0|1] (default: 1) - disables/enables alive drops mode during buytime
*
*     VERSIONS
*       0.4   now only fakemeta (v1.71+) module instead of engine+cstrike modules required
*             excluded "rnd_fun" command (not work properly under the current version)
*             added "rnd_buy" command which allows to restrict alive drops mode during buytime
*             added description for all commands which can be listed with "amx_help" command
*             now on player's death dropped nades recieves velocity accordingly
*             now total number of the dropped nades not re-counted every nade drop
*             immediate nade drop/collect prevention method changed to "on ground" check
*             made code optimization and some other improvements
*       0.3.1 fixed: "To many dropped nades on the map!" message was never displayed
*             added client center text error message in case nade entity not created
*       0.3   excluded "fake" version of plugin
*             fakemeta module not required anymore
*             fixed: nade entity wasn't actually removed on collect
*             nade drop attempt recognize method changed to "drop" client command hook
*             added "drop [weapon_name]" command support
*             added limit of total number of dropped nades to prevent possibility of server crash
*             code changed so exploits can't be used so corresponding protection methods removed
*             added fun drops mode for alive players
*             CVARs replaced with CVAR-behaviour-like commands
*             added CS standard-like weapon switching after drop for alive players
*             changed death recognize method to distinguish any death type
*             new round (freezetime) start recognize method changed to more efficient one
*             drop/collect delay method changed to nade think
*             some other changes and additions
*       0.2   included "fake" version of plugin (fake entity, fake collect)
*             restricted ability of using nade multiple drop exploit
*             restricted ability of using nade drop/buy exploit
*             fixed: duplicate of throwed and exploded on death nade also remain on the ground
*             cleanup of all dropped nades take place on every new round (freezetime) start
*             geometric nade immediate drop/collect prevention method changed to touch ignore
*             some other small changes and additions
*       0.1   first release
*/

/* *************************************************** Init **************************************************** */

#include <amxmodx>	// AMX Mod X 1.71+ required, check your addons/metamod/plugins.ini
#include <fakemeta>	// fakemeta module required, check your configs/modules.ini
#include <amxmisc>	// this is not a module!

// plugin's main information
#define PLUGIN_NAME "Real Nade Drops"
#define PLUGIN_VERSION "0.4"
#define PLUGIN_AUTHOR "VEN"

// OPTIONS BELOW

// console commands' names
new CMD_ALIVE[] = "rnd_alive"
new CMD_BUY[] = "rnd_buy"
new CMD_DEATH[] = "rnd_death"

// console commands' access level
#define CMD_ACCESS_LEVEL ADMIN_CVAR

// modes' default state (true: ON, false: OFF)
new bool:MODE_ALIVE = true
new bool:MODE_BUY = true
new bool:MODE_DEATH = true

// uncomment to allow alive drops mode during buytime only for players who is outside buyzone (for rnd_buy 0)
//#define OBEY_BUYZONE

// center text client message (for rnd_buy 0)
#if defined OBEY_BUYZONE
	new MSG_BUY[] = "You have to be outside buyzone!"
#else
	new MSG_BUY[] = "You have to wait %d second(s)!"
#endif

// center text client message
new MSG_TOMANY[] = "To many dropped nades on the map!"

// error log and center text client message
new MSG_ERROR[] = "ERROR: Unable to create grenade entity!"

// max. allowed number of the dropped nades
#define MAX_NADE_ENTITIES 192

// nade unique classname
new NADE_NAME[] = "real_nade"

// for alive drops
#define NADE_PLR_DIFF_ANGLE_HOR 0 // player/nade horisontal angle difference in degrees
#define NADE_VELOCITY 350 // nade drop start velocity

// not really a configurable value unless you edited every corresponding array
#define NADE_TYPES 3 // nuber of nade types

// for drop on death
new const NADE_PLR_DIFF_DIST[NADE_TYPES] = {8, 8, 8} // player/nade distance difference
new const NADE_DIFF_DIST[NADE_TYPES] = {14, 0, -14} // nades distance difference
new const NADE_PLR_DIFF_ANGLE[NADE_TYPES] = {45, 45, 45} // player/nade angle difference in degrees

// uncomment to disable automatic 32/64bit processor detection
// possible values are <0: 32bit | 1: 64bit>
//#define PROCESSOR_TYPE 0

// OPTIONS ABOVE

// player nades ammo private data 32bit offsets
#define OFFSET_AMMO_HE_32BIT 388
#define OFFSET_AMMO_FB_32BIT 387
#define OFFSET_AMMO_SG_32BIT 389

// player nades ammo private data 64bit offsets
#define OFFSET_AMMO_HE_64BIT 437
#define OFFSET_AMMO_FB_64BIT 436
#define OFFSET_AMMO_SG_64BIT 438

// player nades ammo linux offset difference
#define OFFSET_AMMO_LINUXDIFF 5

// determination of actual offsets
#if !defined PROCESSOR_TYPE // is automatic 32/64bit processor detection?
	#if cellbits == 32 // is the size of a cell are 32 bits?
		// then considering processor as 32bit
		new NADE_OFFSET_AMMO[NADE_TYPES] = {OFFSET_AMMO_HE_32BIT, OFFSET_AMMO_FB_32BIT, OFFSET_AMMO_SG_32BIT}
	#else // in other case considering the size of a cell as 64 bits
		// and then considering processor as 64bit
		new NADE_OFFSET_AMMO[NADE_TYPES] = {OFFSET_AMMO_HE_64BIT, OFFSET_AMMO_FB_64BIT, OFFSET_AMMO_SG_64BIT}
	#endif
#else // processor type specified by PROCESSOR_TYPE define
	#if PROCESSOR_TYPE == 0 // 32bit processor defined
		new NADE_OFFSET_AMMO[NADE_TYPES] = {OFFSET_AMMO_HE_32BIT, OFFSET_AMMO_FB_32BIT, OFFSET_AMMO_SG_32BIT}
	#else // considering that 64bit processor defined
		new NADE_OFFSET_AMMO[NADE_TYPES] = {OFFSET_AMMO_HE_64BIT, OFFSET_AMMO_FB_64BIT, OFFSET_AMMO_SG_64BIT}
	#endif
#endif

new NADE_ENTITY[] = "armoury_entity" // nade entity type

new const NADE_WEAPON_ID[NADE_TYPES] = {CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE} // nade weapon id
new const NADE_WEAPON_NAME[NADE_TYPES][] = {"weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade"} // nade weapon name
new const NADE_ITEM_ID[NADE_TYPES][] = {"15", "14", "18"} // nade armoury item id

#define WEAPONS 29 // number of weapons in weapons priority list
// This is CS standard-like weapons priority list. Weapon ids placed in decreasing priority order.
// Actually this list keep only follow exact priority order: primary, secondary, c4, grenades, knife.
// Inside primary and secondary class here are no exact priority order because by default player can have only one weapon of each class.
// Inside grenades class here are exact priority order because player can have different grenades at the same time.
new const WEAPON_PRIORITY[WEAPONS] = {3, 5, 7, 8, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24, 27, 28, 30, 1, 10, 11, 16, 17, 26, 6, 4, 9, 25, 29}

// HLSDK constants
#define	FL_ONGROUND (1<<9)
#define	EF_NODRAW 128
#define IN_ATTACK (1<<0)

new bool:g_freezetime
new Float:g_round_start_time

#define MAX_PLAYERS 32
new bool:g_alive[MAX_PLAYERS + 1]
new bool:g_buyzone[MAX_PLAYERS + 1]

new g_nades_number

new g_maxplayers
new g_pcvar_buytime
new g_ipsz_armoury_entity

// strings cache
new g_classname[] = "classname"
new g_lastinv[] = "lastinv"
new g_item[] = "item"
new g_count[] = "count"

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR) // register plugin

	// register console commands
	register_concmd(CMD_ALIVE, "concmd_config", CMD_ACCESS_LEVEL, "[0|1] - disallows/allows to alive players drop nades")
	register_concmd(CMD_BUY, "concmd_config", CMD_ACCESS_LEVEL, "[0|1] - disables/enables alive drops mode during buytime")
	register_concmd(CMD_DEATH, "concmd_config", CMD_ACCESS_LEVEL, "[0|1] - disables/enables drop player nades on death")

	// register events and log events
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") // new round
	register_event("ResetHUD", "event_hud_reset", "be") // alive player hud reset
	register_event("Health", "event_dying", "bd", "1=0") // player dying (but not only!)
	register_event("StatusIcon", "event_buyzone_icon", "b", "2=buyzone") // buyzone icon
	register_logevent("logevent_round_start", 2, "0=World triggered", "1=Round_Start") // round start

	// register client console commands
	register_clcmd("drop", "clcmd_drop") // register "drop" client console command
	register_clcmd("fullupdate", "clcmd_fullupdate") // register "fullupdate" client console command

	// register forwards
	register_forward(FM_Touch, "forward_touch") // register touch forward

	// caching some values
	g_maxplayers = get_maxplayers() // actual max. players number
	g_pcvar_buytime = get_cvar_pointer("mp_buytime") // mp_buytime CVAR pointer
	g_ipsz_armoury_entity = engfunc(EngFunc_AllocString, NADE_ENTITY) // nade original integer classname
}

/* *************************************************** Base **************************************************** */

public clcmd_drop(id) {
	if (!MODE_ALIVE || !is_user_alive(id)) // if nade drops not allowed to alive players or player isn't alive
		return PLUGIN_CONTINUE

	new current, clip, ammo, i
	current = get_user_weapon(id, clip, ammo) // get id and ammo of current weapon

	new arg[21]
	read_argv(1, arg, 20) // get name of weapon to drop
	if (!arg[0]) { // if weapon name isn't specified
		if (!ammo) // if no weapon ammo (usually knife)
			return PLUGIN_CONTINUE

		// get nade index
		for (i = 0; i < NADE_TYPES; ++i) {
			if (current == NADE_WEAPON_ID[i]) // if current weapon is nade
				break
		}
	}
	else {
		// check if weapon to drop is nade
		for (i = 0; i < NADE_TYPES; ++i) {
			if (equal(arg, NADE_WEAPON_NAME[i])) // if weapon to drop is nade
				break
		}
	}

	if (i == NADE_TYPES) // if weapon to drop isn't nade
		return PLUGIN_CONTINUE

	new weapon = NADE_WEAPON_ID[i]
	ammo = get_pdata_int(id, NADE_OFFSET_AMMO[i], OFFSET_AMMO_LINUXDIFF) // get nade actual ammo
	if (ammo < 1) // if no nade ammo
		return PLUGIN_CONTINUE

	if (g_nades_number >= MAX_NADE_ENTITIES) {
		client_print(id, print_center, MSG_TOMANY)
		return PLUGIN_HANDLED
	}

	if (!MODE_BUY && !g_freezetime) { // is rnd_buy is 0 and currently not a freezetime
		new Float:wait = get_pcvar_float(g_pcvar_buytime) * 60 - (get_gametime() - g_round_start_time)
		if (wait > 0) { // is currently a buytime
			#if defined OBEY_BUYZONE
				if (g_buyzone[id]) { // is player in buyzone
					client_print(id, print_center, MSG_BUY)
					return PLUGIN_HANDLED
				}
			#else
				new seconds = floatround(wait, floatround_floor)
				client_print(id, print_center, MSG_BUY, seconds ? seconds : 1)
				return PLUGIN_HANDLED
			#endif
		}
	}

	new nade = engfunc(EngFunc_CreateNamedEntity, g_ipsz_armoury_entity) // create nade entity
	if (!nade) { // if nade entity not created
		client_print(id, print_center, MSG_ERROR) // client error center text message
		log_amx(MSG_ERROR) // log error
		return PLUGIN_HANDLED
	}

	g_nades_number++

	set_pdata_int(id, NADE_OFFSET_AMMO[i], --ammo, OFFSET_AMMO_LINUXDIFF) // reduce nade ammo over one unit
	if (!ammo) { // no more weapon ammo
		if (current == weapon) { // if current weapon is weapon to drop
			// CS standard-like weapon switching after drop
			for (new j = 0; j < WEAPONS; ++j) {
				if (user_has_weapon(id, WEAPON_PRIORITY[j]) && weapon != WEAPON_PRIORITY[j]) { // search for player main weapon id
					new wname[20] // longest weapon name is "weapon_smokegrenade" (19 characters long)
					get_weaponname(WEAPON_PRIORITY[j], wname, 19) // get name of player main weapon
					engclient_cmd(id, wname) // switch player to his main weapon
					break
				}
			}
		}
		else {
			// this is necessary to strip nade properly
			engclient_cmd(id, NADE_WEAPON_NAME[i]) // switch to nade
			engclient_cmd(id, g_lastinv) // switch to previous weapon
		}
	}

	set_nade_kvd(nade, g_item, NADE_ITEM_ID[i]) // set nade item type

	set_pev(nade, pev_classname, NADE_NAME) // set nade unique classname

	// setup nade start origin
	new Float:origin[3]
	pev(id, pev_origin, origin)
	engfunc(EngFunc_SetOrigin, nade, origin)

	// setup nade angles
	new Float:angles[3]
	pev(id, pev_angles, angles)
	angles[0] = 0.0 // we don't need specific vertical angle
	angles[1] += NADE_PLR_DIFF_ANGLE_HOR
	set_pev(nade, pev_angles, angles)

	// setup nade velocity
	new Float:anglevec[3], Float:velocity[3]
	pev(id, pev_v_angle, anglevec)
	engfunc(EngFunc_MakeVectors, anglevec)
	global_get(glb_v_forward, anglevec)
	velocity[0] = anglevec[0] * NADE_VELOCITY
	velocity[1] = anglevec[1] * NADE_VELOCITY
	velocity[2] = anglevec[2] * NADE_VELOCITY
	set_pev(nade, pev_velocity, velocity)

	dllfunc(DLLFunc_Spawn, nade) // spawn nade

	return PLUGIN_HANDLED
}

public forward_touch(nade, id) {
	if (!id || id > g_maxplayers || nade <= g_maxplayers) // check nade/player indexes
		return FMRES_IGNORED

	new class[32]
	pev(nade, pev_classname, class, 31)
	if (!equal(class, NADE_NAME)) // check if it's not dropped nade
		return FMRES_IGNORED

	if (!(pev(nade, pev_flags) & FL_ONGROUND)) // if nade is still not on the ground
		return FMRES_SUPERCEDE // prevent immediate nade drop/collect

	if (pev(nade, pev_effects) & EF_NODRAW) { // nade was collected and it's not visible because of NODRAW effect
		engfunc(EngFunc_RemoveEntity, nade) // remove nade entity
		g_nades_number--
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

public event_hud_reset(id) {
	g_alive[id] = true
}

public event_dying(id) {
	if (!g_alive[id]) // if player already dead
		return

	g_alive[id] = false

	if (!MODE_DEATH) // if drop player nades on death is disabled
		return

	new ammo_fix[NADE_TYPES]
	if (pev(id, pev_button) & IN_ATTACK) { // if player hold down attack button
		new clip, ammo, weapon = get_user_weapon(id, clip, ammo) // get id of current weapon

		for (new i = 0; i < NADE_TYPES; ++i) {
			if (weapon == NADE_WEAPON_ID[i]) { // if current weapon is nade
				ammo_fix[i] = -1 // create ammo fix since nade will be throwed
				break
			}
		}
	}

	for (new i = 0; i < NADE_TYPES; ++i) {
		new ammo = get_pdata_int(id, NADE_OFFSET_AMMO[i], OFFSET_AMMO_LINUXDIFF) // get nade actual ammo
		ammo += ammo_fix[i] // apply ammo fix
		if (ammo < 1) // if no nade ammo
			continue

		new nade = engfunc(EngFunc_CreateNamedEntity, g_ipsz_armoury_entity) // create nade entity
		if (!nade) { // if nade entity not created
			log_amx(MSG_ERROR) // log error
			continue
		}

		g_nades_number++

		set_nade_kvd(nade, g_item, NADE_ITEM_ID[i]) // set nade item type

		// setup nade ammo
		new count[4]
		num_to_str(ammo, count, 3)
		set_nade_kvd(nade, g_count, count)

		set_pev(nade, pev_classname, NADE_NAME) // set nade unique classname

		// setup nade origin and angle
		new Float:origin[3]
		pev(id, pev_origin, origin)
		new Float:angles[3]
		pev(id, pev_angles, angles)
		origin[0] += floatcos(angles[1], degrees) * NADE_PLR_DIFF_DIST[i] + floatcos(angles[1] + 90, degrees) * NADE_DIFF_DIST[i]
		origin[1] += floatsin(angles[1], degrees) * NADE_PLR_DIFF_DIST[i] + floatsin(angles[1] + 90, degrees) * NADE_DIFF_DIST[i]
		engfunc(EngFunc_SetOrigin, nade, origin)
		angles[0] = 0.0 // we don't need specific vertical angle
		angles[1] += NADE_PLR_DIFF_ANGLE[i]
		set_pev(nade, pev_angles, angles)

		// setup nade velocity
		new Float:velocity[3]
		pev(id, pev_velocity, velocity)
		set_pev(nade, pev_velocity, velocity)

		dllfunc(DLLFunc_Spawn, nade) // spawn nade
	}
}

public event_new_round() {
	g_freezetime = true
	g_nades_number = 0

	// remove all dropped nades
	new nade = -1
	while ((nade = engfunc(EngFunc_FindEntityByString, nade, g_classname, NADE_NAME))) // find nade entity id by nade unique classname
		engfunc(EngFunc_RemoveEntity, nade) // remove nade entity
}

public logevent_round_start() {
	g_freezetime = false
	g_round_start_time = get_gametime()
}

public event_buyzone_icon(id) {
	g_buyzone[id] = bool:read_data(1)
}

public client_disconnect(id) {
	g_alive[id] = false // if player is disconnected he is not alive
	g_buyzone[id] = false
}

public clcmd_fullupdate(id) {
	return PLUGIN_HANDLED // can block fake "not in buyzone" exploit
}

// function to view and change plugin modes state via console commands
public concmd_config(id, level, cid) {
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new command[32], argument[2], bool:value
	read_argv(0, command, 31)
	new bool:change = false
	if (read_argc() > 1) {
		change = true
		read_argv(1, argument, 1)
		value = bool:str_to_num(argument)
	}

	if (equali(command, CMD_ALIVE)) {
		if (change)
			MODE_ALIVE = value
		else
			value = MODE_ALIVE
	}
	else if (equali(command, CMD_BUY)) {
		if (change)
			MODE_BUY = value
		else
			value = MODE_BUY
	}
	else if (equali(command, CMD_DEATH)) {
		if (change)
			MODE_DEATH = value
		else
			value = MODE_DEATH
	}

	if (!change)
		console_print(id, "^"%s^" is ^"%d^"", command, value)

	return PLUGIN_HANDLED
}

set_nade_kvd(nade, const key[], const value[]) {
	set_kvd(0, KV_ClassName, NADE_ENTITY)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	return dllfunc(DLLFunc_KeyValue, nade, 0)
}

/* **************************************************** EOF **************************************************** */
