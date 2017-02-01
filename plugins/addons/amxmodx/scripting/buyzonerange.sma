/* AMX Mod X
*   Buyzone Range
*
* (c) Copyright 2006 by VEN
*
* This file is provided as is (no warranties)
*
*     DESCRIPTION
*       Plugin allows to set buyzone range: everywhere/nowhere/default
*       Note: AMX Mod X v1.75+ required
*
*     CVARs
*       bz_range (0: Nowhere, 1: Default, 2: Everywhere, default: 1)
*       Note: CVAR change is accepted every new round and player spawn
*/

#include <amxmodx>
#include <fakemeta>

// plugin's main information
#define PLUGIN_NAME "Buyzone Range"
#define PLUGIN_VERSION "0.1"
#define PLUGIN_AUTHOR "VEN"

// OPTIONS BELOW

// CVAR name and its default value
#define CVAR_NAME "bz_range"
#define CVAR_DEF "2"

// uncomment to disable automatic 32/64bit processor detection
// possible values is <0: 32bit | 1: 64bit>
//#define PROCESSOR_TYPE 0

// OPTIONS ABOVE

// mapzone player's private data offset
#define OFFSET_32BIT 235
#define OFFSET_64BIT 268

// offset's linux difference
#define OFFSET_LINUX_DIFF 5

// buyzone bit
#define BIT_BUYZONE (1<<0)

// determination of actual offsets
#if !defined PROCESSOR_TYPE // is automatic 32/64bit processor detection?
	#if cellbits == 32 // is the size of a cell 32 bits?
		// then considering processor as 32 bit
		#define OFFSET OFFSET_32BIT
	#else // in other case considering the size of a cell as 64 bits
		// and then considering processor as 64 bit
		#define OFFSET OFFSET_64BIT
	#endif
#else // processor type is specified by PROCESSOR_TYPE define
	#if PROCESSOR_TYPE == 0 // 32bit processor defined
		#define OFFSET OFFSET_32BIT
	#else // considering that defined 64bit processor
		#define OFFSET OFFSET_64BIT
	#endif
#endif

// get/set mapzone bits
#define CS_GET_USER_MAPZONES(%1) get_pdata_int(%1, OFFSET, OFFSET_LINUX_DIFF)
#define CS_SET_USER_MAPZONES(%1,%2) set_pdata_int(%1, OFFSET, %2, OFFSET_LINUX_DIFF)

// fake buyzone absmin and absmax
new Float:g_buyzone_min[3] = {-8192.0, -8192.0, -8192.0}
new Float:g_buyzone_max[3] = {-8191.0, -8191.0, -8191.0}

new g_buyzone
new g_pcvar

new bool:g_enabled
new g_bit

new bool:g_new_round
new g_maxplayers

//#define MAX_PLAYERS 32
new bool:g_alive[33]

new g_msgid_icon
new g_icon_name[] = "buyzone"

#define ICON_R 0
#define ICON_G 160
#define ICON_B 0

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	g_pcvar = register_cvar(CVAR_NAME, CVAR_DEF)

	register_clcmd("buy", "menu_block")
	register_clcmd("buyequip", "menu_block")

	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("ResetHUD", "event_player_alive", "be")
	register_event("Health", "event_player_dead", "bd", "1=0")

	register_forward(FM_PlayerPostThink, "forward_player_postthink")

	g_msgid_icon = get_user_msgid("StatusIcon")
	register_message(g_msgid_icon, "message_status_icon")

	g_maxplayers = get_maxplayers()

	g_buyzone = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
	dllfunc(DLLFunc_Spawn, g_buyzone)
	engfunc(EngFunc_SetSize, g_buyzone, g_buyzone_min, g_buyzone_max)

	update_state_vars()
}

public forward_player_postthink(id) {
	if (g_alive[id] && g_enabled) {
		switch (g_bit) {
			case BIT_BUYZONE: dllfunc(DLLFunc_Touch, g_buyzone, id)
			default: CS_SET_USER_MAPZONES(id, CS_GET_USER_MAPZONES(id) & ~BIT_BUYZONE)
		}
	}
}

public event_new_round() {
	g_new_round = true
	set_task(0.1, "task_unset_var")
	update_state_vars()
}

public task_unset_var() {
	g_new_round = false
}

public event_player_alive(id) {
	g_alive[id] = true

	if (g_new_round) {
		if (g_enabled)
			draw_buyzone_icon(id, g_bit)
	}
	else {
		update_state_vars()
		if (g_enabled) {
			for (new i = 1; i <= g_maxplayers; ++i) {
				if (g_alive[i])
					draw_buyzone_icon(i, g_bit)
			}
		}
	}
}

public event_player_dead(id) {
	g_alive[id] = false
}

public client_disconnect(id) {
	g_alive[id] = false
}

public message_status_icon(msg_id, msg_dest, id) {
	if (!g_alive[id] || !g_enabled)
		return PLUGIN_CONTINUE

	new icon[8]
	get_msg_arg_string(2, icon, 7)
	if (equal(icon, g_icon_name))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public menu_block(id) {
	if (g_alive[id] && g_enabled && !g_bit)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

update_state_vars() {
	new cvar_value = get_pcvar_num(g_pcvar)
	g_enabled = true
	switch (cvar_value) {
		case  0: g_bit = 0
		case  1: g_enabled = false
		default: g_bit = BIT_BUYZONE
	}
}

draw_buyzone_icon(id, draw) {
	message_begin(MSG_ONE, g_msgid_icon, _, id)
	write_byte(draw)
	write_string(g_icon_name)
	if (draw) {
		write_byte(ICON_R)
		write_byte(ICON_G)
		write_byte(ICON_B)
	}
	message_end()
}
