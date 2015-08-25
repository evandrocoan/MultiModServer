/*================================================================================
	
	-----------------------
	-*- [ZP] Ammo Packs -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zp50_core>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

#define TASK_HIDEMONEY 100
#define ID_HIDEMONEY (taskid - TASK_HIDEMONEY)

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSMONEY = 115

const HIDE_MONEY_BIT = (1<<5)

#define MAXPLAYERS 32

new g_MaxPlayers
new g_MsgHideWeapon, g_MsgCrosshair
new g_AmmoPacks[MAXPLAYERS+1]

new cvar_starting_ammo_packs, cvar_disable_money

public plugin_init()
{
	register_plugin("[ZP] Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MaxPlayers = get_maxplayers()
	g_MsgHideWeapon = get_user_msgid("HideWeapon")
	g_MsgCrosshair = get_user_msgid("Crosshair")
	
	cvar_starting_ammo_packs = register_cvar("zp_starting_ammo_packs", "5")
	cvar_disable_money = register_cvar("zp_disable_money", "0")
	
	register_event("ResetHUD", "event_reset_hud", "be")
	register_message(get_user_msgid("Money"), "message_money")
}

public plugin_natives()
{
	register_library("zp50_ammopacks")
	register_native("zp_ammopacks_get", "native_ammopacks_get")
	register_native("zp_ammopacks_set", "native_ammopacks_set")
}

public native_ammopacks_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_AmmoPacks[id];
}

public native_ammopacks_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new amount = get_param(2)
	
	g_AmmoPacks[id] = amount
	return true;
}

public client_putinserver(id)
{
	g_AmmoPacks[id] = get_pcvar_num(cvar_starting_ammo_packs)
}

public client_disconnect(id)
{
	remove_task(id+TASK_HIDEMONEY)
}

public event_reset_hud(id)
{
	// Hide money?
	if (get_pcvar_num(cvar_disable_money))
		set_task(0.1, "task_hide_money", id+TASK_HIDEMONEY)
}

// Hide Player's Money Task
public task_hide_money(taskid)
{
	// Hide money
	message_begin(MSG_ONE, g_MsgHideWeapon, _, ID_HIDEMONEY)
	write_byte(HIDE_MONEY_BIT) // what to hide bitsum
	message_end()
	
	// Hide the HL crosshair that's drawn
	message_begin(MSG_ONE, g_MsgCrosshair, _, ID_HIDEMONEY)
	write_byte(0) // toggle
	message_end()
}

public message_money(msg_id, msg_dest, msg_entity)
{
	// Disable money setting enabled?
	if (!get_pcvar_num(cvar_disable_money))
		return PLUGIN_CONTINUE;
	
	fm_cs_set_user_money(msg_entity, 0)
	return PLUGIN_HANDLED;
}

// Set User Money
stock fm_cs_set_user_money(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSMONEY, value)
}